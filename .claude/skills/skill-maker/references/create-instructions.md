# Create Mode Instructions

Workflow for creating a new Agent Skill. Steps are ordered intentionally — **do not skip or reorder**.

## Step 1 — Track Progress

Create a visible progress checklist so the user can see which steps are done and which remain. **This is the very first thing you do — before reading any references, before assessing complexity.** Use whatever task/todo tracking tool is available in your environment (e.g., task lists, todo items, progress checklists).

```text
Create mode steps:
1. Track progress
2. Assess requirements
3. Plan the skill (complexity-dependent)
4. Scaffold
5. Write SKILL.md
6. Write supporting files
7. Register in CLAUDE.md
8. Self-audit against checklist
9. Validate (final gate)
```

**Why this matters**: The user has no visibility into your internal progress. The checklist is their progress bar — it shows what's done, what's next, and how far along the build is. Without it, the user sees silence until you produce output.

**Why ordering matters**: Reading references before creating the checklist means the user sees no progress for the first several seconds. Create the checklist first, then read references — the user immediately knows work has started.

---

## Step 2 — Assess Requirements

Determine what information you have and what's missing.

**Required** — name, description, purpose.
**Optional** — argument-hint, invocation model, complexity level, needs scripts/references/assets, compatibility, execution context, agent type.

### Complex / full-tier requests — read FORMS.md first

**If the request is complex or explicitly `--full`**: Read [FORMS.md](FORMS.md) **before doing anything else in this step**. Use it as a checklist to identify what's been provided vs. what's missing. This front-loads structure and prevents missed requirements. Then proceed with the decision tree below.

### Decision tree

1. If the user provides name + clear purpose + enough context → determine complexity, then proceed.
2. If the user's intent is ambiguous or required fields are missing → ask targeted follow-up questions (not a form — just ask what's unclear).
3. If the user explicitly asks for a "simple" or "quick" skill → simple tier.
4. If the user explicitly asks for a "complex" or "full" skill → full tier.
5. If unclear, default to standard tier.

### Name collision check

Before proceeding, check if `.claude/skills/<name>/` already exists. If it does, confirm with the user: update the existing skill, or choose a different name?

### Output format check

If the skill produces user-facing output (tables, reports, summaries), confirm:

- Is the output a single artifact or multiple?
- What format? (markdown table, JSON, prose, mixed)
- What level of detail? (summary vs comprehensive)

If the user says "a table" (singular), plan for one table. Don't split into multiple unless the user agrees.

---

## Step 3 — Plan the Skill (all tiers produce a spec)

Every tier gets a `SKILL-SPEC.md`. Planning depth scales with complexity — but user approval is always required. Use [assets/skill-spec-template.md](../assets/skill-spec-template.md) as the template.

### Simple tier — lightweight spec

Fill in the Identity and Behavior sections only. Target ~10 lines.

### Standard tier — basic spec

Fill in the Identity, Behavior, and File Plan sections. Target ~15-20 lines.

### Full tier — detailed spec

Fill in all sections: Identity, Behavior, File Plan, Edge Cases, Open Questions. Target ~30-50 lines.

**For full skills, additionally determine:**

- What output does the skill produce? (table, report, JSON, mixed) → plan output template in assets/
- Does the skill interact with external APIs or tools? → plan API reference in references/
- Are there multiple distinct operations? → plan one script per operation (SRP)
- What is the primary response format? → plan response template in assets/

### Save the spec and get user approval

> **The spec review is the highest-value quality gate in the entire workflow.** Expect 1-3 iterations. This is normal and saves significant rework — design mismatches caught here cost minutes to fix in a spec, but hours to fix in code.

1. **Write** the completed spec to `.claude/skills/skill-maker/SKILL-SPEC.md` (the new skill directory doesn't exist yet).
2. **Ask the user to review it.** Say something like: _"Review the spec at `SKILL-SPEC.md` and let me know when you're happy with it, or what to change."_
3. **Do not proceed to Step 4 until the user explicitly approves.** Silence is not approval — ask again if needed.
4. If the user requests changes, update the spec, re-present, and wait for approval again. Multiple iterations are expected and valuable.
5. After scaffold (Step 4), move the spec to `.claude/skills/<new-skill>/SKILL-SPEC.md`.

---

## Step 4 — Scaffold

Run the scaffold script:

```bash
# name: kebab-case, 1-64 chars (e.g. "pr-triage", "code-review")
# purpose: meta-skill | development | admin | utility | other (default: other)

# Simple
bash .claude/skills/skill-maker/scripts/scaffold.sh "<name>" "<purpose>" --quick

# Standard (default)
bash .claude/skills/skill-maker/scripts/scaffold.sh "<name>" "<purpose>"

# Full
bash .claude/skills/skill-maker/scripts/scaffold.sh "<name>" "<purpose>" --full

# With extra args
bash .claude/skills/skill-maker/scripts/scaffold.sh "<name>" "<purpose>" --description "..." --argument-hint "..."
```

After scaffold succeeds:

1. **Move the spec** into the new skill directory:

```bash
mv .claude/skills/skill-maker/SKILL-SPEC.md .claude/skills/<name>/SKILL-SPEC.md
```

2. **Make scripts executable** (scaffold creates directories but not scripts — you'll create those in Step 5):

```bash
chmod +x .claude/skills/<name>/scripts/*.sh
```

Run this after creating scripts in Step 6, not here. Listed here so you don't forget.

---

## Step 5 — Write SKILL.md

**Read the scaffolded SKILL.md first** (tool requirement — files must be read before writing).

Before filling in the TODO markers, **read these three files** (each covers non-overlapping concerns):

1. **Read** [SPEC.md](SPEC.md) — frontmatter field names, types, and validation constraints (name regex, description length, required vs optional)
2. **Read** [CLAUDE-CODE.md](CLAUDE-CODE.md) — fields that ONLY exist in Claude Code and are NOT in the base spec: `disable-model-invocation`, `user-invocable`, `argument-hint`, `model`, `context`, `agent`, `hooks`, string substitutions (`$ARGUMENTS`), dynamic context injection (`` !`cmd` ``)
3. **Read** [BEST-PRACTICES.md](BEST-PRACTICES.md) — quality principles: conciseness, freedom-to-fragility matching, description phrasing, anti-patterns

Then fill in all TODO markers. Ensure all template sections are present: Purpose, When to Use, Workflow, Example Inputs, Edge Cases, File References.

New skills start at **version 0.1.0**. Bump to 1.0.0 only after the skill has been tested and validated in real use.

---

## Step 6 — Write Supporting Files

File requirements depend on complexity tier. **SRP applies**: one script per operation, one reference doc per topic.

### Simple (`--quick`)

- **Required**: 1 SRP script
- **Optional**: REFERENCE.md, 1 template

### Standard (default)

- **Required**: REFERENCE.md, 1-5 SRP scripts
- **Optional**: additional reference docs, templates, maybe an asset

### Full (`--full`)

All of the following are expected:

- **references/REFERENCE.md** — domain context, rules, assumptions
- **references/FORMS.md** — intake/review forms for structured usage
- At least 1 additional focused reference doc (API docs, output format, etc.)
- **scripts/** — 3+ SRP scripts (one per operation) (up to 10 for full skills)
- **assets/** — at least 1 of: output template, response template, JSON schema, validation checklist, or guide

### Script requirements (all tiers)

- Self-contained, with `--help` support (use heredoc, not sed header parsing)
- Structured output (JSON/CSV to stdout, diagnostics to stderr)
- No interactive prompts
- Helpful error messages (what went wrong, what to try)
- **Graceful degradation** — if a fetch fails partway (e.g., page 3 of pagination), return what was fetched so far with a warning. Don't hard-exit on the first API error. The agent can work with partial data.
- **Summary stats in output** — every fetch script should include a `summary` object in its JSON output (counts, totals, breakdowns). Don't force the agent to count items from raw arrays.
- **Bot/automation detection** — when fetching user-attributed data, detect bot accounts using multiple signals: `user.type == "Bot"`, login suffix `[bot]`, known bot patterns (dependabot, github-actions, etc.). Don't rely on a single check.
- After creating all scripts, run `chmod +x .claude/skills/<name>/scripts/*.sh`

### Multi-script orchestration (SRP skills)

When a skill uses multiple SRP scripts (one per data source), the SKILL.md must include fallback guidance: if one script fails, the agent should continue with the others and note the gap. SRP means each script is independent — a failure in one should not block the rest.

---

## Step 7 — Register in CLAUDE.md

**Read CLAUDE.md before editing it** (tool requirement — files must be read before writing).

Check if the skill needs to be listed in CLAUDE.md under the skills section. Skills with `user-invocable: true` should be documented so users know they can invoke them.

---

## Step 8 — Self-Audit

Do a quality check against [assets/checklist.md](../assets/checklist.md):

- Description has **what** + **when**?
- Examples are concrete (not placeholder)?
- Edge cases have fallback behavior?
- File references point to real files?
- `allowed-tools` is NOT present in frontmatter?
- Scripts follow SRP?
- File count meets tier requirements?

Fix any gaps before proceeding to validation.

---

## Step 9 — Validate (Final Gate)

Run the validation script:

```bash
bash .claude/skills/skill-maker/scripts/validate.sh ".claude/skills/<name>"
```

Review output and fix any issues. PASSING VALIDATION DOES NOT EQUAL HIGH QUALITY — it checks structure, not substance. Step 8 (self-audit) covers substance.

If validation passes and self-audit is clean, the skill is done.
