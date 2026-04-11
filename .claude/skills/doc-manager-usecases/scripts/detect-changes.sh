#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
detect-changes.sh — Find what changed since a use-cases doc was last modified.

Usage:
  bash scripts/detect-changes.sh <doc-path> [--scope <path>]

Arguments:
  doc-path   Path to the use-cases doc to check.
  --scope    Override the auto-detected scope directory. By default:
             - project doc → docs/designs/ and src/ (broad)
             - service doc → src/<service>/ (narrow)

Behavior:
  1. Finds the last commit that modified the use-cases doc.
  2. Lists all files changed since that commit within the scope.
  3. Categorizes changes by type (added, modified, deleted).

Output:
  JSON to stdout:
  {
    "doc_path": "<path>",
    "type": "project|service",
    "service": "<service-name>|null",
    "last_modified_commit": "<sha>",
    "last_modified_date": "<date>",
    "last_modified_message": "<commit message>",
    "scope": "<scope-path>",
    "changes": {
      "added": ["file1", "file2"],
      "modified": ["file3"],
      "deleted": ["file4"]
    },
    "summary": {
      "total": N,
      "added": N,
      "modified": N,
      "deleted": N
    },
    "warnings": [...]
  }
  Diagnostics to stderr.

Exit codes:
  0  Success
  1  Fatal error (no git history)
  2  Invalid arguments
HELP
  exit 0
}

[[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && show_help

DOC_PATH="${1:-}"
SCOPE_OVERRIDE=""

if [[ -z "$DOC_PATH" ]]; then
  echo "Error: doc-path is required." >&2
  echo "Usage: bash scripts/detect-changes.sh <doc-path> [--scope <path>]" >&2
  exit 2
fi

# Parse optional --scope
shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope) SCOPE_OVERRIDE="${2:-}"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

WARNINGS="[]"

add_warning() {
  WARNINGS=$(echo "$WARNINGS" | jq --arg w "$1" '. + [$w]')
}

# --- Classification ---
classify_doc() {
  local path="$1"
  path="${path#./}"
  if [[ "$path" == "docs/designs/use-cases/use-cases.md" || "$path" == "docs/designs/use-cases/use_cases.md" ]]; then
    echo "project"
  elif [[ "$path" =~ ^docs/designs/use-cases/(.+)-use[-_]cases\.md$ ]]; then
    echo "service"
  else
    echo "project"
  fi
}

extract_service() {
  local path="$1"
  path="${path#./}"
  if [[ "$path" =~ ^docs/designs/use-cases/(.+)-use[-_]cases\.md$ ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    echo ""
  fi
}

TYPE=$(classify_doc "$DOC_PATH")
SERVICE=$(extract_service "$DOC_PATH")
SERVICE_JSON="${SERVICE:-null}"

# --- Scope detection ---
if [[ -n "$SCOPE_OVERRIDE" ]]; then
  SCOPE="$SCOPE_OVERRIDE"
else
  if [[ "$TYPE" == "project" ]]; then
    SCOPE="."
  else
    SCOPE="src/${SERVICE}"
    if [[ ! -d "$SCOPE" ]]; then
      add_warning "Service directory ${SCOPE} not found. Falling back to project-wide scope."
      SCOPE="."
    fi
  fi
fi

# --- Check file exists ---
if [[ ! -f "$DOC_PATH" ]]; then
  echo "Error: Use-cases doc not found at ${DOC_PATH}" >&2
  jq -n --arg path "$DOC_PATH" --arg type "$TYPE" --arg svc "$SERVICE_JSON" \
    '{doc_path: $path, type: $type, service: (if $svc == "null" then null else $svc end), last_modified_commit: null, last_modified_date: null, last_modified_message: null, scope: null, changes: {added:[], modified:[], deleted:[]}, summary: {total:0, added:0, modified:0, deleted:0}, warnings: ["Use-cases doc not found"]}'
  exit 1
fi

# --- Find last commit that modified the doc ---
LAST_COMMIT=$(git log -1 --format="%H" -- "$DOC_PATH" 2>/dev/null || true)

if [[ -z "$LAST_COMMIT" ]]; then
  add_warning "No git history found for ${DOC_PATH}. Listing all tracked files in scope instead."
  echo "Warning: No git history for ${DOC_PATH}. Falling back to full scope listing." >&2

  ADDED_FILES=$(git ls-files "$SCOPE" 2>/dev/null | grep -v "^${DOC_PATH}$" | jq -R . | jq -s .)
  TOTAL=$(echo "$ADDED_FILES" | jq 'length')

  jq -n \
    --arg path "$DOC_PATH" --arg type "$TYPE" --arg svc "$SERVICE_JSON" --arg scope "$SCOPE" \
    --argjson added "$ADDED_FILES" \
    --argjson total "$TOTAL" \
    --argjson warnings "$WARNINGS" \
    '{
      doc_path: $path,
      type: $type,
      service: (if $svc == "null" then null else $svc end),
      last_modified_commit: null,
      last_modified_date: null,
      last_modified_message: null,
      scope: $scope,
      changes: { added: $added, modified: [], deleted: [] },
      summary: { total: $total, added: $total, modified: 0, deleted: 0 },
      warnings: $warnings
    }'
  exit 0
fi

LAST_DATE=$(git log -1 --format="%ai" "$LAST_COMMIT" 2>/dev/null)
LAST_MSG=$(git log -1 --format="%s" "$LAST_COMMIT" 2>/dev/null)

echo "Last modified: ${LAST_COMMIT:0:8} (${LAST_DATE}) — ${LAST_MSG}" >&2

# --- Find changes since that commit ---
ADDED=$(git diff --name-only --diff-filter=A "${LAST_COMMIT}..HEAD" -- "$SCOPE" 2>/dev/null | grep -v "^${DOC_PATH}$" || true)
MODIFIED=$(git diff --name-only --diff-filter=M "${LAST_COMMIT}..HEAD" -- "$SCOPE" 2>/dev/null | grep -v "^${DOC_PATH}$" || true)
DELETED=$(git diff --name-only --diff-filter=D "${LAST_COMMIT}..HEAD" -- "$SCOPE" 2>/dev/null | grep -v "^${DOC_PATH}$" || true)

# Convert to JSON arrays safely (handle empty strings)
to_json_array() { if [[ -z "$1" ]]; then echo "[]"; else echo "$1" | jq -R . | jq -s .; fi; }
ADDED_JSON=$(to_json_array "$ADDED")
MODIFIED_JSON=$(to_json_array "$MODIFIED")
DELETED_JSON=$(to_json_array "$DELETED")

COUNT_A=$(echo "$ADDED_JSON" | jq 'length')
COUNT_M=$(echo "$MODIFIED_JSON" | jq 'length')
COUNT_D=$(echo "$DELETED_JSON" | jq 'length')
COUNT_TOTAL=$((COUNT_A + COUNT_M + COUNT_D))

echo "Changes since last doc update: ${COUNT_TOTAL} files (${COUNT_A} added, ${COUNT_M} modified, ${COUNT_D} deleted)" >&2

jq -n \
  --arg path "$DOC_PATH" --arg type "$TYPE" --arg svc "$SERVICE_JSON" --arg scope "$SCOPE" \
  --arg commit "$LAST_COMMIT" --arg date "$LAST_DATE" --arg msg "$LAST_MSG" \
  --argjson added "$ADDED_JSON" --argjson modified "$MODIFIED_JSON" --argjson deleted "$DELETED_JSON" \
  --argjson ca "$COUNT_A" --argjson cm "$COUNT_M" --argjson cd "$COUNT_D" --argjson ct "$COUNT_TOTAL" \
  --argjson warnings "$WARNINGS" \
  '{
    doc_path: $path,
    type: $type,
    service: (if $svc == "null" then null else $svc end),
    last_modified_commit: $commit,
    last_modified_date: $date,
    last_modified_message: $msg,
    scope: $scope,
    changes: { added: $added, modified: $modified, deleted: $deleted },
    summary: { total: $ct, added: $ca, modified: $cm, deleted: $cd },
    warnings: $warnings
  }'
