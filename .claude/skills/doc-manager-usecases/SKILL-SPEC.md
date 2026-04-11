# Skill Spec: doc-manager-usecases

## Identity

- **Name**: doc-manager-usecases
- **Purpose**: documentation
- **Complexity**: standard
- **Description**: Creates and updates use-case documentation at project and service levels. Classifies the target doc by filename pattern, selects the correct template, gathers relevant context from code and design docs, and produces or refreshes use-case content with Mermaid diagrams (state, sequence, ER). For updates, detects what changed since the doc was last modified via git history and focuses on those changes. Use when creating or updating use-case docs, or when the user mentions use-case documentation.

## Behavior

- **Input**: Service name (e.g., `ctx-svc`), `project`, or a full path (e.g., `docs/designs/use-cases/ctx-svc-use-cases.md`)
- **Output format**: Markdown document with Given/When/Then tables and Mermaid diagrams
- **Output structure**: Single artifact — a use-cases markdown file at `docs/designs/use-cases/`
- **Operations**:
  1. **classify** — Determine doc type from path/name: `project` (`use-cases.md`) or `service` (`<service>-use-cases.md`)
  2. **mode**: either `create` or `update`, inferred from user intent or file existence
     - `create`: Spawn a new use-cases doc from the appropriate template, then populate by gathering context (code structure, dependencies, integrations, API surface) based on type
     - `update`: Read existing doc, use git history to find what changed since last modified, then refresh affected sections
- **External dependencies**: git, jq (both expected in dev environment)

## File Plan

- **scripts/init-usecases-doc.sh**: Classify input (project or service), resolve output path under `docs/designs/use-cases/`, copy correct template. Validates service directory exists (with `-svc` suffix fallback).
- **scripts/detect-changes.sh**: Find files changed since the use-cases doc was last modified. Scopes to `src/<service>/` for service docs, broad scope for project docs.
- **references/REFERENCE.md**: Classification rules detail, context-gathering strategies per type, section anatomy, Mermaid diagram conventions (stateDiagram-v2, flowchart TD, erDiagram), service name resolution.
- **assets/project-usecases-template.md**: Copied from `__use_cases.md` — project-level use-cases template with multi-service scope.
- **assets/service-usecases-template.md**: Copied from `__(service)use_cases.md` — service-level use-cases template with single-service focus.

## Edge Cases

- **Doc exists on create**: Ask user — overwrite or switch to update mode?
- **No changes detected on update**: Report "use-cases doc is up to date" with last-modified commit info.
- **Service doesn't exist in src/**: Warn, try `-svc` suffix, list available services if not found.
- **Multiple docs with dependencies**: Process service docs before project doc.
- **Git history unavailable**: Fall back to full scope read. Add warning.
