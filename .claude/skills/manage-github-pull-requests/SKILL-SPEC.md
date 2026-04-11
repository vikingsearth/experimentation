# Skill Spec: manage-github-pull-requests

## Identity

- **Name**: manage-github-pull-requests
- **Purpose**: development
- **Complexity**: full
- **Description**: Manages GitHub pull requests via gh CLI and GitHub API — creates PRs with auto-populated descriptions from the PR template, updates metadata (labels, assignees, reviewers, draft status), links issues, and queries PRs with filters. Enforces project conventions from git-pr.md rule. Three command approaches: `gh pr` for CRUD, `gh api` REST for metadata fields, `gh api` GraphQL for advanced queries and status checks. Complements pr-triage (which handles post-review feedback); this skill handles PR lifecycle from creation through merge. Use when creating PRs, updating PR metadata, linking issues, or when the user mentions pull requests, PR creation, or PR administration.

## Behavior

- **Input**: User intent (create, update, merge, query) + PR details (title, base branch, issue linkage, labels, etc.) or PR number for updates
- **Output format**: mixed (confirmation messages, PR URLs, tables for listing)
- **Output structure**: Single artifact per operation — PR URL on create, confirmation on update, table on list/query
- **Command approaches** (three patterns, scripts select the right one per operation):
  1. **`gh pr`** — standard CLI for create, edit, merge, list, view, comment, ready/draft
  2. **`gh api` REST** — for label management, reviewer assignment beyond what `gh pr edit` exposes
  3. **`gh api` GraphQL** — for advanced PR queries (by review status, check status), bulk operations
- **Operations**:
  1. **Create PR** — `gh pr create` with `--title` (conventional commit format), `--body` (populated from `.github/pull_request_template.md`), `--base`, `--label`, `--assignee`, `--reviewer`, `--project`, `--draft`; then link issues via "Closes #N" or "Addresses #N" in body
     - Title enforced as `type(scope): description` per git-pr.md
     - Body auto-populated from PR template with user-provided sections filled in
     - Always assigns current user (`@me`)
     - Always adds reviewer "Derivco/aurora-core"
     - Always links at least one issue — if none provided, prompt user
  2. **Update PR content** — `gh pr edit <number>` for title, body changes
  3. **Manage metadata** — umbrella operation covering all PR fields:
     - **Labels**: `gh pr edit --add-label/--remove-label` or `gh api` REST
     - **Assignee**: `gh pr edit --add-assignee/--remove-assignee`
     - **Reviewers**: `gh pr edit --add-reviewer/--remove-reviewer`
     - **Draft status**: `gh pr ready` or `gh api` GraphQL `convertPullRequestToDraft`
     - **Base branch**: `gh pr edit --base`
     - **Project**: `gh api` GraphQL to add/remove PR from a ProjectV2
     - **Milestone**: `gh pr edit --milestone` or `gh api` REST
  4. **Link issues** — edit PR body to add/update "Closes #N" or "Addresses #N" references; validate issues exist before linking
  5. **Merge PR** — `gh pr merge <number>` with `--squash`/`--merge`/`--rebase`, `--delete-branch`, `--auto`; validate checks pass before merge
  6. **Add comment** — `gh pr comment <number> --body`
  7. **Query PRs** — `gh pr list` with `--state`, `--label`, `--assignee`, `--base`, `--search` filters; `gh api` GraphQL for review-status filtering and check-status queries
- **Complementary with pr-triage**: This skill creates and manages PR lifecycle (CRUD, metadata, merge). pr-triage handles post-review feedback (fetching comments, classifying, resolving). They don't overlap — use this skill to create/manage PRs, use pr-triage to handle review feedback on existing PRs.
- **External dependencies**: `gh` CLI (authenticated), `jq`, `git`

## File Plan

- **scripts/**:
  - `create-pr.sh` — creates a PR with conventional commit title, auto-populated template body, labels, assignee, reviewer, issue linkage. Validates title format and issue references.
  - `update-pr.sh` — updates PR title or body content via `gh pr edit`. Content-only changes.
  - `manage-metadata.sh` — umbrella script for all metadata operations: `--add-labels`, `--remove-labels`, `--assignee`, `--add-reviewer`, `--remove-reviewer`, `--draft`, `--ready`, `--base`, `--project`, `--milestone`. Routes each sub-operation to the correct command approach.
  - `link-issues.sh` — manages issue references in PR body: adds "Closes #N" or "Addresses #N", removes stale references, validates issues exist.
  - `merge-pr.sh` — merges PR with strategy selection (squash/merge/rebase), pre-merge check validation, optional branch cleanup.
  - `add-comment.sh` — posts a comment on a PR via `gh pr comment`.
  - `query-prs.sh` — lists/searches PRs with filters, outputs JSON or table. Uses `gh pr list` for basic filters, GraphQL for review-status and check-status queries.
- **references/**:
  - `REFERENCE.md` — GitHub PR API patterns (all three command approaches), gh CLI commands, conventional commit title format, label taxonomy, reviewer defaults, merge strategies
  - `FORMS.md` — structured intake forms: create-PR intake (required/optional fields, issue linkage), update-PR change form, metadata change form, merge confirmation form
- **assets/**:
  - `pr-body-template.md` — PR body template matching `.github/pull_request_template.md` with placeholder markers for automated population

## Edge Cases

- **No issue linked**: Always require at least one issue reference — if the user doesn't provide one, prompt them. If no relevant issue exists, offer to create one via manage-github-issues skill.
- **Title format violation**: Reject non-conventional titles (`type(scope): description` enforced). Suggest corrections.
- **Branch not pushed**: If creating from a local branch that hasn't been pushed, warn — `gh pr create` will push automatically but user should be aware.
- **Draft vs ready**: Default to non-draft unless `--draft` specified. Support converting between states.
- **Merge blocked**: If checks are failing or reviews are missing, report the blockers clearly rather than forcing merge. Support `--auto` for auto-merge once checks pass.
- **GraphQL vs REST vs CLI**: Each script selects the right approach — `gh pr` for CRUD, REST for labels, GraphQL for draft conversion and advanced queries. REFERENCE.md documents the routing.
- **Rate limiting**: If gh api returns 403/429, report to user rather than retrying silently.
- **Reviewer team not found**: If "Derivco/aurora-core" team is not accessible, warn and continue without reviewer assignment.
- **Stale issue references**: When linking issues, validate they exist and are open. Warn about closed issues.
