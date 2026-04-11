#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
init-plan.sh — Initialize a development plan from the project template.

Usage:
  bash scripts/init-plan.sh [plan-path]

Arguments:
  plan-path   Path to create the plan file. Defaults to ".tmp/state/plan.md".

Behavior:
  1. Creates the target directory if it doesn't exist.
  2. Copies the plan template from assets/plan-template.md.
  3. If the target file already exists, exits with a warning (no overwrite).

Output:
  JSON to stdout:
  {
    "created": true|false,
    "path": "<absolute-path>",
    "message": "...",
    "warnings": [...]
  }
  Diagnostics to stderr.

Exit codes:
  0  Success
  1  Fatal error
  2  Invalid arguments
HELP
  exit 0
}

[[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && show_help

PLAN_PATH="${1:-.tmp/state/plan.md}"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="${SKILL_DIR}/assets/plan-template.md"
WARNINGS="[]"

add_warning() {
  WARNINGS=$(echo "$WARNINGS" | jq --arg w "$1" '. + [$w]')
}

# Check template exists
if [[ ! -f "$TEMPLATE" ]]; then
  echo "Error: Plan template not found at ${TEMPLATE}" >&2
  jq -n --arg path "$PLAN_PATH" '{created: false, path: $path, message: "Template not found", warnings: []}'
  exit 1
fi

# Check if plan already exists
if [[ -f "$PLAN_PATH" ]]; then
  echo "Warning: Plan already exists at ${PLAN_PATH}. Use update operation instead." >&2
  ABS_PATH="$(cd "$(dirname "$PLAN_PATH")" && pwd)/$(basename "$PLAN_PATH")"
  jq -n --arg path "$ABS_PATH" '{created: false, path: $path, message: "Plan already exists. Use update operation instead.", warnings: ["Plan file already exists — not overwriting."]}'
  exit 0
fi

# Create directory and copy template
TARGET_DIR="$(dirname "$PLAN_PATH")"
mkdir -p "$TARGET_DIR"
cp "$TEMPLATE" "$PLAN_PATH"

ABS_PATH="$(cd "$(dirname "$PLAN_PATH")" && pwd)/$(basename "$PLAN_PATH")"
echo "Created plan at ${ABS_PATH}" >&2

jq -n --arg path "$ABS_PATH" --argjson warnings "$WARNINGS" \
  '{created: true, path: $path, message: "Plan initialized from template", warnings: $warnings}'
