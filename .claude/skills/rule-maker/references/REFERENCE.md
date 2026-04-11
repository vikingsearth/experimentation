# Create Rule Reference

## Rule File Conventions

Rules live in `.claude/rules/` as `.md` files. All `.md` files in that directory (and subdirectories) are automatically loaded as project memory with the same priority as `.claude/CLAUDE.md`.

### Directory Structure

```
.claude/rules/
├── code-style.md           # Unconditional — applies to all files
├── testing.md              # Unconditional
├── security.md             # Unconditional
├── frontend/
│   ├── react.md            # Path-scoped to src/frontend/**
│   └── styles.md           # Path-scoped to src/frontend/**/*.css
└── backend/
    ├── api.md              # Path-scoped to src/*-svc/**
    └── database.md         # Path-scoped to src/ctx-svc/**
```

### Naming Conventions

- Use kebab-case for filenames: `code-style.md`, not `codeStyle.md`
- Use descriptive names that indicate the topic: `effect-ts.md`, not `rules.md`
- Subdirectory names should match domains: `frontend/`, `backend/`, `testing/`

## Frontmatter Specification

Rule files support one optional frontmatter field:

### `paths` (optional)

An array of glob patterns. When present, the rule only applies when Claude is working with files matching any of the patterns. When absent, the rule is unconditional.

```yaml
---
paths:
  - "src/api/**/*.ts"
  - "src/middleware/**/*.ts"
---
```

### Supported Glob Patterns

| Pattern | Matches |
|---------|---------|
| `**/*.ts` | All `.ts` files recursively |
| `src/**/*` | All files under `src/` |
| `*.md` | Markdown files in project root only |
| `src/frontend/**/*.{ts,tsx}` | TS/TSX files under frontend |
| `{src,lib}/**/*.ts` | TS files under `src/` or `lib/` |
| `tests/**/*.test.ts` | Test files matching naming convention |

### Invalid Patterns (caught by validate-rule.sh)

| Pattern | Problem |
|---------|---------|
| `src\api\*.ts` | Windows-style backslashes |
| `src/api/` | Trailing slash (matches nothing) |
| `*.` | Trailing dot |
| (empty string) | Empty pattern |

## Content Guidelines

### Token Cost Awareness

Rules are loaded into context automatically. Every line costs tokens. Write rules as if you're paying per word:

- **Do**: Actionable instructions, code examples, specific patterns
- **Don't**: Background explanations, rationale essays, tutorial-style content

### Good Rule Content

```markdown
# Effect-TS Conventions

- Use `Effect.gen` for generator-based composition
- Wrap external calls in `Effect.tryPromise` with tagged errors
- Define service interfaces with `Context.Tag`
- Use `Layer` for dependency injection, not constructor injection
- Error types: `Data.TaggedEnum` for domain errors, `Schema.Struct` for validation

Example tagged error:
\`\`\`typescript
class DbError extends Data.TaggedError("DbError")<{
  readonly message: string
}> {}
\`\`\`
```

### Bad Rule Content

```markdown
# Effect-TS

Effect-TS is a functional programming library for TypeScript that provides
algebraic effects and handlers. It was created by Michael Arnaldi and is
inspired by ZIO from the Scala ecosystem. The library offers several key
features including...
[200 lines of tutorial]
```

### Structure Template

For most rules, follow this pattern:

1. **Title** — `# Topic Name`
2. **Core rules** — bullet list of actionable instructions
3. **Examples** — short code snippets showing the pattern
4. **Anti-patterns** — what NOT to do (optional, only if common mistakes exist)

## Splitting Heuristics (Detail)

### When to Split

| Signal | Example | Action |
|--------|---------|--------|
| Multiple H2 topics | Testing + Code Style + API Design | 3 rule files |
| >200 lines condensed | Large standards guide | Split at H2 boundaries |
| Different path scopes | Frontend rules + Backend rules | Split by scope |
| Independent concerns | Logging + Error handling | Separate files |

### When NOT to Split

- Closely related instructions (e.g., "naming" and "formatting" are both code style)
- Short content (<50 lines) covering 2 related topics
- Content that needs to be read together for coherence

### Subdirectory Grouping

Group rules into subdirectories when:
- 3+ rule files share a domain (e.g., frontend, backend, testing)
- The domain is clearly distinct from other rules
- The grouping helps discoverability

## Rule Spec Template

The RULE-SPEC.md should contain:

```markdown
# Rule Spec: [topic]

## Files to Create

| File | Path Scope | Content Summary |
|------|-----------|-----------------|
| `rule-name.md` | unconditional / `src/**/*.ts` | Brief description |

## Source Material

- `path/to/source.md` — what to extract from it

## Content Outline

### rule-name.md
- Section 1: ...
- Section 2: ...
- Estimated lines: ~N

## Split Rationale (if applicable)

Why the source material is being split into N files.
```

## Existing Project Context

### Current `.claude/rules/` Status

No `.claude/rules/` directory exists yet. The `scaffold-rule.sh` script will create it on first use.

### Existing Rules

| Rule | Scope | Notes |
|------|-------|-------|
| `effect-ts-core.md` | Backend `**/*.ts` | Composition, errors, DI, concurrency |
| `effect-ts-data.md` | Backend `**/*.ts` | Option, Schema, Brand, naming |
| `effect-ts-infra.md` | Backend `**/*.ts` | HTTP, observability, testing, streams |
| `mcp-server-dev.md` | `src/mcp-registry/**/*.ts` | SDK, structure, sessions, tools |
| `mcp-server-deploy.md` | `src/mcp-registry/**` | PM2, nginx, Docker, shutdown |
