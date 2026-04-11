#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
init-topic.sh — Create a new discussion topic directory with scratchpad from template.

Usage:
  bash scripts/init-topic.sh <topic-slug>

Arguments:
  topic-slug    Required. Kebab-case name (e.g., "auth-redesign", "memory-v2").
                1-64 chars, lowercase alphanumeric + hyphens.

Creates:
  .tmp/discussions/<topic-slug>/
  ├── scratchpad.md    (from assets/scratchpad-template.md)
  ├── docs/
  └── archive/

Output (stdout):
  JSON object: { "topic", "path", "created" }

Exit codes:
  0  Success
  1  Invalid arguments or topic already exists
HELP
  exit 0
}

[[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && show_help

# --- Parse arguments ---

TOPIC_SLUG="${1:-}"
KEBAB_REGEX='^[a-z0-9]+(-[a-z0-9]+)*$'

if [[ -z "$TOPIC_SLUG" ]]; then
  echo '{"error": "topic-slug is required"}' >&2
  exit 1
fi

if ! [[ "$TOPIC_SLUG" =~ $KEBAB_REGEX ]]; then
  echo "{\"error\": \"topic-slug must be kebab-case\", \"received\": \"$TOPIC_SLUG\"}" >&2
  exit 1
fi

if [[ ${#TOPIC_SLUG} -gt 64 ]]; then
  echo "{\"error\": \"topic-slug must be 64 characters or fewer\", \"length\": ${#TOPIC_SLUG}}" >&2
  exit 1
fi

# --- Locate paths ---

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$SKILL_ROOT/../../.." && pwd)"

DISCUSSIONS_DIR="$REPO_ROOT/.tmp/discussions"
TOPIC_DIR="$DISCUSSIONS_DIR/$TOPIC_SLUG"
TEMPLATE_FILE="$SKILL_ROOT/assets/scratchpad-template.md"

if [[ -d "$TOPIC_DIR" ]]; then
  echo "{\"error\": \"topic already exists\", \"path\": \"$TOPIC_DIR\"}" >&2
  exit 1
fi

if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo "{\"error\": \"scratchpad template not found\", \"expected\": \"$TEMPLATE_FILE\"}" >&2
  exit 1
fi

# --- Create directory structure ---

mkdir -p "$TOPIC_DIR/docs"
mkdir -p "$TOPIC_DIR/archive"

# --- Hydrate scratchpad template ---

TOPIC_TITLE=$(echo "$TOPIC_SLUG" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')
CURRENT_DATE=$(date +%Y-%m-%d)
CURRENT_TIME=$(date +%H:%M)

CONTENT=$(cat "$TEMPLATE_FILE")
CONTENT=$(echo "$CONTENT" | sed "s|{{TOPIC_NAME}}|$TOPIC_TITLE|g")
CONTENT=$(echo "$CONTENT" | sed "s|{{TOPIC_SLUG}}|$TOPIC_SLUG|g")
CONTENT=$(echo "$CONTENT" | sed "s|{{DATE}}|$CURRENT_DATE|g")
CONTENT=$(echo "$CONTENT" | sed "s|{{TIME}}|$CURRENT_TIME|g")
CONTENT=$(echo "$CONTENT" | sed "s|{{INITIAL_CONTEXT}}|<!-- Initial context goes here -->|g")

echo "$CONTENT" > "$TOPIC_DIR/scratchpad.md"

# --- Output ---

cat <<JSON
{
  "topic": "$TOPIC_SLUG",
  "title": "$TOPIC_TITLE",
  "path": "$TOPIC_DIR",
  "scratchpad": "$TOPIC_DIR/scratchpad.md",
  "created": "$CURRENT_DATE"
}
JSON
