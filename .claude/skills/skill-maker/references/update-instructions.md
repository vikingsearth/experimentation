# Update Mode Instructions

Workflow for updating an existing Agent Skill. Steps are ordered intentionally — **do not skip or reorder**.

## Step 0 — Plan

Before starting, create a progress checklist (using TodoWrite) for all steps below. Mark each step as you complete it.

```text
Update mode steps:
1. Identify target skill
2. Classify the change
3. Analyze intent
4. Backfill missing files (if needed)
5. Apply changes
6. Register in CLAUDE.md (if needed)
7. Self-audit against checklist
8. Validate (final gate)
```

---

## Step 1 — Identify Target

Locate the skill directory and read its current SKILL.md:

```bash
cat .claude/skills/<name>/SKILL.md
```

Understand the current state: what files exist, what tier the skill is at, what version it's on.

---

## Step 2 — Classify the Change

Determine the type of update:

- **Metadata change** (description, version, fields) — edit frontmatter only
- **Instruction change** (workflow, steps, examples) — edit SKILL.md body
- **File change** (add/remove scripts, references, assets) — modify directory contents
- **Structural change** (rename, reorganize, tier change) — may require scaffold adjustment

---

## Step 3 — Analyze Intent

Before modifying files, determine intent priority:

1. **Explicit request** — what the user literally asked for (must-do)
2. **Spec gaps** — run `validate.sh`, review against [assets/checklist.md](../assets/checklist.md) (should-do)
3. **Tooling constraints** — check compatibility field and platform support (consider)
4. **Minimal change** — prefer the smallest edit set that fully satisfies 1-3

If conflict exists between "minimal change" and "functional completeness", choose completeness and summarize why.

---

## Step 4 — Backfill Missing Files

If the skill is missing standard files for its tier, run the upgrade script:

```bash
# Preview what would be created
bash .claude/skills/skill-maker/scripts/upgrade.sh "<name>" --dry-run

# Apply
bash .claude/skills/skill-maker/scripts/upgrade.sh "<name>"
```

---

## Step 5 — Apply Changes

Edit the SKILL.md and/or supporting files. Bump the version in metadata:

- **Patch** (0.1.0 → 0.1.1): Bug fixes, typos, minor adjustments
- **Minor** (0.1.0 → 0.2.0): New features, added files, workflow changes
- **Major** (0.1.0 → 1.0.0): Breaking changes, restructuring, tier change
- **First stable** (0.x.y → 1.0.0): Only after the skill has been tested and validated in real use

---

## Step 6 — Register in CLAUDE.md

If the update changes the skill's invokability or name, check if CLAUDE.md needs updating.

---

## Step 7 — Self-Audit

Quick quality check against [assets/checklist.md](../assets/checklist.md). Focus on the dimensions affected by the change.

---

## Step 8 — Validate (Final Gate)

```bash
bash .claude/skills/skill-maker/scripts/validate.sh ".claude/skills/<name>"
```

Review output and fix any issues. The skill is done when validation passes and self-audit is clean.
