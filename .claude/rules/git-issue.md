# Git Issue Standards

## Title

- Concise, descriptive, action-oriented
- No type prefix in the title — that's what labels and the Type field are for
- Imperative or noun-phrase: "Add retry logic for chat reconnect" or "Chat reconnect retry"

## Template

Use `.github/issue_template.md`. Required sections vary by type:

| Section | Bug | Feature | Improvement | Documentation |
|---------|-----|---------|-------------|---------------|
| Description | Always | Always | Always | Always |
| Expected Behavior | Required | — | — | — |
| Actual Behavior | Required | — | — | — |
| Steps to Reproduce | Required | — | — | — |
| Acceptance Criteria | — | Required | Recommended | — |
| Environment (service, OS, Node) | Required | — | — | — |

## Type Hierarchy

Every issue must have a **Type** field set in GitHub Projects:

| Type | Can parent | Can child of | Description |
|------|-----------|-------------|-------------|
| Epic | Feature, Story | — (no parent) | Large initiative spanning multiple features |
| Feature | Story, Task, Bug | Epic | Distinct capability or user-facing change |
| Story | Task, Bug | Epic, Feature | User-focused narrative with acceptance criteria |
| Task | — (no children) | Feature, Story | Concrete implementation unit |
| Bug | — (no children) | Feature, Story | Defect report |

- Most issues are **Feature**, **Story**, or **Task**
- Always link to a parent issue if Type is not Epic
- Alert the user if no relevant parent issue exists — don't create orphan work

## Sub-Issues

- Use task lists (`- [ ]`) for decomposition within an issue body
- Reference parent with "Part of #N" in the description

## Required Metadata

### Labels

Apply from this taxonomy (combine as needed):

| Label | When |
|-------|------|
| `bug` | Something isn't working |
| `enhancement` | New feature or request |
| `documentation` | Docs improvements or additions |
| `qol` | Quality of life improvement |
| `ai-tooling` | AI tooling, skills, rules, prompts |
| `help wanted` | Extra attention needed |
| `good first issue` | Good for newcomers |
| `deprecated` | No longer considered or maintained |
| `question` | Further information requested |

- **Always include `aurora`** label for team visibility

### Project

- Assign to the **Nebula** project

### Assignee

- Assign to the current user by default (user can specify otherwise)

### Relationships

- Always link to a parent issue if Type is not Epic
- Use `gh issue create --body "Part of #N"` for sub-issues
