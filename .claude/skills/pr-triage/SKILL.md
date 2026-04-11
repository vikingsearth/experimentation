---
name: pr-triage
description: Fetches PR comments, review comments, and review threads from GitHub, builds a unified triage table with classification and recommended actions, then executes user-directed resolutions. Use when reviewing PR feedback or triaging PR comments.
compatibility: Requires gh CLI (authenticated), jq, and git.
metadata:
  author: nebula-aurora
  version: "0.1.0"
  purpose: development
  type: P1
disable-model-invocation: false
user-invocable: true
argument-hint: "Give the pull request number"
---

# PR Triage

Fetches all feedback on a GitHub PR (issue comments, review comments, review threads), classifies each item, and presents a unified triage table. After user direction, executes resolutions: fixing code, replying to threads, and posting comments.

## When to Use

- User wants to review and act on PR feedback
- User mentions triaging, resolving, or addressing PR comments
- User provides a PR number and asks what needs to be done

## Workflow

### Phase 1 — Fetch & Triage

1. **Detect repo** — extract `owner/repo` from `gh repo view --json nameWithOwner`
2. **Fetch data** — run the four fetch scripts in parallel. If one fails, continue with the others and note the gap.
   - `bash scripts/fetch-pr-metadata.sh <pr-number>`
   - `bash scripts/fetch-comments.sh <owner> <repo> <pr-number>`
   - `bash scripts/fetch-review-comments.sh <owner> <repo> <pr-number>`
   - `bash scripts/fetch-review-threads.sh <owner> <repo> <pr-number>`
3. **Classify** — for each item, determine type and priority using rules in [references/REFERENCE.md](references/REFERENCE.md)
4. **Deduplicate** — review threads (GraphQL) are primary. Remove review comments that match a thread by `path + line + first comment body`.
5. **Build triage table** — present a single unified table using the format in [assets/triage-table-template.md](assets/triage-table-template.md). Sort by priority (high → low), then by file path.
6. **Wait for user direction** — present the table and ask the user what to do with each item. Accept natural language (see Interactive Decision Pattern below).

### Phase 2 — Execute Resolutions

7. **Parse user directives** — map each item to an action: `fix`, `ignore`, `discuss`, or `skip`.
8. **Execute per item**:
   - **fix**: Read the file, understand the feedback, make the code change, commit with conventional commits (max 2 files per commit, no `--author`, no `Co-Authored-By`)
   - **ignore**: Reply to the comment/thread with the user's reason using `bash scripts/reply-comment.sh`, then resolve the thread if applicable using `bash scripts/resolve-thread.sh`
   - **discuss**: Reply with the user's message using `bash scripts/reply-comment.sh`. Leave thread unresolved.
   - **skip**: Do nothing.
9. **Resolution report** — summarize what was done per item (action taken, commit hash if fixed, reply posted if commented).

### Interactive Decision Pattern

Accept natural language directives. Examples the user might say:

- "fix 1, 3, and 5, ignore the rest"
- "address all the high-priority ones, skip everything else"
- "fix the type safety issues, ignore the nitpicks, discuss item 4 with 'this is intentional because...'"
- "do 1 and 3, let me think about the others"

Interpret intent categories: **fix** (make the code change), **ignore** (reply with reason + resolve), **discuss** (reply without resolving), **skip** (no action). If genuinely ambiguous, ask for clarification.

## Example Inputs

- `/pr-triage 142`
- `/pr-triage 87`

## Edge Cases

- **PR not found**: Report error — likely wrong number or insufficient permissions.
- **No feedback at all**: Show "No feedback found on PR #N" — don't error.
- **Rate limit hit**: Return partial data with warnings. Work with what was fetched.
- **One fetch script fails**: Continue with others. Note which source is missing in the table header.
- **Bot comments**: Detected via `user.type`, `[bot]` suffix, known bot names. Classified as `informational` / `low` priority unless CI failure (`high`).
- **Already-resolved threads**: Included but marked `resolved`. Default recommendation: skip.
- **Outdated threads**: Included but marked `outdated`. Default recommendation: verify relevance.
- **Duplicate items**: GraphQL threads are primary. Deduplicate against REST review comments by `path + line + body`.

## File References

| File | Purpose |
|------|---------|
| `references/REFERENCE.md` | Triage classification rules, priority assignment, resolution execution |
| `references/github-api.md` | REST and GraphQL endpoint reference, pagination, auth |
| `references/FORMS.md` | Structured forms for triage review cycle |
| `scripts/fetch-pr-metadata.sh` | Fetches PR title, state, author, branches, change stats |
| `scripts/fetch-comments.sh` | Fetches issue-level PR comments (REST, paginated) |
| `scripts/fetch-review-comments.sh` | Fetches inline review comments (REST, paginated) |
| `scripts/fetch-review-threads.sh` | Fetches review threads with resolution status (GraphQL) |
| `scripts/reply-comment.sh` | Posts a reply to a comment or thread |
| `scripts/resolve-thread.sh` | Resolves a review thread (GraphQL mutation) |
| `assets/triage-table-template.md` | Unified triage table format and column definitions |
