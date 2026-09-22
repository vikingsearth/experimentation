# The four-arm tier ladder, complete

Same five briefs, same target, same sequential method, same blind-gradeable
outputs. Arms A and B ran as in-process Claude Code subagents; arms C and D as
bare `claude -p` workers against a local ollama daemon.

## Results

| Arm | Model | Briefs done | Citations | Fabricated | Coverage vs A+B | Report words | Wall clock |
|---|---|---|---|---|---|---|---|
| A | Haiku 4.5 | 5/5 | 117 | 0 | 73% | 5,302 | **6 min** |
| B | Sonnet 5 | 5/5 | 106 | 0 | 67% | 5,447 | 9 min |
| C | qwen3:8b local | 5/5 | 39 | **2** | 12% | 1,241 | 11 min |
| D | gemma4:12b local | **4/5** | 57 | 0 | 41% | 1,754 | **407 min** |

Coverage is measured against the union of locations arms A and B found, so A and
B scoring 73% and 67% against their own union is expected: each found things the
other missed.

## What the ladder shows

**The two local models fail in opposite directions.**

| | qwen3:8b | gemma4:12b |
|---|---|---|
| Does the work? | No, on 2 of 5 briefs it called no tool at all | Yes, every brief it attempted |
| Honest about it? | **No.** Claimed in `Files I read` to have opened files it never touched, and cited 2 lines past the end of a 98-line file | **Yes.** Zero fabrications across 57 citations |
| Thorough? | No, 12% coverage | Partly, 41% |
| Fast? | Yes, 11 min, because it skipped the work | **No. 407 min, and it still did not finish** |

qwen3 is fast and dishonest. gemma is honest and unusably slow. Neither is
usable as-is, for different reasons.

**gemma's precision is genuinely good.** On brief 2 every one of its 7
citations landed on a real comparison line, which neither Anthropic arm managed,
and it found all three sites qwen3 missed including the receipt check buried
inside a tool. On brief 4 all 4 citations were on target. It is a
precision-over-recall machine: it lands on real code and stops early.

**Brief 5 defeated it entirely.** Two attempts, 105 and 101 minutes, both killed
by the watchdog while still generating. The heaviest brief is beyond practical
reach for this model on this machine.

## The cause of the slowness is not the hardware

gemma emitted **101,477 output tokens** across four briefs to produce 1,754
words of report. Brief 4 is the clearest case: the files it was asked to read
total about 2,581 tokens, and it generated 41,077 output tokens to report on
them, sixteen times the size of what it read.

At 5.7 to 13.1 tokens per second, that generation *is* the wall clock. A faster
runtime multiplies tokens per second. Removing the thinking removes most of the
tokens.

## Measured: the thinking control exists, and the worker route cannot reach it

Probed 2026-09-22 on `gemma4-12b-40k`, same prompt each time.

| Route | Setting | Output tokens | Time |
|---|---|---|---|
| `/api/chat` | default | 122 | 14,424 ms |
| `/api/chat` | `think: false` | **2** | **682 ms** |
| `/api/chat` | `think: "low"` | 120 | 7,702 ms |
| `/v1/messages` | default | 113 | 7,235 ms |
| `/v1/messages` | `think: false` top level | 126 | 8,008 ms |
| `/v1/messages` | `options.think: false` | 127 | 8,065 ms |

**Turning thinking off cuts output 61x and latency 21x** on the native route.
`"low"` is nearly useless: it halves latency but barely touches token count.

**The route a worker uses ignores it.** All three `/v1/messages` rows are within
noise of each other, exactly as that route ignores `options.num_ctx`.

**And the derived-model workaround is closed.** Building a model with the
setting baked in fails outright:

```
$ ollama create gemma4-12b-40k-nothink -f Modelfile.nothink
Error: unknown parameter 'think'
```

So the trick that solved the context ceiling does not transfer. Thinking cannot
be configured for a `claude -p` worker through ollama at all.

## What that leaves

| Lever | Cost | Notes |
|---|---|---|
| **A shim translating `/v1/messages` to `/api/chat` with `think:false`** | Small, maybe 50 lines | The only path that keeps the harness and unlocks a measured 61x token cut. Turns the "different runtime" idea into something far cheaper |
| An instruction in the brief telling the model to reason briefly | Free | Works on any route, but it is brief design rather than runtime, and a model that ignores instructions is exactly the failure mode we are trying to avoid |
| A different runtime such as MLX | Large | Also needs a shim, because MLX servers speak OpenAI format, so it carries the shim cost *plus* the runtime change |

The shim is the finding. It was hiding behind a question about runtimes.
