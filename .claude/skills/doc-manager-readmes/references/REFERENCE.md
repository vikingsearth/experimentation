# Manage READMEs Reference

## Classification Rules (Detail)

### Root README (`./README.md`)

The project root README is the entry point for the entire repository. It must synthesize information from all services and docs into a coherent overview.

**Context to gather for create:**
- All `src/*/README.md` files — extract service name, purpose, port, tech stack
- `docs/designs/*.md` — architecture overview, key design decisions
- `CONTRIBUTING.md` — how to contribute (link, don't duplicate)
- `CLAUDE.md` — project overview, build commands, architecture diagram (if present)
- `docs/adrs/` — count and list key ADRs for reference
- `package.json` files in services — for tech stack summary

**Context to gather for update:**
- Run `detect-changes.sh` scoped to the repo root
- Focus on changed service READMEs, new/removed services, changed docs

**Must include a `Source` section** at the end listing the docs and files consulted.

### Service README (`src/<service>/README.md`)

Service READMEs document a single microservice. They are self-contained — a developer should be able to understand the service from this README alone.

**Context to gather for create:**
- `src/<service>/package.json` — name, scripts, dependencies
- `src/<service>/.env.example` — environment variables
- `src/<service>/src/` — code structure, entry point, route definitions
- `src/<service>/tsconfig.json` — TypeScript config
- `src/<service>/tests/` or `src/<service>/__tests__/` — test structure
- `src/<service>/Dockerfile` (if present) — container config

**Context to gather for update:**
- Run `detect-changes.sh` scoped to `src/<service>/`
- Focus on changed routes, new dependencies, config changes, new tests

**No `Source` section needed** — the source is the service code itself.

### Generic README (any other path)

Generic READMEs cover directories like `docs/tools/`, `scripts/`, `tests/`, etc. There's no fixed template structure — adapt to what the directory contains.

**Context to gather for create:**
- Files in the same directory and immediate subdirectories
- User-provided context about the directory's purpose
- Related docs elsewhere in the project

**Context to gather for update:**
- Run `detect-changes.sh` scoped to the parent directory
- Focus on new/removed/changed files in the directory

**Must include a `Source` section** listing referenced files and docs.

## Section Anatomy

### Root README sections (from template)

| Section | Content source | Update trigger |
|---------|---------------|----------------|
| Project name + badges | Manual / CI config | Rarely changes |
| About | `CLAUDE.md`, design docs | Architecture changes |
| Features | Service READMEs | New services or major features |
| Getting Started | `CONTRIBUTING.md`, `Makefile` | Setup process changes |
| Configuration | `.env.example` files | Config changes |
| API Documentation | Service READMEs | API changes |
| Running Tests | `package.json` scripts | Test config changes |
| Contributing | `CONTRIBUTING.md` | Process changes |

### Service README sections (from template)

| Section | Content source | Update trigger |
|---------|---------------|----------------|
| Service Overview | `package.json`, code entry point | Service purpose changes |
| Architecture | Code structure, imports, dependencies | Structural refactors |
| Getting Started | `.env.example`, `package.json` scripts | Setup changes |
| Configuration | `.env.example` | New/changed env vars |
| API Documentation | Route definitions in code | Route changes |
| Database Schema | Migration files, models | Schema changes |
| Running Tests | `package.json` test scripts | Test config changes |
| Development | Code structure tree | File additions/removals |

## Relationship to update-docs Agent

The `update-docs` agent (`.github/agents/update-docs.agent.md`) provides generic documentation update guidance. This skill **replaces** the README-specific parts of that agent with a more structured approach:

- **update-docs**: General-purpose doc updater, template-aware but README-agnostic
- **doc-manager-readmes**: README-specific, with classification, templates, and git-based change detection

When the update-docs agent encounters a README update request, it should defer to this skill's workflow.

## Writing Style

Follow the update-docs agent's g3 guideline:
- Write active, not passive
- Use simple language and avoid jargon
- Use headings, subheadings, and bullet points
- Include examples and code snippets where appropriate
