---
name: reviewer
description: Performs comprehensive multi-aspect code review by orchestrating 6 specialized review passes — code quality, simplification, comment accuracy, test coverage, error handling, and type design. Each pass runs as a subagent with dedicated instructions and the orchestrator aggregates all findings into a unified severity-ranked report. Adapted from Anthropic's pr-review-toolkit for this project's conventions. Use when reviewing code changes, preparing for a PR, or when the user mentions code review, review my changes, check my code, or PR review.
compatibility: Requires git CLI. Works in any AI agent with subagent/task dispatch capability.
metadata:
  author: nebula-aurora
  version: "0.1.0"
  purpose: development
  type: P1
disable-model-invocation: false
user-invocable: true
argument-hint: "[review-aspects: code|simplify|comments|tests|errors|types|all]"
---

# Reviewer

Orchestrates 6 specialized code review passes via subagents, then aggregates findings into a single severity-ranked report.

## When to Use

- Before creating a pull request — comprehensive review of all changes
- After writing or modifying code — targeted review of specific aspects
- When the user says "review my code", "check my changes", "PR review", or "review"
- When preparing code for commit and want quality assurance

## Workflow

### Step 1 — Determine Review Scope

Run the scope script to identify what changed:

```bash
bash .claude/skills/reviewer/scripts/get-review-scope.sh
```

Supports flags: `--staged` (staged changes only), `--branch <base>` (diff against branch), `--files <path...>` (specific files).

If the script returns no changed files, report "No changes detected" and suggest the user specify files or a base branch.

If the diff exceeds ~2000 lines, warn the user and suggest narrowing scope.

### Step 2 — Select Review Aspects

Parse the user's input to determine which review passes to run. Default is `all`.

| Aspect | Keyword | Reference File | Focus |
|--------|---------|---------------|-------|
| Code Quality | `code` | [code-reviewer.md](references/code-reviewer.md) | Project guidelines compliance, bug detection, confidence scoring |
| Simplification | `simplify` | [code-simplifier.md](references/code-simplifier.md) | Clarity, nesting reduction, redundancy, project standards |
| Comment Accuracy | `comments` | [comment-analyzer.md](references/comment-analyzer.md) | Factual verification, rot detection, maintainability |
| Test Coverage | `tests` | [test-analyzer.md](references/test-analyzer.md) | Behavioral coverage, critical gaps, criticality rating |
| Error Handling | `errors` | [error-handler-auditor.md](references/error-handler-auditor.md) | Silent failures, catch blocks, logging, fallback behavior |
| Type Design | `types` | [type-analyzer.md](references/type-analyzer.md) | Encapsulation, invariant expression/enforcement |

**Applicability rules** — skip aspects that don't apply to the changed files:
- `types`: skip if no type definitions were added or modified
- `tests`: skip if no test files were changed AND no new code was added
- `comments`: skip if no documentation comments were added or modified
- `code`, `errors`, `simplify`: always applicable when source files changed

### Step 3 — Dispatch Subagents

For each selected review aspect, spawn a subagent. Each subagent receives:

1. **Its dedicated instruction file** — read the corresponding reference file from the table above and include its full content as the subagent's task prompt
2. **The review scope** — list of changed files and the diff output from Step 1
3. **Project context** — instruct the subagent to read CLAUDE.md and any applicable `.claude/rules/` files for project-specific standards

**Subagent dispatch pattern** (per aspect):

```
Launch subagent with prompt:
"You are a [aspect] specialist. Follow the instructions below exactly.

[Full content of the reference file, e.g., references/code-reviewer.md]

## Review Scope
Changed files: [file list from Step 1]
Diff: [diff output from Step 1]

Read CLAUDE.md and applicable .claude/rules/ files for project standards.
Analyze only the changed files. Produce your findings in the output format specified in your instructions."
```

Execute aspects **sequentially** (one at a time). If a subagent fails or returns empty, log a warning and continue with remaining aspects — each aspect is independent (SRP).

### Step 4 — Aggregate Results

Collect all subagent reports. Merge findings into the unified report format from [review-report-template.md](assets/review-report-template.md):

1. **Deduplicate** — if multiple aspects flag the same file:line, keep the highest-severity version and note which aspects flagged it
2. **Classify severity**:
   - **Critical** (must fix): bugs, security issues, silent failures, confidence ≥ 90
   - **Important** (should fix): guideline violations, missing tests for critical paths, confidence 80-89
   - **Suggestions** (nice to have): simplification opportunities, comment improvements, minor type design notes
3. **Count** issues per severity per aspect
4. **Strengths** — collect positive observations from all aspects

### Step 5 — Present Report

Output the aggregated report. See [REFERENCE.md](references/REFERENCE.md) for the full aggregation rules and severity classification details.

## Example Inputs

- `/reviewer` — full review of all unstaged changes, all aspects
- `/reviewer code errors` — review only code quality and error handling
- `/reviewer tests` — review only test coverage for changed files
- `/reviewer --staged` — review staged changes only
- `/reviewer types simplify` — review type design and simplification only
- "review my changes before I create a PR"
- "check the error handling in my latest code"

## Edge Cases

- **No changed files**: Report "No changes detected" — suggest `--files` or `--branch` flags
- **Subagent failure**: Warn in report, continue with remaining aspects
- **Large diff (>2000 lines)**: Warn user, suggest narrowing scope to specific files
- **No CLAUDE.md**: Code-reviewer and code-simplifier skip project guidelines checks, note this in output
- **Aspect not applicable**: Skip with a note (e.g., "types: skipped — no type definitions changed")
- **Mixed languages**: Each aspect handles multi-language diffs — the instructions are language-agnostic

## File References

- `scripts/get-review-scope.sh` — extracts changed files and diff from git
- `references/REFERENCE.md` — orchestration workflow, severity classification, aggregation rules
- `references/FORMS.md` — structured intake form for review requests
- `references/code-reviewer.md` — subagent instructions: code quality review
- `references/code-simplifier.md` — subagent instructions: simplification pass
- `references/comment-analyzer.md` — subagent instructions: comment accuracy audit
- `references/test-analyzer.md` — subagent instructions: test coverage analysis
- `references/error-handler-auditor.md` — subagent instructions: error handling audit
- `references/type-analyzer.md` — subagent instructions: type design analysis
- `assets/review-report-template.md` — output template for the aggregated report
