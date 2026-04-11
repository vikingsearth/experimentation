#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
init-readme.sh — Classify a README path and copy the correct template.

Usage:
  bash scripts/init-readme.sh <readme-path>

Arguments:
  readme-path   Target path for the README file (e.g., "src/ctx-svc/README.md", "README.md", "docs/tools/README.md").

Behavior:
  1. Classifies the path as root, service, or generic.
  2. Copies the matching template to the target path.
  3. Creates parent directories if needed.
  4. If the target already exists, exits without overwriting.

Output:
  JSON to stdout:
  {
    "created": true|false,
    "path": "<absolute-path>",
    "type": "root|service|generic",
    "template": "<template-file-used>",
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

README_PATH="${1:-}"
if [[ -z "$README_PATH" ]]; then
  echo "Error: readme-path is required." >&2
  echo "Usage: bash scripts/init-readme.sh <readme-path>" >&2
  exit 2
fi

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: 'jq' is required but not installed." >&2
  exit 1
fi

WARNINGS="[]"

add_warning() {
  WARNINGS=$(echo "$WARNINGS" | jq --arg w "$1" '. + [$w]')
}

# --- Classification ---
classify_readme() {
  local path="$1"
  # Normalize: strip leading ./
  path="${path#./}"

  if [[ "$path" == "README.md" ]]; then
    echo "root"
  elif [[ "$path" =~ ^src/[^/]+/README\.md$ ]]; then
    echo "service"
  else
    echo "generic"
  fi
}

TYPE=$(classify_readme "$README_PATH")

# --- Template selection ---
case "$TYPE" in
  root)    TEMPLATE="${SKILL_DIR}/assets/root-readme-template.md" ;;
  service) TEMPLATE="${SKILL_DIR}/assets/service-readme-template.md" ;;
  generic) TEMPLATE="${SKILL_DIR}/assets/generic-readme-template.md" ;;
esac

TEMPLATE_NAME=$(basename "$TEMPLATE")

# Check template exists
if [[ ! -f "$TEMPLATE" ]]; then
  echo "Error: Template not found at ${TEMPLATE}" >&2
  jq -n --arg path "$README_PATH" --arg type "$TYPE" --arg tpl "$TEMPLATE_NAME" \
    '{created: false, path: $path, type: $type, template: $tpl, message: "Template not found", warnings: []}'
  exit 1
fi

# Check if README already exists
if [[ -f "$README_PATH" ]]; then
  echo "Warning: README already exists at ${README_PATH}. Use update mode instead." >&2
  ABS_PATH="$(cd "$(dirname "$README_PATH")" && pwd)/$(basename "$README_PATH")"
  jq -n --arg path "$ABS_PATH" --arg type "$TYPE" --arg tpl "$TEMPLATE_NAME" \
    '{created: false, path: $path, type: $type, template: $tpl, message: "README already exists. Use update mode instead.", warnings: ["File already exists — not overwriting."]}'
  exit 0
fi

# Create directory and copy template
TARGET_DIR="$(dirname "$README_PATH")"
mkdir -p "$TARGET_DIR"
cp "$TEMPLATE" "$README_PATH"

ABS_PATH="$(cd "$(dirname "$README_PATH")" && pwd)/$(basename "$README_PATH")"
echo "Created ${TYPE} README at ${ABS_PATH} from ${TEMPLATE_NAME}" >&2

jq -n --arg path "$ABS_PATH" --arg type "$TYPE" --arg tpl "$TEMPLATE_NAME" --argjson warnings "$WARNINGS" \
  '{created: true, path: $path, type: $type, template: $tpl, message: "README initialized from template", warnings: $warnings}'
