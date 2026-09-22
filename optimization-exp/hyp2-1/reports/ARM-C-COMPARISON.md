# Arm C, two runs compared

Model: `qwen3-8b-40k`. Same five briefs, same sequential method, same machine.
Run 1: 2026-09-11 16:49:30. Run 2: 17:15:10, after the runner gained a
turn-count gate that labels a one-turn worker `no-tools`.

Run 1 predates that gate, so its one-turn results are relabelled here to match.
Nothing about the worker command changed between runs.

## Per-brief outcome

| Brief | Run 1 | Run 2 first attempt | Run 2 retry | Verdict |
|---|---|---|---|---|
| 01 data model | 2 turns, ok | 2 turns, ok | - | **worked both times** |
| 02 policy thresholds | 3 turns, ok | 1 turn, no-tools | 3 turns, ok | **inconsistent** |
| 03 risk and budget | 1 turn, no-tools | 1 turn, no-tools | 1 turn, no-tools | **never worked, 3 of 3** |
| 04 state and audit | 1 turn, no-tools | 1 turn, no-tools | 1 turn, no-tools | **never worked, 3 of 3** |
| 05 presentation | 3 turns, ok | 4 turns, ok | - | **worked both times** |

## What reproduced

**The failures are per-brief, not random.** Briefs 3 and 4 failed every attempt
across both runs, six attempts between them, none of which called a tool.
Briefs 1 and 5 worked every time. Only brief 2 varied.

**The token counts are near-identical between runs**, which is the strongest
evidence this is a property of the brief rather than chance:

| Brief | Run 1 input | Run 2 input |
|---|---|---|
| 01 | 6,901 | 6,902 |
| 03 | 1,967 | 1,967, twice |
| 04 | 1,974 | 1,974, twice |

Brief 3 consumed exactly 1,967 tokens on three separate attempts. The model is
not rolling a dice, it is doing the same thing every time.

## What did not reproduce

**Citation density is unstable.** Brief 1 read the same files in both runs and
produced six findings both times, but cited 22 locations in run 1 and 6 in run
2. Same findings, quarter of the detail. **Coverage counts are therefore not a
reliable per-run metric for this tier**, which weakens the 33% and 38% coverage
figures reported from run 1 alone.

## What the two runs settle

| Question | Answer |
|---|---|
| Was run 1 an artifact of the machine locking? | No. No sleep events in the window, and run 2 reproduces the same briefs failing |
| Is the failure stochastic or brief-dependent? | **Brief-dependent.** Same briefs, same token counts, every attempt |
| Does a retry recover it? | **Sometimes.** Brief 2 recovered. Briefs 3 and 4 never did, in four retry attempts |
| Did context ever bind? | No. Worst case 22,886 against a 40,960 ceiling |

## The likely mechanism, and a cheap test

Briefs 2 and 3 point at the same two files, so size does not explain why one
works and the other never does. The difference is framing.

Brief 2 asks for something concrete and searchable: every place an amount is
compared against a limit. Brief 3 opens conceptually: *"Accumulation is
different from comparison: adding amounts in mixed currencies is wrong in a way
that a single comparison is not."* Brief 4 opens the same way: *"The state
object is the spine. If currency is dropped here, every agent downstream is
wrong regardless of what else is fixed."*

Both briefs that never worked lead with a conceptual claim. Both briefs that
always worked lead with a concrete instruction. A model of this size can write
a plausible essay from the conceptual framing without opening anything, and it
does.

**The test is cheap**: rewrite brief 3's opening concretely, keeping the same
ask, and run it alone. If it starts calling tools, the finding is about brief
design for weak models rather than about the model's competence. That would
also mean hypothesis 2.1's rich briefs, written for Anthropic tiers, are
actively mis-shaped for local ones.

## Operational conclusion

A local tier at this size needs **a turn-count gate**. Without one, run 1 wrote
two fabricated reports to disk labelled `ok`, including citations to lines
beyond the end of a 98-line file. With one, the same failures surface honestly
as `no-tools` and never reach a manager.

The gate is necessary and not sufficient. It converts silent fabrication into
visible absence, which is the right trade, but three of five briefs still
produced either nothing or a third of the coverage the Anthropic tiers managed.
