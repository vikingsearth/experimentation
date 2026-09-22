# Hypothesis 2.1 - extending the tier ladder to local models

Date: 2026-09-10
Status: **complete.** Arm C run twice 2026-09-11, arm D 2026-09-21.
Follow-on: [hypothesis_4.md](hypothesis_4.md) (speed), [hypothesis_5.md](hypothesis_5.md) (other models)
Results: `optimization-exp/hyp2-1/reports/ARM-C-COMPARISON.md`
Continues: [hypothesis_2.md](hypothesis_2.md)
Results so far: [results_2.md](results_2.md)
Mechanism proven in: [hypothesis_1.md](hypothesis_1.md)

## What this adds

[Hypothesis 2](hypothesis_2.md) compared two Anthropic subagent tiers on a
fixed task. This adds two local tiers below them, using the same five briefs,
the same target, and the same sequential method, so all four sit on one ladder.

| Arm | Subagent engine | Runs on | Status |
|---|---|---|---|
| A | Haiku 4.5 | Subscription window | Done. 8.4/15 |
| B | Sonnet 5 | Subscription window | Done. 13.0/15 |
| **C** | **qwen3:8b, local** | **Nothing. Free** | **This document** |
| **D** | **gemma4:12b, local** | **Nothing. Free** | **This document** |

Everything is already built. The briefs exist, the target is fixed, the
ground-truth key exists, the grading protocol is established, and
[hypothesis 1](hypothesis_1.md) proved a local worker runs the Claude Code
harness end to end against the local ollama server.

## The question

Not "are local models as good". They will not be. The question is **where the
quality curve actually bends**, and whether the bend sits above or below the
point where work stops being useful.

Arm A already showed a cheap tier producing zero fabrications and a usable, if
shallower, result. If arm C holds that property, the argument for local work
during a spent window is strong. If it collapses, the ladder has a floor and we
know where it is.

## What is comparable, and what is not

This matters more than it looks, and it changes what the arms can claim.

| Measure | Comparable across all four arms? | Why |
|---|---|---|
| Quality, four dimensions | **Yes** | Same briefs, same target, same blind grader, same rubric |
| Fabrication count | **Yes** | Same ground-truth key, same mechanical check |
| Tool calls | **Yes** | Same tools available, same task |
| Wall-clock | **Yes**, if every arm stays sequential | Arms A and B were run one subagent at a time for exactly this reason |
| Completion rate | **Yes**, and new | Arms A and B completed 5 of 5. Local arms may not |
| **Token usage** | **No** | See below |
| Money | Not applicable | Local arms cost nothing. The comparison is window and time |

**Why tokens are not comparable.** Arms A and B ran as in-process subagents
carrying the full Claude Code harness. Arm A's five subagents consumed 337,673
tokens, most of it fixed overhead. Local workers run with `--bare`, which
[hypothesis 1](hypothesis_1.md) measured at under 1,000 tokens of system prompt
against roughly 32,000 for a full-harness worker. A local arm will therefore
report dramatically lower token counts while doing the same work, and that
number means nothing as a like-for-like.

Report local token usage as **tokens through the local engine**, in its own
column, never subtracted from or divided against arms A and B.

## Context risk, measured

This was the headline risk when the arm was proposed. Measuring both sides of
it, the models and the target, shrinks it considerably.

### What each model can actually hold

Read from the ollama API, not assumed. Run it yourself:

```bash
node optimization-exp/hyp2-1/ollama-context.mjs
```

| Model | Params | On disk | Architecture max | Modelfile `num_ctx` | Thinking |
|---|---|---|---|---|---|
| qwen3:8b | 8.2B | 4.9 GB | **40,960** | not set | yes |
| gemma4:12b | 11.9B | 7.0 GB | **262,144** | not set | yes |
| qwen3:30b | 30.5B | 17.3 GB | 262,144 | not set | yes |

Three things follow from that table.

1. **The daemon, not the model, is the binding constraint.** No model pins a
   `num_ctx` in its own Modelfile, so the daemon decides. It was observed
   serving 32,768 during the hypothesis 1 concurrency test.
2. **The two arms have very different ceilings if we ever raise it.**
   qwen3:8b tops out at 40,960, so raising the daemon past that buys it
   nothing. gemma4:12b could go to 262,144, memory permitting.
3. **Both models think**, which is the accumulation risk below, not a size risk.

The API stores the architecture ceiling family-prefixed, so the key differs per
model: `qwen3.context_length`, `gemma4.context_length`, `qwen3moe.context_length`.
The script finds it without knowing the family. The context a model was
*actually* loaded with is only visible in `/api/ps` while it is resident, so
check it during a run rather than before one.

### What the API does not tell you

Checked against `/api/show` on 2026-09-11, because both would have been useful.

| Question | Answer |
|---|---|
| Is there a link to the model's ollama.com library entry? | **No.** The only URLs anywhere in the response are inside the licence text. No description, homepage, author or registry reference. The `FROM` line in the returned Modelfile points at a local blob path, not a registry |
| Is there a stated maximum for `num_ctx` or any other parameter? | **No.** There is no schema, range or limits endpoint. The `parameters` field lists only what a Modelfile pinned, not what is settable |

So the library page has to be constructed from the tag, and the script does
that while labelling it as constructed rather than reported:
`https://ollama.com/library/qwen3` for `qwen3:8b`.

For `num_ctx`, the architecture's `context_length` is the practical ceiling
rather than an enforced one. ollama will allocate a larger cache if asked; the
model is simply past what it was trained on.

### Three ways to set the context, and which reach this arm

All tested on 2026-09-11 rather than assumed.

| Method | Scope | Reaches a `claude -p` worker? | Cost |
|---|---|---|---|
| `options.num_ctx` in the request body | Per request | **No** | Free, but unusable here |
| `OLLAMA_CONTEXT_LENGTH` + daemon restart | Every model, globally | Yes | A restart, which drops all loaded models |
| **`PARAMETER num_ctx` in a Modelfile** | **Per model** | **Yes** | **A one-off `ollama create`. No restart, no extra disk** |

**Per-request is ruled out.** `options.num_ctx` is honoured on `/api/generate`
and `/api/chat`, which loaded a model at 8,192 on request. The same field is
**ignored** on `/v1/messages`, which loaded at the daemon default of 32,768.
`/v1/messages` is the route a `claude -p` worker uses, so a worker cannot ask
for its own context.

**A derived model is the clean answer.** Pinning `num_ctx` into a Modelfile
bakes the context into the model itself, so it flows through any route
including the Anthropic one. Verified back to back on one daemon:

```
ctxtest:8k   loaded context_length = 8192     <- Modelfile pinned 8192
qwen3:8b     loaded context_length = 32768    <- daemon default
```

Building one:

```bash
printf 'FROM qwen3:8b\nPARAMETER num_ctx 40960\n' > Modelfile.qwen3-8b-40k
ollama create qwen3-8b-40k -f Modelfile.qwen3-8b-40k
```

**It costs no extra disk.** ollama layers are content-addressed, so the derived
model points at the same 4.9 GB weight blob as its parent. `ollama list` shows
a size for each, but the bytes are shared.

**What this changes for the arm.** Context is now a per-arm setting rather than
a machine-wide one. If a brief hits the ceiling, the fix is a derived model for
that arm alone, leaving the daemon and every other model untouched. Sensible
ceilings would be `qwen3-8b-40k` at 40,960, which is that model's architecture
maximum, and a gemma4 variant at whatever memory allows, since its architecture
tops out at 262,144.

The only caveat is that it changes the model tag, so the results must record
which tag ran. An arm on `qwen3-8b-40k` is not the same arm as one on
`qwen3:8b`.

### The target is small

| File | Tokens (approx) |
|---|---|
| `agents.py` | 5,450 |
| `main.py` | 1,774 |
| `tools.py` | 1,657 |
| `data.py` | 1,580 |
| `README.md` | 957 |
| `state.py` | 807 |
| `requirements.txt` | 131 |
| `docs/` (5 files) | 7,566 |
| **Everything** | **~19,900** |

### Per-brief budget

Each brief names the files its investigator should start from, so no worker
needs the whole tree.

| Brief | Files the brief names | File tokens | Plus system (~1k) and brief (~1.1k) | Headroom in 32k |
|---|---|---|---|---|
| 1 Data model | `data.py`, `requirements.txt` | 1,711 | 3,811 | 28,957 |
| 2 Policy thresholds | `agents.py`, `tools.py` | 7,107 | 9,207 | 23,561 |
| 3 Risk and budget | `agents.py`, `tools.py` | 7,107 | 9,207 | 23,561 |
| 4 State and audit | `state.py`, `main.py` | 2,581 | 4,681 | 28,087 |
| **5 Presentation** | `main.py`, `agents.py`, `README.md`, `docs/` | **15,747** | **17,847** | **14,921** |

**Every brief fits, with room.** Even brief 5, the worst case, leaves about
15k of headroom.

### Where it can still go wrong

Headroom is not the same as safety, because a conversation accumulates. Every
turn resends the whole history, so the budget is consumed by:

1. **Re-reads.** A worker that opens `agents.py` twice pays 5,450 tokens twice.
2. **Broad greps.** `grep -rn "amount" src/` returns dozens of lines. A few
   careless sweeps cost more than reading a file.
3. **Thinking tokens.** qwen3 and gemma4 are both thinking models. In
   [hypothesis 1](hypothesis_1.md), qwen3:8b spent 1,589 output tokens on a
   task whose correct answer was one word, and qwen3:30b spent 2,389 and then
   answered with a single dash. Across ten turns this is thousands of tokens of
   accumulated history.
4. **Tool results the worker did not need.** Arm A's workers opened six files
   each when their briefs named two.

Realistic worst case for brief 5: 17,847 of intended content, plus a re-read of
`agents.py` (5,450), plus accumulated thinking across ten turns (~5,000), lands
around 28,000. Inside 32,768, but not by much.

### How this was handled: the constraint is gone

The 32,768 was never a property of the models, only of the daemon. Both arms
now run on **derived models pinned to their own architecture maximum**, so
context cannot bind and the arm measures the model rather than a config choice.

Built 2026-09-11. Modelfiles in `optimization-exp/hyp2-1/modelfiles/`.

| Arm | Model the arm runs | Context | Measured resident | Against the 32,768 default |
|---|---|---|---|---|
| C | `qwen3-8b-40k` | **40,960** | 10.6 GB | 25% more context, 1.1 GB more memory |
| D | `gemma4-12b-256k` | **262,144** | 7.7 GB | 8x the context, no extra cost |

Two measurements worth keeping.

**qwen3:8b is the expensive one and the tightest.** Its cache costs 144 KB per
token, and 40,960 is a hard architectural ceiling, only 2.3x the worst-case
brief. It is the arm most likely to hit a context problem.

**gemma4:12b is the opposite.** Its cache costs 25.6 KB per token, six times
cheaper, because sliding-window attention means most of its 48 layers hold only
1,024 tokens regardless of the declared context. Measured at three sizes:

| Context | Resident |
|---|---|
| 32,768, the daemon default | 7.8 GB |
| 65,536 | 8.6 GB |
| **262,144, architecture max** | **7.7 GB** |

The full maximum costing *less* than a quarter of it was not expected. The
likely reason is that sliding-window layers never allocate beyond their window,
so a larger declared context mostly changes a number rather than an allocation.
Recorded as measured, not as explained.

**Why the two arms get different numbers.** The criterion is that context must
not bind, not that both arms get the same figure. Each model at its own ceiling
means neither was held back, which is the fair comparison. Matching them at
some middle value would have capped gemma4 for no reason.

**The arms are named after the derived tags.** An arm on `qwen3-8b-40k` is not
an arm on `qwen3:8b`, and the results must say which one ran.

**Still worth doing: run brief 5 last**, since at 17,847 tokens it is the
heaviest, so four results are banked before the riskiest. And still instrument
the token counts, because a worker can waste context on re-reads and thinking
even when the ceiling is generous.

### Detecting a context failure rather than a quality failure

A worker that runs out of context does not announce it. It produces a truncated
or incoherent report that looks like a bad answer. Distinguish them:

- Record `input_tokens` from every turn's JSON output. A run that approaches
  the loaded context was constrained, and its quality score is not a fair
  reading of the model.
- Confirm the loaded figure during the run, not before it. `ollama ps` and the
  script's "Loaded with" column only report while the model is resident.
- Treat any report missing required sections as **incomplete**, not as low
  quality, and record it under completion rate.
- Retry once. If the second attempt also fails, that is the finding.

## Other risks carried over from hypothesis 1

| Risk | Evidence | Handling |
|---|---|---|
| **Empty or degenerate output** | qwen3:30b answered "-" after 2,389 thinking tokens | One retry, then record as incomplete |
| **Wall-clock** | ~90-100s for a trivial two-turn task | This task ran 8-15 tool calls in arms A and B. Estimate 10-25 min per worker, so 2-4 hours for both arms. Run in the background |
| **Memory pressure** | The hypothesis 1 concurrency test began at 35 GB used and swapped hard | Check free memory before starting. Only one model is resident at a time because the arms are sequential |
| **Output shape compliance** | Arms A and B both broke the required structure occasionally | Expect worse. Grade structure under Standards, as before |
| **No project rules in bare mode** | Measured in hypothesis 1 | **Already handled.** The rich briefs restate every convention inline. This is the design decision that makes the arm possible |

## Method

Unchanged from arms A and B except for the engine.

0. Run `node optimization-exp/hyp2-1/ollama-context.mjs` and record the table
   in the results, so the context the arm ran under is on the record.
1. Check free memory. Close what is not needed.
2. Arm C first, on **`qwen3-8b-40k`**. Smaller and faster, so it shakes out the
   launcher before the slower model runs.
3. Briefs in order 1, 2, 3, 4, then 5 last.
4. One worker at a time. No parallelism, matching arms A and B.
5. Then arm D on **`gemma4-12b-256k`**, same order.
6. Save each report verbatim, record tokens, tool calls, wall-clock and
   completion.
7. Add all ten reports to the blind grading pool with the same rubric and the
   same ground-truth key.

Launch shape, verified in [hypothesis 1](hypothesis_1.md):

```bash
echo "<brief>" | ANTHROPIC_BASE_URL=http://localhost:11434 ANTHROPIC_AUTH_TOKEN=ollama ANTHROPIC_API_KEY="" \
  claude -p --bare --strict-mcp-config --tools Bash Read --model qwen3-8b-40k \
  --output-format json > reports/arm-c-qwen3-8b/01-data-model.json
```

`--bare` is mandatory. Without it the harness alone is ~32k tokens and nothing
fits.

## Predictions

| Prediction | Reasoning |
|---|---|
| Both local arms score below arm A on every dimension | Arm A already scored 3.0 on depth across all five briefs. There is not much room below that before a report stops being useful |
| **Fabrication will be non-zero** | Arms A and B both scored zero across 230 citations. This is the property most likely to break first, and it is the pass/fail criterion |
| Completion rate below 5 of 5 for at least one arm | Hypothesis 1 produced one degenerate answer in six single-turn runs |
| gemma4:12b beats qwen3:8b | Larger, and its 262k native context suggests better long-context behaviour, though the daemon caps both at 32k |
| Alignment will be the worst dimension | It was already Haiku's worst at 2.6. Scope discipline is the first thing to go |
| No brief exceeds the context ceiling | Worst case 17,847 against 40,960 for arm C and 262,144 for arm D. Arm C is the one to watch |

The prediction worth watching is fabrication. If a local arm invents file paths,
the tier is unusable without a verification layer, and
[hypothesis 3](hypothesis_3.md) has just found that cheap verification does not
work well.

## Arm C result, two runs

Full detail in `optimization-exp/hyp2-1/reports/ARM-C-COMPARISON.md`. Run 1 was
repeated in full because the machine locked during it; the lock turned out not
to have touched the run, and the second run became the variance measurement
this work had been missing.

### The headline

`qwen3-8b-40k` **fails the pass/fail criterion**, and the manner of failure is
worse than the prediction.

| | |
|---|---|
| Predicted | Shallower than Haiku, fabrication non-zero |
| Observed | On 2 of 5 briefs it called **no tool at all**, then wrote a well-formed report claiming in `Files I read` that it had opened files. Two citations pointed past the end of a 98-line file |

Arms A and B produced zero fabrications across 230 citations between them.

### The failure is per-brief and reproducible

| Brief | Attempts across both runs | Outcome |
|---|---|---|
| 01 data model | 2 | worked every time |
| 02 policy thresholds | 3 | failed once, recovered on retry |
| 03 risk and budget | 3 | **never worked** |
| 04 state and audit | 3 | **never worked** |
| 05 presentation | 2 | worked every time |

Token counts settle it. Brief 3 consumed exactly **1,967 input tokens on three
separate attempts**; brief 4, exactly 1,974 on three. This is not chance.

### The probable cause is our own brief wording

Briefs 2 and 3 point at the same two files, so reading volume does not explain
why one works and the other never does. The split is how each opens.

| Opening style | Briefs | Outcome |
|---|---|---|
| Concrete, searchable instruction | 1, 2, 5 | worked |
| Conceptual claim first | 3, 4 | never worked |

Brief 3 opens *"Accumulation is different from comparison..."* and brief 4
*"The state object is the spine..."*. A model this size can write a plausible
essay from that without opening anything, and does.

**If this holds, the rich briefs are mis-shaped for local tiers.** They were
written for Anthropic models, where a conceptual opening adds useful framing.
The cheap test is to rewrite brief 3's opening concretely, keep the ask
identical, and run it alone.

### A run-1 claim that did not survive

Coverage percentages are **not stable per run**. Brief 1 read the same files in
both runs, produced the same six findings, and cited 22 locations in run 1
against 6 in run 2. The 33% and 38% coverage figures from run 1 should not be
quoted as measurements.

### Context never bound

Worst case was 22,886 input tokens against the 40,960 ceiling, and the failing
briefs used under 2,000. Building the derived model did its job: this reads the
model, not the daemon default. Had the arm run at 32,768 the result would have
been arguable.

### Methodology change this forced

The runner's `ok` status originally only checked for a Findings section, so a
zero-tool-call report passed. **Turn count is the real signal.** The runner now
labels any one-turn worker `no-tools` and retries it. Run 1 predates the gate,
which is why two fabricated reports were written to disk marked `ok`.

Any local tier needs that gate. It converts silent fabrication into visible
absence, which is the right trade, and it is a few lines of harness code.

## What a result would change

| If | Then |
|---|---|
| Local scores close to arm A with zero fabrication | Local becomes the genuine out-of-window fallback. The main cost is hours, not quality |
| Local fabricates | The tier needs ground-truth verification, which hypothesis 3's spike suggests is expensive. Local is then for gathering only, with every claim re-checked |
| Local cannot complete the briefs | The ladder has a floor above these models on this class of task, and that is a clean finding |
| gemma4:12b matches arm A | Worth testing qwen3:30b, which was left out of this design for memory reasons |
