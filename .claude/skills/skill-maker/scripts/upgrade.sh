#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
upgrade.sh — Non-destructively upgrade an existing skill by backfilling missing files.

Usage:
  bash scripts/upgrade.sh <skill-name> [--dry-run]

Arguments:
  skill-name   Required. Name of an existing skill in .claude/skills/.
  --dry-run    Optional. Report what would be created without writing files.

Behavior:
  - Ensures subdirectories exist (references/, scripts/, assets/)
  - Creates missing standard files from templates (skips existing files)
  - Runs validate.sh after upgrade (unless --dry-run)

Exit codes:
  0  Success
  1  Skill not found or validation failed
  2  Invalid arguments
HELP
  exit 0
}

[[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && show_help

SKILL_NAME="${1:-}"
DRY_RUN=false

# Check for --dry-run in any position
for arg in "$@"; do
  [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
done

# Remove --dry-run from SKILL_NAME if it was first arg
[[ "$SKILL_NAME" == "--dry-run" ]] && SKILL_NAME="${2:-}"

if [[ -z "$SKILL_NAME" ]]; then
  echo "Error: skill-name is required."
  echo "Usage: bash scripts/upgrade.sh <skill-name> [--dry-run]"
  exit 2
fi

# --- Locate skill ---

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAKER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_ROOT="$(cd "$MAKER_ROOT/.." && pwd)"
TARGET_DIR="$SKILLS_ROOT/$SKILL_NAME"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Error: skill directory not found: $TARGET_DIR"
  echo "  Use 'bash scripts/scaffold.sh $SKILL_NAME' to create a new skill."
  exit 1
fi

# --- Template hydration helper ---

hydrate() {
  local template_content="$1"
  echo "$template_content" \
    | sed "s/{{SKILL_NAME}}/$SKILL_NAME/g" \
    | sed "s/{{DATE}}/$(date -u +%Y-%m-%d)/g"
}

# --- Standard files to backfill ---

CREATED=0
SKIPPED=0

ensure_dir() {
  local dir="$1"
  if [[ ! -d "$TARGET_DIR/$dir" ]]; then
    if $DRY_RUN; then
      echo "Would create directory: $dir/"
    else
      mkdir -p "$TARGET_DIR/$dir"
      echo "Created directory: $dir/"
    fi
  fi
}

backfill_file() {
  local file_path="$1"
  local content="$2"

  if [[ -f "$TARGET_DIR/$file_path" ]]; then
    echo "Skipped (exists): $file_path"
    SKIPPED=$((SKIPPED + 1))
  else
    if $DRY_RUN; then
      echo "Would create: $file_path"
    else
      echo "$content" > "$TARGET_DIR/$file_path"
      echo "Created: $file_path"
    fi
    CREATED=$((CREATED + 1))
  fi
}

# --- Ensure directories ---

ensure_dir "references"
ensure_dir "scripts"
ensure_dir "assets"

# --- Backfill standard files ---

backfill_file "references/REFERENCE.md" "$(hydrate "# ${SKILL_NAME} Reference

## Context

Capture domain context, assumptions, and boundaries for this skill.

## Rules

- Rule 1
- Rule 2

## Quality Checklist

- [ ] Output answers user intent
- [ ] Output is actionable
- [ ] Trade-offs are explicit

## Examples

| Input | Expected Output |
|-------|-----------------|
| Example input 1 | Expected shape |
")"

backfill_file "references/FORMS.md" "$(hydrate "# ${SKILL_NAME} Forms

## Intake Form

\`\`\`markdown
Objective:
Audience:
Constraints:
Definition of done:
\`\`\`

## Review Form

\`\`\`markdown
What changed:
Assumptions made:
Validation performed:
Open questions:
\`\`\`
")"

# --- Summary ---

if $DRY_RUN; then
  echo ""
  echo "Dry run complete for: $SKILL_NAME"
  echo "  Would create: $CREATED file(s)"
  echo "  Would skip: $SKIPPED file(s)"
else
  echo ""
  echo "Upgrade complete for: $SKILL_NAME"
  echo "  Created: $CREATED, Skipped: $SKIPPED"

  # Run validation
  echo ""
  echo "Running validation..."
  bash "$MAKER_ROOT/scripts/validate.sh" "$TARGET_DIR" || true
fi
