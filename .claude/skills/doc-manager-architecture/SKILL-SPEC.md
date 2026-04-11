# Skill Spec: doc-manager-architecture

## Identity

- **Name**: doc-manager-architecture
- **Purpose**: documentation
- **Complexity**: standard
- **Description**: Creates and updates architecture documentation at project and service levels. Classifies the target doc by filename pattern, selects the correct template, gathers relevant context from code, config, and design docs, and produces or refreshes architecture content with Mermaid diagrams. For updates, detects what changed since the doc was last modified via git history and focuses on those changes. Use when creating or updating architecture docs, or when the user mentions architecture documentation.

## Behavior

- **Input**: One or more architecture doc paths or service names (e.g., `docs/designs/architecture/architecture.md`, `ctx-svc`, `docs/designs/architecture/evt-svc-architecture.md`)
- **Output format**: Markdown architecture document(s) with Mermaid diagrams
- **Output structure**: Single or multiple architecture doc artifacts, each written to `docs/designs/architecture/`
- **Operations**:
  1. **classify** — Determine doc type from path/name: `project` (`architecture.md`) or `service` (`<service>-architecture.md`)
  2. **mode**: either `create` or `update`, inferred from user intent or file existence
     - `create`: Spawn a new architecture doc from the appropriate template, then populate by gathering context (code structure, dependencies, integrations, API surface) based on type
     - `update`: Read existing doc, use git history to find what changed since last modified, then refresh affected sections
- **External dependencies**: Git CLI (for change detection), filesystem access

## File Plan

- **SKILL.md** — router, classification logic, operation detection, workflow per type, file references
- **scripts/**:
  - `init-arch-doc.sh` — classify a path/service name, copy the correct template to `docs/designs/architecture/`, output JSON with path + type + status
  - `detect-changes.sh` — given an architecture doc path, find its last modified commit, then list files changed since that commit within the relevant scope (service dir or project-wide)
- **references/**:
  - `REFERENCE.md` — classification rules, context-gathering strategy per type, section anatomy for each template, Mermaid diagramming conventions
- **assets/**:
  - `project-architecture-template.md` — project-level architecture template (from `__architecture.md`)
  - `service-architecture-template.md` — service-level architecture template (from `__(service)architecture.md`)
