# Arm C running observations

Notes taken during the run. The full audit and blind grading happen after.

## Brief 01, data model

**Structure: better than expected.** All four required sections present, six
findings in the exact field format. No preamble leak, which two Sonnet reports
and one Haiku report in hypothesis 2 did have.

**Speed: far faster than predicted.** 130s wall against an estimate of 15-30
minutes. But only **2 turns**, where the Haiku worker on this brief used 10
tool calls and opened 6 files.

**Accuracy: the first real problem.** Of 22 file-and-line citations, 17 land on
a line that actually holds a monetary value. Five do not:

| Cited | What is actually there | What the model meant |
|---|---|---|
| `data.py:142` | `SAMPLE_EXPENSES = [` | the list opener |
| `data.py:144` | `"id": "EXP-001",` | an id field |
| `data.py:152` | `{` | a brace |
| `data.py:160` | `},` | a brace |
| `data.py:170` | `{` | a brace |

The real amount lines are 147, 156, 165 and 174. The model cited the dict
boundaries instead, and marked the finding **`confirmed`**, meaning it claimed
to have seen this in tool output.

These are **misattributions**, not fabrications: the file is real and the lines
exist, they just do not contain what is claimed. Arms A and B produced **zero**
of either across 230 citations between them. Arm C produced five in its first
report.

**Terseness.** 301 words against roughly 1,000 for the Haiku equivalent, and
"What I could not determine: none" where the stronger arms listed several
genuine open questions.

## Working hypothesis, to test against the remaining briefs

Two turns suggests the model read very little and reconstructed the rest from
the brief plus a partial read. That would explain the pattern: correct
structure, correct file, approximately correct region, wrong exact line. If it
holds across briefs, the finding is that this tier produces
**confidently-placed but imprecise citations**, which is more dangerous than
being obviously wrong, because it survives a shape check.

## Brief 02, policy thresholds

3 turns, 190s. Citation accuracy better (4 of 5 on target), coverage still poor.

| Measure | Value |
|---|---|
| Coverage against the A+B union | 3 of 8 locations, 38% |
| Missed | `agents.py:189` and `:200` (the hardcoded caps), `tools.py:93` (receipt threshold) |
| Drifted into | `agents.py:287`, which the brief assigns to another investigator |
| Wrong | `agents.py:419`, which is the comment `# Standard approval` |

`tools.py:93` is the site arm B specifically flagged as the one a real
implementation would most likely miss, because the comparison lives inside the
tool rather than in the agent. The cheap tier walked past it.

## Brief 03, risk and budget: the run's defining failure

**One turn. 1,967 input tokens.** The system prompt plus this brief is about
2,100 tokens on its own, so the worker **read nothing at all** and answered
from the brief text.

It then wrote this:

```
## Files I read

- general-experimentation/agentic-workflows/src/agents.py
- general-experimentation/agentic-workflows/src/tools.py
```

Both false. No tool was called.

The brief said, explicitly: *"Every file path, symbol name and line number in
your report must come from something a tool actually returned to you"* and
*"one path per line, every file you actually opened"*. This is a direct breach
of a stated rule, not a lapse of care.

Its three citations:

| Cited | What is actually there |
|---|---|
| `agents.py:42` | `print(f"{'=' * 60}")`, a separator |
| `tools.py:112` | `"largest_single_expense": 0.0,` |
| `tools.py:189` | `}` |

**This is the qualitative line arms A and B never crossed.** Their errors were
shallowness and scope drift on work they had actually done. This is invented
provenance: a confident, correctly-shaped report about a codebase the worker
never opened.

### A defect in the runner this exposed

The `ok` status only checks that a report contains a Findings section. A report
with zero tool calls passes that check. **Turn count is the real signal**, and
any worker finishing in one turn should be treated as not having investigated.
Worth adding to the runner before arm D, and worth recording as a
methodological lesson regardless.

## Brief 04, state and audit: hard fabrication

One turn again, 1,974 input tokens, nothing read. Two consecutive briefs with
zero tool calls makes it a pattern rather than a one-off.

It claimed `## Files I read: state.py`. It did not open it.

Its citations:

| Cited | Reality |
|---|---|
| `state.py:32` | `"""`, a docstring delimiter |
| `state.py:68` | `status: str = "pending"`, not a monetary field |
| `state.py:112` | **The file is 98 lines long** |
| `state.py:157` | **The file is 98 lines long** |

The last two are **hard fabrications**: line numbers that cannot exist in a
file of that length. This is the strict-sense failure, not the softer
misattribution seen in briefs 1 and 2.

## Where this leaves the pass/fail criterion

[Hypothesis 2](hypothesis_2.md) set fabrication as the pass/fail measure, on
the reasoning that a shallow subagent is recoverable but a confidently wrong
one poisons the synthesis.

| Arm | Citations | Fabrications |
|---|---|---|
| A, Haiku | 119 | 0 |
| B, Sonnet | 111 | 0 |
| **C, qwen3:8b** | ~35 so far | **2 hard, plus 2 briefs of invented provenance** |

Arm C fails it. Not marginally, and not because of context: input token counts
of about 1,970 against a 40,960 ceiling mean context was never remotely the
constraint. The derived model removed that variable successfully, which makes
this a clean reading of the model rather than of the configuration.

## Brief 05 and the completed run

Brief 5, the heaviest, did read files: 3 turns, 10,812 input tokens, 210s. But
it cited only 5 locations against 57 that arms A and B found between them, a
4% coverage rate on the brief with the largest surface.

### Arm C, complete

| Brief | Turns | Input | Wall | Citations | Hard fabrications | Coverage vs A+B |
|---|---|---|---|---|---|---|
| 01 data model | 2 | 6,901 | 130s | 22 | 0 | 14/42 = 33% |
| 02 policy thresholds | 3 | 14,162 | 190s | 5 | 0 | 3/8 = 38% |
| 03 risk and budget | **1** | 1,967 | 80s | 3 | 0 | 0/26 = **0%** |
| 04 state and audit | **1** | 1,974 | 70s | 4 | **2** | 0/29 = **0%** |
| 05 presentation | 3 | 10,812 | 210s | 5 | 0 | 2/57 = 4% |

Run: 2026-09-11 16:49:30 to 17:00:51. Worker wall 680s. 35,816 tokens in and
9,374 out through the local engine. Five of five briefs returned a
structurally valid report.

### The three findings

**1. It fails the pass/fail criterion.** Two hard fabrications, and two of five
briefs where it did no work at all while claiming in `Files I read` that it
had. Arms A and B produced zero of either across 230 citations.

**2. Coverage collapsed, and that is the bigger number.** 19 of 162 locations
that the Anthropic tiers found, about 12% overall. Its five reports total 1,241
words against roughly 5,000 for arm A. This is not a tier that is shallower; on
three of five briefs it is a tier that did not investigate.

**3. Context was never involved.** The largest input seen was 14,162 against a
40,960 ceiling. The two failed briefs used under 2,000 tokens. Building the
derived model did its job: this reads the model, not the daemon configuration.
Had the arm run at the 32,768 default and produced this, the result would have
been arguable. It is not.

### What it got right, which is worth not burying

Structural compliance was **better than the Anthropic arms**. All five reports
carried the four required sections in the right order with correctly shaped
finding blocks. No preamble leaked, where two Sonnet reports and one Haiku
report did leak. Format adherence and investigative honesty turn out to be
independent properties.

### Against the predictions

| Predicted | Outcome |
|---|---|
| Scores below arm A on every dimension | Correct, but by a far larger margin than intended |
| **Fabrication will be non-zero** | **Correct.** This was the prediction worth watching and it held |
| Completion below 5 of 5 for at least one arm | **Wrong in a worse way.** 5 of 5 completed and looked valid. The failures are invisible to a completion check |
| Alignment will be the worst dimension | Superseded. Provenance failure outranks it |
| No brief exceeds the context ceiling | Correct, by a wide margin |

The completion prediction being wrong is the uncomfortable part. A run that
fails loudly is cheap to catch. This one produced five well-formed reports, two
of which were fabricated wholesale, and only the turn count gave it away.
