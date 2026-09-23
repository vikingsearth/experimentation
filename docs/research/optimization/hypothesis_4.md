# Hypothesis 4 - speed levers on one model

Date: 2026-09-22
Status: **run 2026-09-22.** Results: [results_4.md](results_4.md)
Continues: [hypothesis_2_1.md](hypothesis_2_1.md)
Baseline: `optimization-exp/hyp2-1/reports/ARM-D-AND-LADDER.md`
Probe assets: `optimization-exp/hyp4/`

## The problem this exists to solve

[Arm D](hypothesis_2_1.md) established that gemma4:12b does honest,
precise work as a local subagent and is **unusably slow**: 407 minutes for four
briefs, with the fifth abandoned after two attempts of over 100 minutes each.
Haiku did all five in six minutes.

So the local tier is not blocked on quality. It is blocked on wall clock.

## The hypothesis

> The wall clock is dominated by thinking tokens, not by hardware throughput.
> Removing the thinking will buy far more than changing the inference runtime.

### Why, in one measurement

gemma emitted **101,477 output tokens** across four briefs to produce 1,754
words of report. On brief 4 it generated 41,077 tokens about files totalling
roughly 2,581 tokens, sixteen times the size of what it read. At 5.7 to 13.1
tokens per second, that generation is essentially the entire elapsed time.

## What is already measured

Probed 2026-09-22, before designing the arms, because the answer reshapes them.

| Route | Setting | Output tokens | Time |
|---|---|---|---|
| `/api/chat` | default | 122 | 14,424 ms |
| `/api/chat` | `think: false` | **2** | **682 ms** |
| `/api/chat` | `think: "low"` | 120 | 7,702 ms |
| `/v1/messages` | default | 113 | 7,235 ms |
| `/v1/messages` | `think: false` | 126 | 8,008 ms |
| `/v1/messages` | `options.think: false` | 127 | 8,065 ms |

Three findings, all load-bearing.

1. **The lever is real and enormous.** 61x fewer output tokens, 21x faster.
2. **`"low"` is not a useful middle setting.** It halves latency while leaving
   token count almost unchanged, so a `high`/`medium`/`low` sweep is not worth
   running.
3. **The worker route cannot reach it.** All three `/v1/messages` rows are
   within noise. And the derived-model workaround that solved the context
   ceiling is closed: `ollama create` fails with `Error: unknown parameter
   'think'`.

**Consequence: the thinking arm cannot be run as originally imagined.** There is
no configuration change that reaches a `claude -p` worker. Something has to be
built first.

## Arms

| Arm | What changes | Built on |
|---|---|---|
| **D0 baseline** | Nothing. Arm D as run | Already measured |
| **4A shim, thinking off** | A ~50 line proxy accepting `/v1/messages` and forwarding to `/api/chat` with `think:false` | Must be written |
| **4B shim, thinking on** | The same shim, forwarding unchanged | Separates the shim's own cost from the thinking saving |
| 4C runtime swap (optional) | MLX or similar behind the same shim | Only if 4A succeeds and speed is still the blocker |

**4B is not optional padding.** Without it, a speedup in 4A could be the shim
rather than the setting. It is one extra run and it makes the result
attributable.

**4C is deliberately last and conditional.** An MLX server speaks OpenAI format,
so it needs a shim regardless. Once 4A exists, swapping the backend behind it is
a small change rather than a separate project. Running it before 4A would
confound runtime, shim and thinking in one arm.

```
worker (claude -p)
      |  /v1/messages          <- the only route the harness speaks
      v
   [ shim ]  --> /api/chat  { think: false }   <- the lever, unreachable without this
      |
      v
   ollama  (or MLX behind the same interface, later)
```

## Do not run five briefs

Arm D took 407 minutes for four briefs. A three-arm design over five briefs is
unaffordable and unnecessary for a speed question.

**Use brief 3 as the speed probe.** It is the heaviest that gemma actually
completed, at 36,819 output tokens and 48 minutes, so it has the most headroom
to show an improvement. Add brief 1 as a second point, since it is the cheapest
at 1,418 seconds and confirms the effect is not specific to one brief.

That is two briefs times three arms, six runs instead of fifteen.

## Measurements

| Measure | Why |
|---|---|
| Output tokens | The hypothesis is that this is the cost. It is the primary number |
| Wall clock | What actually hurts |
| Tokens per second | Separates "generated less" from "generated faster" |
| Turn count | A worker that stops calling tools has not got faster, it has stopped working |
| Citations, on-target rate, fabrications | **Non-negotiable.** qwen3 was fast because it skipped the work |
| Coverage against the A+B union | Same measure as the ladder, so results stay comparable |

## Predictions

| Prediction | Reasoning |
|---|---|
| 4A cuts output tokens by 10x or more | The probe showed 61x on a trivial prompt; a real brief has irreducible report text, so the ratio shrinks but stays large |
| 4A brings a brief under 10 minutes | 48 minutes with a 10x token cut lands near 5, plus fixed overhead |
| 4B is close to D0 | The shim should add milliseconds, not minutes |
| **Quality will drop, and this is the risk** | Thinking is doing real work. gemma's precision was its one strength |
| Coverage falls further than precision | Following a thread to its second and third site is what thinking buys. Landing on a real line is cheaper |

**The failure that would end this line of work**: 4A comes back fast, well
formed, and fabricating. That is qwen3's failure mode reproduced by
configuration, and it would mean thinking is what kept gemma honest.

## What this settles either way

If 4A is fast and honest, a local tier becomes genuinely viable and hypothesis 5
can run at practical cost. If 4A is fast and dishonest, the local tier's
slowness is not a bug to be optimised away, it is the price of the only local
model that told the truth. Either result is worth having.
