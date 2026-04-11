#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
scaffold.sh — Create a new skill directory by hydrating assets/skill-template.md.

Usage:
  bash scripts/scaffold.sh <skill-name> [purpose] [--full] [--quick]
    [--description "..."] [--argument-hint "..."]

Arguments:
  skill-name        Required. kebab-case name (e.g., "my-new-skill").
  purpose           Optional. One of: meta-skill, development, admin, utility, other.
                    Defaults to "other".

Flags:
  --full            Create starter files in references/ and assets/.
  --quick           Minimal scaffold: only scripts/ dir, no references/ or assets/.
  --description     Provide the skill description directly (skips TODO).
--argument-hint   Descriptive string shown as autocomplete hint in the agent UI.
                      Must explain what to pass, not just name a placeholder.
                      e.g., "Give the pull request number" not "<pr-number>".

Creates:
  .claude/skills/<skill-name>/
  ├── SKILL.md          (hydrated from assets/skill-template.md)
  ├── references/       (--full: with starter files; --quick: skipped)
  ├── scripts/          (always created)
  └── assets/           (--full: created; --quick: skipped)

Exit codes:
  0  Success
  1  Invalid arguments or name collision
HELP
  exit 0
}

[[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && show_help

# --- Parse arguments ---

SKILL_NAME=""
PURPOSE="other"
FULL_MODE=false
QUICK_MODE=false
DESCRIPTION=""
ARGUMENT_HINT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --full) FULL_MODE=true; shift ;;
    --quick) QUICK_MODE=true; shift ;;
    --description)
      DESCRIPTION="${2:-}"
      shift 2 || { echo "Error: --description requires a value." >&2; exit 1; }
      ;;
    --argument-hint)
      ARGUMENT_HINT="${2:-}"
      shift 2 || { echo "Error: --argument-hint requires a value." >&2; exit 1; }
      ;;
    -*)
      echo "Error: unknown flag: $1" >&2
      exit 1
      ;;
    *)
      if [[ -z "$SKILL_NAME" ]]; then
        SKILL_NAME="$1"
      elif [[ "$PURPOSE" == "other" ]]; then
        PURPOSE="$1"
      fi
      shift
      ;;
  esac
done

ALLOWED_PURPOSES=("meta-skill" "development" "admin" "utility" "other")
KEBAB_REGEX='^[a-z0-9]+(-[a-z0-9]+)*$'

# --- Validation ---

if [[ -z "$SKILL_NAME" ]]; then
  echo "Error: skill-name is required."
  echo "Usage: bash scripts/scaffold.sh <skill-name> [purpose] [--full] [--quick]"
  exit 1
fi

if $FULL_MODE && $QUICK_MODE; then
  echo "Error: --full and --quick are mutually exclusive."
  exit 1
fi

if ! [[ "$SKILL_NAME" =~ $KEBAB_REGEX ]]; then
  echo "Error: skill-name must be kebab-case (lowercase alphanumeric + hyphens, no leading/trailing/consecutive hyphens)."
  echo "  Received: $SKILL_NAME"
  echo "  Hint: e.g. \"pr-triage\", not \"PR Triage\" or \"pr_triage\""
  exit 1
fi

if [[ ${#SKILL_NAME} -gt 64 ]]; then
  echo "Error: skill-name must be 64 characters or fewer."
  echo "  Received: ${#SKILL_NAME} characters"
  exit 1
fi

purpose_valid=false
for p in "${ALLOWED_PURPOSES[@]}"; do
  [[ "$PURPOSE" == "$p" ]] && purpose_valid=true && break
done
if ! $purpose_valid; then
  echo "Error: purpose must be one of: ${ALLOWED_PURPOSES[*]}"
  echo "  Received: $PURPOSE"
  echo "  Hint: purpose is the second positional arg. Use --description for the skill description."
  exit 1
fi

# --- Locate paths ---

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAKER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_ROOT="$(cd "$MAKER_ROOT/.." && pwd)"
TARGET_DIR="$SKILLS_ROOT/$SKILL_NAME"
TEMPLATE_FILE="$MAKER_ROOT/assets/skill-template.md"

if [[ -d "$TARGET_DIR" ]]; then
  echo "Error: skill directory already exists: $TARGET_DIR"
  echo "  Use update mode or 'bash scripts/upgrade.sh $SKILL_NAME' instead."
  exit 1
fi

if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo "Error: template not found: $TEMPLATE_FILE"
  exit 1
fi

# --- Create directories ---

mkdir -p "$TARGET_DIR/scripts"

if ! $QUICK_MODE; then
  mkdir -p "$TARGET_DIR/references"
  mkdir -p "$TARGET_DIR/assets"
fi

# --- Hydrate template ---

# Convert skill-name to Title Case for heading
SKILL_TITLE=$(echo "$SKILL_NAME" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')

# Set defaults for known placeholders
[[ -z "$DESCRIPTION" ]] && DESCRIPTION="TODO — describe what this skill does and when to use it."

# Read template and substitute known values
CONTENT=$(cat "$TEMPLATE_FILE")

# Replace known placeholders
CONTENT=$(echo "$CONTENT" | sed "s|{{SKILL_NAME}}|${SKILL_NAME}|g")
CONTENT=$(echo "$CONTENT" | sed "s|{{SKILL_TITLE}}|${SKILL_TITLE}|g")
CONTENT=$(echo "$CONTENT" | sed "s|{{DESCRIPTION}}|${DESCRIPTION}|g")
CONTENT=$(echo "$CONTENT" | sed "s|{{COMPATIBILITY}}|Designed for Claude Code with shell access.|g")
CONTENT=$(echo "$CONTENT" | sed "s|{{AUTHOR}}|nebula-aurora|g")
CONTENT=$(echo "$CONTENT" | sed "s|{{VERSION}}|0.1.0|g")
CONTENT=$(echo "$CONTENT" | sed "s|{{PURPOSE}}|${PURPOSE}|g")
CONTENT=$(echo "$CONTENT" | sed "s|{{TYPE}}|P1|g")
CONTENT=$(echo "$CONTENT" | sed "s|{{DISABLE_MODEL_INVOCATION}}|false|g")
CONTENT=$(echo "$CONTENT" | sed "s|{{USER_invocable}}|true|g")

# Handle argument-hint: include line or remove it
if [[ -n "$ARGUMENT_HINT" ]]; then
  CONTENT=$(echo "$CONTENT" | sed "s|{{ARGUMENT_HINT_LINE}}|argument-hint: ${ARGUMENT_HINT}|g")
else
  CONTENT=$(echo "$CONTENT" | sed '/{{ARGUMENT_HINT_LINE}}/d')
fi

# Replace remaining {{PLACEHOLDER}} with TODO markers
CONTENT=$(echo "$CONTENT" | sed 's|{{PURPOSE_DESCRIPTION}}|TODO — one sentence describing the skill purpose.|g')
CONTENT=$(echo "$CONTENT" | sed 's|{{TRIGGER_1}}|TODO — first trigger condition|g')
CONTENT=$(echo "$CONTENT" | sed 's|{{TRIGGER_2}}|TODO — second trigger condition|g')
CONTENT=$(echo "$CONTENT" | sed 's|{{STEP_1}}|TODO — step 1|g')
CONTENT=$(echo "$CONTENT" | sed 's|{{STEP_2}}|TODO — step 2|g')
CONTENT=$(echo "$CONTENT" | sed 's|{{STEP_3}}|TODO — step 3|g')
CONTENT=$(echo "$CONTENT" | sed 's|{{EXAMPLE_1}}|TODO — example input 1|g')
CONTENT=$(echo "$CONTENT" | sed 's|{{EXAMPLE_2}}|TODO — example input 2|g')
CONTENT=$(echo "$CONTENT" | sed 's|{{EDGE_CASE_1}}|TODO — edge case 1|g')
CONTENT=$(echo "$CONTENT" | sed 's|{{FALLBACK_1}}|TODO — fallback behavior|g')
CONTENT=$(echo "$CONTENT" | sed 's|{{EDGE_CASE_2}}|TODO — edge case 2|g')
CONTENT=$(echo "$CONTENT" | sed 's|{{FALLBACK_2}}|TODO — fallback behavior|g')
CONTENT=$(echo "$CONTENT" | sed 's|{{REF_FILE}}|TODO|g')
CONTENT=$(echo "$CONTENT" | sed 's|{{REF_DESCRIPTION}}|TODO — reference description|g')
CONTENT=$(echo "$CONTENT" | sed 's|{{SCRIPT_FILE}}|TODO|g')
CONTENT=$(echo "$CONTENT" | sed 's|{{SCRIPT_DESCRIPTION}}|TODO — script description|g')
CONTENT=$(echo "$CONTENT" | sed 's|{{ASSET_FILE}}|TODO|g')
CONTENT=$(echo "$CONTENT" | sed 's|{{ASSET_DESCRIPTION}}|TODO — asset description|g')

# Write SKILL.md
echo "$CONTENT" > "$TARGET_DIR/SKILL.md"

# --- Full mode: create starter files ---

if $FULL_MODE; then
  cat > "$TARGET_DIR/references/REFERENCE.md" << EOF
# ${SKILL_TITLE} Reference

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
EOF

  cat > "$TARGET_DIR/references/FORMS.md" << EOF
# ${SKILL_TITLE} Forms

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
EOF
fi

# --- Output ---

echo "Created skill: $TARGET_DIR"
echo "  SKILL.md       (hydrated from skill-template.md — fill in TODO sections)"
echo "  scripts/       (add executable scripts as needed)"

if $QUICK_MODE; then
  echo ""
  echo "Quick mode: references/ and assets/ were skipped."
else
  echo "  references/    (add supplementary docs as needed)"
  echo "  assets/        (add templates, data, images as needed)"
fi

if $FULL_MODE; then
  echo ""
  echo "Full mode: also created starter files:"
  echo "  references/REFERENCE.md"
  echo "  references/FORMS.md"
fi

echo ""
echo "Next: Read the scaffolded SKILL.md before writing to it (tool requirement)."
