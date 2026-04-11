---
name: doc-manager-readmes
description: Creates and updates README files at any level of the project — root, service, or generic. Classifies the target README by location, selects the correct template, gathers relevant context from code and docs, and produces or refreshes the README content. For updates, detects what changed since the last README edit via git history and focuses on those changes. Use when creating a new README, updating an existing README, or when the user mentions README maintenance.
compatibility: Designed for Claude Code and GitHub Copilot with shell access.
metadata:
  author: nebula-aurora
  version: "0.1.0"
  purpose: documentation
  type: P1
disable-model-invocation: false
user-invocable: true
argument-hint: "README path(s) to create or update (e.g., 'src/ctx-svc/README.md', 'README.md')"
---

# Manage READMEs

Creates and updates README files at any project level — root, service, or generic — using the correct template and context-appropriate content.

## When to Use

- User wants to create a new README for a service, the project root, or any directory
- User wants to update an existing README after code or doc changes
- User mentions "README", "update readme", "create readme", "refresh readme"
- User provides one or more README file paths

## Design Principles

**Classification drives everything**: The README's file path determines its type, which determines its template, which determines what context to gather. Classification is automatic — the user just provides a path.

**Change-focused updates**: When updating, don't re-read the entire codebase. Use git history to find what changed since the README was last modified, then focus on those changes.

**Source traceability**: Root and generic READMEs include a `Source` section at the end linking to the documentation and references used in their creation. Service READMEs don't need this — their source is the service code itself.

## Classification Rules

| Path pattern | Type | Template | Context scope |
|-------------|------|----------|---------------|
| `./README.md` | root | `assets/root-readme-template.md` | All service READMEs, `docs/`, `CONTRIBUTING.md`, `CLAUDE.md` |
| `src/<service>/README.md` | service | `assets/service-readme-template.md` | Service code, config, `package.json`, `.env.example`, tests |
| Anything else | generic | `assets/generic-readme-template.md` | User-provided context + files in the same directory |

## Operation Detection

| User says... | Operation |
|-------------|-----------|
| "create a readme for X", "new readme" | **create** |
| "update the readme", "refresh the readme" | **update** |
| (README path exists on disk) | **update** (inferred) |
| (README path does not exist on disk) | **create** (inferred) |

## Workflow

### Step 1 — Classify

For each README path provided:
1. Determine the type using the classification rules above.
2. If the file exists, mode = **update**. If not, mode = **create**.
3. Log the classification: path, type, mode.

### Step 2 — Create (new README)

1. Run `bash scripts/init-readme.sh "<path>"` to copy the correct template.
2. Read the created file.
3. Gather context based on type:
   - **root**: Read all service READMEs under `src/*/README.md`, read `docs/designs/`, `CONTRIBUTING.md`, `CLAUDE.md` (if present). Synthesize a project overview.
   - **service**: Read the service's `src/<service>/` directory — `package.json`, `.env.example`, `src/` code structure, test files. Populate architecture, API, configuration, and setup sections.
   - **generic**: Ask the user what content and references to include. Read files in the same directory and user-provided references.
4. Fill in all template sections with gathered context.
5. For root and generic types, add a `Source` section at the end listing the docs/files used.
6. Present the README to the user for review.

### Step 3 — Update (existing README)

1. Read the existing README.
2. Run `bash scripts/detect-changes.sh "<path>"` to find what changed since the README was last modified.
3. Review the change list and determine which README sections are affected:
   - **root**: Check if any service READMEs, `docs/`, or `CONTRIBUTING.md` changed. Update the overview, features, or service descriptions accordingly.
   - **service**: Check if code, config, API routes, dependencies, or tests changed. Update architecture, API, configuration, or setup sections.
   - **generic**: Check if referenced files or sibling files changed. Update relevant sections.
4. Read only the changed files (not the entire codebase).
5. Update the affected sections in the README, preserving unchanged sections.
6. For root and generic types, update the `Source` section if sources changed.
7. Present the changes to the user for review.

### Multi-README orchestration

When multiple README paths are provided, process them sequentially. If one fails (e.g., missing context), continue with the others and note the gap.

For root README updates that depend on service READMEs: update service READMEs first, then the root.

## Example Inputs

- "Create a README for src/ctx-svc/"
- "Update README.md"
- "Create READMEs for src/ctx-svc/ and src/evt-svc/"
- "Refresh the root README after the auth refactor"
- "Create a README for docs/tools/"

## Edge Cases

- **README exists on create**: Ask the user — overwrite or switch to update mode?
- **No changes detected on update**: Report "README is up to date" with the last-modified commit info.
- **Service has no code yet**: Create a minimal README with placeholders; note which sections need filling once code exists.
- **Multiple READMEs with dependencies**: Process service READMEs before root to ensure the root has fresh service summaries.
- **Git history unavailable**: Fall back to reading the full scope rather than change-focused updates. Add a warning.

## File References

| File | Purpose | When loaded |
|------|---------|-------------|
| `references/REFERENCE.md` | Classification rules, context strategy, section anatomy | During all operations |
| `scripts/init-readme.sh` | Classify path + copy correct template | During create |
| `scripts/detect-changes.sh` | Find changes since README last modified | During update |
| `assets/root-readme-template.md` | Root-level README template | During root create |
| `assets/service-readme-template.md` | Service-level README template | During service create |
| `assets/generic-readme-template.md` | Generic README template | During generic create |
