# Hypothesis 2 experiment - working directory

Run assets for [hypothesis 2](../../docs/research/optimization/hypothesis_2.md).
The design, predictions, rubric and expected outcomes live in that document.
This directory holds only what a run consumes and produces.

## Layout

| Path | What it is |
|---|---|
| `briefs/` | The five subagent briefs. **Rich** variant, used by arms A and B |
| `ground-truth.md` | Facts about the target, for the grader. **Never given to a subagent** |
| `reports/` | Where subagent reports land, one subdirectory per arm |

## The benchmark task

**Target**: `general-experimentation/agentic-workflows/` in this repository.

A self-contained Python demo, 1189 lines across five source modules, no
dependencies, no tests. Five cooperating agents process expense reports
through a pipeline sharing one state object.

**The question put to the swarm**: what would it take to add multi-currency
support? Every monetary amount today is an implicit US dollar `float`.

### Why this target

| Requirement from the design | How this target meets it |
|---|---|
| Splits into five independent lookups | The change is cross-cutting. Amounts appear in all five modules, and the module boundaries give five non-overlapping areas |
| Checkable ground truth | Six source files. Any claimed path, symbol or line can be checked in one command |
| Investigation, not judgment | The swarm reports what exists. The manager decides what to do |
| Big enough to require searching | 1189 lines is past what fits in one read, so a subagent must actually look |
| Safe to publish | This repository is public and the target is already in it. No internal code enters the experiment |

## The five briefs

Each subagent gets exactly one brief and nothing else. It does not see the
others and does not need to.

| Brief | Area | Core question |
|---|---|---|
| [01](briefs/01-data-model.md) | Data model and inputs | Where do amounts enter or sit as static data? |
| [02](briefs/02-policy-thresholds.md) | Policy thresholds | Where is an amount compared against a limit? |
| [03](briefs/03-risk-and-budget.md) | Risk and budget | Where is an amount accumulated or scored? |
| [04](briefs/04-state-and-audit.md) | State and audit | What would the shared state need to carry currency? |
| [05](briefs/05-presentation-and-docs.md) | Presentation and docs | Where is an amount formatted, printed or documented? |

Each brief names its own out-of-scope areas explicitly, so the five carve the
problem up rather than overlapping.

## What is deliberately identical across the briefs

The scaffolding, byte for byte. Context, working rules, restated conventions,
output shape and the anti-fabrication instruction are generated from one
template. Only the question, the starting points, the completion criteria and
the out-of-scope list differ.

That matters because the experiment varies the **subagent model** and nothing
else. Any variation in brief quality between the five would confound it.

## Running an arm

1. Confirm the standing one-subagent-at-a-time rule has been lifted for the run.
   Every arm is five subagents at once.
2. Set the subagent model for the arm. Haiku for arm A, Sonnet for arm B.
3. Give each subagent one brief, verbatim. Do not summarise or paraphrase it.
4. Collect the five reports into `reports/<arm>/`.
5. Record window usage before and after, and wall-clock.
6. Have the manager synthesise, and keep that synthesis alongside the reports.

Arms must not share a session. One arm per fresh window where possible, so the
usage readings are attributable.

## Grading

Blind, in a separate session, against the rubric in the hypothesis document.
The grader gets the task, the briefs, the anonymised reports in shuffled order
and `ground-truth.md`. It does not get the arm labels, the model names or the
hypothesis.

## Not yet written

The **thin** brief variants, needed for the brief-richness extension. Those
carry the same asks with the scaffolding stripped out.
