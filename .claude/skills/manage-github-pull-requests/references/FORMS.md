# Pull Request Operations — Intake Forms

## Create PR

```markdown
Title: [type(scope): description in conventional commit format]
Base branch: [main]
Closes issues: [comma-separated issue numbers, or "none"]
Addresses issues: [comma-separated issue numbers, or "none"]
Description: [what changed and why]
Type of change: [bug-fix | feature | breaking | docs | refactor | perf | test]
Labels: [comma-separated labels]
Draft: [yes | no]
```

## Update PR

```markdown
PR number: [#N]
New title: [leave blank to keep current]
New body: [leave blank to keep current]
```

## Manage Metadata

```markdown
PR number: [#N]
Add labels: [comma-separated, or blank]
Remove labels: [comma-separated, or blank]
Add reviewer: [user or team slug, or blank]
Assignee: [username, or blank]
Mark ready: [yes | no]
Convert to draft: [yes | no]
```

## Link Issues

```markdown
PR number: [#N]
Closes: [comma-separated issue numbers]
Addresses: [comma-separated issue numbers]
Remove links: [comma-separated issue numbers]
```

## Merge PR

```markdown
PR number: [#N]
Strategy: [squash | merge | rebase]
Delete branch: [yes | no]
Auto-merge: [yes | no]
```

## Add Comment

```markdown
PR number: [#N]
Comment: [markdown text]
```

## Query PRs

```markdown
Filter by state: [open | closed | merged | all]
Filter by author: [username or blank]
Filter by label: [label name or blank]
Specific PR: [#N or blank for list]
Show: [list | details | checks | files | reviews]
```
