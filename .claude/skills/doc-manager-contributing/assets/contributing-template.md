# Contributing Guide: [PROJECT NAME]

## Overview

> **This file owns developer workflows, onboarding, setup guides, and tooling rules.** For project context, architecture, key patterns, and coding conventions, see [CLAUDE.md](CLAUDE.md). These two files have complementary, non-overlapping ownership — see [ADR-0003](docs/adrs/adr-0003-ai-tooling-configuration-strategy.md) for the rationale.

// Brief description of the project — what it is, its core value proposition, and the high-level tech approach.

### ⚡️ NOTE

For detailed architecture information, read the [docs/designs/architecture.md] and [docs/designs/use_cases.md]

---

## Project Structure & Responsibilities

// Project tree showing the monorepo layout. Include top-level directories, key config files, and service directories with brief annotations.

```text
project-name/ (root)
├── .github/
│   ├── agents/ - // description
│   ├── prompts/ - // description
│   ├── chatmodes/ - // description
│   ├── instructions/ - // description
│   ├── templates/ - // description
│   └── workflows/ - // description
├── .claude/
│   ├── commands/ - // description
│   └── skills/ - // description
├── docs/
│   ├── adrs/ - Architecture Decision Records
│   └── designs/ - Architecture and design documents
├── src/
│   ├── [service-a]/ - // description
│   │   ├── package.json, tsconfig.json
│   │   └── src/ - // source code description
│   ├── [service-b]/ - // description
│   │   ├── package.json, tsconfig.json
│   │   └── src/ - // source code description
│   ├── docker-compose.yml - // description
│   └── dapr/ - // description (if applicable)
├── tests/ - // Integration test harnesses
├── scripts/ - // Utility and setup scripts
├── package.json - Root workspace configuration
├── CLAUDE.md - Project context, architecture, conventions (AI agents)
├── CONTRIBUTING.md - Developer workflows, onboarding, setup (this file)
├── CHANGELOG.md - Comprehensive change log
├── VERSIONING.md - Per-service semantic versioning strategy
└── README.md - Project documentation
```

---

## Key Technologies

// List each technology with a brief description of its role in the project.

- **[Framework/Runtime]**: // description of use within this project
- **[Frontend Framework]**: // description of use within this project
- **[Database/Storage]**: // description of use within this project
- **[Messaging/Eventing]**: // description of use within this project
- **[Infrastructure/Orchestration]**: // description of use within this project
- **[Build Tool]**: // description of use within this project

---

## Authentication Setup for Development

// Describe the authentication strategy (e.g., Keycloak, OAuth, JWT) and how to configure it for local development.

**Production:** // How auth is enforced in production.

**Development:** // How to run locally — any bypass flags, local identity providers, etc.

### Running [Identity Provider] Locally

1. **Start the identity provider**:

   ```bash
   # command to start
   ```

2. **Configure service** (`.env`):

   ```env
   AUTH_URL=http://localhost:PORT
   AUTH_REALM=dev
   AUTH_CLIENT_ID=dev-client
   ```

### User ID Format

// Describe how user IDs are derived (e.g., hashed email, UUID, JWT claim).

---

## Project Details: File & Directory Responsibilities

// For each major service/component, describe its directory structure and key components.

### [Service/Component Name]

#### Project Structure

- `src/[service]/src/`: // description
- `src/[service]/package.json`: // description
- `src/[service]/Dockerfile`: // description (if applicable)

#### Key Components

- // Key module or file and its purpose
- // Key module or file and its purpose

// Repeat this section for each service in the project.

---

## Tools

// List tools required for development with setup instructions.

### Tool: [Tool Name]

**Purpose**: // What this tool is used for

**Setup**:

```bash
# installation or setup command
```

**Usage**:

```bash
# usage command or example
```

**Configuration**:

- `[./path/to/config]`: // description of config and what it maintains

// Repeat for each tool.

---

## Setup & Development

// Step-by-step instructions for getting the project running locally from scratch.

### Prerequisites

```bash
# Required versions
node >= XX.X.X
npm >= XX.X.X
# Any other tools (Docker, Dapr CLI, etc.)
```

### Installation

```bash
# Clone and install
git clone <repo-url>
cd project-name
# Install command (e.g., make ninstall, npm install)
```

### Environment Configuration

// Describe required `.env` files per service, any secrets that need to be configured, and where to find example configs.

### Infrastructure

```bash
# Start infrastructure dependencies (databases, message brokers, etc.)
# command to start
```

### Running Services

```bash
# Start individual services
# command to start [service-a]
# command to start [service-b]

# Or start all services
# command to start all
```

### VS Code Tasks

// If the project uses VS Code tasks, list the key ones.

| Task | Description |
|---|---|
| `[Task Name]` | // what it does |
| `[Task Name]` | // what it does |

---

## Build & Development

// Detailed build commands, workspace patterns, and development workflows.

### Build Commands

```bash
# Build all
npm run build

# Build specific service
npm run build --workspace=src/[service]
```

### Testing

```bash
# Run all tests
npm run test

# Run tests for specific service
npm run test --workspace=src/[service]

# Coverage
npm run test:coverage
```

### Linting & Type Checking

```bash
# Lint everything
npm run lint

# Auto-fix
npm run fix

# Type check
npm run type-check
```

---

## Debugging

// Tips for debugging common issues — service connectivity, database connections, authentication, etc.

### Common Issues

| Issue | Solution |
|---|---|
| [Description of common issue] | [How to fix it] |
| [Description of common issue] | [How to fix it] |

### Service-Specific Debugging

// Per-service debugging tips, log locations, health check endpoints, etc.

---

## Git Commit Best Practices

// Commit conventions and workflow.

- **Conventional commits**: `feat(scope):`, `fix(scope):`, `refactor(scope):`, `docs(scope):`, `chore(scope):`, `ci(scope):`
- **Branch naming**: `feature/name`, `fix/name`, `refactor/name`
- **Max files per commit**: // guideline (e.g., 2 files per commit, preferably 1)
- **Message format**: imperative mood, lowercase, no period, max 72 chars
- **Version bumps**: `feat:` → minor, `fix:`/`refactor:` → patch, `feat!:` or `BREAKING CHANGE` → major

---

## Collaboration Tips

// Team-specific collaboration guidelines.

- Keep frontend and backend code separated for clarity
- Use clear commit messages and PR descriptions
- Document new components, APIs, and scripts in `docs/designs/`
- Update this guide as the project evolves

---

## Research

// Links to relevant external documentation, RFCs, or research materials that inform the project.

| Topic | Link |
|---|---|
| [Topic] | [URL] |

---

## Tools used in this repository

// Summary table of all tools, their purpose, and links to documentation.

| Tool | Purpose | Docs |
|---|---|---|
| [Tool Name] | // purpose | [Link] |
