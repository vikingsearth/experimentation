---
name: manage-github-pull-requests
description: Manages GitHub pull requests via gh CLI and GitHub API — creates PRs with auto-populated template bodies and conventional commit titles, updates metadata (labels, assignees, reviewers, draft status), links issues, merges with strategy selection, and queries PRs with filters. Enforces project conventions from git-pr.md rule. Three command approaches — gh pr for CRUD, gh api REST for metadata, gh api GraphQL for advanced queries and draft conversion. Complements pr-triage (post-review feedback). Use when creating PRs, updating PR metadata, merging, or when the user mentions pull requests, PR creation, or PR administration.
compatibility: Requires gh CLI (authenticated), jq, and git.
metadata:
  author: nebula-aurora
  version: "0.1.0"
  purpose: development
  type: P2
disable-model-invocation: false
user-invocable: true
argument-hint: "[create|update|metadata|merge|query] [pr-number]"
---

# Manage GitHub Pull Requests

Creates, updates, and manages GitHub pull requests with full convention enforcement — conventional commit titles, PR template bodies, issue linkage, reviewer assignment, and merge strategy selection.

## When to Use

- User wants to create a new pull request
- User wants to update PR content (title, body) or metadata (labels, reviewers, assignees, draft status)
- User wants to link or unlink issues on a PR
- User wants to merge a PR with a specific strategy
- User wants to add a comment to a PR
- User wants to query/list PRs with filters
- User mentions pull requests, PR creation, or PR administration
- **Not for**: triaging PR review feedback — use `pr-triage` for that

## Workflow

### Phase 1 — Intake

1. **Detect repo** — extract `owner/repo` from `gh repo view --json nameWithOwner`
2. **Determine operation** — classify user intent into: create, update, manage-metadata, link-issues, merge, add-comment, or query
3. **Gather parameters** — use intake forms from [references/FORMS.md](references/FORMS.md) to identify required vs provided fields

### Phase 2 — Execute

4. **Route to script** — run the appropriate script based on operation:

   | Operation | Script | Command Approach |
   |-----------|--------|-----------------|
   | Create PR | `bash scripts/create-pr.sh` | `gh pr create` with template body |
   | Update content | `bash scripts/update-pr.sh` | `gh pr edit` |
   | Manage metadata | `bash scripts/manage-metadata.sh` | CLI / REST / GraphQL per sub-operation |
   | Link issues | `bash scripts/link-issues.sh` | Body editing + issue validation |
   | Merge PR | `bash scripts/merge-pr.sh` | `gh pr merge` with strategy |
   | Add comment | `bash scripts/add-comment.sh` | `gh pr comment` |
   | Query PRs | `bash scripts/query-prs.sh` | `gh pr list` / GraphQL |

5. **Convention enforcement** — always apply per [git-pr.md rule](../../rules/git-pr.md):
   - Title must be `type(scope): description` — imperative mood, lowercase, no period, max 72 chars
   - Body auto-populated from `.github/pull_request_template.md`
   - Assignee: current user (`@me`)
   - Reviewer: "Derivco/aurora-core" team
   - At least one issue must be linked — no orphan PRs
   - Labels from the standard taxonomy

### Phase 3 — Report

6. **Confirm result** — report PR URL on create, confirmation on update, table on query, merge status on merge.

## Example Inputs

- "Create a PR for this branch — it fixes the chat reconnect timeout, closes #85"
- "Create a draft PR for feature/work-breakdown-skill"
- "Add the `enhancement` label to PR #142"
- "Add wikus-bergh as reviewer on PR #150"
- "Mark PR #142 as ready for review"
- "Merge PR #142 with squash"
- "List all open PRs assigned to me"
- "Link issue #90 to PR #142"

## Edge Cases

- **No issue linked**: Always require at least one issue reference. If none provided, prompt the user. If no relevant issue exists, offer to create one via manage-github-issues.
- **Title format violation**: Reject non-conventional titles. Suggest corrections based on the branch name or commit history.
- **Branch not pushed**: Warn that `gh pr create` will push automatically — user should be aware.
- **Draft vs ready**: Default to non-draft unless `--draft` specified. Support converting between states.
- **Merge blocked**: If checks fail or reviews are missing, report blockers clearly. Support `--auto` for auto-merge once checks pass.
- **GraphQL vs REST vs CLI**: Each script selects the right approach. See [references/REFERENCE.md](references/REFERENCE.md) for routing.
- **Rate limiting**: If gh api returns 403/429, report to user rather than retrying silently.
- **Reviewer team not found**: If "Derivco/aurora-core" is not accessible, warn and continue without reviewer.
- **Stale issue references**: When linking, validate issues exist and are open. Warn about closed issues.

## File References

| File | Purpose |
|------|---------|
| `references/REFERENCE.md` | GitHub PR API patterns (CLI/REST/GraphQL), conventional commit title format, label taxonomy, merge strategies |
| `references/FORMS.md` | Structured intake forms per operation type |
| `scripts/create-pr.sh` | Creates a PR with conventional title, template body, labels, assignee, reviewer, issue linkage |
| `scripts/update-pr.sh` | Updates PR title or body content |
| `scripts/manage-metadata.sh` | Manages all metadata: labels, assignee, reviewers, draft status, base, project, milestone |
| `scripts/link-issues.sh` | Manages issue references in PR body (Closes/Addresses #N) |
| `scripts/merge-pr.sh` | Merges PR with strategy selection and pre-merge validation |
| `scripts/add-comment.sh` | Posts a comment on a PR |
| `scripts/query-prs.sh` | Lists/searches PRs with filters, outputs JSON or table |
| `assets/pr-body-template.md` | PR body template with placeholder markers for automated population |
