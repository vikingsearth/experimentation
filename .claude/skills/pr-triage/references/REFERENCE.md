# PR Triage Reference

## Triage Classification

### Comment Type Detection

Classify each comment by scanning the body for signal patterns. First match wins.

| Type | Signals | Examples |
|------|---------|---------|
| `blocker` | "must", "blocking", "required", "cannot merge", "do not merge" | "This must be fixed before merge" |
| `change-request` | "please change", "should be", "needs to be", "instead of", "replace with" | "This should use a Map instead of an object" |
| `question` | ends with `?`, "why", "what about", "have you considered", "is this intentional" | "Why not use the existing helper?" |
| `suggestion` | "consider", "might want to", "could also", "what about", "nit:", "optional:" | "Consider using Array.from() here" |
| `nitpick` | "nit:", "nit ", "minor:", "style:", "formatting" | "nit: trailing whitespace" |
| `approval` | "LGTM", "looks good", "ship it", "approved", ":+1:", ":shipit:" | "LGTM — nice refactor" |
| `informational` | everything else — status updates, context, CI output, links | "CI passed on retry" |

### Priority Assignment

| Priority | Criteria |
|----------|----------|
| `high` | Blockers. Change-requests from CODEOWNERS. Unresolved threads from maintainers. CI failures from bots. |
| `medium` | Change-requests from non-owner reviewers. Actionable questions. Substantive suggestions. |
| `low` | Nitpicks. Informational. Approvals. Already-resolved threads. Outdated threads. Bot comments (non-failure). |

### Status Detection

| Status | How detected |
|--------|-------------|
| `open` | Thread is not resolved and not outdated. No "fixed"/"done"/"addressed" in follow-up replies. |
| `resolved` | Thread `isResolved == true` (GraphQL). Or follow-up reply contains "fixed", "done", "addressed". |
| `outdated` | Thread `isOutdated == true` (GraphQL). Code has changed since the review. |

### Deduplication

Review threads (GraphQL) are the **primary source** — they contain resolution status and thread structure that REST review comments lack.

To deduplicate:
1. Build a set of `(path, line, first_comment_body_trimmed)` from GraphQL threads.
2. For each REST review comment, check if it matches a thread in the set.
3. If match found, drop the REST comment (the thread already covers it).
4. Issue comments (REST) are never deduplicated — they're a different data source.

### Bot Detection

A comment author is a bot if **any** of these match:
- `user.type == "Bot"`
- `user.login` ends with `[bot]`
- `user.login` matches known bot pattern: `dependabot`, `github-actions`, `renovate`, `codecov`, `sonarcloud`, `copilot`, `claude-code`, `netlify`, `vercel`

Bot comments default to `informational` / `low` unless the body indicates a CI failure (contains "failed", "error", "❌").

## Resolution Execution

### Fix

1. Read the file referenced in the comment (`path` field).
2. Understand the feedback — what change is requested.
3. If the comment contains a GitHub suggestion block (` ```suggestion ... ``` `), apply it exactly.
4. Make the code change.
5. Commit with conventional commits: `fix(scope): description` — max 2 files per commit.
6. After fixing, reply to the comment: "Fixed in `<commit-hash>`."
7. If it's a thread, resolve it after replying.

### Ignore

1. Reply to the comment with the user's reason (e.g., "Out of scope for this PR — tracking in #123").
2. If it's a thread, resolve it after replying.

### Discuss

1. Reply to the comment with the user's message.
2. Do **not** resolve the thread — leave it open for further discussion.

### Skip

No action. Item is left as-is.

## Recommended Actions (defaults)

The triage table includes a recommended action per item. These are suggestions — the user decides.

| Condition | Recommended Action |
|-----------|--------------------|
| `blocker` + `open` | fix |
| `change-request` + `open` | fix |
| `question` + `open` | discuss |
| `suggestion` + `open` | fix (if low-effort) or discuss |
| `nitpick` + `open` | fix (if trivial) or ignore |
| `approval` | skip |
| `informational` | skip |
| `resolved` | skip |
| `outdated` | skip (or verify) |
| Bot + non-failure | skip |
