#!/usr/bin/env bash
# {{HOOK_NAME}} — Claude Code {{EVENT_NAME}} hook
#
# Event: {{EVENT_NAME}}
# Matcher: {{MATCHER}}
# Purpose: {{PURPOSE}}
#
# Input: JSON on stdin (see references/event-schemas.md for {{EVENT_NAME}} schema)
# Output: JSON on stdout (exit 0), or error on stderr (exit 2 to block)
#
# Usage:
#   echo '{"tool_name":"Bash","tool_input":{"command":"ls"}}' | ./{{HOOK_NAME}}.sh
#   ./{{HOOK_NAME}}.sh --help
#   ./{{HOOK_NAME}}.sh --dry-run < input.json

set -euo pipefail

# --- Help ---
show_help() {
  cat <<'HELP'
{{HOOK_NAME}} — Claude Code {{EVENT_NAME}} hook

USAGE
  echo '<json>' | ./{{HOOK_NAME}}.sh         Process hook event
  ./{{HOOK_NAME}}.sh --help                  Show this help
  ./{{HOOK_NAME}}.sh --dry-run < input.json  Parse input, show what would happen

EXIT CODES
  0   Success (action proceeds)
  2   Blocking error (action prevented, stderr fed to Claude)
  *   Non-blocking warning (action proceeds, stderr logged)

ENVIRONMENT
  CLAUDE_PROJECT_DIR   Project root (set by Claude Code)
HELP
}

# --- Argument handling ---
DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --help|-h) show_help; exit 0 ;;
    --dry-run) DRY_RUN=true ;;
  esac
done

# --- Prerequisites ---
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed. Install with: brew install jq (macOS) or apt-get install jq (Linux)" >&2
  exit 1
fi

# --- Read input ---
INPUT=$(cat)

# --- Parse event fields ---
# Adjust these based on the event schema (see references/event-schemas.md)
# Example for PreToolUse/PostToolUse:
# TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
# TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty')
# FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
# COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# --- Dry run ---
if [[ "$DRY_RUN" == "true" ]]; then
  echo "=== DRY RUN ===" >&2
  echo "Event: {{EVENT_NAME}}" >&2
  echo "Input:" >&2
  echo "$INPUT" | jq '.' >&2
  echo "Would execute: {{PURPOSE}}" >&2
  exit 0
fi

# --- Hook logic ---
# TODO: Implement your hook logic here
#
# To ALLOW (exit 0, no output needed):
#   exit 0
#
# To BLOCK (exit 2, stderr becomes feedback for Claude):
#   echo "Reason for blocking" >&2
#   exit 2
#
# To return structured output (exit 0 with JSON):
#   jq -n '{
#     "hookSpecificOutput": {
#       "hookEventName": "{{EVENT_NAME}}",
#       "permissionDecision": "deny",
#       "permissionDecisionReason": "Explanation"
#     }
#   }'
#
# To inject context:
#   jq -n '{ "additionalContext": "Extra info for Claude" }'

exit 0
