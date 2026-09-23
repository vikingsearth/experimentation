# Hypothesis 5 - which open model, once speed is solved

Date: 2026-09-22
Status: **complete, 2026-09-22.** Results: [results_5.md](results_5.md)
Ladder so far: `optimization-exp/hyp2-1/reports/ARM-D-AND-LADDER.md`

## The hypothesis

> Among open models that fit this machine, at least one does honest,
> reasonably thorough investigation at a wall clock that makes a local
> subagent tier worth using.

Two models have been tested. Neither qualifies, and they fail in opposite
directions:

| Model | Honest? | Thorough? | Fast? |
|---|---|---|---|
| qwen3:8b | **No.** Fabricated provenance, cited past end of file | No, 12% coverage | Yes, because it skipped the work |
| gemma4:12b | Yes, zero fabrications in 57 citations | Partly, 41% | **No.** 407 min for four briefs, fifth abandoned |

The question is whether that is the whole field or just the two we happened to
have.

## Why this is blocked, not merely later

A four-model bake-off at gemma's pace is 10 to 16 hours of wall clock, and that
assumes every model finishes, which gemma did not. Hypothesis 4 exists to find a
configuration where a brief costs minutes instead of an hour. **Until it does,
this experiment is unaffordable rather than uninformative.**

If hypothesis 4 fails, this one changes shape: the question becomes whether any
open model is honest *and* fast without intervention, which is a much narrower
search.

## Candidate screen, before any full run

Running five briefs against an unvetted model is how arm C burned two runs
discovering a model that would not call tools. Screen first, cheaply.

| Gate | Test | Why it comes first |
|---|---|---|
| 1. Tool calling | The smoke test used for arms C and D: list the `.py` files via Bash | qwen3 failed the *task* while passing this, so it is necessary and not sufficient |
| 2. Turn count on one real brief | Run brief 1 only. A one-turn result means no investigation | This is the check that would have caught qwen3 in ten minutes rather than two runs |
| 3. Honest provenance | Audit that brief's citations against the ground-truth key | Fabrication is the pass/fail criterion for the whole line of work |
| 4. Wall clock | Same brief, measured | If brief 1 costs an hour, the model is out regardless of quality |

Only models clearing all four earn the full five-brief run.

## Candidates

Not yet chosen. The shape of a sensible slate:

| Slot | Rationale |
|---|---|
| gemma4:12b at whatever hypothesis 4 settles on | The incumbent. Everything is measured against it |
| A coding-tuned model | The task is code investigation. A code-tuned model is the obvious untested axis. DeepSeek's coder line is the usual first pick |
| A general instruction model from a different family | GLM or similar, to avoid concluding something about one lineage |
| Optional: a smaller variant of whichever wins | If a 7B does what a 12B does, the wall clock problem mostly disappears |

Selection criteria before pulling anything: it must declare `tools` capability,
fit comfortably in 36 GB alongside the desktop, and be available in the ollama
library so the existing harness works unchanged.

Disk is not a constraint now. Removing qwen3:30b freed 17 GB, taking the model
store from 29 GB to 12 GB.

## Method

Identical to arms C and D, so results join the existing ladder rather than
starting a new one.

- The same five briefs, unchanged.
- One worker at a time. The daemon serves a single slot.
- A derived model per candidate pinning `num_ctx` to 40,960, matching arms C
  and D, so context is never the differing variable.
- The turn-count gate on. A one-turn worker is `no-tools`, not `ok`.
- Reports graded blind against the same rubric, added to the same pool.

## Predictions

| Prediction | Reasoning |
|---|---|
| A coding-tuned model beats both incumbents on coverage | The task is tracing values through source. That is what code tuning is for |
| Honesty does not track size | The 8B fabricated and the 12B did not, but one pair is not a trend. This is the thing to watch, not assume |
| At least one candidate fails gate 1 or 2 | Two of the first two local models had a disqualifying flaw. The base rate is not good |
| No open candidate reaches Haiku's 73% coverage | gemma managed 41% while being honest. Closing that gap is a large jump |

## What a result would change

| If | Then |
|---|---|
| A candidate is honest, above 60% coverage, and under 10 minutes a brief | The local tier is real. Hypothesis 1's off-window argument becomes practical rather than theoretical |
| The best candidate is honest but still thin | Local becomes a gathering tier only, with the manager doing all synthesis and a verification pass over anything load-bearing |
| Every candidate fabricates except gemma | gemma's slowness is the price of honesty, and the lever is hypothesis 4, not model choice |
