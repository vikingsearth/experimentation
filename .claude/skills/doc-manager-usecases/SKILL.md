---
name: doc-manager-usecases
description: Creates and updates use-case documentation at project and service levels. Classifies the target doc by filename pattern, selects the correct template, gathers relevant context from code and design docs, and produces or refreshes use-case content with Mermaid diagrams (state, sequence, ER). For updates, detects what changed since the doc was last modified via git history and focuses on those changes. Use when creating or updating use-case docs, or when the user mentions use-case documentation.
compatibility: Designed for Claude Code and GitHub Copilot with shell access.
metadata:
  author: nebula-aurora
  version: "0.1.0"
  purpose: documentation
  type: P1
disable-model-invocation: false
user-invocable: true
argument-hint: "Service name or use-cases doc path (e.g., 'ctx-svc', 'docs/designs/use-cases/use-cases.md')"
---

# Manage Use-Cases Docs

Creates and updates use-case documentation at project and service levels, using templates with Given/When/Then tables and Mermaid diagrams (state, sequence, ER).

## When to Use

- User wants to create a new use-cases doc for a service or the project
- User wants to update an existing use-cases doc after code or design changes
- User mentions "use-cases doc", "update use-cases", "create use-cases doc"
- User provides a service name or use-cases doc path

## Design Principles

**Classification by filename**: The doc's path determines its type — `use-cases.md` is project-level, `<service>-use-cases.md` is service-level. The user can provide either a full path or just a service name.

**Change-focused updates**: When updating, use git history to find what changed since the doc was last modified, then focus on those changes. Don't re-read the entire codebase.

**Implementation-specific use-cases**: Each use-case must be specific to the actual code implementation — not generic descriptions. Auth flows should reflect the auth method actually used, API endpoints should match actual routes, etc.

**Mermaid diagrams are first-class**: Use-case docs include three diagram types per feature: state diagrams (logic flow), sequence/flowchart diagrams (system interactions), and ER diagrams (data structures).

## Classification Rules

| Input | Type | Output path | Template |
|-------|------|-------------|----------|
| `use-cases.md` or `project` | project | `docs/designs/use-cases/use-cases.md` | `assets/project-usecases-template.md` |
| `<service>` (e.g., `ctx-svc`) | service | `docs/designs/use-cases/<service>-use-cases.md` | `assets/service-usecases-template.md` |
| `docs/designs/use-cases/<service>-use-cases.md` | service | as provided | `assets/service-usecases-template.md` |
| `docs/designs/use-cases/use-cases.md` | project | as provided | `assets/project-usecases-template.md` |

## Operation Detection

| User says... | Operation |
|-------------|-----------|
| "create use-cases doc for X", "new use-cases doc" | **create** |
| "update use-cases doc", "refresh use-cases doc for X" | **update** |
| (doc path exists on disk) | **update** (inferred) |
| (doc path does not exist on disk) | **create** (inferred) |

## Workflow

### Step 1 — Classify

For each input (path or service name):
1. Determine the type (project or service) using the classification rules above.
2. Resolve the full output path under `docs/designs/use-cases/`.
3. If the file exists, mode = **update**. If not, mode = **create**.
4. Log: path, type, mode.

### Step 2 — Create (new use-cases doc)

1. Run `bash scripts/init-usecases-doc.sh "<input>"` to copy the correct template.
2. Read the created file.
3. Gather context based on type:
   - **project**: Read `CLAUDE.md` for project overview, existing service use-cases docs for feature summaries, `docs/designs/*.md` for cross-cutting concerns. Identify the key user-facing use-cases across the system.
   - **service**: Read the service's `src/<service>/` directory — `package.json` (dependencies, scripts), `.env.example` (config), `src/` code structure (entry point, routes, handlers, middleware). Identify use-cases from API endpoints, event handlers, and business logic. Build Given/When/Then tables and Mermaid diagrams for each feature.
4. Fill in all template sections with gathered context. Each use-case should have:
   - Given/When/Then feature table
   - State diagram (logic flow within the feature)
   - Sequence/flowchart diagram (interactions between systems)
   - ER diagram (data structures for entities)
5. Present the doc to the user for review.

### Step 3 — Update (existing use-cases doc)

1. Read the existing use-cases doc.
2. Run `bash scripts/detect-changes.sh "<path>"` to find what changed since the doc was last modified.
3. Review the change list and determine which sections are affected:
   - **project**: Check if service use-cases docs, design docs, or CLAUDE.md changed. Update use-case descriptions and diagrams accordingly.
   - **service**: Check if routes, handlers, business logic, event handlers, or dependencies changed. Update affected use-cases, add new ones for new features, remove obsolete ones.
4. Read only the changed files (not the entire codebase).
5. Update the affected sections, preserving unchanged sections.
6. Update Mermaid diagrams to reflect implementation changes.
7. Present the changes to the user for review.

### Multi-doc orchestration

When multiple docs are requested, process them sequentially. If one fails, continue with the others and note the gap.

For project use-cases updates that depend on service docs: update service docs first, then the project doc.

## Example Inputs

- "Create a use-cases doc for ctx-svc"
- "Update the project use-cases doc"
- "Create use-cases docs for ctx-svc and evt-svc"
- "Refresh the frontend use-cases doc after the chat refactor"
- "Update docs/designs/use-cases/use-cases.md"

## Edge Cases

- **Doc exists on create**: Ask the user — overwrite or switch to update mode?
- **No changes detected on update**: Report "use-cases doc is up to date" with the last-modified commit info.
- **Service doesn't exist in src/**: Warn and ask if the user meant a different service name. List available services.
- **Multiple docs with dependencies**: Process service docs before project doc.
- **Git history unavailable**: Fall back to reading the full scope. Add a warning.

## File References

| File | Purpose | When loaded |
|------|---------|-------------|
| `references/REFERENCE.md` | Classification rules, context strategy, Mermaid conventions, Given/When/Then format | During all operations |
| `scripts/init-usecases-doc.sh` | Classify input + copy correct template | During create |
| `scripts/detect-changes.sh` | Find changes since doc last modified | During update |
| `assets/project-usecases-template.md` | Project-level use-cases template | During project create |
| `assets/service-usecases-template.md` | Service-level use-cases template | During service create |
