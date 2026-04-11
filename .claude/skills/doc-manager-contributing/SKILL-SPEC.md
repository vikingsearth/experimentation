# Skill Spec: doc-manager-contributing

## Identity

- **Name**: doc-manager-contributing
- **Purpose**: documentation
- **Complexity**: standard
- **Description**: Creates and updates the root CONTRIBUTING.md file. Gathers context from project structure, service configs, tooling, and development workflows to produce a comprehensive contributing guide. For updates, detects what changed since the doc was last modified via git history and focuses on those changes. Use when creating or updating the contributing guide, or when the user mentions CONTRIBUTING.md.

## Behavior

- **Input**: No arguments needed (always targets `./CONTRIBUTING.md`). Optional `--force` to overwrite on create.
- **Output format**: Markdown document with structured sections (project structure, setup, tooling, debugging, git conventions)
- **Output structure**: Single artifact — `./CONTRIBUTING.md`
- **Operations**:
  1. **mode**: either `create` or `update`, inferred from user intent or file existence
     - `create`: Copy template to `./CONTRIBUTING.md`, then populate by gathering context from all services, config files, scripts, and tooling
     - `update`: Read existing doc, use git history to find what changed since last modified, then refresh affected sections
- **External dependencies**: git, jq (both expected in dev environment)

## File Plan

- **scripts/init-contributing.sh**: Check if `./CONTRIBUTING.md` exists, copy template if not. Simple — no classification needed (single target).
- **scripts/detect-changes.sh**: Find files changed since `./CONTRIBUTING.md` was last modified. Scopes to entire repo (project structure, services, config, scripts).
- **references/REFERENCE.md**: Context-gathering strategy, section anatomy, update triggers per section.
- **assets/contributing-template.md**: Copied from `__CONTRIBUTING.md` — the full template with all section placeholders.

## Edge Cases

- **Doc exists on create**: Ask user — overwrite or switch to update mode?
- **No changes detected on update**: Report "CONTRIBUTING.md is up to date" with last-modified commit info.
- **Git history unavailable**: Fall back to full repo read. Add warning.
- **New service added**: Should trigger updates to Project Structure, Setup, and Running Services sections.
