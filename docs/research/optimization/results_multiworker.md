# Repeated sampling closes the easy half of the gap and cannot touch the hard half

Date: 2026-09-22
Status: **analysis of existing artifacts, no new runs**
Ladder: [results_ladder.md](results_ladder.md)
Hypothesis 5: [results_5.md](results_5.md)

## Why this exists

[Results 5](results_5.md) noticed that on brief 2, gemma and devstral both
scored 38% and **found different sites**: devstral caught the per-person cap
gemma missed, gemma caught the receipt threshold devstral missed. Neither was a
subset of the other.

That raised a question the ladder had never asked. If two cheap workers miss
different things, does running two of them beat running one?

**No new runs were needed.** Three local runs of brief 2 already existed on
disk: gemma with thinking off, devstral in arm E, and devstral in its screen.
The union is arithmetic over artifacts we already had.

## Result

Reference set: the 8 locations Haiku and Sonnet found between them on brief 2.

| Configuration | Coverage | Runs needed |
|---|---|---|
| Haiku | 6/8 = 75% | 1, in 62s |
| Sonnet | 7/8 = 88% | 1, in 100s |
| gemma think-off alone | 3/8 = 38% | 1 |
| devstral alone | 3/8 = 38% | 1 |
| **gemma + devstral** | **4/8 = 50%** | 2 |
| gemma + both devstral runs | 5/8 = 62% | 3 |
| **devstral run twice, alone** | **5/8 = 62%** | 2 |

**Two workers beat one.** 38% to 50% mixed, 62% at three.

## The twist: it is not model diversity, it is variance

**Devstral against itself does as well as the mixed pair, and better.** Its two
runs on brief 2 shared only **4 of 19** citations. Same model, same brief, same
configuration, largely different findings each time.

So the gain does not come from combining different models. It comes from
**sampling the same weak model more than once**. That is simpler and cheaper
than a multi-model setup: one model stays resident, no second pull, no second
derived model.

It also retroactively explains something from hypothesis 2.1 that was recorded
as a defect. Arm C's two runs of brief 1 produced 22 citations and then 6, and
that instability was written up as "coverage is not a reliable per-run metric".
It is the same phenomenon, seen from the other side. **The instability is the
resource.**

## Where the ceiling actually is

Per-location, across every local run ever made on this brief:

| Location | Source | Found by any local worker? |
|---|---|---|
| `agents.py:141` | `if amount > policy["max_single_expense"]:` | Yes |
| `agents.py:152` | `if amount > policy["requires_pre_approval_above"]:` | Yes |
| `agents.py:393` | `elif amount <= thresholds["auto_approve_up_to"]` | Yes |
| `tools.py:93` | `required = amount > threshold` | Yes |
| `agents.py:189` | `if per_person > 50:` | Once, by one devstral run |
| **`agents.py:196`** | `if "alcohol" in notes:` | **Never** |
| **`agents.py:200`** | `if alcohol_amount > 30:` | **Never** |
| **`agents.py:204`** | `break` | **Never** |

The three-line alcohol block is found by **no local model, in any
configuration, in any run**. It is the finding that requires noticing that a
value parsed out of free-text notes participates in a monetary comparison.

**Union sampling can never reach it, because no sample ever contains it.**

## The honest arithmetic

| | Haiku | Local, sampled 3x |
|---|---|---|
| Coverage | 75% | 62% |
| Runs | 1 | 3 |
| Wall clock | 62s | ~15 min |
| Window cost | Non-zero | Zero |

62% looks close to 75% until you notice which 38% is missing. The reachable
part of the gap is the part that needed searching. The unreachable part is the
part that needed inference, and more samples do not produce inference.

## What this changes

**Adopt, cheaply.** If a local tier is used at all, run the same worker two or
three times on the same brief and union the findings. It is a loop in the
harness, needs no new model, and measurably lifts 38% to 62%.

**Stop treating run-to-run instability as a defect.** It was recorded as one in
hypothesis 2.1. For a union strategy it is the mechanism.

**Do not expect it to close the gap.** There is a class of finding this tier
does not reach at any sample count. That is a capability ceiling, and it is the
same conclusion hypothesis 5 reached from a different direction.

## Caveats

- One brief. Brief 2 was chosen because it is where models separate, but the
  union effect has not been measured on the other four.
- Three runs, two of them devstral. The devstral-against-itself result rests on
  two samples.
- Union was computed over cited locations, not over graded report quality. Two
  reports that name the same line may still differ in what they say about it,
  and a manager would have to reconcile them.
- Nobody has tested whether a manager synthesising two thin reports produces a
  better answer than one, which is the question that actually matters
  downstream.
