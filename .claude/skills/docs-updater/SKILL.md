---
name: docs-updater
description: Orchestrates parallel documentation updates by spawning 4 doc-management skills as subagents — doc-manager-readmes, doc-manager-architecture, doc-manager-usecases, and doc-manager-contributing. Each subagent detects what changed via git history and updates its target docs accordingly. Use when the user wants to refresh all documentation, or mentions update docs, refresh documentation, or sync docs.
compatibility: Requires git CLI and subagent dispatch capability.
metadata:
  author: nebula-aurora
  version: "0.1.0"
  purpose: development
  type: P2
disable-model-invocation: false
user-invocable: true
argument-hint: "[scope: readmes|architecture|usecases|contributing|all]"
---

# Docs Updater

Spawns 4 documentation skills as parallel subagents to refresh all project documentation based on recent code changes.

## When to Use

- After completing a feature or refactor — refresh all docs at once
- Before creating a PR — ensure docs are up to date
- When the user says "update docs", "refresh documentation", "sync docs", or "update all documentation"
- Periodically to catch documentation drift

## Workflow

### Step 1 — Select Scope

Parse the user's input to determine which doc skills to run. Default is `all`.

| Keyword | Skill | Target Docs |
|---------|-------|-------------|
| `readmes` | doc-manager-readmes | README.md files (root, service, generic) |
| `architecture` | doc-manager-architecture | Architecture docs in `docs/designs/` |
| `usecases` | doc-manager-usecases | Use-case docs in `docs/designs/use-cases/` |
| `contributing` | doc-manager-contributing | Root CONTRIBUTING.md |
| `all` | All 4 above | All documentation |

### Step 2 — Spawn Subagents

For each selected skill, spawn a subagent. Each subagent receives:

1. **The skill's SKILL.md content** — read from `.claude/skills/<skill-name>/SKILL.md` and include as the subagent's task instructions
2. **The update directive** — instruct the subagent to run in **update mode** (detect what changed via git history, focus updates on those changes)

**Subagent dispatch pattern** (per skill):

```
Launch subagent with prompt:
"Follow the instructions in this skill file to UPDATE the documentation.
Detect what changed since the docs were last modified via git history.
Focus updates on those changes. Do not rewrite unchanged sections.

[Full content of .claude/skills/<skill-name>/SKILL.md]"
```

Launch all selected subagents. If one subagent fails, log the failure and continue with the others — each skill is independent (SRP).

### Step 3 — Collect Results

After all subagents complete, collect their results:

- **Updated**: Which docs were modified and what changed
- **Skipped**: Which docs were already up to date (no relevant changes detected)
- **Failed**: Which skills encountered errors (include error details)

### Step 4 — Report Summary

Present a concise summary:

```markdown
## Documentation Update Summary

| Skill | Status | Details |
|-------|--------|---------|
| doc-manager-readmes | Updated | Updated root README.md, src/frontend/README.md |
| doc-manager-architecture | Skipped | No architecture-relevant changes detected |
| doc-manager-usecases | Updated | Updated docs/designs/use-cases/chat-flow.md |
| doc-manager-contributing | Failed | Error: could not detect last modified date |
```

## Example Inputs

- `/docs-updater` — update all documentation
- `/docs-updater readmes` — update only README files
- `/docs-updater architecture usecases` — update architecture and use-case docs
- `/docs-updater contributing` — update only CONTRIBUTING.md
- "update all the docs before I create a PR"
- "refresh the documentation"

## Edge Cases

- **No changes detected**: If git history shows no relevant changes for any skill, report "All documentation is up to date" rather than running empty updates
- **Subagent failure**: Log the error, continue with remaining skills, include failure in the summary table
- **Missing skill**: If a target skill directory doesn't exist (e.g., someone deleted `.claude/skills/doc-manager-readmes/`), skip it with a warning
- **Large change set**: Each subagent handles its own scope — the orchestrator doesn't need to manage diff size

## File References

- `references/REFERENCE.md` — subagent dispatch protocol, skill-to-doc mapping, scope selection rules
