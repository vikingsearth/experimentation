# GitHub Pull Requests API Reference

## Authentication

All calls use `gh` CLI which handles authentication via `gh auth login`.

## Command Approach Routing

| Operation | Approach | Command |
|-----------|----------|---------|
| Create PR | `gh pr` CLI | `gh pr create --title --body --base --label --assignee --project --draft` |
| Edit title/body | `gh pr` CLI | `gh pr edit NUMBER --title --body` |
| Labels | `gh pr` CLI | `gh pr edit --add-label / --remove-label` |
| Assignee | `gh pr` CLI | `gh pr edit --add-assignee / --remove-assignee` |
| Reviewer | `gh pr` CLI | `gh pr edit --add-reviewer / --remove-reviewer` |
| Base branch | `gh pr` CLI | `gh pr edit --base BRANCH` |
| Milestone | `gh pr` CLI | `gh pr edit --milestone NAME` |
| Mark ready | `gh pr` CLI | `gh pr ready NUMBER` |
| Convert to draft | GraphQL | `convertPullRequestToDraft` mutation |
| Merge | `gh pr` CLI | `gh pr merge NUMBER --squash/--merge/--rebase` |
| Auto-merge | `gh pr` CLI | `gh pr merge --auto` / `--disable-auto` |
| Add to project | GraphQL | `addProjectV2ItemById` mutation |
| Comment | `gh pr` CLI | `gh pr comment NUMBER --body` |
| View | `gh pr` CLI | `gh pr view NUMBER --json ...` |
| List | `gh pr` CLI | `gh pr list --state --author --label --limit` |
| Checks | `gh pr` CLI | `gh pr checks NUMBER` |
| Files | `gh pr` CLI | `gh pr view NUMBER --json files` |
| Reviews | REST API | `GET /repos/{o}/{r}/pulls/{n}/reviews` |

## gh pr CLI Commands

### Create

```bash
gh pr create --title "feat(scope): description" \
  --body "$(cat .github/pull_request_template.md)" \
  --base main --assignee "@me" --project "Nebula" --draft
```

### Edit

```bash
gh pr edit NUMBER --title "feat(scope): new title"
gh pr edit NUMBER --body "New body content"
gh pr edit NUMBER --add-label "enhancement,aurora"
gh pr edit NUMBER --remove-label "bug"
gh pr edit NUMBER --add-assignee "@me"
gh pr edit NUMBER --add-reviewer "Derivco/aurora-core"
gh pr edit NUMBER --base develop
gh pr edit NUMBER --milestone "Sprint 14"
```

### Merge

```bash
gh pr merge NUMBER --squash --delete-branch
gh pr merge NUMBER --merge
gh pr merge NUMBER --rebase
gh pr merge NUMBER --auto --squash     # Auto-merge when checks pass
gh pr merge NUMBER --disable-auto      # Cancel auto-merge
gh pr merge NUMBER --admin --squash    # Bypass branch protection
```

### View & List

```bash
gh pr view NUMBER --json number,title,state,isDraft,author,labels,reviewDecision,url
gh pr list --state open --label "enhancement" --assignee "@me" --limit 30
gh pr list --json number,title,author,state,isDraft,labels,headRefName,updatedAt
gh pr checks NUMBER --json name,state,conclusion
```

### Comment

```bash
gh pr comment NUMBER --body "Comment text with **markdown**"
```

### Ready / Draft

```bash
gh pr ready NUMBER                    # Mark draft as ready for review
```

## GraphQL Mutations

### Convert to Draft

```graphql
mutation($prId: ID!) {
  convertPullRequestToDraft(input: { pullRequestId: $prId }) {
    pullRequest { isDraft }
  }
}
```

### Add PR to Project

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
query($owner: String!) {
  organization(login: $owner) {
    projectsV2(first: 20) {
      nodes { id title }
    }
  }
}
```

## REST API Endpoints

### PR Reviews

```bash
gh api "repos/{owner}/{repo}/pulls/{number}/reviews" \
  --jq '[.[] | {author: .user.login, state: .state, submitted: .submitted_at}]'
```

### PR Comments

```bash
gh api -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /repos/{owner}/{repo}/pulls/{number}/comments
```

## Conventional Commit Title Format

```
type(scope): description
```

| Type | When | Version Bump |
|------|------|-------------|
| `feat` | New feature | Minor |
| `fix` | Bug fix | Patch |
| `refactor` | Restructuring | Patch |
| `docs` | Documentation | Patch |
| `chore` | Maintenance | Patch |
| `ci` | CI/CD changes | Patch |
| `perf` | Performance | Patch |
| `build` | Build system | Patch |

Rules: imperative mood, lowercase, no period, max 72 chars.

## Label Taxonomy

Apply relevant labels from this set:

| Label | When |
|-------|------|
| `bug` | Something isn't working |
| `enhancement` | New feature or request |
| `documentation` | Docs improvements |
| `qol` | Quality of life improvement |
| `ai-tooling` | AI tooling, skills, rules, prompts |
| `help wanted` | Extra attention needed |
| `deprecated` | No longer maintained |

## Merge Strategies

| Strategy | When | Commit History |
|----------|------|---------------|
| Squash | Default, keeps history clean | Single commit per PR |
| Merge | Feature branches with meaningful commit history | Preserves all commits |
| Rebase | Linear history preference | Replays commits on base |

## Issue Linkage Keywords

- **Auto-close**: `Closes #N`, `Fixes #N`, `Resolves #N`
- **Reference only**: `Addresses #N`, `References #N`, `Part of #N`

## Defaults

- **Assignee**: `@me`
- **Reviewer**: `Derivco/aurora-core`
- **Base branch**: `main`
- **Merge strategy**: `squash`
- **Project**: `Nebula`
