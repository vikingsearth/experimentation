# Hypothesis 5 candidate selection

Date: 2026-09-22

## What we are actually looking for

The ladder says the local gap is **coverage**, not speed and not honesty.
gemma4:12b with thinking off is fast (37 min for five briefs), precise (70 of 74
citations on target, the best rate on the ladder) and honest (zero fabrications
in 131 citations). It reaches 34% of what the cloud arms found.

So the candidate that wins keeps precision and honesty and adds recall.

## Chosen

| Model | Size | Why |
|---|---|---|
| `qwen2.5-coder:14b` | ~9 GB | The sharpest test of the coverage hypothesis. Coding-tuned, comparable size to the incumbent, so any gain is attributable to code tuning rather than parameter count. A different generation and training run from qwen3:8b, which failed on tool use |
| `glm4:9b` | ~5.5 GB | A different lineage entirely. Guards against concluding something about one family. Smaller, so it also tests whether recall tracks size |

## Considered and deferred

| Model | Why not now |
|---|---|
| `devstral:24b` | Mistral's agentic coding model, the most interesting candidate on paper because it is built for tool-driven codebase work. Deferred because at ~14 GB it is twice the incumbent's size and would roughly double wall clock, confounding a coverage result with a size result. Worth running alone if the two chosen models both fail |
| `deepseek-coder-v2:16b` | Mixture-of-experts, so its effective capacity is hard to compare against dense models of similar file size |
| `codestral:22b`, `mistral-small:24b` | Same size objection as devstral, with less reason to expect an agentic advantage |
| `codegemma:7b`, `qwen2.5-coder:7b` | Smaller than the incumbent. If a 12B reaches 34%, a 7B is unlikely to close a gap to 73% |

## Method

Identical to arms C, D and D2 so results join the ladder:

- The same five briefs, unchanged.
- A derived model per candidate pinning `num_ctx` to 40,960.
- Through the thinking shim with thinking off, matching arm D2, since that is
  the configuration the ladder says is viable.
- One worker at a time.
- The turn-count gate on.

## Screen before the full run

Run **brief 2 only**, not brief 1. Brief 1 is where every model looks
acceptable, 76% for both gemma configurations. Brief 2 separates them: it
contains findings that require inferring that a bare literal functions as a
policy limit, which is exactly what gemma lost when thinking was disabled.

| Gate | Fail condition |
|---|---|
| Tool calling | One turn, meaning no tool was called |
| Honesty | Any fabricated citation |
| Coverage | Below gemma's 38% on this brief |
| Wall clock | Beyond roughly 10 minutes for one brief |

## Two method changes forced by the candidates themselves

Checked with `ollama-context.mjs` before running.

| | qwen2.5-coder:14b | glm4:9b | gemma4:12b (incumbent) |
|---|---|---|---|
| Architecture max context | **32,768** | 131,072 | 262,144 |
| Thinking capability | **no** | **no** | yes |

### 1. No shim, and no thinking flag

Neither candidate is a thinking model, so there is nothing to disable. Running
them through the thinking shim would be pure overhead, and the shim was
measured at **1.3x slower** than the direct route in arm 4B. They run on the
direct route.

This makes the comparison to arm D2 fair rather than unfair: D2 is gemma with
its thinking suppressed, and these models have none to suppress.

### 2. Context is 32,768, not 40,960

`qwen2.5-coder:14b` tops out at 32,768, below the 40,960 used for arms C, D and
D2. Rather than give the two candidates different ceilings, both run at the
daemon default of 32,768, which is also qwen2.5-coder's maximum.

Peak context on the ladder's briefs never approached that: the largest single
read was about 23,000 tokens. The risk is confined to brief 5, whose breadth
caused gemma to accumulate context over 420 turns. If a candidate fails brief 5
specifically, the ceiling is a candidate explanation and must be reported as
one rather than scored as poor quality.

## Screen results

### qwen2.5-coder:14b - FAILED gate 1, tool calling

Both attempts identical: 1 turn, 2,032 input tokens, no tool called, 70s and 20s.

It did not skip the work the way qwen3:8b did. It **wrote a tool call as text**:

```json
{ "name": "Bash",
  "arguments": { "command": "find . -name '*.py' -print0 | xargs -0 grep -rnE '\\b([0-9]+(\\.[0-9]+)?)\\s*[<>=]\\s*([0-9]+(\\.[0-9]+)?)'" } }
```

That is a sensible opening move for this brief, a regex sweep for numeric
comparisons across the source. The model knew what to do and could not express
it in the harness's format, so nothing ran.

**This is a protocol failure, not a competence failure.** It is also the second
qwen model to fail tool use, across two generations and two tunings, in two
different ways.

### A finding that outlives this candidate

`ollama show` reported `tools` in this model's capabilities. It does not call
tools under this harness. **The capability flag is not a usable screen.** The
only reliable gate is the cheap one already in use: run one real brief and
check the turn count.

### glm4:9b - FAILED gate 1, tool calling

Both attempts identical: 1 turn, 1,411 input tokens, no tool called.

It produced a **well-formed report** with Summary and Findings sections,
written entirely from the brief without opening a single file. This is qwen3's
failure mode exactly, and the turn-count gate is the only thing that caught it.
Without that gate it would have been written to disk as a legitimate result.

Note the input count: 1,411 tokens is *less* than the system prompt plus brief.
It did not finish reading what it was handed.

### Three of three failed the same gate, in three different ways

| Model | Failure |
|---|---|
| qwen3:8b | Skipped the work, then stated in `Files I read` that it had opened files |
| qwen2.5-coder:14b | Produced the correct command, emitted it as text instead of a tool call |
| glm4:9b | Wrote a plausible report from the brief alone |

**Tool-calling competence, not code understanding and not parameter count, is
the scarce property.** qwen2.5-coder is larger than gemma and coding-tuned, and
knew exactly what command to run. It still could not participate.

That promotes `devstral:24b` from deferred to the obvious next candidate: it is
the only model on the shortlist explicitly built for agentic, tool-driven
codebase work. Its size premium is now justified by the thing it is built for,
rather than being an unexplained confound.
