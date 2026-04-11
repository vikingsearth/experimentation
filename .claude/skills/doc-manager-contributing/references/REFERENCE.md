# Manage Contributing Doc Reference

## Context-Gathering Strategy

### For Create (full context needed)

The CONTRIBUTING.md covers the entire project, so context must be gathered broadly:

| Source | What to extract |
|--------|----------------|
| `CLAUDE.md` | Project overview, architecture diagram, build commands, conventions, auth setup |
| `src/*/package.json` | Service names, npm scripts (dev, build, test, lint), dependencies |
| `src/*/.env.example` | Environment variables per service, required secrets |
| `Makefile` | Workspace-level commands (install, docker, health checks) |
| `src/docker-compose.yml` | Infrastructure services, ports, profiles, dependencies |
| `docs/designs/` | Architecture docs, design docs (for cross-references) |
| `scripts/` | Utility scripts, setup scripts, migration scripts |
| `.vscode/tasks.json` | VS Code task definitions for dev workflow |
| `VERSIONING.md` | Per-service versioning strategy |
| `tsconfig.json` files | TypeScript configuration per service |
| `Dockerfile` files | Container build config per service |

### For Update (change-focused)

Run `detect-changes.sh` to find what changed since the CONTRIBUTING.md was last modified. Map changes to sections:

| Changed file pattern | Affected sections |
|---------------------|-------------------|
| `src/*/package.json` | Key Technologies, Build & Development, Testing |
| `src/*/.env.example` | Environment Configuration, Authentication Setup |
| `Makefile` | Setup & Development, Build Commands |
| `src/docker-compose.yml` | Infrastructure, Setup & Development |
| New `src/<service>/` directory | Project Structure, Running Services, Service Details |
| Removed `src/<service>/` directory | Project Structure, Running Services, Service Details |
| `scripts/*` | Tools section |
| `.vscode/tasks.json` | VS Code Tasks |
| `VERSIONING.md` | Git Commit Best Practices |
| Auth-related config files | Authentication Setup |

## Section Anatomy

### Template sections and their content sources

| Section | Content source | Update trigger |
|---------|---------------|----------------|
| Overview | `CLAUDE.md` project description | Rarely changes |
| Project Structure & Responsibilities | `src/` directory listing, service `package.json` | New/removed services |
| Key Technologies | Service `package.json` dependencies | Dependency changes |
| Authentication Setup | `CLAUDE.md` auth section, `.env.example` auth vars | Auth config changes |
| Project Details | Service code structure, key components | Major refactors |
| Tools | `scripts/`, external tool configs | New tools, script changes |
| Setup & Development | `Makefile`, `package.json` scripts, `.env.example` | Setup process changes |
| Build & Development | `package.json` build/test/lint scripts | Script changes |
| Debugging | Common issues, service health checks | New issues discovered |
| Git Commit Best Practices | `VERSIONING.md`, team conventions | Convention changes |
| Collaboration Tips | Team guidelines | Process changes |
| Research | External docs, RFCs | New references |
| Tools Summary | All tools in repo | Tool changes |

## Relationship to CLAUDE.md

CONTRIBUTING.md and CLAUDE.md have **complementary, non-overlapping ownership**:

| Concern | Owner |
|---------|-------|
| Developer workflows, onboarding, setup guides | CONTRIBUTING.md |
| Project context, architecture, key patterns | CLAUDE.md |
| Build/dev/test commands (detailed) | CONTRIBUTING.md |
| Build/dev/test commands (quick reference) | CLAUDE.md |
| Coding conventions, naming, style | CLAUDE.md |
| Git commit conventions, PR workflow | CONTRIBUTING.md |
| Authentication details (config, setup) | CONTRIBUTING.md |
| Authentication overview (strategy) | CLAUDE.md |

When populating CONTRIBUTING.md, reference CLAUDE.md for architecture details rather than duplicating them. Use links: `See [CLAUDE.md](CLAUDE.md) for architecture details.`

## Writing Style

- Write for a developer who is new to the project
- Use imperative mood for instructions ("Install dependencies", not "You should install")
- Include actual commands, not placeholders
- Group related setup steps together
- Provide both individual service commands and bulk commands where applicable
- Use tables for structured reference information
- Keep debugging tips practical — actual error messages and solutions
