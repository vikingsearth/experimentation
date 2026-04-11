---
name: doc-manager-contributing
description: Creates and updates the root CONTRIBUTING.md file. Gathers context from project structure, service configs, tooling, and development workflows to produce a comprehensive contributing guide. For updates, detects what changed since the doc was last modified via git history and focuses on those changes. Use when creating or updating the contributing guide, or when the user mentions CONTRIBUTING.md.
compatibility: Designed for Claude Code and GitHub Copilot with shell access.
metadata:
  author: nebula-aurora
  version: "0.1.0"
  purpose: documentation
  type: P1
disable-model-invocation: false
user-invocable: true
argument-hint: "No arguments needed — always targets ./CONTRIBUTING.md"
---

# Manage Contributing Doc

Creates and updates the root `CONTRIBUTING.md` with structured sections covering project structure, setup, tooling, debugging, and git conventions — populated from code and config context.

## When to Use

- User wants to create a new CONTRIBUTING.md for the project
- User wants to update the existing CONTRIBUTING.md after project changes
- User mentions "contributing guide", "update contributing", "create contributing doc"
- User mentions "CONTRIBUTING.md"

## Design Principles

**Single target**: This skill always operates on `./CONTRIBUTING.md` — no classification needed. The template provides a comprehensive structure for developer onboarding and workflows.

**Change-focused updates**: When updating, use git history to find what changed since the doc was last modified, then focus on those changes. Don't re-read every file in the repo.

**Complementary to CLAUDE.md**: CONTRIBUTING.md owns developer workflows, onboarding, setup guides, and tooling rules. CLAUDE.md owns project context, architecture, key patterns, and coding conventions. These have non-overlapping ownership.

## Operation Detection

| User says... | Operation |
|-------------|-----------|
| "create contributing guide", "new CONTRIBUTING.md" | **create** |
| "update contributing", "refresh contributing guide" | **update** |
| (CONTRIBUTING.md exists on disk) | **update** (inferred) |
| (CONTRIBUTING.md does not exist on disk) | **create** (inferred) |

## Workflow

### Step 1 — Check Status

1. Check if `./CONTRIBUTING.md` exists.
2. If the file exists, mode = **update**. If not, mode = **create**.
3. Log: path, mode.

### Step 2 — Create (new CONTRIBUTING.md)

1. Run `bash scripts/init-contributing.sh` to copy the template.
2. Read the created file.
3. Gather context from the entire project:
   - `CLAUDE.md` — project overview, architecture, build commands, conventions
   - `src/*/package.json` — service names, scripts, dependencies
   - `src/*/.env.example` — environment variables per service
   - `Makefile` — workspace-level commands
   - `src/docker-compose.yml` — infrastructure topology
   - `docs/designs/` — architecture and design docs
   - `scripts/` — utility scripts
   - `.vscode/tasks.json` — VS Code task definitions
   - `VERSIONING.md` — versioning strategy
4. Fill in all template sections with gathered context:
   - Project structure tree with annotations
   - Key technologies list
   - Authentication setup
   - Service details and key components
   - Tools and setup instructions
   - Build, test, and lint commands
   - Debugging tips and common issues
   - Git commit conventions
5. Present the doc to the user for review.

### Step 3 — Update (existing CONTRIBUTING.md)

1. Read the existing CONTRIBUTING.md.
2. Run `bash scripts/detect-changes.sh` to find what changed since the doc was last modified.
3. Review the change list and determine which sections are affected:
   - New/removed services → Project Structure, Setup, Running Services
   - Changed `package.json` scripts → Build & Development commands
   - Changed `.env.example` → Environment Configuration
   - Changed `Makefile` → Setup & Development commands
   - Changed `docker-compose.yml` → Infrastructure section
   - Changed auth config → Authentication Setup
   - New tools/scripts → Tools section
4. Read only the changed files (not the entire repo).
5. Update the affected sections, preserving unchanged sections.
6. Present the changes to the user for review.

## Example Inputs

- "Create a CONTRIBUTING.md"
- "Update the contributing guide"
- "Refresh CONTRIBUTING.md after adding the new service"
- "Update CONTRIBUTING.md with the new build commands"

## Edge Cases

- **Doc exists on create**: Ask the user — overwrite or switch to update mode?
- **No changes detected on update**: Report "CONTRIBUTING.md is up to date" with the last-modified commit info.
- **Git history unavailable**: Fall back to reading the full project scope. Add a warning.
- **New service added**: Should trigger updates to Project Structure, Setup, and Running Services sections.
- **CLAUDE.md missing**: Gather context from code directly; add a warning that the project overview may be incomplete.

## File References

| File | Purpose | When loaded |
|------|---------|-------------|
| `references/REFERENCE.md` | Context-gathering strategy, section anatomy, update triggers | During all operations |
| `scripts/init-contributing.sh` | Copy template to `./CONTRIBUTING.md` | During create |
| `scripts/detect-changes.sh` | Find changes since doc last modified | During update |
| `assets/contributing-template.md` | CONTRIBUTING.md template with all section placeholders | During create |
