---
name: doc-manager-architecture
description: Creates and updates architecture documentation at project and service levels. Classifies the target doc by filename pattern, selects the correct template, gathers relevant context from code, config, and design docs, and produces or refreshes architecture content with Mermaid diagrams. For updates, detects what changed since the doc was last modified via git history and focuses on those changes. Use when creating or updating architecture docs, or when the user mentions architecture documentation.
compatibility: Designed for Claude Code and GitHub Copilot with shell access.
metadata:
  author: nebula-aurora
  version: "0.1.0"
  purpose: documentation
  type: P1
disable-model-invocation: false
user-invocable: true
argument-hint: "Service name or architecture doc path (e.g., 'ctx-svc', 'docs/designs/architecture/architecture.md')"
---

# Manage Architecture Docs

Creates and updates architecture documentation at project and service levels, using templates with Mermaid diagrams and context gathered from code and design docs.

## When to Use

- User wants to create a new architecture doc for a service or the project
- User wants to update an existing architecture doc after code or design changes
- User mentions "architecture doc", "update architecture", "create architecture doc"
- User provides a service name or architecture doc path

## Design Principles

**Classification by filename**: The doc's path determines its type — `architecture.md` is project-level, `<service>-architecture.md` is service-level. The user can provide either a full path or just a service name.

**Change-focused updates**: When updating, use git history to find what changed since the doc was last modified, then focus on those changes. Don't re-read the entire codebase.

**Mermaid diagrams are first-class**: Architecture docs use Mermaid flowcharts for component diagrams. Every component section should include a diagram showing internal structure and data flow.

## Classification Rules

| Input | Type | Output path | Template |
|-------|------|-------------|----------|
| `architecture.md` or `project` | project | `docs/designs/architecture/architecture.md` | `assets/project-architecture-template.md` |
| `<service>` (e.g., `ctx-svc`) | service | `docs/designs/architecture/<service>-architecture.md` | `assets/service-architecture-template.md` |
| `docs/designs/architecture/<service>-architecture.md` | service | as provided | `assets/service-architecture-template.md` |
| `docs/designs/architecture/architecture.md` | project | as provided | `assets/project-architecture-template.md` |

## Operation Detection

| User says... | Operation |
|-------------|-----------|
| "create architecture doc for X", "new architecture doc" | **create** |
| "update architecture doc", "refresh architecture doc for X" | **update** |
| (doc path exists on disk) | **update** (inferred) |
| (doc path does not exist on disk) | **create** (inferred) |

## Workflow

### Step 1 — Classify

For each input (path or service name):
1. Determine the type (project or service) using the classification rules above.
2. Resolve the full output path under `docs/designs/architecture/`.
3. If the file exists, mode = **update**. If not, mode = **create**.
4. Log: path, type, mode.

### Step 2 — Create (new architecture doc)

1. Run `bash scripts/init-arch-doc.sh "<input>"` to copy the correct template.
2. Read the created file.
3. Gather context based on type:
   - **project**: Read `CLAUDE.md` for architecture overview, `docs/designs/c4-*.md` for diagrams, existing service architecture docs for component summaries. Synthesize high-level system components with Mermaid flowcharts.
   - **service**: Read the service's `src/<service>/` directory — `package.json` (dependencies, scripts), `.env.example` (config), `src/` code structure (entry point, routes, layers), `tsconfig.json`. Identify internal components, external dependencies, API surface, and integration points. Build Mermaid diagrams for each component.
4. Fill in all template sections with gathered context.
5. Present the doc to the user for review.

### Step 3 — Update (existing architecture doc)

1. Read the existing architecture doc.
2. Run `bash scripts/detect-changes.sh "<path>"` to find what changed since the doc was last modified.
3. Review the change list and determine which sections are affected:
   - **project**: Check if service architecture docs, C4 diagrams, or CLAUDE.md changed. Update component definitions and system diagrams.
   - **service**: Check if code structure, dependencies, routes, config, or integration points changed. Update component sections, diagrams, and integration points.
4. Read only the changed files (not the entire codebase).
5. Update the affected sections, preserving unchanged sections.
6. Update Mermaid diagrams to reflect structural changes.
7. Present the changes to the user for review.

### Multi-doc orchestration

When multiple docs are requested, process them sequentially. If one fails, continue with the others and note the gap.

For project architecture updates that depend on service docs: update service docs first, then the project doc.

## Example Inputs

- "Create an architecture doc for ctx-svc"
- "Update the project architecture doc"
- "Create architecture docs for ctx-svc and evt-svc"
- "Refresh the frontend architecture doc after the composable refactor"
- "Update docs/designs/architecture/architecture.md"

## Edge Cases

- **Doc exists on create**: Ask the user — overwrite or switch to update mode?
- **No changes detected on update**: Report "architecture doc is up to date" with the last-modified commit info.
- **Service doesn't exist in src/**: Warn and ask if the user meant a different service name. List available services.
- **Multiple docs with dependencies**: Process service docs before project doc.
- **Git history unavailable**: Fall back to reading the full scope. Add a warning.

## File References

| File | Purpose | When loaded |
|------|---------|-------------|
| `references/REFERENCE.md` | Classification rules, context strategy, Mermaid conventions | During all operations |
| `scripts/init-arch-doc.sh` | Classify input + copy correct template | During create |
| `scripts/detect-changes.sh` | Find changes since doc last modified | During update |
| `assets/project-architecture-template.md` | Project-level architecture template | During project create |
| `assets/service-architecture-template.md` | Service-level architecture template | During service create |
