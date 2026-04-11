---
name: manage-github-issues
description: Manages GitHub issues via gh CLI and GitHub API — creates issues with correct metadata (type hierarchy, labels, project, assignee, parent linkage), updates descriptions and comments, and manages all issue metadata. Enforces project conventions from git-issue.md rule. Three command approaches — gh issue for CRUD, gh api REST for labels/assignees, gh api GraphQL for project fields and sub-issue relationships. Use when creating issues, updating issue metadata, managing sub-issues, or when the user mentions GitHub issues, work planning, or issue administration.
compatibility: Requires gh CLI (authenticated), jq, and git.
metadata:
  author: nebula-aurora
  version: "0.1.0"
  purpose: development
  type: P1
disable-model-invocation: false
user-invocable: true
argument-hint: "[create|update|metadata|query|comment] [issue-number]"
---

# Manage GitHub Issues

Creates, updates, and queries GitHub issues with full metadata enforcement — type hierarchy, labels, project assignment, parent linkage, and all project-specific fields.

## When to Use

- User wants to create a new issue (any type: Epic, Feature, Story, Task, Bug)
- User wants to batch-create sub-issues under a parent
- User wants to update issue content (title, body) or metadata (labels, type, assignee, project, milestone, parent)
- User wants to add a comment to an issue
- User wants to query/list issues with filters
- User mentions GitHub issues, work items, work planning, or issue administration

## Workflow

### Phase 1 — Intake

1. **Detect repo** — extract `owner/repo` from `gh repo view --json nameWithOwner`
2. **Determine operation** — classify user intent into: create, create-sub-issues, update, manage-metadata, add-comment, or query
3. **Gather parameters** — use intake forms from [references/FORMS.md](references/FORMS.md) to identify required vs provided fields. For create operations, the Type determines which body template to use.

### Phase 2 — Execute

4. **Route to script** — run the appropriate script based on operation:

   | Operation | Script | Command Approach |
   |-----------|--------|-----------------|
   | Create issue | `bash scripts/create-issue.sh` | `gh issue` → GraphQL (Type) → REST/GraphQL (parent) |
   | Create sub-issues | `bash scripts/create-sub-issues.sh` | loops `create-issue.sh` per child |
   | Update content | `bash scripts/update-issue.sh` | `gh issue edit` |
   | Manage metadata | `bash scripts/manage-metadata.sh` | CLI / REST / GraphQL per sub-operation |
   | Add comment | `bash scripts/add-comment.sh` | `gh issue comment` |
   | Query issues | `bash scripts/query-issues.sh` | `gh issue list` / GraphQL |

5. **Type hierarchy enforcement** — when creating or linking issues, validate against the hierarchy:
   - **Epic** → can parent Feature, Story
   - **Feature** → can parent Story, Task, Bug
   - **Story** → can parent Task, Bug
   - **Task** → no children
   - **Bug** → no children

6. **Convention enforcement** — always apply per [git-issue.md rule](../../rules/git-issue.md):
   - Always include `aurora` label
   - Assign to current user by default
   - Assign to "Nebula" project
   - Link to parent issue if Type is not Epic

### Phase 3 — Report

7. **Confirm result** — report issue URL on create, confirmation on update, table on query.

## Example Inputs

- "Create a Feature issue for adding retry logic to chat reconnect, under Epic #42"
- "Create 3 Task sub-issues under Story #85: implement API, write tests, update docs"
- "Update the labels on issue #120 — add `enhancement` and remove `bug`"
- "Set the Type of issue #95 to Story"
- "Change the assignee on #130 to wikus-bergh"
- "List all open Feature issues assigned to me"
- "Add a comment to #99 saying the fix has been deployed"

## Edge Cases

- **No parent issue exists**: Alert the user and ask whether to create one or proceed without parent linkage.
- **Type hierarchy violation**: Reject and explain the allowed hierarchy (e.g., "Task cannot parent another Task").
- **Label not found**: Warn and skip — don't create labels automatically.
- **Issue already exists**: Check for duplicate titles in open issues and warn before creating.
- **GraphQL vs REST vs CLI**: Each script selects the right approach per operation. See [references/REFERENCE.md](references/REFERENCE.md) for the routing table.
- **Rate limiting**: If `gh api` returns 403/429, report to user rather than retrying silently.
- **Project not found**: Report clearly if "Nebula" project is not found or user lacks access.
- **Type field not configured**: Report if the ProjectV2 doesn't have a Type single-select field.

## File References

| File | Purpose |
|------|---------|
| `references/REFERENCE.md` | GitHub API patterns (CLI/REST/GraphQL), type hierarchy rules, label taxonomy, command routing |
| `references/FORMS.md` | Structured intake forms per operation type |
| `scripts/create-issue.sh` | Creates a single issue with full metadata and type-specific body template |
| `scripts/create-sub-issues.sh` | Batch-creates sub-issues under a parent with hierarchy validation |
| `scripts/update-issue.sh` | Updates issue title or body content |
| `scripts/manage-metadata.sh` | Manages all metadata: labels, assignee, type, project, milestone, relationships |
| `scripts/add-comment.sh` | Posts a comment on an issue |
| `scripts/query-issues.sh` | Lists/searches issues with filters, outputs JSON or table |
| `assets/template-epic.md` | Epic issue body template |
| `assets/template-feature.md` | Feature issue body template |
| `assets/template-story.md` | Story issue body template |
| `assets/template-task.md` | Task issue body template |
| `assets/template-bug.md` | Bug issue body template |
