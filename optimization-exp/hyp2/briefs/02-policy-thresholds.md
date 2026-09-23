# Brief 2 of 5 - Policy thresholds and comparisons

## Context

You are one of five investigators looking at the same codebase at the same
time. Each of us has a different, non-overlapping question. You will not see
the other briefs or the other reports, and you do not need to. Answer only
your own question.

The codebase is a self-contained Python demo called **Agentic Workflows:
Expense Approval Demo**, at `general-experimentation/agentic-workflows/` in
this repository. Five cooperating agents process expense reports through
classification, policy checking, risk assessment, decision making and review.
It uses the Python standard library only.

The proposed change under investigation is:

**Add multi-currency support to the expense approval workflow.**

Today every monetary amount in the system is an implicit US dollar `float`.
The change would let an expense be submitted in another currency (for example
EUR or ZAR), be evaluated correctly against policy limits and budgets, and be
reported in both its original currency and a single base currency.

Nobody is asking you to make this change. You are working out what it would
take, for your assigned area only.

## Your question

Find every place an amount is **compared against a limit or threshold**, and
work out what each comparison would need in order to be correct when the two
sides are in different currencies.

A comparison between an amount in one currency and a limit in another is the
core correctness risk in this change. Find all of them.

## Where to look

Start with the `PolicyAgent` class in
`general-experimentation/agentic-workflows/src/agents.py`.

Then look at these functions in
`general-experimentation/agentic-workflows/src/tools.py`:
`get_policy_rules`, `get_approval_thresholds`, `check_receipt_attached`.

## How to work

- **Use tools. Do not answer from assumption.** Every file path, symbol name
  and line number in your report must come from something a tool actually
  returned to you.
- **This build has no Glob or Grep tool.** Use `Bash` for file search, for
  example `ls`, `find`, `grep -rn`. Use `Read` to open a file.
- **If you cannot find something, say so.** Write it under "What I could not
  determine". A stated gap is a correct answer. A guess that looks like a
  finding is the worst possible outcome.
- **Mark every finding `confirmed` or `inferred`.** `confirmed` means you saw
  it in tool output. `inferred` means you reasoned it from something else.
- Do not modify any file. This is a read-only investigation.
- Do not read or quote any `.env` file, anywhere, for any reason.

## Conventions this codebase follows

These are not inherited automatically, so they are restated here:

- Python 3.9+, standard library only. Adding a dependency is a significant
  change and must be called out as one.
- Type hints on function signatures, `from __future__ import annotations` at
  the top of modules that need forward references.
- Module-level docstrings explaining the module's role in the pipeline.
- Monetary values are currently bare `float`, with no currency attached.
- `src/state.py` holds the single shared state object that every agent reads
  from and writes to. Treat it as the spine of the system.

## Output shape

Reply with exactly these sections, in this order, and nothing else.

```
## Summary

<Two or three sentences. What would this change mean for your area?>

## Findings

### F1. <short title>

- **Location**: `<path>:<line>`
- **What it does today**:
- **What the change would require**:
- **Confidence**: confirmed | inferred

### F2. <short title>

<...same five fields, repeat for every finding...>

## What I could not determine

- <one bullet per open question, or the single word: none>

## Files I read

- <one path per line, every file you actually opened>
```

## Done when

You have listed every comparison operator that has a monetary value on either
side, with its file and line, and said for each whether it would break, and
what it would need.

## Out of scope

- Where the policy numbers are defined as data (brief 1)
- Risk scoring and budget consumption (brief 3)
- The shared state object (brief 4)
- Printing and formatting (brief 5)

Do not investigate anything above. Another investigator has it.
