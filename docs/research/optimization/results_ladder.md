# The complete tier ladder

Date: 2026-09-22
Regenerate: `node optimization-exp/ladder.mjs`

Six arms, the same five briefs, the same target, the same sequential method.
Cloud arms ran as in-process Claude Code subagents; local arms as bare
`claude -p` workers against ollama. Coverage is measured against the union of
what Haiku and Sonnet found, so those two scoring 73% and 67% against their own
union is expected: each found things the other missed.

## Totals

| Arm | Briefs done | Citations | On target | Fabricated | Coverage | Words | Wall |
|---|---|---|---|---|---|---|---|
| Haiku 4.5 | 5/5 | 115 | 89 | 0 | **73%** | 5,307 | **6 min** |
| Sonnet 5 | 5/5 | 106 | 71 | 0 | 67% | 5,452 | 9 min |
| qwen3:8b run 1 | 5/5 | 39 | 26 | **2** | 12% | 1,246 | 11 min |
| qwen3:8b run 2 | 5/5 | 23 | 14 | **2** | 5% | 1,398 | 13 min |
| gemma4:12b thinking on | **4/5** | 57 | 51 | 0 | 41% | 1,758 | **261 min** |
| **gemma4:12b thinking off** | **5/5** | 74 | **70** | 0 | 34% | 2,332 | **37 min** |

## Coverage by brief

| Arm | 01 | 02 | 03 | 04 | 05 |
|---|---|---|---|---|---|
| Haiku | 95% | 75% | 65% | 83% | 53% |
| Sonnet | 86% | 88% | 54% | 45% | 68% |
| qwen3 run 1 | 33% | 38% | 0% | 0% | 4% |
| qwen3 run 2 | 12% | 0% | 4% | 0% | 4% |
| gemma thinking on | 76% | 75% | 8% | 10% | - |
| gemma thinking off | 76% | 38% | 15% | 3% | 26% |

## Wall clock by brief

| Arm | 01 | 02 | 03 | 04 | 05 |
|---|---|---|---|---|---|
| Haiku | 75s | 62s | 81s | 67s | 91s |
| Sonnet | 56s | 100s | 176s | 75s | 136s |
| qwen3 run 1 | 130s | 190s | 80s | 70s | 210s |
| qwen3 run 2 | 171s | 150s | **no-tools** | **no-tools** | 291s |
| gemma thinking on | 24m | 34m | 48m | 51m | **abandoned** |
| gemma thinking off | 141s | 190s | 190s | 101s | **26m** |

## What the ladder says

### Haiku is the benchmark and nothing local is close

73% coverage in six minutes, zero fabrications. Sonnet is slower, less thorough
on this task, and would cost roughly 2.5x the window. **The cheapest cloud tier
is the one to beat, and nothing beat it.**

### The two local models fail in opposite ways

| | qwen3:8b | gemma4:12b |
|---|---|---|
| Does the work | No. Zero tool calls on 2 of 5 briefs | Yes, always |
| Honest | **No.** Claimed to read files it never opened; cited 2 lines past the end of a 98-line file | **Yes.** Zero fabrications in 131 citations across both configurations |
| Reproducible | **No.** 12% coverage one run, 5% the next | Yes. Brief 1 landed within 10 output tokens across separate runs |

qwen3's second run is the damning one: **5% coverage and still 2 fabrications**.
It is not merely weak, it is unreliable in a way that makes a turn-count gate
mandatory rather than advisory.

### Thinking off is a real trade, not a free win

| Measure | Thinking on | Thinking off |
|---|---|---|
| Briefs completed | 4/5 | **5/5** |
| Wall clock | 261 min | **37 min** |
| On-target rate | 51/57 = 89% | 70/74 = **95%** |
| Coverage | 41% (of 4 briefs) | 34% (of 5) |

It is **7x faster**, finishes the brief that previously defeated the model, and
has the **highest precision of any arm on the ladder including both cloud
tiers**. What it loses is inference.

Brief 2 is the clearest case. With thinking on, gemma found all three sites
qwen3 missed, including the hardcoded per-person and alcohol caps, which are
bare literals in code that function as policy limits. Without thinking it lost
both and coverage halved, 75% to 38%. Those findings require noticing that a
number *is* a policy limit, not locating a named one.

**So thinking buys inference, not accuracy.** Precision went up without it.

### Brief 5 breaks the model either way, differently

| | Outcome |
|---|---|
| Thinking on | Never completed. Two attempts, 105 and 101 minutes, killed mid-generation |
| Thinking off | Completed in 26 minutes, via **420 turns** and 8.98 million cumulative input tokens |

Those 420 turns were a loop: each emitted exactly 33 output tokens, received a
tiny result, and repeated, with context creeping up 55 tokens a round. It
escaped and produced a usable report with 17 findings and no fabrications, but
it took 40x the turns of any other brief.

**Thinking is what lets the model decide it has enough and stop.** Without it,
on the brief with the widest surface, it could not terminate cleanly. With it,
it could not stop generating. Brief 5 exceeds this model's reach in both
configurations.

## The honest summary

| Question | Answer |
|---|---|
| Is a local subagent tier viable? | **Not yet.** The best local configuration is 34% coverage in 37 minutes against Haiku's 73% in 6 |
| Is it closer than it was? | Yes, dramatically. 261 minutes to 37, and 4/5 to 5/5 |
| Is the blocker still speed? | **No.** That was hypothesis 4 and it is solved. The blocker is now coverage |
| Is any local model trustworthy? | gemma, yes. 131 citations, zero fabrications, reproducible. qwen3, no |
| What would close the gap? | Not configuration. gemma at its best, thinking on, brief 2, reached 75%, equal to Haiku. It cannot hold that across briefs. That is a model-capability gap |

## What follows

[Hypothesis 5](hypothesis_5.md) is unblocked and now has a sharper question than
"which model is best". Gemma with thinking off is honest, precise and fast, and
thin. The candidate that wins is the one that keeps those three properties and
adds recall.

The screen should use **brief 2**, not brief 1. Brief 1 is where every model
looks decent, 76% for both gemma configurations. Brief 2 separates them, because
it contains findings that require inference rather than lookup.
