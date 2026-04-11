# Skill Spec: create-rule

## Identity

- **Name**: create-rule
- **Purpose**: development
- **Complexity**: standard
- **Description**: Creates `.claude/rules/` rule files through iterative planning. Accepts source docs or guides as context, generates a rule spec for user review, then scaffolds the rule file with optional path scoping. Proposes natural splitting when content spans multiple concerns. Use when creating a new Claude Code rule, converting a guide to a rule, or when the user mentions `.claude/rules/`.

## Behavior

- **Input**: Rule topic/name, optional source docs (guides, context files) to incorporate, optional path patterns for scoping.
- **Output format**: Markdown rule file(s) in `.claude/rules/`
- **Output structure**: Single or multiple rule files — skill proposes splitting when content covers distinct concerns
- **Operations**:
  1. **assess** — Gather requirements: rule topic, source docs, path scoping needs. Analyse source docs for scope and concern boundaries.
  2. **plan** — Write a rule spec (`RULE-SPEC.md`) for user review. If source material spans multiple concerns, propose a split with one file per topic. Iterate until user approves.
  3. **scaffold** — Run `scaffold-rule.sh` to create the rule file(s) from template with frontmatter.
  4. **populate** — Fill in rule content from source docs and context. Condense and restructure for conciseness.
  5. **validate** — Run `validate-rule.sh` to check frontmatter and structure.
- **External dependencies**: None (pure bash + file operations)

## Frontmatter Fields

Rule files use YAML frontmatter (`---` delimiters). All fields are optional — rules without frontmatter are valid unconditional rules.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `paths` | string[] | No | Glob patterns scoping when this rule applies. Without this field, the rule is unconditional (loaded for all files). |

### `paths` Glob Patterns

Standard glob syntax supported:

| Pattern | Matches |
|---------|---------|
| `**/*.ts` | All TypeScript files in any directory |
| `src/**/*` | All files under `src/` |
| `*.md` | Markdown files in project root only |
| `src/components/*.tsx` | React components in a specific directory |

Multiple patterns and brace expansion:
```yaml
paths:
  - "src/**/*.{ts,tsx}"
  - "{src,lib}/**/*.ts"
  - "tests/**/*.test.ts"
```

### Frontmatter Examples

**Unconditional rule** (no frontmatter needed):
```markdown
# Code Style Rules

- Use 2-space indentation
- Prefer `const` over `let`
```

**Path-scoped rule**:
```markdown
---
paths:
  - "src/api/**/*.ts"
---

# API Development Rules

- All endpoints must include input validation
```

## File Plan

- **scripts/scaffold-rule.sh**: Create a rule file from template with name, optional `paths` frontmatter. Creates `.claude/rules/` directory if needed. Accepts subdirectory for organisation.
- **scripts/validate-rule.sh**: Validate rule file structure — checks frontmatter format, `paths` glob syntax, file extension, file size guidelines.
- **references/REFERENCE.md**: Rule conventions (from rules.md), splitting heuristics, path pattern examples, content guidelines.
- **assets/rule-template.md**: Starter template for a rule file (with and without `paths` frontmatter).
- **assets/rule-spec-template.md**: Planning spec template for iterative review.

## Splitting Heuristics

When source material or accumulated rule content should be split into separate files:

- **Multiple topics**: Source covers distinct concerns (e.g., testing conventions + API design + database patterns) → one rule file per topic
- **Size threshold**: Rule file exceeds ~200 lines → look for natural section breaks to split
- **Path divergence**: Different sections apply to different file patterns (e.g., frontend vs backend rules) → split by path scope
- **Subdirectory grouping**: Related rules that share a domain → group under a subdirectory (e.g., `.claude/rules/frontend/`)

Proposed splits are presented in the RULE-SPEC.md for user approval before scaffolding.

## Edge Cases

- **Rule file already exists**: Warn user — update content or choose a different name?
- **Source doc too large**: Condense; if still large (>200 lines), propose splitting by concern.
- **Cross-cutting concerns**: Detect when source material covers multiple topics (e.g., "testing + code style") and propose separate rule files.
- **No path scoping needed**: Omit `paths` frontmatter entirely (unconditional rule).
- **Subdirectory organisation**: Support creating rules in subdirectories (e.g., `.claude/rules/backend/api.md`).
- **Invalid glob patterns**: `validate-rule.sh` checks for common glob mistakes (missing `**`, Windows paths, trailing slashes).
