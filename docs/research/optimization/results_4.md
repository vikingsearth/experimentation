# Results 4 - the thinking setting is the whole story

Date: 2026-09-22
Status: **arms run.** One observation per cell, two briefs
Design: [hypothesis_4.md](hypothesis_4.md)
Assets: `optimization-exp/hyp4/`

## Headline

Turning thinking off made a local worker **11.7x to 17x faster with no loss of
quality**, and the control proves the entire gain belongs to that setting rather
than to the shim built to reach it.

## Brief 1, every arm on the ladder

| Arm | Turns | Output tokens | Wall | Citations | On target | Fabricated | Coverage |
|---|---|---|---|---|---|---|---|
| Haiku | 10 tools | n/a | 75s | 40 | 30 | 0 | **95%** |
| Sonnet | 6 tools | n/a | 56s | 36 | 29 | 0 | 86% |
| gemma, direct, thinking on | 8 | 7,625 | 1,418s | 40 | 35 | 0 | 76% |
| gemma, shim, thinking on | 10 | 6,935 | 1,865s | 42 | 40 | 0 | 67% |
| **gemma, shim, thinking off** | 4 | **969** | **121s** | **45** | **41** | 0 | 79% |

## Brief 3

| Arm | Turns | Output tokens | Wall | Citations | On target | Fabricated | Coverage |
|---|---|---|---|---|---|---|---|
| gemma, direct, thinking on | 5 | 36,819 | 2,886s | 6 | 5 | 0 | 8% |
| **gemma, shim, thinking off** | 6 | **1,000** | **170s** | 10 | 8 | 0 | 8% |

## Attribution

The control existed to answer one question: is the speed the setting, or the
shim?

| Configuration | Wall | Output tokens |
|---|---|---|
| Direct, thinking on (baseline) | 1,418s | 7,625 |
| **Shim, thinking on** | **1,865s** | 6,935 |
| Shim, thinking off | 121s | 969 |

**The shim alone is 1.3x slower than no shim.** It buys nothing but access, most
likely because it calls upstream with `stream:false` and waits for the whole
response. Against the like-for-like control, thinking off is **15.4x faster and
7.2x fewer tokens**.

So the shim is a pure enabler. Its only value is reaching a setting that
`/v1/messages` ignores and `ollama create` refuses.

## The prediction that was wrong

Hypothesis 4 predicted quality would drop, with coverage falling further than
precision, on the reasoning that thinking is what buys following a thread to its
second and third site.

**It did not.** On brief 1, thinking off produced the most citations of any arm
(45), the best on-target rate of any arm including both Anthropic tiers (41 of
45), and better coverage than either thinking-on gemma arm. On brief 3, coverage
was identical at 8% but the citation count rose from 6 to 10, and the two arms
covered different ground: thinking off found ten locations the thinking run
missed and lost six.

**Zero fabrications in every arm, across both briefs.** The named risk, that
thinking off would reproduce qwen3's fast-and-confident failure, did not appear.

## What actually changed, mechanically

Brief 3 is the clearest case. Input tokens were 37,380 with thinking and 37,156
without, so the worker read the same material. Turns went **up**, 5 to 6, so it
used more tools, not fewer. Output tokens fell from 36,819 to 1,000.

It is not going faster by doing less work. It is going faster by not narrating
the work.

## What this does and does not fix

**Fixed: the local tier is no longer unusably slow.**

| | Before | After |
|---|---|---|
| Brief 1 | 1,418s | 121s |
| Brief 3 | 2,886s | 170s |
| Combined, these two briefs | 72 min | **under 5 min** |

Haiku does the same two in about 2.5 minutes. A local worker is now within the
same order of magnitude as the cheapest cloud tier, having been twenty to thirty
times worse.

**Not fixed: coverage.** 79% on brief 1 is respectable. 8% on brief 3 is not,
and it is unchanged from the baseline. Speed was the blocker and no longer is;
thoroughness still is, and it is a property of the model rather than of how it
is configured.

## Caveats

- One observation per cell, two briefs. Given the size of the effect, 15x rather
  than a few percent, noise is unlikely to explain it, but this is not a
  measured variance.
- Only brief 1 has a thinking-on shim control. Brief 3's attribution is inferred
  from brief 1's.
- The shim is about 130 lines and handles the traffic this harness actually
  sends. It is not a general-purpose translator.
- Briefs 2, 4 and 5 were not re-run. Brief 5 defeated gemma entirely at
  baseline and is the interesting test of whether this makes it reachable.

## What follows

1. **Re-run the full five briefs with thinking off.** The arm D result, 4 of 5
   with the fifth abandoned after two 100-minute attempts, should now be
   affordable to redo properly. That is the number that belongs in the ladder.
2. **[Hypothesis 5](hypothesis_5.md) is unblocked.** A four-model bake-off was
   10 to 16 hours at the old pace. At this pace it is under an hour per model,
   and the candidate screen can run in minutes.
3. The shim's own inefficiency, being 1.3x slower than direct, is worth one
   look at streaming passthrough if local ever becomes the default path.
