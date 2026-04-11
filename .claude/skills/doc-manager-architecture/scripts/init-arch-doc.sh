#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
init-arch-doc.sh — Classify input and copy the correct architecture template.

Usage:
  bash scripts/init-arch-doc.sh <input>

Arguments:
  input   A service name (e.g., "ctx-svc"), "project"/"architecture.md", or a full
          path like "docs/designs/architecture/ctx-svc-architecture.md".

Behavior:
  1. Classifies the input as project or service type.
  2. Resolves the output path under docs/designs/architecture/.
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
  echo "Usage: bash scripts/init-arch-doc.sh <input>" >&2
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

  # Full path to project architecture
  if [[ "$input" == "docs/designs/architecture/architecture.md" ]]; then
    echo "project"
  # Full path to service architecture
  elif [[ "$input" =~ ^docs/designs/architecture/(.+)-architecture\.md$ ]]; then
    echo "service"
  # Keywords for project
  elif [[ "$input" == "project" || "$input" == "architecture.md" || "$input" == "architecture" ]]; then
    echo "project"
  # Anything else is a service name
  else
    echo "service"
  fi
}

extract_service_name() {
  local input="$1"
  input="${input#./}"

  if [[ "$input" =~ ^docs/designs/architecture/(.+)-architecture\.md$ ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    # Treat as a service name directly
    echo "$input"
  fi
}

TYPE=$(classify_input "$INPUT")

if [[ "$TYPE" == "project" ]]; then
  OUTPUT_PATH="docs/designs/architecture/architecture.md"
  TEMPLATE="${SKILL_DIR}/assets/project-architecture-template.md"
  SERVICE_NAME="null"
else
  SERVICE_NAME=$(extract_service_name "$INPUT")
  OUTPUT_PATH="docs/designs/architecture/${SERVICE_NAME}-architecture.md"
  TEMPLATE="${SKILL_DIR}/assets/service-architecture-template.md"

  # Validate service exists
  if [[ ! -d "src/${SERVICE_NAME}" ]]; then
    # Try with -svc suffix
    if [[ ! -d "src/${SERVICE_NAME}-svc" ]]; then
      add_warning "Service directory src/${SERVICE_NAME}/ not found. Doc will be created but may need manual context."
      echo "Warning: src/${SERVICE_NAME}/ not found." >&2
    else
      SERVICE_NAME="${SERVICE_NAME}-svc"
      OUTPUT_PATH="docs/designs/architecture/${SERVICE_NAME}-architecture.md"
      echo "Resolved to src/${SERVICE_NAME}/" >&2
    fi
  fi
fi

TEMPLATE_NAME=$(basename "$TEMPLATE")

# Check template exists
if [[ ! -f "$TEMPLATE" ]]; then
  echo "Error: Template not found at ${TEMPLATE}" >&2
  jq -n --arg path "$OUTPUT_PATH" --arg type "$TYPE" --arg svc "$SERVICE_NAME" --arg tpl "$TEMPLATE_NAME" \
    '{created: false, path: $path, type: $type, service: $svc, template: $tpl, message: "Template not found", warnings: []}'
  exit 1
fi

# Check if doc already exists
if [[ -f "$OUTPUT_PATH" ]]; then
  echo "Warning: Architecture doc already exists at ${OUTPUT_PATH}. Use update mode instead." >&2
  ABS_PATH="$(cd "$(dirname "$OUTPUT_PATH")" && pwd)/$(basename "$OUTPUT_PATH")"
  jq -n --arg path "$ABS_PATH" --arg type "$TYPE" --arg svc "$SERVICE_NAME" --arg tpl "$TEMPLATE_NAME" \
    '{created: false, path: $path, type: $type, service: (if $svc == "null" then null else $svc end), template: $tpl, message: "Architecture doc already exists. Use update mode instead.", warnings: ["File already exists — not overwriting."]}'
  exit 0
fi

# Create directory and copy template
TARGET_DIR="$(dirname "$OUTPUT_PATH")"
mkdir -p "$TARGET_DIR"
cp "$TEMPLATE" "$OUTPUT_PATH"

ABS_PATH="$(cd "$(dirname "$OUTPUT_PATH")" && pwd)/$(basename "$OUTPUT_PATH")"
echo "Created ${TYPE} architecture doc at ${ABS_PATH} from ${TEMPLATE_NAME}" >&2

jq -n --arg path "$ABS_PATH" --arg type "$TYPE" --arg svc "$SERVICE_NAME" --arg tpl "$TEMPLATE_NAME" --argjson warnings "$WARNINGS" \
  '{created: true, path: $path, type: $type, service: (if $svc == "null" then null else $svc end), template: $tpl, message: "Architecture doc initialized from template", warnings: $warnings}'
