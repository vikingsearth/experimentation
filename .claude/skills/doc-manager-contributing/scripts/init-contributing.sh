#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
init-contributing.sh — Copy the CONTRIBUTING.md template to the project root.

Usage:
  bash scripts/init-contributing.sh [--force]

Options:
  --force   Overwrite existing CONTRIBUTING.md (default: refuse to overwrite).

Behavior:
  1. Checks if ./CONTRIBUTING.md already exists.
  2. If it does not exist (or --force), copies the template.
  3. Creates no parent directories (target is always project root).

Output:
  JSON to stdout:
  {
    "created": true|false,
    "path": "<absolute-path>",
    "template": "contributing-template.md",
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

FORCE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=true; shift ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="${SKILL_DIR}/assets/contributing-template.md"
TARGET="CONTRIBUTING.md"
WARNINGS="[]"

add_warning() {
  WARNINGS=$(echo "$WARNINGS" | jq --arg w "$1" '. + [$w]')
}

# Check template exists
if [[ ! -f "$TEMPLATE" ]]; then
  echo "Error: Template not found at ${TEMPLATE}" >&2
  jq -n --arg tpl "contributing-template.md" \
    '{created: false, path: null, template: $tpl, message: "Template not found", warnings: []}'
  exit 1
fi

# Check if CONTRIBUTING.md already exists
if [[ -f "$TARGET" && "$FORCE" != "true" ]]; then
  echo "Warning: CONTRIBUTING.md already exists. Use update mode or --force to overwrite." >&2
  ABS_PATH="$(pwd)/${TARGET}"
  jq -n --arg path "$ABS_PATH" --arg tpl "contributing-template.md" \
    '{created: false, path: $path, template: $tpl, message: "CONTRIBUTING.md already exists. Use update mode or --force to overwrite.", warnings: ["File already exists — not overwriting."]}'
  exit 0
fi

if [[ -f "$TARGET" && "$FORCE" == "true" ]]; then
  add_warning "Overwriting existing CONTRIBUTING.md (--force specified)."
  echo "Warning: Overwriting existing CONTRIBUTING.md" >&2
fi

cp "$TEMPLATE" "$TARGET"
ABS_PATH="$(pwd)/${TARGET}"
echo "Created CONTRIBUTING.md from template" >&2

jq -n --arg path "$ABS_PATH" --arg tpl "contributing-template.md" \
  --argjson warnings "$WARNINGS" \
  '{created: true, path: $path, template: $tpl, message: "CONTRIBUTING.md created from template", warnings: $warnings}'
