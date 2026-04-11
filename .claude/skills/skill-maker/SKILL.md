---
name: skill-maker
description: Creates and updates Agent Skills in .claude/skills/. Use when creating a new skill, modifying an existing skill, or when the user mentions skill structure, conventions, or agent skill capabilities. Handles simple, standard, and full complexity tiers.
compatibility: Designed for Claude Code with shell access (bash, node). Works with any filesystem-based coding agent.
metadata:
  author: nebula-aurora
  version: "2.2.0"
  purpose: meta-skill
  type: P0
disable-model-invocation: false
user-invocable: true
---

# Skill Maker

Creates and updates Agent Skills with complexity-tiered workflows and collaborative planning.

## When to Use

- User wants to **create** a new skill from scratch
- User wants to **update** an existing skill (metadata, instructions, files)
- User asks about skill structure, conventions, or capabilities

## Example Inputs

- `/skill-maker create a PR comment analyzer skill`
- `/skill-maker update pr-triage to add a resolve script`
- "Create a simple skill that formats markdown tables"
- "Add a new reference doc to the code-review skill"

## Design Principles

**SRP for skills**: One skill = one responsibility. If a skill does "read data" and "write/mutate data", split it. A triage skill shows feedback; a resolve skill acts on it.

**SRP for scripts**: One script per operation. "Fetch + transform + validate" = 3 scripts, not one monolith.

**Complexity tiers**: Skill depth scales with complexity. Simple skills are lean; full skills are comprehensive.

| Tier | Flag | Required Files | Optional Files |
|------|------|---------------|----------------|
| **Simple** | `--quick` | SKILL.md, 1 SRP script | REFERENCE.md, 1 template |
| **Standard** | (default) | SKILL.md, REFERENCE.md, 1-5 SRP scripts | additional reference docs, templates, maybe an asset |
| **Full** | `--full` | SKILL.md, REFERENCE.md, FORMS.md, 3+ SRP scripts (up to 10), at least 1 asset (template, guide, JSON schema, or checklist) | additional reference docs, additional scripts, additional assets |

## Mode Detection

Determine the mode from the user's intent. If ambiguous, ask.

| Mode | Trigger | Instructions |
|------|---------|-------------|
| **create** | "create a skill", "new skill", "add a skill" | Follow [references/create-instructions.md](references/create-instructions.md) |
| **update** | "update skill X", "change the description", "add a script to" | Follow [references/update-instructions.md](references/update-instructions.md) |

## Edge Cases

- **Name collision**: If `.claude/skills/<name>/` already exists during create, confirm with user: update the existing skill, or choose a different name?
- **Missing fields**: Ask for only the missing required fields, don't re-ask for optional ones that have sensible defaults.
- **Legacy commands**: If `.claude/commands/` files exist, note that skills in `.claude/skills/` take precedence when names overlap.
- **Monorepo skills**: Skills can live in nested `.claude/skills/` directories (e.g., `packages/frontend/.claude/skills/`).

## File Map

| File | Purpose | When loaded |
|------|---------|-------------|
| `SKILL.md` | Router + design principles (this file) | On activation |
| `references/create-instructions.md` | Create mode workflow (complexity-tiered) | During create |
| `references/update-instructions.md` | Update mode workflow | During update |
| `references/SPEC.md` | Agent Skills specification | During create/update |
| `references/CLAUDE-CODE.md` | Claude Code extensions | During create/update |
| `references/BEST-PRACTICES.md` | Authoring quality guidelines | During create/update |
| `references/FORMS.md` | Structured intake/review forms | During create/update |
| `scripts/scaffold.sh` | Template hydration + directory scaffolding | During create |
| `scripts/upgrade.sh` | Non-destructive backfill of missing files | During update |
| `scripts/validate.sh` | Structural validation (20 checks) | During create/update |
| `assets/skill-template.md` | SKILL.md starter template | During create |
| `assets/skill-spec-template.md` | Planning spec template (scaled by complexity) | During create |
| `assets/frontmatter-fields.json` | Machine-readable field defs | During create/validate |
| `assets/checklist.md` | Quality review checklist | During self-audit |
| `assets/reference-template.md` | Starter REFERENCE.md | During create (--full) / upgrade |
| `assets/forms-template.md` | Starter FORMS.md | During create (--full) / upgrade |
| `assets/output-template.md` | Output skeleton for new skills | During create |
| `assets/script-template.sh` | Starter Bash script | During create |
| `assets/script-template.js` | Starter Node.js script | During create |
