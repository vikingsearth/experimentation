#!/usr/bin/env bash
# merge-config.sh — Non-destructively merge a hook entry into .claude/settings.json
#
# Reads the existing settings file, appends a new hook entry to the specified
# event array, and writes back with all non-hook keys preserved.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
DEFAULT_SETTINGS="$REPO_ROOT/.claude/settings.json"

# --- Help ---
show_help() {
  cat <<'HELP'
merge-config.sh — Non-destructively merge a hook entry into .claude/settings.json

USAGE
  merge-config.sh --event <EventName> --config '<json>' [OPTIONS]

REQUIRED
  --event <name>       Claude Code event name (e.g., "PreToolUse")
  --config <json>      JSON object: the matcher group to append
                       Example: '{"matcher":"Bash","hooks":[{"type":"command","command":"..."}]}'

OPTIONS
  --settings <path>    Path to settings file (default: .claude/settings.json)
  --dry-run            Preview the merged output without writing
  --help               Show this help

EXAMPLES
  merge-config.sh --event PreToolUse \
    --config '{"matcher":"Bash","hooks":[{"type":"command","command":"./scripts/hook-scripts/block-rm.sh"}]}' \
    --dry-run

  merge-config.sh --event PostToolUse \
    --config '{"matcher":"Edit|Write","hooks":[{"type":"command","command":"npx prettier --write"}]}'
HELP
}

# --- Prerequisites ---
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed. Install with: brew install jq (macOS) or apt-get install jq (Linux)" >&2
  exit 1
fi

# --- Parse args ---
EVENT_NAME=""
CONFIG_JSON=""
SETTINGS_FILE="$DEFAULT_SETTINGS"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --event)    EVENT_NAME="$2"; shift 2 ;;
    --config)   CONFIG_JSON="$2"; shift 2 ;;
    --settings) SETTINGS_FILE="$2"; shift 2 ;;
    --dry-run)  DRY_RUN=true; shift ;;
    --help|-h)  show_help; exit 0 ;;
    *)          echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# --- Validate ---
if [[ -z "$EVENT_NAME" ]]; then
  echo "Error: --event is required" >&2
  exit 1
fi

if [[ -z "$CONFIG_JSON" ]]; then
  echo "Error: --config is required" >&2
  exit 1
fi

# Validate config JSON
if ! echo "$CONFIG_JSON" | jq '.' &>/dev/null; then
  echo "Error: --config is not valid JSON" >&2
  exit 1
fi

# --- Read or create settings ---
if [[ -f "$SETTINGS_FILE" ]]; then
  CURRENT=$(cat "$SETTINGS_FILE")
  # Validate existing file is valid JSON
  if ! echo "$CURRENT" | jq '.' &>/dev/null; then
    echo "Error: $SETTINGS_FILE is not valid JSON" >&2
    exit 1
  fi
else
  echo "Creating $SETTINGS_FILE with empty hooks structure" >&2
  CURRENT='{ "hooks": {} }'
  if [[ "$DRY_RUN" == "false" ]]; then
    mkdir -p "$(dirname "$SETTINGS_FILE")"
  fi
fi

# --- Merge ---
# Strategy:
# 1. Ensure .hooks exists
# 2. Ensure .hooks.<EventName> is an array
# 3. Append the new config object to that array
# 4. Preserve everything else

MERGED=$(echo "$CURRENT" | jq \
  --arg event "$EVENT_NAME" \
  --argjson entry "$CONFIG_JSON" \
  '
  # Ensure hooks object exists
  .hooks //= {} |
  # Ensure event array exists
  .hooks[$event] //= [] |
  # Append new entry
  .hooks[$event] += [$entry]
  '
)

# --- Output ---
if [[ "$DRY_RUN" == "true" ]]; then
  echo "=== DRY RUN — would write to $SETTINGS_FILE ===" >&2
  echo "$MERGED" | jq '.'
  exit 0
fi

echo "$MERGED" | jq '.' > "$SETTINGS_FILE"
echo "Merged hook into $SETTINGS_FILE under hooks.$EVENT_NAME" >&2
echo "$SETTINGS_FILE"
