# Skill Spec: docs-updater

## Identity

- **Name**: docs-updater
- **Purpose**: development
- **Complexity**: standard
- **Description**: Orchestrates parallel documentation updates by spawning 4 doc-management skills as subagents — doc-manager-readmes, doc-manager-architecture, doc-manager-usecases, and doc-manager-contributing. Each subagent detects what changed via git history and updates its target docs accordingly. Use when the user wants to refresh all documentation after code changes, or mentions "update docs", "refresh documentation", or "sync docs".

## Behavior

- **Input**: Optional scope keywords (e.g., `readmes`, `architecture`, `usecases`, `contributing`, or `all`). Default: `all`.
- **Output format**: prose (summary of what each subagent updated)
- **Output structure**: Single summary listing each skill's result (updated/skipped/failed)
- **Operations**:
  1. Parse scope — determine which doc skills to run
  2. Spawn subagents — one per selected doc skill, in parallel
  3. Collect results — aggregate what was updated/skipped
  4. Report summary
- **External dependencies**: The 4 target skills must exist in `.claude/skills/`

## File Plan

- **references/REFERENCE.md**: Subagent dispatch protocol, scope selection, skill-to-doc mapping
