# GitHub Issues API Reference

## Authentication

All calls use `gh api` which handles authentication via `gh auth login`.

## Command Approach Routing

Each metadata field routes to a specific command approach:

| Field | Approach | Command |
|-------|----------|---------|
| Title | `gh issue` CLI | `gh issue edit --title` |
| Body | `gh issue` CLI | `gh issue edit --body` |
| Labels | REST API | `POST/PUT/DELETE /repos/{o}/{r}/issues/{n}/labels` |
| Assignee | `gh issue` CLI | `gh issue edit --add-assignee/--remove-assignee` |
| Milestone | `gh issue` CLI | `gh issue edit --milestone` |
| Type | GraphQL | `updateProjectV2ItemFieldValue` mutation |
| Project | GraphQL | `addProjectV2ItemById` mutation |
| Parent linkage | Body edit + GraphQL | "Part of #N" in body, sub-issue API |

## gh issue CLI Commands

### Create

```bash
gh issue create --title "Title" --body "Body" --label "aurora,enhancement" \
  --assignee "@me" --project "Nebula"
```

### Edit

```bash
gh issue edit NUMBER --title "New title"
gh issue edit NUMBER --body "New body"
gh issue edit NUMBER --add-assignee "username"
gh issue edit NUMBER --remove-assignee "username"
gh issue edit NUMBER --milestone "Sprint 14"
```

### Comment

```bash
gh issue comment NUMBER --body "Comment text"
```

### List

```bash
gh issue list --state open --label "aurora" --assignee "@me" --limit 30
gh issue list --json number,title,labels,assignees,state,url
```

## REST API Endpoints

### Labels

```bash
# Add labels
gh api "repos/{owner}/{repo}/issues/{number}/labels" \
  --method POST --input - <<< '{"labels": ["bug", "aurora"]}'

# Replace all labels
gh api "repos/{owner}/{repo}/issues/{number}/labels" \
  --method PUT --input - <<< '{"labels": ["enhancement", "aurora"]}'

# Remove a label
gh api "repos/{owner}/{repo}/issues/{number}/labels/{label}" \
  --method DELETE
```

### Issue Details

```bash
# Get issue node_id (needed for GraphQL mutations)
gh api "repos/{owner}/{repo}/issues/{number}" --jq '.node_id'
```

## GraphQL Queries & Mutations

### Find Issue in Project

```graphql
query($owner: String!, $repo: String!, $issueNumber: Int!) {
  repository(owner: $owner, name: $repo) {
    issue(number: $issueNumber) {
      projectItems(first: 10) {
        nodes {
          id
          project { title id }
        }
      }
    }
  }
}
```

### Get Type Field Options

```graphql
query($projectId: ID!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      field(name: "Type") {
        ... on ProjectV2SingleSelectField {
          id
          options { id name }
        }
      }
    }
  }
}
```

### Set Type Field Value

```graphql
mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
  updateProjectV2ItemFieldValue(input: {
    projectId: $projectId
    itemId: $itemId
    fieldId: $fieldId
    value: { singleSelectOptionId: $optionId }
  }) {
    projectV2Item { id }
  }
}
```

### Add Issue to Project

```graphql
mutation($projectId: ID!, $contentId: ID!) {
  addProjectV2ItemById(input: {
    projectId: $projectId
    contentId: $contentId
  }) {
    item { id }
  }
}
```

### Find Project by Name

```graphql
# For organization repos:
query($owner: String!) {
  organization(login: $owner) {
    projectsV2(first: 20) {
      nodes { id title }
    }
  }
}

# For user repos:
query($owner: String!) {
  user(login: $owner) {
    projectsV2(first: 20) {
      nodes { id title }
    }
  }
}
```

### Search Issues (for parent-child queries)

```graphql
query($searchQuery: String!, $limit: Int!) {
  search(query: $searchQuery, type: ISSUE, first: $limit) {
    nodes {
      ... on Issue {
        number title state
        labels(first: 10) { nodes { name } }
        assignees(first: 5) { nodes { login } }
        url
      }
    }
  }
}
```

## Type Hierarchy

| Type | Can Parent | Can Be Child Of |
|------|-----------|-----------------|
| Epic | Feature, Story | — (no parent) |
| Feature | Story, Task, Bug | Epic |
| Story | Task, Bug | Epic, Feature |
| Task | — (no children) | Feature, Story |
| Bug | — (no children) | Feature, Story |

### Validation Rules

- Task and Bug are leaf types — they cannot have children
- Epic is a root type — it cannot be a child
- Always link to a parent issue if Type is not Epic (alert user if missing)

## Label Taxonomy

Always include `aurora`. Apply from:

| Label | When |
|-------|------|
| `aurora` | Always — team visibility |
| `bug` | Something isn't working |
| `enhancement` | New feature or request |
| `documentation` | Docs improvements |
| `qol` | Quality of life improvement |
| `ai-tooling` | AI tooling, skills, rules, prompts |
| `help wanted` | Extra attention needed |
| `good first issue` | Good for newcomers |
| `deprecated` | No longer maintained |
| `question` | Further information requested |

## Project Defaults

- **Project**: Nebula
- **Assignee**: current user (@me)
- **Parent linkage**: "Part of #N" in issue body
