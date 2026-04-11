---
name: create-rule
description: Creates .claude/rules/ rule files through iterative planning. Accepts source docs or guides as context, generates a rule spec for user review, then scaffolds the rule file with optional path scoping. Proposes natural splitting when content spans multiple concerns. Use when creating a new Claude Code rule, converting a guide to a rule, or when the user mentions .claude/rules/.
compatibility: Designed for Claude Code and GitHub Copilot with shell access.
metadata:
  author: nebula-aurora
  version: "0.1.0"
  purpose: development
  type: P1
disable-model-invocation: false
user-invocable: true
argument-hint: "Rule topic and optional source docs (e.g., 'effect-ts standards from .claude/rules/effect-ts-core.md')"
---

# Create Rule

Creates `.claude/rules/` rule files through iterative planning — accepts source docs as context, proposes splitting for cross-cutting concerns, and validates frontmatter structure.

## When to Use

- User wants to create a new `.claude/rules/` rule file
- User wants to convert a guide or context doc into a rule
- User mentions "create rule", "add rule", "new rule", ".claude/rules/"
- User provides source material that should become project-level instructions

## Design Principles

**Iterative planning**: Like skill-maker, the user reviews a spec (RULE-SPEC.md) before the rule is created. This catches scope issues early — especially when source material should be split.

**One concern per file**: Each rule file should cover a single topic. If source material spans testing + code style + API design, propose three separate rule files rather than one monolith.

**Concise over comprehensive**: Rules are loaded into context automatically. Every line costs tokens. Condense source material aggressively — keep only actionable instructions, drop explanations that Claude already knows.

**Path scoping is optional**: Only add `paths` frontmatter when rules genuinely apply to specific file types. Most rules are unconditional.

## Workflow

### Step 1 — Assess

Gather requirements from the user:
1. **Topic**: What is the rule about? (e.g., "Effect-TS conventions", "API design patterns")
2. **Source docs**: Are there existing docs/guides to incorporate? Read them.
3. **Path scoping**: Does this rule apply to all files or specific patterns?
4. **Subdirectory**: Should it go under a subdirectory? (e.g., `.claude/rules/backend/`)

If source docs are provided, analyse them for:
- **Concern count**: Does the material cover one topic or multiple?
- **Path divergence**: Do different sections apply to different file patterns?
- **Size**: Will the condensed content exceed ~200 lines?

### Step 2 — Plan (RULE-SPEC.md)

Write a rule spec to `.claude/skills/create-rule/RULE-SPEC.md` for user review.

The spec should include:
- Rule file name(s) and path(s) under `.claude/rules/`
- Whether `paths` frontmatter is needed (and which patterns)
- Content outline — key sections and what each covers
- If splitting is proposed: rationale for the split, one entry per proposed file

**Wait for user approval.** Iterate if the user wants changes. Do not proceed until approved.

After approval, move the spec: `mv .claude/skills/create-rule/RULE-SPEC.md .claude/rules/RULE-SPEC.md` (or to the subdirectory if applicable). Delete it after the rule is finalized.

### Step 3 — Scaffold

For each approved rule file:
1. Run `bash scripts/scaffold-rule.sh "<name>" [--paths "<glob1>" "<glob2>"] [--subdir "<dir>"]`
2. Read the scaffolded file.

### Step 4 — Populate

Fill in the rule content:
1. If source docs were provided, read and condense them:
   - Keep actionable instructions (do this, don't do that)
   - Drop background explanations Claude already knows
   - Use bullet points and code examples
   - Keep under ~200 lines per rule file
2. If no source docs, write the rule content from the user's description and project context.
3. Present the populated rule to the user for review.

### Step 5 — Validate

Run `bash scripts/validate-rule.sh "<rule-path>"` to check:
- File extension is `.md`
- Frontmatter format is valid (if present)
- `paths` patterns use valid glob syntax
- File size is within guidelines
- No Windows-style paths

Clean up: delete the RULE-SPEC.md if still present.

## Example Inputs

- "Create a rule for Effect-TS conventions based on existing .claude/rules/effect-ts-core.md"
- "Add a rule for API design patterns scoped to src/api/"
- "Create rules from the MCP development guide"
- "Add a testing conventions rule for all test files"
- "Create a rule for frontend component patterns under .claude/rules/frontend/"

## Splitting Heuristics

When to propose splitting source material into multiple rule files:

| Signal | Action |
|--------|--------|
| Source covers 2+ distinct topics | One rule file per topic |
| Content exceeds ~200 lines after condensing | Split at natural section breaks |
| Different sections apply to different file patterns | Split by path scope |
| Related rules share a domain | Group under a subdirectory |

Present proposed splits in the RULE-SPEC.md with rationale. The user decides.

## Edge Cases

- **Rule file already exists**: Warn user — update content or choose a different name?
- **Source doc too large**: Condense aggressively; if still >200 lines, propose splitting.
- **Cross-cutting concerns**: Detect multiple topics and propose separate rule files.
- **No path scoping needed**: Omit `paths` frontmatter entirely (unconditional rule).
- **Subdirectory organisation**: Create subdirectory if it doesn't exist.
- **Invalid glob patterns**: `validate-rule.sh` catches common mistakes.
- **No `.claude/rules/` directory**: `scaffold-rule.sh` creates it automatically.

## File References

| File | Purpose | When loaded |
|------|---------|-------------|
| `references/REFERENCE.md` | Rule conventions, frontmatter spec, content guidelines, glob patterns | During all operations |
| `scripts/scaffold-rule.sh` | Create rule file from template with optional frontmatter | During scaffold |
| `scripts/validate-rule.sh` | Validate rule file structure and frontmatter | During validate |
| `assets/rule-template.md` | Starter template for rule files | During scaffold |
| `assets/rule-spec-template.md` | Planning spec template for iterative review | During plan |
