# Manage GitHub Issues — Intake Forms

## Create Issue

```markdown
### Required
- **Title**: <concise, action-oriented, imperative or noun-phrase>
- **Type**: <Epic | Feature | Story | Task | Bug>

### Optional
- **Body**: <custom body text, or leave blank for type-specific template>
- **Labels**: <comma-separated, aurora always added>
- **Assignee**: <GitHub username, default: @me>
- **Project**: <project name, default: Nebula>
- **Parent**: <parent issue number, required unless Type is Epic>
- **Milestone**: <milestone name>
```

### Required Sections by Type

| Section | Epic | Feature | Story | Task | Bug |
|---------|------|---------|-------|------|-----|
| Description | Yes | Yes | Yes | Yes | Yes |
| Vision / Scope | Yes | — | — | — | — |
| Acceptance Criteria | — | Yes | Yes | — | — |
| User Story Format | — | — | Yes | — | — |
| Implementation Notes | — | — | — | Yes | — |
| Steps to Reproduce | — | — | — | — | Yes |
| Expected/Actual Behavior | — | — | — | — | Yes |
| Environment | — | — | — | — | Yes |

## Create Sub-Issues (Batch)

```markdown
### Required
- **Parent**: <parent issue number>
- **Child Type**: <Task | Bug | Story | Feature>
- **Titles** (one per line):
  - Title 1
  - Title 2
  - Title 3

### Optional
- **Labels**: <applied to all children>
- **Assignee**: <applied to all children, default: @me>
```

## Update Issue Content

```markdown
- **Issue Number**: <#N>
- **Update Title**: <new title, or leave blank>
- **Update Body**: <new body text, or leave blank>
```

## Manage Metadata

```markdown
- **Issue Number**: <#N>
- **Operation** (one or more):
  - [ ] Add labels: <comma-separated>
  - [ ] Remove labels: <comma-separated>
  - [ ] Set assignee: <username>
  - [ ] Set type: <Epic | Feature | Story | Task | Bug>
  - [ ] Set milestone: <name>
  - [ ] Link parent: <#N>
  - [ ] Remove parent
  - [ ] Add to project: <project name>
```

## Add Comment

```markdown
- **Issue Number**: <#N>
- **Comment**: <comment body text>
```

## Query Issues

```markdown
- **Filters** (combine as needed):
  - State: <open | closed | all>
  - Labels: <comma-separated>
  - Assignee: <username or @me>
  - Type: <Epic | Feature | Story | Task | Bug>
  - Milestone: <name>
  - Parent: <#N — list children>
  - Search: <free-text query>
- **Output**: <table (default) | json>
- **Limit**: <number, default: 30>
```
