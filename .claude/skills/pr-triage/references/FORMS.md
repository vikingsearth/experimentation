# PR Triage Forms

## Phase 1 — Triage Review Form

Presented to user after building the triage table.

```markdown
## PR #<number> — <title>

**Author**: <author> | **State**: <state> | **Changes**: +<additions> -<deletions> across <files> files

### Triage Table

| # | Source | File | Line | Author | Type | Priority | Status | Excerpt | Recommended |
|---|--------|------|------|--------|------|----------|--------|---------|-------------|
| 1 | thread | src/foo.ts | 42 | reviewer1 | change-request | high | open | "Use Map instead of..." | fix |
| 2 | comment | — | — | reviewer2 | question | medium | open | "Why not use the..." | discuss |

### What would you like to do?

Tell me what to do with each item. Examples:
- "fix 1, discuss 2 with 'good point, will track in a follow-up'"
- "fix all high priority, skip the rest"
- "address 1 and 2, ignore 3 with 'out of scope'"
```

## Phase 2 — Resolution Report Form

Presented to user after executing resolutions.

```markdown
## Resolution Report — PR #<number>

| # | Action | Result | Detail |
|---|--------|--------|--------|
| 1 | fix | committed | `abc1234` — fix(scope): description |
| 2 | discuss | replied | Posted reply to thread |
| 3 | ignore | resolved | Replied with reason + resolved thread |
| 4 | skip | — | No action taken |

**Summary**: Fixed 1, discussed 1, ignored 1, skipped 1.
```
