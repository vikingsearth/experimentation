# Skill Spec: manage-github-issues

## Identity

- **Name**: manage-github-issues
- **Purpose**: development
- **Complexity**: full
- **Description**: Manages GitHub issues via gh CLI and GitHub API — creates issues with correct metadata (type hierarchy, labels, project, assignee, parent linkage), updates descriptions and comments, and manages all issue metadata (labels, type, assignee, milestone, project, relationships). Enforces project conventions from git-issue.md rule. Three command approaches: `gh issue` for standard CRUD, `gh api` REST for metadata fields, `gh api` GraphQL for project fields and sub-issue relationships. Use when creating issues, updating issue metadata, managing sub-issues, or when the user mentions GitHub issues, work planning, or issue administration.

## Behavior

- **Input**: User intent (create, update, query) + issue details (title, type, parent, labels, etc.) or issue number for updates
- **Output format**: mixed (confirmation messages, issue URLs, tables for listing)
- **Output structure**: Single artifact per operation — issue URL on create, confirmation on update, table on list/query
- **Command approaches** (three patterns, scripts select the right one per operation):
  1. **`gh issue`** — standard CLI for create, edit title/body, close, list, comment
  2. **`gh api` REST** — for label management, assignee changes, and fields not exposed via `gh issue`
  3. **`gh api` GraphQL** — for GitHub Projects fields (Type, Status), sub-issue relationships, and bulk queries
- **Operations**:
  1. **Create issue** — `gh issue create` with `--title`, `--body`, `--label`, `--assignee`, `--project`; then `gh api` GraphQL to set project Type field (Epic/Feature/Story/Task/Bug); then `gh api` GraphQL or REST to link parent via "Part of #N" or sub-issue API
  2. **Create sub-issues** — batch-create tasks/bugs under a parent: loops `gh issue create` per child, sets Type via GraphQL, adds "Part of #N" body linkage, validates parent type allows children per hierarchy
  3. **Update issue body** — `gh issue edit <number> --title/--body` for content changes
  4. **Manage metadata** — umbrella operation covering all issue fields:
     - **Labels**: `gh api` REST to add/remove/replace labels (`POST /repos/{owner}/{repo}/issues/{number}/labels`)
     - **Assignee**: `gh issue edit --add-assignee/--remove-assignee` or `gh api` REST
     - **Type**: `gh api` GraphQL to update the project Type field (ProjectV2 single-select field mutation)
     - **Project**: `gh api` GraphQL to add/remove issue from a ProjectV2
     - **Milestone**: `gh issue edit --milestone` or `gh api` REST
     - **Relationships**: `gh api` GraphQL to link/unlink parent issues, manage sub-issue hierarchy; validate against type hierarchy rules (e.g., Task cannot parent another Task)
  5. **Add comment** — `gh issue comment <number> --body`
  6. **Query issues** — `gh issue list` with `--label`, `--assignee`, `--milestone`, `--state` filters; `gh api` GraphQL for project-field filtering (by Type, Status) and cross-referencing parent/child relationships
- **External dependencies**: `gh` CLI (authenticated), `jq`

## File Plan

- **scripts/**:
  - `create-issue.sh` — creates a single issue with full metadata: `gh issue create` → GraphQL Type set → parent linkage. Accepts `--type` to select the correct body template. Validates type hierarchy if parent specified.
  - `create-sub-issues.sh` — batch-creates sub-issues under a parent from a list: validates parent type allows children, loops `create-issue.sh` per child, reports results table.
  - `update-issue.sh` — updates issue title or body via `gh issue edit`. Content-only changes.
  - `manage-metadata.sh` — umbrella script for all metadata operations: `--labels`, `--assignee`, `--type`, `--project`, `--milestone`, `--parent`, `--remove-parent`. Routes each sub-operation to the correct command approach (CLI / REST / GraphQL).
  - `add-comment.sh` — posts a comment on an issue via `gh issue comment`.
  - `query-issues.sh` — lists/searches issues with filters, outputs as JSON or table. Uses `gh issue list` for basic filters, GraphQL for project-field queries.
- **references/**:
  - `REFERENCE.md` — GitHub Issues API patterns (all three command approaches), gh CLI commands, type hierarchy rules, label taxonomy, project field mutation examples
  - `FORMS.md` — structured intake forms: create-issue intake (required/optional fields per type), update-issue change form, bulk sub-issue intake list, metadata change form
- **assets/**:
  - `template-epic.md` — Epic issue body template: vision, scope, success criteria, child feature checklist
  - `template-feature.md` — Feature issue body template: description, acceptance criteria, related stories checklist
  - `template-story.md` — Story issue body template: user story format, acceptance criteria, task checklist
  - `template-task.md` — Task issue body template: concise description, implementation notes, definition of done
  - `template-bug.md` — Bug issue body template: expected/actual behavior, steps to reproduce, environment info

## Edge Cases

- **No parent issue exists**: Alert the user and ask whether to create one or proceed without parent linkage
- **Type hierarchy violation**: If user tries to add a Task child to a Task, reject and explain the hierarchy (Epic→Feature/Story, Feature→Story/Task/Bug, Story→Task/Bug, Task/Bug→none)
- **Label not found**: If a label doesn't exist on the repo, warn and skip (don't create labels automatically)
- **Issue already exists**: When creating, check for duplicate titles in open issues and warn
- **GraphQL vs REST vs CLI**: Each script selects the right approach per operation — `gh issue` for content CRUD, REST for labels/assignees, GraphQL for project fields and relationships. REFERENCE.md documents which approach to use for each field.
- **Rate limiting**: If gh api returns 403/429, report to user rather than retrying silently
- **Project not found**: If the target project ("Nebula") is not found or user lacks access, report clearly with instructions
- **Type field not configured**: If the ProjectV2 doesn't have a Type single-select field, report the missing configuration
