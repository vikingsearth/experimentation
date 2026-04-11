# Reviewer Reference

## Orchestration Workflow

The reviewer skill follows a 5-step orchestration pattern:

1. **Scope** → `get-review-scope.sh` extracts changed files + diff
2. **Select** → parse user args to pick which aspects to run
3. **Dispatch** → spawn one subagent per selected aspect
4. **Aggregate** → collect reports, deduplicate, classify severity
5. **Report** → output unified report from template

### Subagent Dispatch Protocol

Each subagent receives a prompt constructed from:

```
[Full content of the aspect's reference file]

## Review Scope
Changed files: [file list]
Diff: [diff output]

Read CLAUDE.md and applicable .claude/rules/ files for project-specific standards.
Analyze only the changed files. Produce findings in the output format specified above.
```

Subagents execute **sequentially** — one at a time. Each is independent (SRP): if one fails, log a warning in the report and continue with the next.

## Aspect Selection Logic

Default: `all` (run every applicable aspect).

| Keyword | Aspect | Reference File | Always Applicable? |
|---------|--------|---------------|-------------------|
| `code` | Code Quality | `code-reviewer.md` | Yes (if source files changed) |
| `simplify` | Simplification | `code-simplifier.md` | Yes (if source files changed) |
| `comments` | Comment Accuracy | `comment-analyzer.md` | Only if comments were added/modified |
| `tests` | Test Coverage | `test-analyzer.md` | Only if test files changed or new code added |
| `errors` | Error Handling | `error-handler-auditor.md` | Yes (if source files changed) |
| `types` | Type Design | `type-analyzer.md` | Only if type definitions added/modified |

When `all` is selected, skip non-applicable aspects with a note rather than running an empty analysis.

## Severity Classification

Findings from all aspects are classified into three tiers:

### Critical (must fix before merge)
- Bugs that will break functionality
- Security vulnerabilities
- Silent failures (empty catch blocks, swallowed errors)
- Explicit project rule violations (confidence >= 90)
- Test gaps for critical paths (criticality 9-10)

### Important (should fix)
- Project guideline violations (confidence 80-89)
- Missing error context or logging
- Test gaps for important business logic (criticality 7-8)
- Type design with weak invariant enforcement (< 5/10)
- Misleading or factually incorrect comments

### Suggestions (nice to have)
- Simplification opportunities
- Comment improvements
- Minor type design notes
- Test quality improvements (criticality < 7)
- Style preferences not explicitly in project rules

## Deduplication Rules

When multiple aspects flag the same file:line:
1. Keep the highest-severity finding
2. Note which other aspects also flagged it
3. Merge the recommendations if they're complementary

Example: if `code` flags a catch block as a rule violation (Important) and `errors` flags the same block as a silent failure (Critical), keep the Critical finding and note both aspects identified it.

## Strength Collection

Each aspect may report positive observations. Collect these into a unified "Strengths" section. Deduplicate similar praise. Include 3-5 strengths maximum to keep the section focused.
