# Results 5 - a null result, and a useful one

Date: 2026-09-22
Status: **complete.** Four candidates screened, one taken to a full run
Design: [hypothesis_5.md](hypothesis_5.md)
Assets: `optimization-exp/hyp5/`
Full ladder: [results_ladder.md](results_ladder.md)

## Headline

**No open model tested beats gemma4:12b, and gemma does not come close to
Haiku.** The hypothesis asked whether some open model does honest, reasonably
thorough investigation at a usable speed. Four candidates say no.

Coverage never moved. Across the entire hypothesis it sat between 15% and 38%
against Haiku's 73%.

## The screen

Every candidate ran brief 2 first, chosen over brief 1 because brief 1 is where
every model looks acceptable and brief 2 rewards inferring that a bare literal
functions as a policy limit.

| Candidate | Result | How it failed |
|---|---|---|
| `qwen2.5-coder:14b` | **Failed gate 1** | Wrote the tool call as text in a fenced code block. The command was correct; the format was not |
| `glm4:9b` | **Failed gate 1** | Produced a well-formed report with Summary and Findings, from the brief alone, without opening a file |
| `devstral:24b` | **Passed** | 16 turns, zero fabrications, 342s, 38% coverage |

Both failures reproduced exactly on retry.

## The full run, arm E

`devstral:24b`, all five briefs, direct route.

| Arm | Briefs | Citations | On target | Fabricated | Coverage | Wall |
|---|---|---|---|---|---|---|
| Haiku | 5/5 | 115 | 89 | 0 | **73%** | 6 min |
| gemma think-off | 5/5 | 74 | **70** | 0 | **34%** | 37 min |
| gemma think-on | 4/5 | 57 | 51 | 0 | 41% | 261 min |
| **devstral** | **4/5** | 36 | 21 | 0 | **15%** | **20 min** |

**Devstral is roughly half as good as gemma** and has the weakest on-target
rate of any honest arm, 21 of 36 against gemma's 70 of 74. It is imprecise as
well as thin, though it never fabricates.

**The screen oversold it.** Brief 2 gave 38% on the screen and 38% again in the
full run, so that number was real. It was also the only brief where devstral
matched gemma. The 16-turn screen run was not typical; the full run ranged from
2 to 11 turns.

**Brief 1 failed both attempts**, identically. It made one or two tool calls,
announced its next step in prose, and stopped. The second attempt asserted that
`data.py` contains no numeric literals. That file is the entire subject of
brief 1 and consists almost entirely of monetary literals.

## The one genuine win

Devstral completed **brief 5 in 310 seconds across 11 turns**.

| Arm | Brief 5 |
|---|---|
| gemma, thinking on | Never completed. Two attempts, 105 and 101 minutes, killed mid-generation |
| gemma, thinking off | Completed in 26 minutes via **420 turns** |
| **devstral** | **310 seconds, 11 turns** |

Brief 5 has the widest surface of the five. It induces a termination pathology
in gemma in both configurations: with thinking it narrates without stopping,
without thinking it loops. Devstral simply finishes. Whatever the agentic
tuning does, it is about knowing when a task is complete.

That is a real capability difference, and it is the only axis on which any
candidate beat the incumbent.

## What failed, and what that says

Three of four candidates failed on **tool calling**, not on quality, and each
failed differently:

| Model | Failure |
|---|---|
| qwen3:8b | Skipped the work, then stated in `Files I read` that it had opened files |
| qwen2.5-coder:14b | Produced the right command, emitted it as text |
| glm4:9b | Wrote a plausible report from the brief alone |
| devstral:24b | Narrated its next step, then stopped, on 2 of 6 brief attempts |

**Tool-calling reliability is the scarce property**, not code understanding and
not parameter count. qwen2.5-coder is larger than gemma, coding-tuned, and knew
exactly the right opening move. It still could not participate.

### Two findings that outlive the candidates

**`ollama show` capabilities are not a screen.** qwen2.5-coder advertises
`tools` and does not call them under this harness. The only reliable gate is
the cheap one: run one real brief, check the turn count.

**The turn-count gate is load-bearing.** glm4 produced a structurally perfect
report from the brief alone. Without the gate it would have been filed as a
legitimate result, exactly as two of qwen3's fabricated reports were before the
gate existed.

## Where this leaves the local tier

| Question | Answer |
|---|---|
| Is there a better open model than gemma? | **Not among those tested.** Four candidates, none beat 34% |
| Is the gap capability or configuration? | **Capability.** Hypothesis 4 solved speed with a 15x gain and coverage did not move at all |
| Is the local tier usable? | For gathering with a manager doing all synthesis, and only behind a turn-count gate. Not as a replacement for Haiku |

## What is actually worth trying next

Not more models. Five have been tested and coverage has not moved once.

**Two cheap workers on the same brief.** ~~Untested.~~ **Tested, see
[results_multiworker.md](results_multiworker.md).** Union of two workers lifts
brief 2 from 38% to 50%, and three runs reach 62%. But the gain comes from
sampling variance rather than model diversity: devstral against its own second
run does as well as the mixed pair. And no local worker, in any configuration
or run, ever finds the alcohol-check block, so the ceiling is capability after
all.

**A model per brief type.** Devstral is the only model that finishes brief 5
cleanly; gemma is better on everything else. Routing by brief rather than
picking one model is untested.

If another model is pulled, the only one with a real question attached is
`mistral-small:24b`: same family as devstral without the agentic tuning, which
would isolate whether devstral's termination behaviour comes from the tuning or
the lineage.
