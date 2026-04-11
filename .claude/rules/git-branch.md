# Git Branch Standards

## Naming Pattern

```
<type>/<short-description>
```

Use **kebab-case** for the description. Keep it concise and descriptive.

### Branch Types

| Prefix | Purpose | Example |
|--------|---------|---------|
| `feature/` | New feature or capability | `feature/work-breakdown-skill` |
| `fix/` | Bug fix | `fix/chat-reconnect-timeout` |
| `refactor/` | Code restructuring | `refactor/actor-state-management` |
| `docs/` | Documentation changes | `docs/adr-0009-message-sdk` |
| `hotfix/` | Urgent production fix | `hotfix/auth-token-expiry` |
| `release/` | Release preparation | `release/v2.1.0` |
| `chore/` | Maintenance, tooling, config | `chore/update-eslint-config` |

## Per-Service Version Tags

Tags follow: `<service>/v<version>` (e.g., `frontend/v1.3.0`, `ctx-svc/v0.8.2`)

Versioning follows [VERSIONING.md](../../VERSIONING.md) — conventional commit types determine the bump.

## Anti-Patterns

- **No ticket-only names**: `feature/JIRA-1234` — include a description
- **No initials or dates**: `wikus/march-changes` — use the type prefix
- **No generic names**: `feature/updates`, `fix/stuff` — be specific
- **No deeply nested prefixes**: `feature/frontend/chat/retry` — keep flat
