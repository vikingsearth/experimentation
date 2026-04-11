# Skill Spec: pr-triage

## Identity

- **Name**: pr-triage
- **Purpose**: development
- **Complexity**: full
- **Description**: Fetches PR comments, review comments, and review threads from GitHub, builds a unified triage table with classification and recommended actions, then executes user-directed resolutions (fix code, reply to threads, post comments). Use when reviewing PR feedback or when the user mentions triaging, resolving, or addressing PR comments.

## Behavior

- **Input**: PR number (required, passed as `$ARGUMENTS`). Repo detected from git remote.
- **Output format**: mixed (markdown triage table + execution summary)
- **Output structure**: Single unified triage table in Phase 1; resolution report in Phase 2.
- **Operations**:
  1. **Fetch PR metadata** — title, state, author, branch, change stats
  2. **Fetch issue comments** — top-level PR conversation comments (REST, paginated)
  3. **Fetch review comments** — inline code review comments (REST, paginated)
  4. **Fetch review threads** — threaded reviews with resolved/outdated status (GraphQL, cursor-paginated)
  5. **Build triage table** — classify each item (blocker, change-request, question, suggestion, nitpick, approval, informational), assign priority, deduplicate threads vs review comments, present unified table
  6. **Execute resolutions** — based on user direction: fix code, reply to comment/thread, resolve thread
  7. **Reply to comment** — post a reply to a review comment or issue comment
  8. **Resolve thread** — mark a review thread as resolved via GraphQL mutation
- **External dependencies**: `gh` CLI (authenticated), `jq`, `git`

## File Plan

- **scripts/**:
  - `fetch-pr-metadata.sh` — fetches PR title, state, author, base/head branches, additions/deletions/changed files
  - `fetch-comments.sh` — fetches issue-level PR comments (REST `/issues/{number}/comments`)
  - `fetch-review-comments.sh` — fetches inline review comments (REST `/pulls/{number}/comments`)
  - `fetch-review-threads.sh` — fetches review threads with resolution status (GraphQL `reviewThreads`)
  - `reply-comment.sh` — posts a reply to a review comment or issue comment
  - `resolve-thread.sh` — resolves a review thread (GraphQL mutation `resolveReviewThread`)
- **references/**:
  - `REFERENCE.md` — triage classification rules (type detection signals, priority assignment, status detection, dedup logic), resolution execution rules
  - `github-api.md` — REST and GraphQL endpoint reference, pagination patterns, authentication, rate limiting
  - `FORMS.md` — structured forms for the triage review cycle
- **assets/**:
  - `triage-table-template.md` — unified triage table template with column definitions and example rows

## Edge Cases

- **PR not found or inaccessible**: Script exits with clear error. Agent reports to user — likely wrong PR number or insufficient permissions.
- **No comments/reviews at all**: Show empty triage table with a "No feedback found" message. Don't error.
- **Rate limit hit during pagination**: Return partial data fetched so far + warning. Agent can work with partial results.
- **One fetch script fails, others succeed**: Agent continues with successful sources. Triage table notes which source failed.
- **Bot comments (CI, dependabot, etc.)**: Detect via `user.type`, `[bot]` suffix, known bot names. Classify as `informational` with `low` priority by default (unless CI failure — then `high`).
- **Already-resolved threads**: Include in table but mark as `resolved`. Default recommendation: skip.
- **Outdated threads (code changed since review)**: Include but mark as `outdated`. Default recommendation: verify if still relevant.
- **Duplicate items (thread appears in both review comments and review threads)**: GraphQL threads are primary source. Deduplicate by matching `path + line + first comment body` against REST review comments.
- **User provides ambiguous resolution directives**: Accept natural language. Interpret intent (fix, ignore, discuss, skip) from context. Ask for clarification only if genuinely ambiguous.

## Open Questions

None — requirements are clear. Ready for approval.
