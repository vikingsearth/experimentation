# Docs Updater Reference

## Skill-to-Doc Mapping

| Skill | Skill Path | Target Docs | Update Detection |
|-------|-----------|-------------|-----------------|
| doc-manager-readmes | `.claude/skills/doc-manager-readmes/SKILL.md` | README.md at root, service, and generic levels | Git history since last README edit |
| doc-manager-architecture | `.claude/skills/doc-manager-architecture/SKILL.md` | `docs/designs/architecture.md`, service-level arch docs | Git history since last doc edit |
| doc-manager-usecases | `.claude/skills/doc-manager-usecases/SKILL.md` | `docs/designs/use-cases/*.md` | Git history since last doc edit |
| doc-manager-contributing | `.claude/skills/doc-manager-contributing/SKILL.md` | Root `CONTRIBUTING.md` | Git history since last doc edit |

## Scope Selection Rules

User input is parsed as space-separated keywords. Each keyword maps to one skill:

- `readmes` → doc-manager-readmes
- `architecture` → doc-manager-architecture
- `usecases` → doc-manager-usecases
- `contributing` → doc-manager-contributing
- `all` (or no input) → all 4 skills

Multiple keywords can be combined: `readmes architecture` runs both.

## Subagent Dispatch Protocol

Each subagent is launched with:

1. **Full SKILL.md content** of the target skill — read the file and include its entire content as the subagent's instructions
2. **Update directive** — the subagent should operate in update mode (not create mode)
3. **No additional scope narrowing** — each skill handles its own change detection internally via git history

### Subagent Prompt Template

```
You are a documentation specialist. Follow the skill instructions below to UPDATE existing documentation.

KEY DIRECTIVES:
- Operate in UPDATE mode — detect what changed since the docs were last modified
- Use git history to identify relevant code changes
- Focus updates on sections affected by recent changes
- Do not rewrite unchanged content
- If no relevant changes are detected, report "No updates needed" and stop

SKILL INSTRUCTIONS:
[Full content of .claude/skills/<skill-name>/SKILL.md]
```

## Failure Handling

- Each skill runs independently — a failure in one does not affect others
- On failure, capture the error message and include it in the summary
- Common failure modes:
  - Target doc doesn't exist yet (skill may create it — this is expected behavior, not a failure)
  - Git history unavailable (shallow clone) — warn and skip
  - Skill directory missing — skip with warning in summary
