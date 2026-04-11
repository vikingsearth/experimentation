# Git Pull Request Standards

## Title

Use conventional commit format: `type(scope): description`

```
feat(frontend): add chat message retry button
fix(ctx-svc): handle null player context gracefully
```

Same rules as commit messages — imperative mood, lowercase, no period, max 72 chars.

## Template

Use `.github/pull_request_template.md`. Fill in all sections:

| Section | Required | Notes |
|---------|----------|-------|
| Description | Yes | Explain *what* changed and *why*, not *how* (code shows how) |
| Type of Change | Yes | Bug fix, new feature, breaking change, docs, refactoring, perf, test coverage |
| Testing | Yes | Unit tests, integration tests, manual testing performed |
| Checklist | Yes | Code style, self-review, comments, docs, no warnings, tests, dependent changes |
| Related Issues | Yes | Link every PR to at least one issue |
| Screenshots | If UI changes | Before/after for visual changes |

## Issue Linkage

- Reference with `Closes #N` (auto-closes on merge) or `Addresses #N` (links without closing)
- If no issues exist, create them via `gh issue create` first — then link
- Never submit a PR without issue linkage

## Assignee & Reviewer

- **Assignee**: current user (`gh pr edit --add-assignee @me`)
- **Reviewer**: "Aurora Core" team (`gh pr edit --add-reviewer "Derivco/aurora-core"`)

## Labels

Apply relevant labels from the same taxonomy as issues:

`bug`, `enhancement`, `documentation`, `qol`, `ai-tooling`, `deprecated`, `help wanted`, `good first issue`

```bash
gh pr edit --add-label "enhancement,ai-tooling"
```

## PR Scope

- One feature or fix per PR — matches the atomic commit philosophy
- Keep PRs focused and reviewable
- Large changes should be broken into a chain of smaller PRs

## PR Creation Workflow

```bash
# 1. Create PR with template
gh pr create --title "type(scope): description" --body "$(cat .github/pull_request_template.md)"

# 2. Set metadata
gh pr edit --add-assignee @me
gh pr edit --add-reviewer "Derivco/aurora-core"
gh pr edit --add-label "enhancement"
```

## Automated Reviews

- Claude Code Review runs automatically on PRs to `main`
- Can also be triggered by `@claude-code` in PR comments
- When reviewing: only analyze changes in the PR's own commits — exclude merge commit diffs and base branch changes
