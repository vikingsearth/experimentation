#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
init-usecases-doc.sh — Classify input and copy the correct use-cases template.

Usage:
  bash scripts/init-usecases-doc.sh <input>

Arguments:
  input   A service name (e.g., "ctx-svc"), "project"/"use-cases.md", or a full
          path like "docs/designs/use-cases/ctx-svc-use-cases.md".

Behavior:
  1. Classifies the input as project or service type.
  2. Resolves the output path under docs/designs/use-cases/.
  3. Copies the matching template to the target path.
  4. Creates parent directories if needed.
  5. If the target already exists, exits without overwriting.

Output:
  JSON to stdout:
  {
    "created": true|false,
    "path": "<absolute-path>",
    "type": "project|service",
    "service": "<service-name>|null",
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

INPUT="${1:-}"
if [[ -z "$INPUT" ]]; then
  echo "Error: input is required." >&2
  echo "Usage: bash scripts/init-usecases-doc.sh <input>" >&2
  exit 2
fi

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WARNINGS="[]"

add_warning() {
  WARNINGS=$(echo "$WARNINGS" | jq --arg w "$1" '. + [$w]')
}

# --- Classification ---
classify_input() {
  local input="$1"
  # Strip leading ./
  input="${input#./}"

  # Full path to project use-cases
  if [[ "$input" == "docs/designs/use-cases/use-cases.md" || "$input" == "docs/designs/use-cases/use_cases.md" ]]; then
    echo "project"
  # Full path to service use-cases
  elif [[ "$input" =~ ^docs/designs/use-cases/(.+)-use[-_]cases\.md$ ]]; then
    echo "service"
  # Keywords for project
  elif [[ "$input" == "project" || "$input" == "use-cases.md" || "$input" == "use-cases" || "$input" == "use_cases.md" || "$input" == "use_cases" ]]; then
    echo "project"
  # Anything else is a service name
  else
    echo "service"
  fi
}

extract_service_name() {
  local input="$1"
  input="${input#./}"

  if [[ "$input" =~ ^docs/designs/use-cases/(.+)-use[-_]cases\.md$ ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    # Treat as a service name directly
    echo "$input"
  fi
}

TYPE=$(classify_input "$INPUT")

if [[ "$TYPE" == "project" ]]; then
  OUTPUT_PATH="docs/designs/use-cases/use-cases.md"
  TEMPLATE="${SKILL_DIR}/assets/project-usecases-template.md"
  SERVICE_NAME="null"
else
  SERVICE_NAME=$(extract_service_name "$INPUT")
  OUTPUT_PATH="docs/designs/use-cases/${SERVICE_NAME}-use-cases.md"
  TEMPLATE="${SKILL_DIR}/assets/service-usecases-template.md"

  # Validate service exists
  if [[ ! -d "src/${SERVICE_NAME}" ]]; then
    # Try with -svc suffix
    if [[ ! -d "src/${SERVICE_NAME}-svc" ]]; then
      add_warning "Service directory src/${SERVICE_NAME}/ not found. Doc will be created but may need manual context."
      echo "Warning: src/${SERVICE_NAME}/ not found." >&2
    else
      SERVICE_NAME="${SERVICE_NAME}-svc"
      OUTPUT_PATH="docs/designs/use-cases/${SERVICE_NAME}-use-cases.md"
      echo "Resolved to src/${SERVICE_NAME}/" >&2
    fi
  fi
fi

TEMPLATE_NAME=$(basename "$TEMPLATE")

# Check template exists
if [[ ! -f "$TEMPLATE" ]]; then
  echo "Error: Template not found at ${TEMPLATE}" >&2
  jq -n --arg path "$OUTPUT_PATH" --arg type "$TYPE" --arg svc "$SERVICE_NAME" --arg tpl "$TEMPLATE_NAME" \
    '{created: false, path: $path, type: $type, service: (if $svc == "null" then null else $svc end), template: $tpl, message: "Template not found", warnings: []}'
  exit 1
fi

# Check if doc already exists
if [[ -f "$OUTPUT_PATH" ]]; then
  echo "Warning: Use-cases doc already exists at ${OUTPUT_PATH}. Use update mode instead." >&2
  ABS_PATH="$(cd "$(dirname "$OUTPUT_PATH")" && pwd)/$(basename "$OUTPUT_PATH")"
  jq -n --arg path "$ABS_PATH" --arg type "$TYPE" --arg svc "$SERVICE_NAME" --arg tpl "$TEMPLATE_NAME" \
    '{created: false, path: $path, type: $type, service: (if $svc == "null" then null else $svc end), template: $tpl, message: "Use-cases doc already exists. Use update mode instead.", warnings: ["File already exists — not overwriting."]}'
  exit 0
fi

# Create directory and copy template
TARGET_DIR="$(dirname "$OUTPUT_PATH")"
if [[ ! -d "$TARGET_DIR" ]]; then
  mkdir -p "$TARGET_DIR"
  echo "Created directory: ${TARGET_DIR}" >&2
fi

cp "$TEMPLATE" "$OUTPUT_PATH"
ABS_PATH="$(cd "$(dirname "$OUTPUT_PATH")" && pwd)/$(basename "$OUTPUT_PATH")"
echo "Created use-cases doc: ${OUTPUT_PATH}" >&2

jq -n --arg path "$ABS_PATH" --arg type "$TYPE" --arg svc "$SERVICE_NAME" --arg tpl "$TEMPLATE_NAME" \
  --argjson warnings "$WARNINGS" \
  '{created: true, path: $path, type: $type, service: (if $svc == "null" then null else $svc end), template: $tpl, message: "Use-cases doc created from template", warnings: $warnings}'
