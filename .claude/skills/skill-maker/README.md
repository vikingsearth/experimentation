# Skill Maker

A meta-skill for the full lifecycle of [Agent Skills](https://agentskills.io): **create**, **update**, **audit**, and **inventory**.

Invoke with `/skill-maker` or let Claude activate it when you mention creating, updating, reviewing, or listing skills.

---

## How This Skill Works

### The Agent Skills Model

Agent Skills are a lightweight, open format ([agentskills.io](https://agentskills.io)) for extending AI agent capabilities. A skill is a directory containing a `SKILL.md` file with YAML frontmatter (metadata) and Markdown instructions, plus optional supporting files. Claude Code extends the base spec with additional features like invocation control and subagent execution.

Skills use **progressive disclosure** to manage context efficiently:

1. **Discovery** — at startup, only `name` + `description` from all skills are loaded (~100 tokens each)
2. **Activation** — when a task matches, the full `SKILL.md` body is loaded (< 5000 tokens recommended)
3. **Execution** — supporting files in `references/`, `scripts/`, `assets/` are loaded only on demand

### What This Skill Does

Skill Maker provides four modes — each triggered by user intent:

| Mode | Trigger phrases | What happens |
| ---- | --------------- | ------------ |
| **create** | "create a skill", "new skill" | Gathers requirements, scaffolds directory, writes SKILL.md + supporting files, validates |
| **update** | "update skill X", "change the description" | Reads existing skill, applies changes, bumps version, validates |
| **audit** | "review this skill", "validate", "check quality" | Runs structural validation + quality review against checklist |
| **inventory** | "list skills", "what skills exist" | Enumerates all skills in the repo with metadata summary |

---

## Directory Structure

```txt
skill-maker/
├── SKILL.md                          # Core instructions (this is what Claude reads on activation)
├── README.md                         # Human reference (this file)
│
├── references/                       # Loaded on-demand during create/audit modes
│   ├── SPEC.md                       # Agent Skills specification (condensed)
│   ├── CLAUDE-CODE.md                # Claude Code-specific extensions
│   ├── BEST-PRACTICES.md             # Authoring quality guidelines
│   └── FORMS.md                      # Structured intake forms for each mode
│
├── scripts/                          # Executable utilities Claude runs
│   ├── scaffold.sh                   # Hydrates skill-template.md into new skill (--quick/--full)
│   ├── upgrade.sh                    # Non-destructive backfill of missing files
│   ├── validate.sh                   # Validates skill structure (20 checks)
│   └── inventory.sh                  # Lists all skills with extracted metadata
│
└── assets/                           # Templates and reference data
    ├── skill-template.md             # SKILL.md starter skeleton (with CC fields)
    ├── frontmatter-fields.json       # Machine-readable field definitions
    ├── checklist.md                  # Quality review checklist for audits
    ├── reference-template.md         # Starter REFERENCE.md for new skills
    ├── forms-template.md             # Starter FORMS.md for new skills
    ├── output-template.md            # Output skeleton for new skills
    ├── script-template.sh            # Starter Bash script template
    └── script-template.js            # Starter Node.js script template
```

---

## File-by-File Breakdown

### SKILL.md — The Core

**Role**: Entry point that Claude reads when the skill activates. Contains the four mode workflows, intake requirements, and a file map pointing to supporting resources.

**Key design choices**:

- Under 200 lines (well within the 500-line recommendation)
- Overview and navigation only — detail lives in `references/`
- Uses tables for structured information (modes, requirements, file map)
- Each mode is a self-contained workflow with numbered steps

**Frontmatter fields used**:

| Field | Value | Why |
| ----- | ----- | --- |
| `name` | `skill-maker` | Kebab-case, matches directory name |
| `description` | Keywords: "creates, updates, audits, inventories, Agent Skills" | Keyword-rich for discovery |
| `compatibility` | Claude Code + shell access | Documents runtime needs |
| `metadata.purpose` | `meta-skill` | Follows repo's purpose taxonomy |
| `metadata.type` | `P0` | High-priority skill |
| `disable-model-invocation` | `false` | Claude can auto-activate when relevant |
| `user-invocable` | `true` | Users can invoke with `/skill-maker` |
<!-- allowed-tools removed: defined in Agent Skills spec but not supported by Claude Code -->

### references/ — On-Demand Knowledge

These files are **not** loaded at activation. Claude reads them only when a specific mode needs them, keeping the initial context footprint small.

#### SPEC.md

**Role**: Condensed Agent Skills specification from [agentskills.io/specification](https://agentskills.io/specification).
**When loaded**: During `create` (to get frontmatter right) and `audit` (to check compliance).
**Contents**: Directory structure rules, frontmatter field constraints, name validation regex, description guidelines, progressive disclosure stages.

#### CLAUDE-CODE.md

**Role**: Claude Code-specific extensions that go beyond the base Agent Skills spec.
**When loaded**: During `create` and `audit` for Claude Code-specific fields.
**Contents**: Additional frontmatter fields (`disable-model-invocation`, `user-invocable`, `context`, `agent`, `model`, `hooks`, `argument-hint`), invocation control matrix, string substitutions (`$ARGUMENTS`, `$N`, `${CLAUDE_SESSION_ID}`), dynamic context injection (`!`command``), subagent execution, `allowed-tools` format, project-specific conventions (purpose taxonomy, type/priority).

#### BEST-PRACTICES.md

**Role**: Authoring quality guidelines condensed from [Anthropic's best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices).
**When loaded**: During `create` (to write quality content) and `audit` (to evaluate).
**Contents**: Conciseness principles, freedom-to-fragility matching, naming conventions, progressive disclosure patterns, common patterns (template, examples, workflow, feedback loop), script design rules, anti-patterns to avoid.

#### FORMS.md

**Role**: Structured intake forms for each mode.
**When loaded**: During `create` and `update` to collect requirements; during `audit` for the report template.
**Contents**: Create intake form (required/optional fields), update change form, audit request form, audit report template with pass/warn/fail scoring.

### scripts/ — Executable Utilities

Scripts follow the Agent Skills script design guidelines: `--help` support, structured JSON output, no interactive prompts, helpful error messages, and explicit exit codes.

#### scaffold.sh

**Role**: Creates a new skill directory by hydrating `assets/skill-template.md`.
**Used in**: Create mode, Step 2.
**Interface**: `bash scripts/scaffold.sh <skill-name> [purpose] [--quick] [--full] [--description "..."] [--argument-hint "..."]`
**Validations**: kebab-case name, length limit, allowed purpose values, no directory collision, --quick/--full mutual exclusion.
**Output**: Directory with hydrated `SKILL.md` (TODO markers for unfilled sections) + subdirectories.
**Modes**:

- Default: creates `scripts/`, `references/`, `assets/` + hydrated SKILL.md
- `--quick`: creates `scripts/` only, skips `references/` and `assets/`
- `--full`: also creates starter `references/REFERENCE.md` and `references/FORMS.md`
- `--description`: fills description directly instead of TODO
- `--argument-hint`: adds `argument-hint` field to frontmatter

#### upgrade.sh

**Role**: Non-destructively backfill missing standard files in an existing skill.
**Used in**: Update mode, Step 4.
**Interface**: `bash scripts/upgrade.sh <skill-name> [--dry-run]`
**Behavior**: Ensures subdirectories exist, creates missing `references/REFERENCE.md` and `references/FORMS.md` from templates. Skips existing files. Runs validate.sh after upgrade.
**--dry-run**: Preview what would be created without writing files.

#### validate.sh

**Role**: Structural validation against the Agent Skills spec.
**Used in**: Create mode (Step 5) and Audit mode (Step 1).
**Interface**: `bash scripts/validate.sh <skill-path>`
**Checks performed** (20 total):

1. SKILL.md exists
2. YAML frontmatter present
3. `name` field present
4. Name matches directory name
5. Name is valid kebab-case (1-64 chars)
6. Description present and <= 1024 chars
7. Body <= 500 lines (warning threshold)
8. No Windows-style backslash paths
9. Only recognized subdirectories
10. No consecutive hyphens in name
11. No reserved words in name ("anthropic", "claude")
12. No `user-invocable` typo (should be `user-invocable`)
13. All frontmatter keys are recognized
14. "When to Use" section present (warn)
15. "Workflow" section present (warn)
16. "Edge Cases" section present (warn)
17. "Example Inputs" section present (warn)
18. "File References" section present (warn)
19. `allowed-tools` not present (fail — unsupported by Claude Code)
20. No unsupported frontmatter fields

**Output**: JSON object with per-check results and overall summary (pass/warn/fail).
**Exit codes**: 0 = pass, 1 = fail, 2 = invalid arguments.

#### inventory.sh

**Role**: Enumerates all skills in the repository with extracted metadata.
**Used in**: Inventory mode.
**Interface**: `bash scripts/inventory.sh [search-path]`
**Discovery**: Finds all `.claude/skills/*/SKILL.md` patterns recursively, including nested monorepo skills.
**Output**: JSON array with skill objects containing name, path, version, purpose, invocation settings, file counts, body line count, and truncated description.

### assets/ — Templates and Reference Data

#### skill-template.md

**Role**: SKILL.md starter skeleton with placeholder variables.
**Used in**: Create mode, Step 3.
**Design**: Shows all recommended sections (Purpose, When to Use, Workflow, Example Inputs, Edge Cases, File References) with `{{PLACEHOLDER}}` markers Claude fills in.

#### frontmatter-fields.json

**Role**: Machine-readable field definitions combining the base spec and Claude Code extensions.
**Used in**: Create mode (to know available fields) and validation.
**Contents**: For each field — source (spec vs claude-code), required/optional, type, constraints, description, examples. Also documents string substitutions and dynamic context injection syntax.

#### checklist.md

**Role**: Quality review checklist with checkboxes.
**Used in**: Audit mode, Step 2.
**Dimensions**: Spec compliance, description quality, conciseness, progressive disclosure, script quality, examples, edge cases, naming/terminology, invocation control.

#### reference-template.md

**Role**: Starter REFERENCE.md for new skills with standard sections (Context, Rules, Quality Checklist, Examples).
**Used in**: scaffold.sh --full mode and upgrade.sh backfill.

#### forms-template.md

**Role**: Starter FORMS.md for new skills with Intake and Review forms.
**Used in**: scaffold.sh --full mode and upgrade.sh backfill.

#### output-template.md

**Role**: Output skeleton with Objective, Inputs, Result, Risks, Next Steps sections.
**Used in**: Create mode, for skills that need structured output formatting.

#### script-template.sh / script-template.js

**Role**: Starter script templates for Bash and Node.js with --help support, structured JSON output, error handling, and proper exit codes.
**Used in**: Create mode, when a skill needs executable scripts.

---

## How the Pieces Connect

```txt
User says "create a new skill"
        │
        ▼
   ┌─────────────┐
   │  SKILL.md    │ ◄── Claude reads: identifies "create" mode
   │  (Create     │
   │   workflow)  │
   └──────┬──────┘
          │
    ┌─────┼──────────────────┐
    │     │                  │
    ▼     ▼                  ▼
 FORMS.md   SPEC.md       scaffold.sh
 (collect   CLAUDE-CODE.md  (create dirs)
  inputs)   BEST-PRACTICES.md
            (guide writing)
                             │
                             ▼
                      skill-template.md
                      (fill in skeleton)
                             │
                             ▼
                      validate.sh
                      (check result)
```

```txt
User says "audit skill X"
        │
        ▼
   ┌─────────────┐
   │  SKILL.md    │ ◄── Claude reads: identifies "audit" mode
   │  (Audit      │
   │   workflow)  │
   └──────┬──────┘
          │
    ┌─────┴──────┐
    │            │
    ▼            ▼
 validate.sh  checklist.md
 (structural  (quality
  checks)      review)
    │            │
    └─────┬──────┘
          │
          ▼
    Audit Report
    (pass/warn/fail table)
```

---

## Extending This Skill

To add capabilities:

1. **New validation checks** — edit `scripts/validate.sh`, add a new check section
2. **New quality dimensions** — edit `assets/checklist.md`, add checkbox items
3. **New frontmatter fields** — edit `assets/frontmatter-fields.json` and `references/CLAUDE-CODE.md`
4. **New modes** — edit `SKILL.md`, add a mode section with workflow steps
5. **New reference material** — add files to `references/`, link from `SKILL.md` file map

Always run `bash scripts/validate.sh ".claude/skills/skill-maker"` after changes to ensure the skill itself remains valid.
