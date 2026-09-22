# Results 2 - Haiku vs Sonnet subagents, rich brief

Date: 2026-09-10
Status: **first run complete, single run per cell.** Not repeated, so noise is unmeasured
Hypothesis: [hypothesis_2.md](hypothesis_2.md)
Run assets: `optimization-exp/hyp2/`

## Headline

**The hypothesis does not hold on this task.** Sonnet subagents beat Haiku
subagents on every brief, by a wide and consistent margin, and a blind grader
sorted the ten reports into the two arms without being told they existed.

**But the reason matters.** Haiku did not fail by being wrong. It failed by
being shallower and by wandering out of scope. Fabrication, the pass/fail
criterion, was **zero in both arms**.

## What was run

| | |
|---|---|
| Task | What would it take to add multi-currency support to `general-experimentation/agentic-workflows/` |
| Briefs | The five rich briefs in `optimization-exp/hyp2/briefs/`, byte-identical across arms |
| Arm A | 5 Haiku subagents |
| Arm B | 5 Sonnet subagents |
| Method | Sequential, one subagent at a time, both arms identical |
| Manager | Opus, same session |
| Grading | Blind, by Fable, a model in neither arm. Reports anonymised and shuffled, arm labels withheld |

## Scores

Graded 1-5 per dimension against the rubric in the hypothesis document.

| Brief | Arm A report | Depth | Std | Align | Arm B report | Depth | Std | Align |
|---|---|---|---|---|---|---|---|---|
| 1 Data model | R01 | 3 | 3 | 2 | R06 | 5 | 2 | 5 |
| 2 Policy thresholds | R10 | 3 | 3 | 3 | R02 | 5 | 2 | 5 |
| 3 Risk and budget | R05 | 3 | 2 | 3 | R07 | 5 | 4 | 5 |
| 4 State and audit | R03 | 3 | 3 | 2 | R04 | 5 | 3 | 5 |
| 5 Presentation | R09 | 3 | 3 | 3 | R08 | 5 | 4 | 5 |

| Dimension | A / Haiku | B / Sonnet | Gap |
|---|---|---|---|
| Depth | 3.0 | 5.0 | +2.0 |
| Standards | 2.8 | 3.0 | +0.2 |
| Alignment | 2.6 | 5.0 | +2.4 |
| **Total of 15** | **8.4** | **13.0** | **+4.6** |

Sonnet won **all five** pairwise comparisons. Haiku scored exactly 3 on depth
in every one of its five reports, with no variation at all.

## Errors

| | Fabricated | Misattributed | Unsupported |
|---|---|---|---|
| A / Haiku | 0 | 1 | 1 |
| B / Sonnet | 0 | 2 | 0 |

**Zero fabrications across 230 citations in both arms.** No report cited a file
that does not exist or a line past the end of one. All four traps recorded in
the ground-truth key were avoided by every report that touched them.

The one unsupported claim was Haiku's, and it is the only error that would
mislead someone planning the work: it stated that employee `monthly_budget` is
read by the risk assessor. It is not read anywhere.

## The economics, and why the answer flips

Two efficiency questions have opposite answers. Which one matters depends on
what is scarce.

| Measure | A / Haiku | B / Sonnet | Winner |
|---|---|---|---|
| Raw tokens consumed | 337,673 | 414,968 | Haiku uses 1.23x fewer |
| Quality per 1k raw tokens | 0.0249 | 0.0313 | **Sonnet, by 1.26x** |
| Window-weighted units (Haiku-equivalent) | 337,673 | 829,936 | Haiku uses 2.46x fewer |
| **Quality per 1k window units** | **0.0249** | **0.0157** | **Haiku, by 1.59x** |

Sonnet is the more efficient use of a *token*. Haiku is the more efficient use
of *the window*, because a Sonnet token is billed at roughly twice a Haiku one
and the subscription window is model-weighted.

The original problem is a window problem, not a token problem. On that measure
**Haiku delivers about 1.6x more graded quality per unit of window consumed**,
while producing work that is measurably worse.

## What the grader saw without being told

The grader was given no hint that two arms existed. It independently reported
that the ten reports fall into two clusters of five, each covering all five
briefs exactly once, separated by:

| Stronger cluster (all Sonnet) | Weaker cluster (all Haiku) |
|---|---|
| Repo-relative or absolute paths | Bare `src/...` paths |
| Confidence split per claim, with reasons | Everything marked `confirmed` |
| Partial and grep-only reads annotated | Not annotated |
| Scope boundaries named explicitly | Boundaries rarely named |
| Alignment 5 on every report | All the scope drift, and the one unsupported claim |

The clusters map onto the arms perfectly. **The tiers are distinguishable by a
blind reader from surface markers alone**, which is the strongest single result
against the hypothesis.

## What actually separated them

Not volume. Haiku produced **more** findings (54 against 33) and both arms
cited exactly **107 distinct locations**. Same ground, different granularity.

The grader's summary of the difference: depth in the stronger arm came from
asking *"is this value actually used?"* rather than from listing more sites.
Three examples, all Sonnet, none of which Haiku found:

- `can_approve_up_to` is returned by a tool and never compared anywhere.
- The spending-history totals never reach the risk score at all.
- No code anywhere in the source accumulates an expense into a running total,
  so the summing logic that would need currency conversion does not exist yet.

Each of those reframes the brief rather than adding to it. That is the gap.

## Caveats

- **One run per cell.** The 4.6-point gap is large and perfectly consistent
  across five briefs, so it is unlikely to be noise, but variance is unmeasured.
  This was flagged as a design gap before the run and remains one.
- **Standards is compressed and unreliable.** Both arms scored near 3, and the
  grader noted its own scoring caveat about leading preamble text. It also
  attributed all three preamble leaks to the Sonnet cluster when one of them
  (R05) was Haiku's. Standards did not discriminate and its measurement is
  suspect.
- **Finding count is a useless proxy.** Haiku produced 64% more findings and
  scored lower on every dimension. Drop it as a measure.
- **The manager synthesis was not run.** The hypothesis predicted the gap would
  narrow at the manager's final output, from 10-25% on raw reports to 0-10%
  after synthesis. That prediction is untested and is the most important
  remaining question.
- **Rich brief only.** The thin-brief cells of the extension have not been run.

## What this changes

| Prediction made before the run | Outcome |
|---|---|
| Depth gap of 20-35%, largest of the four | **Confirmed.** 3.0 vs 5.0, the joint-largest gap |
| Standards gap of 10-20% | **Wrong.** 2.8 vs 3.0, no meaningful difference |
| Alignment roughly equal, Haiku possibly ahead | **Badly wrong.** 2.6 vs 5.0, the largest gap of the three. Haiku drifted out of scope constantly |
| Fabrication is the risk that decides it | **Wrong in a useful way.** Zero in both arms. The cheap tier is not dangerous, just weaker |
| Sonnet costs 2-4x | **Confirmed at the window level** (2.46x), but only 1.23x in raw tokens |

The alignment result is the surprise. The prediction was that a narrow model on
a narrow brief would stay on it. The opposite happened: Haiku wandered into
other investigators' territory in four of five reports, while Sonnet repeatedly
named the boundary and stopped.

## The manager synthesis - the deciding test

Run 2026-09-10 after the report grading. A fresh Opus manager per arm, each
given only that arm's five reports under a neutral directory name, told to work
from the reports alone and not open the codebase. The two answers were then
shuffled, anonymised and graded blind by Fable against the same rubric plus
Effectivity, which applies to a manager's answer and not to an investigator's
report.

### Result

| | Manager on Haiku reports | Manager on Sonnet reports |
|---|---|---|
| Depth | 4 | 5 |
| Standards | 4 | 5 |
| Alignment | 5 | 5 |
| Effectivity | 4 | 5 |
| **Total of 20** | **17** | **20** |
| Factual errors about the codebase | **3** | **0** |

### The gap narrows but does not close

| Stage | Haiku | Sonnet | Deficit |
|---|---|---|---|
| Raw subagent reports (of 15) | 8.4 | 13.0 | **35%** |
| Manager synthesis (of 20) | 17 | 20 | **15%** |

The prediction was that synthesis would shrink the gap from 10-25% to 0-10%.
Directionally right, magnitude wrong on both ends: the raw gap was larger than
predicted (35%) and the synthesised gap did not reach single digits (15%).

**An Opus manager recovered roughly half the deficit.** That is a real and
substantial effect. It is not enough to make the tiers interchangeable.

### What the manager could not fix

Errors, not shallowness. The manager working from Haiku reports produced three
factual errors about the codebase that its inputs had led it into:

| Error | Consequence |
|---|---|
| Listed two dimensionless-ratio sites as needing a currency edit | Would send an implementer to change code that needs no change. Its own input had explicitly said no currency logic was needed there |
| Sized the static-data work at ~25 literals | The real figure is 50. Half the volume of the largest edit group |
| Its top risk used the receipt-threshold check as an example of wrongly auto-approving | Two different code paths conflated. The receipt check cannot approve anything |

The manager on Sonnet reports made no codebase errors across every claim the
grader checked.

**Correction, checked 2026-09-10 against the source reports.** An earlier draft
of this document claimed the weak reports misled the manager. That is wrong.
All three errors are **manager-side**, and the reports were right on every one:

| Manager error | What its input actually said |
|---|---|
| Two ratio sites listed as needing edits | The report says verbatim: "No additional currency logic is needed here" |
| data.py sized at ~25 literals | The report gives every line range from which 50 is derivable |
| Receipt check conflated with auto-approve | The reports describe them as two separate findings, both correctly located |

**This is the finding that matters, and it is not the one predicted.** The
manager did not inherit bad information. It received correct information and
degraded it: dropping a stated qualifier, undercounting from ranges it was
given, and merging two distinct findings into one example.

Why the weaker inputs still caused it is the open question. The plausible
mechanism is load rather than content. The Haiku set carried 54 findings to the
Sonnet set's 33 over the same 107 locations, marked everything `confirmed`
without distinguishing certainty, and drifted across scope boundaries so the
same code appeared in several reports under different framings. A manager
integrating that has more to reconcile and fewer signals about what to trust.
The Sonnet set handed over fewer, better-separated, confidence-graded claims and
the same manager model made no errors on it.

**Consequence for verification.** A verifier placed between the subagents and
the manager would have caught none of these three, because none originates in a
report. Catching them requires verifying the synthesis, not the inputs. See
[hypothesis_3.md](hypothesis_3.md).

### What the manager could fix

Both syntheses added real value over their inputs, and the weaker one added
value in ways the stronger one did not. Both independently argued against their
own investigators' framing and converged on convert-once-at-ingress. Both
raised `Decimal`, which no investigator in either arm mentioned. The Haiku-fed
manager contributed the one idea the grader wanted stolen into the other answer:
a module-level base-currency declaration instead of wrapping fifty literals.

So the manager tier is doing heavy lifting regardless of subagent quality. The
gap is not in what a manager can build. It is in what a manager can trust.

### Full-pipeline economics

Counting both the subagents and the Opus synthesis, weighting each model
against the window (Haiku 1x, Sonnet 2x, Opus 5x):

| | Haiku arm | Sonnet arm |
|---|---|---|
| Raw tokens, subagents + synthesis | 418,873 | 497,922 |
| Window units, Haiku-equivalent | 743,673 | 1,244,706 |
| Quality | 17/20 | 20/20 |
| **Quality per 1k window units** | **0.0229** | **0.0161** |

The Haiku pipeline remains **1.4x more window-efficient** end to end, down from
1.6x at the report stage because the Opus synthesis is a fixed cost that dilutes
the difference.

### The honest summary

Both routes produce a usable answer. The Sonnet route produces a correct one.
The Haiku route produces one that is 85% as good, costs 40% less of the window,
and contains three errors that would each cost an implementer a day.

Whether that trade is worth taking depends on something this experiment did not
measure: what a wrong recommendation costs downstream. On a demo codebase,
nothing. On production work, more than the window saving.

## Next

1. Run the thin-brief cells, since alignment failed on the rich brief and the
   rich brief is the one carrying explicit out-of-scope lists.
2. Repeat at least one cell for variance before treating the 4.6 or the 3.0 as
   load-bearing. Both remain single observations.
3. **[Hypothesis 3](hypothesis_3.md) just got more interesting, not less.**
   Fabrication was zero, so a correctness verifier has nothing to catch. But
   the manager's three errors came from inputs that were *shallow and
   overreaching*, not inputs that were fabricated. A verifier with a
   completeness-and-scope mandate, run between the subagents and the manager,
   attacks exactly the failure this experiment found. That is now the most
   promising unexplored idea in the whole line of work.
