# Spike 01 scoring - synthesis verification, reports-only

Date: 2026-09-11 (run 2026-09-10)
Design and conclusions: [hypothesis_3.md](../../../docs/research/optimization/hypothesis_3.md)

## Setup

| | |
|---|---|
| Verifier model | Sonnet 5 |
| Given | `inputs/manager-answer.md` and the five reports in `inputs/sources/` |
| Withheld | The codebase. The verifier was told not to open it |
| Withheld | Any hint of what to look for. The three known errors were never named |
| Cost | 105,226 subagent tokens, 8 tool uses, 211s |

The manager answer under test is the one built from the weaker subagent tier in
[hypothesis 2](../../../docs/research/optimization/hypothesis_2.md). It scored
17/20 in blind grading with three factual errors about the codebase.

## The three known errors, and whether the spike found them

| # | The error | In the sources? | Caught |
|---|---|---|---|
| 1 | `tools.py:136` and `152-159` listed in the "one-token edit" seam. Source report 03 F2 says verbatim "No additional currency logic is needed here" | Yes, verbatim | **No.** The verifier flagged the same table row for a different reason and argued line 163 should be **added** to the edit list |
| 2 | Static data sized at "~25 literals". The source line ranges sum to 44 | Yes, derivable by counting | **No.** Classified "unverifiable from sources". Declined to count the ranges it was given |
| 3 | Risk 1 uses `tools.py:93` as the example of a wrong auto-approval. That location is the receipt-required check, which cannot approve anything | Yes. Report 02 F6 describes it as "indicating a receipt is mandatory" | **No.** The example was not examined |

**Score: 0 of 3.**

## What it found instead

| Finding | Real? | Would it change an implementer's actions? |
|---|---|---|
| V1 Dropped `tools.py:163` citation | Yes | No. And its framing pushes toward editing a site that needs no edit |
| V2 Misquoted the per-currency example structure | Yes | No |
| V3 Two illustrative figures presented next to a source credit | Yes | No |
| V4 `docs/` file count off by one, 4 against 5 | Yes | No |

Four real findings, all hygiene, none consequential.

## The interesting part

On error 1 the verifier did not merely miss the problem. It examined the exact
table row containing it, and concluded that a **further** line should be added
to the edit list. It made the same class of mistake as the manager, on the same
row, from the same evidence.

That points at something more useful than "the verifier was not careful
enough": reading a synthesis against its sources appears to be a similar enough
task to writing one that it inherits the same weaknesses.

## Files

| Path | What |
|---|---|
| `inputs/manager-answer.md` | The synthesis under test |
| `inputs/sources/*.md` | The five reports it was built from |
| `verifier-output.md` | What the verifier returned, verbatim |
| `scoring.md` | This file |
