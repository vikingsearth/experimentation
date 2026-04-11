# Git Commit Standards

## Format

Conventional commits: `type(scope): description`

```bash
git add <files> && git commit -m "type(scope): description"
```

### Types

| Type | When | Version bump |
|------|------|-------------|
| `feat` | New feature or capability | Minor |
| `fix` | Bug fix | Patch |
| `refactor` | Code restructuring, no behavior change | Patch |
| `docs` | Documentation only | Patch |
| `chore` | Maintenance, deps, config | Patch |
| `ci` | CI/CD pipeline changes | Patch |
| `perf` | Performance improvement | Patch |
| `build` | Build system or external deps | Patch |
| `feat!` | Breaking change (or `BREAKING CHANGE` in body) | Major |

### Scope

Use the service or domain name: `frontend`, `aurora-ai`, `ctx-svc`, `evt-svc`, `agent-proxy-svc`, `cc-svc`, `rules`, `skills`, `hooks`, `deps`, `docker`, `dapr`

```
feat(frontend): add chat message retry button
fix(ctx-svc): handle null player context gracefully
docs(skills): update pr-triage workflow documentation
chore(deps): bump vitest to 3.x
```

## Message Rules

- **Imperative mood**: "add" not "added", "fix" not "fixed"
- **Lowercase** — no capitalization after the colon
- **No trailing period**
- **Max 72 characters** for the subject line
- **Under 30 words** total including title
- **Body** (optional): blank line after subject, bullet-point details

## File Limit

- **Maximum 2 files per commit**, preferably 1
- Group by logical unit — don't commit unrelated files together

## Authoring

- **No `--author` flag** — never override the commit author
- **No `Co-Authored-By` trailers** — these mess with git history

## Atomicity

- One logical change per commit
- Don't commit half-done work — split into logical chunks that can be completed quickly
- Test before committing — ensure the code builds
- Never include `node_modules/`, `bin/`, `obj/`, `.tmp/`

## Version Tagging

Per-service git tags: `<service>/v<version>` (e.g., `frontend/v1.3.0`). Version bumps follow the type table above.
