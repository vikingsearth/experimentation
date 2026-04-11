# Reviewer Forms

## Review Request — Intake Form

Use when the user's review request is ambiguous or needs clarification.

```markdown
## Review Request

### Scope
- **What to review**: <unstaged changes (default) | staged | branch diff | specific files>
- **Base branch**: <main, origin/main, etc. — only if branch diff>
- **Files**: <specific file paths — only if narrowing scope>

### Aspects
- **Which aspects**: <all (default) | code | simplify | comments | tests | errors | types>
- **Priority focus**: <any specific concern? e.g., "worried about error handling">

### Context
- **What changed**: <brief description of the changes being reviewed>
- **Ready for PR?**: <yes — full review | no — quick check>
```

## Review Completion — Summary Form

Used by the orchestrator to structure the final report.

```markdown
## Review Summary

### Execution
- Aspects run: <list>
- Aspects skipped: <list + reason>
- Aspects failed: <list + error>

### Counts
- Critical issues: N
- Important issues: N
- Suggestions: N
- Strengths noted: N

### Verdict
- <Ready to merge | Fix critical issues first | Needs attention>
```
