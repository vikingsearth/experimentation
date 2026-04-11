# Triage Table Template

## Column Definitions

| Column | Description |
|--------|-------------|
| **#** | Row number for user reference in directives |
| **Source** | Where the feedback came from: `thread`, `review`, `comment` |
| **File** | File path (if inline review). `—` for issue comments. |
| **Line** | Line number (if inline review). `—` for issue comments. |
| **Author** | GitHub login of the commenter. Suffix with `[bot]` if bot-detected. |
| **Type** | Classification: `blocker`, `change-request`, `question`, `suggestion`, `nitpick`, `approval`, `informational` |
| **Priority** | `high`, `medium`, `low` |
| **Status** | `open`, `resolved`, `outdated` |
| **Excerpt** | First ~80 chars of the comment body, truncated with `...` |
| **Recommended** | Default recommended action: `fix`, `discuss`, `ignore`, `skip` |

## Table Format

```markdown
| # | Source | File | Line | Author | Type | Priority | Status | Excerpt | Recommended |
|---|--------|------|------|--------|------|----------|--------|---------|-------------|
```

## Sort Order

1. Priority: `high` → `medium` → `low`
2. Within same priority: by file path (alphabetical), then line number (ascending)
3. Issue comments (no file) sort after all inline comments within their priority group

## Empty State

If no feedback items exist after fetching:

```markdown
No feedback found on PR #<number>. Nothing to triage.
```

## Partial Data Warning

If one or more fetch scripts failed:

```markdown
> **Warning**: Could not fetch <source>. Table may be incomplete. Items from <sources fetched> are shown below.
```
