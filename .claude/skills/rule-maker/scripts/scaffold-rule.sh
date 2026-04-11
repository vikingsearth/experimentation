#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
scaffold-rule.sh — Create a .claude/rules/ rule file from template.

Usage:
  bash scripts/scaffold-rule.sh <name> [--paths <glob>...] [--subdir <dir>]

Arguments:
  name        Rule filename without extension (e.g., "effect-ts", "api-design").
              Will be created as .claude/rules/<name>.md (or .claude/rules/<subdir>/<name>.md).

Options:
  --paths     One or more glob patterns for path-scoped rules. Each pattern is a
              separate argument after --paths. Omit for unconditional rules.
  --subdir    Subdirectory under .claude/rules/ (e.g., "frontend", "backend").
              Created if it doesn't exist.

Behavior:
  1. Creates .claude/rules/ directory if needed.
  2. Creates subdirectory if --subdir is specified.
  3. Copies the rule template to the target path.
  4. Injects paths frontmatter if --paths is specified.
  5. If the target already exists, exits without overwriting.

Output:
  JSON to stdout:
  {
    "created": true|false,
    "path": "<absolute-path>",
    "name": "<rule-name>",
    "subdir": "<subdir>|null",
    "has_paths": true|false,
    "paths": ["glob1", "glob2"],
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

NAME="${1:-}"
if [[ -z "$NAME" ]]; then
  echo "Error: name is required." >&2
  echo "Usage: bash scripts/scaffold-rule.sh <name> [--paths <glob>...] [--subdir <dir>]" >&2
  exit 2
fi
shift

SUBDIR=""
PATHS=()
WARNINGS="[]"

add_warning() {
  WARNINGS=$(echo "$WARNINGS" | jq --arg w "$1" '. + [$w]')
}

# Parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --subdir)
      SUBDIR="${2:-}"
      if [[ -z "$SUBDIR" ]]; then
        echo "Error: --subdir requires a value." >&2
        exit 2
      fi
      shift 2
      ;;
    --paths)
      shift
      while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
        PATHS+=("$1")
        shift
      done
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 2
      ;;
  esac
done

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="${SKILL_DIR}/assets/rule-template.md"

# Validate name (kebab-case, no extension)
if [[ ! "$NAME" =~ ^[a-z0-9]+(-[a-z0-9]+)*(\.[a-z0-9]+(-[a-z0-9]+)*)*$ ]]; then
  echo "Error: name must be kebab-case (lowercase alphanumeric + hyphens). Got: ${NAME}" >&2
  exit 2
fi

# Strip .md if user included it
NAME="${NAME%.md}"

# Build target path
RULES_DIR=".claude/rules"
if [[ -n "$SUBDIR" ]]; then
  TARGET_DIR="${RULES_DIR}/${SUBDIR}"
else
  TARGET_DIR="${RULES_DIR}"
fi
TARGET_PATH="${TARGET_DIR}/${NAME}.md"

# Check template exists
if [[ ! -f "$TEMPLATE" ]]; then
  echo "Error: Template not found at ${TEMPLATE}" >&2
  jq -n --arg name "$NAME" --arg tpl "rule-template.md" \
    '{created: false, path: null, name: $name, subdir: null, has_paths: false, paths: [], message: "Template not found", warnings: []}'
  exit 1
fi

# Check if rule already exists
if [[ -f "$TARGET_PATH" ]]; then
  echo "Warning: Rule already exists at ${TARGET_PATH}." >&2
  ABS_PATH="$(cd "$(dirname "$TARGET_PATH")" && pwd)/$(basename "$TARGET_PATH")"
  SUBDIR_JSON="${SUBDIR:-null}"
  if [[ ${#PATHS[@]} -gt 0 ]]; then
    PATHS_JSON=$(printf '%s\n' "${PATHS[@]}" | jq -R . | jq -s .)
    HAS_PATHS="true"
  else
    PATHS_JSON="[]"
    HAS_PATHS="false"
  fi
  jq -n --arg path "$ABS_PATH" --arg name "$NAME" --arg subdir "$SUBDIR_JSON" \
    --argjson has_paths "$HAS_PATHS" --argjson paths "$PATHS_JSON" \
    '{created: false, path: $path, name: $name, subdir: (if $subdir == "null" then null else $subdir end), has_paths: $has_paths, paths: $paths, message: "Rule file already exists. Update content or choose a different name.", warnings: ["File already exists — not overwriting."]}'
  exit 0
fi

# Create directories
mkdir -p "$TARGET_DIR"
echo "Ensured directory: ${TARGET_DIR}" >&2

# Build the rule file
if [[ ${#PATHS[@]} -gt 0 ]]; then
  # Build frontmatter with paths
  {
    echo "---"
    echo "paths:"
    for p in "${PATHS[@]}"; do
      echo "  - \"${p}\""
    done
    echo "---"
    echo ""
    cat "$TEMPLATE"
  } > "$TARGET_PATH"
  echo "Created rule with paths frontmatter: ${TARGET_PATH}" >&2
else
  # No frontmatter — unconditional rule
  cp "$TEMPLATE" "$TARGET_PATH"
  echo "Created unconditional rule: ${TARGET_PATH}" >&2
fi

ABS_PATH="$(cd "$(dirname "$TARGET_PATH")" && pwd)/$(basename "$TARGET_PATH")"
SUBDIR_JSON="${SUBDIR:-null}"
if [[ ${#PATHS[@]} -gt 0 ]]; then
  PATHS_JSON=$(printf '%s\n' "${PATHS[@]}" | jq -R . | jq -s .)
  HAS_PATHS="true"
else
  PATHS_JSON="[]"
  HAS_PATHS="false"
fi

jq -n --arg path "$ABS_PATH" --arg name "$NAME" --arg subdir "$SUBDIR_JSON" \
  --argjson has_paths "$HAS_PATHS" --argjson paths "$PATHS_JSON" \
  --argjson warnings "$WARNINGS" \
  '{created: true, path: $path, name: $name, subdir: (if $subdir == "null" then null else $subdir end), has_paths: $has_paths, paths: $paths, message: "Rule file created from template", warnings: $warnings}'
