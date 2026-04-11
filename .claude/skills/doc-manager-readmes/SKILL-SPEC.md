# Skill Spec: doc-manager-readmes

## Identity

- **Name**: doc-manager-readmes
- **Purpose**: documentation
- **Complexity**: standard
- **Description**: Creates and updates README files at any level of the project — root, service, or generic. Classifies the target README by location, selects the correct template, gathers relevant context from code and docs, and produces or refreshes the README content. For updates, detects what changed since the last README edit via git history and focuses on those changes. Use when creating a new README, updating an existing README, or when the user mentions README maintenance.

## Behavior

- **Input**: One or more README file paths (e.g., `README.md`, `src/ctx-svc/README.md`, `docs/tools/README.md`)
- **Output format**: Markdown README file(s)
- **Output structure**: Single or multiple README artifacts, each written to the specified location
- **Operations**:
  1. **classify** — Determine README type from path: `root` (project root), `service` (under `src/<service>/`), or `generic` (anywhere else)
  2. **mode**: either `create` or `update`, inferred from user intent or README existence
     - `create`: Spawn a new README from the appropriate template, then populate it by gathering context (code, config, other docs) based on type
     - `update`: Read existing README, use git history to find what changed since the README was last modified, then refresh affected sections
- **External dependencies**: Git CLI (for change detection), filesystem access

## File Plan

- **SKILL.md** — router, classification logic, operation detection, workflow per type, file references
- **scripts/**:
  - `init-readme.sh` — classify a path, copy the correct template to the target location, output JSON with path + type + status
  - `detect-changes.sh` — given a README path, find its last modified commit, then list files changed since that commit within the relevant scope (service dir, project root, or parent dir) - use git cli
- **references/**:
  - `REFERENCE.md` — classification rules, context-gathering strategy per type, section anatomy for each template, relationship to update-docs agent
- **assets/**:
  - `root-readme-template.md` — project root README template (from `__README.md`)
  - `service-readme-template.md` — service-level README template (from `__(service)README.md`)
  - `generic-readme-template.md` — generic README template for any other location - use the previous two templates as a basis but remove sections that won't apply (e.g., service-level README sections like architecture, endpoints, etc.)
  [note: root and generic README files must contain a `Source` section at the end to link to relevant documentation used in the creation of. Not needed for service README since the source is the service code itself]
