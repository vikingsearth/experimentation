#!/usr/bin/env bash
# validate-hook.sh — Structural validation of a hook configuration and optional script
#
# Checks:
# 1. settings.json is valid JSON
# 2. The event entry exists with correct schema
# 3. If a script path is provided: executable, --help, synthetic input test

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
DEFAULT_SETTINGS="$REPO_ROOT/.claude/settings.json"

# --- Help ---
show_help() {
  cat <<'HELP'
validate-hook.sh — Structural validation of a hook and its script

USAGE
  validate-hook.sh --event <EventName> [OPTIONS]

REQUIRED
  --event <name>       Claude Code event name to validate (e.g., "PreToolUse")

OPTIONS
  --settings <path>    Path to settings file (default: .claude/settings.json)
  --script <path>      Path to hook handler script (relative to repo root)
  --help               Show this help

CHECKS PERFORMED
  1. Settings file is valid JSON
  2. hooks.<event> exists and is an array
  3. Each entry has "matcher" (string) and "hooks" (array)
  4. Each hook has "type" (command|prompt|agent)
  5. Command hooks have "command" field
  6. Prompt/agent hooks have "prompt" field
  If --script is provided:
  7. Script file exists and is executable
  8. Script responds to --help (exit 0)
  9. Script accepts synthetic JSON on stdin (exit 0 or 2)

OUTPUT
  JSON report: { "passed": N, "failed": N, "checks": [...] }

EXAMPLES
  validate-hook.sh --event PreToolUse
  validate-hook.sh --event PostToolUse --script scripts/hook-scripts/format-on-save.sh
HELP
}

# --- Prerequisites ---
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed." >&2
  exit 1
fi

# --- Parse args ---
EVENT_NAME=""
SETTINGS_FILE="$DEFAULT_SETTINGS"
SCRIPT_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --event)    EVENT_NAME="$2"; shift 2 ;;
    --settings) SETTINGS_FILE="$2"; shift 2 ;;
    --script)   SCRIPT_PATH="$2"; shift 2 ;;
    --help|-h)  show_help; exit 0 ;;
    *)          echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$EVENT_NAME" ]]; then
  echo "Error: --event is required" >&2
  exit 1
fi

# --- Check tracking ---
PASSED=0
FAILED=0
CHECKS="[]"

add_check() {
  local name="$1"
  local status="$2"  # pass or fail
  local detail="$3"

  CHECKS=$(echo "$CHECKS" | jq \
    --arg name "$name" \
    --arg status "$status" \
    --arg detail "$detail" \
    '. += [{"name": $name, "status": $status, "detail": $detail}]'
  )

  if [[ "$status" == "pass" ]]; then
    ((PASSED++)) || true
  else
    ((FAILED++)) || true
  fi
}

# --- Check 1: Valid JSON ---
if [[ ! -f "$SETTINGS_FILE" ]]; then
  add_check "settings-exists" "fail" "File not found: $SETTINGS_FILE"
else
  if jq '.' "$SETTINGS_FILE" &>/dev/null; then
    add_check "settings-valid-json" "pass" "Valid JSON"
  else
    add_check "settings-valid-json" "fail" "Invalid JSON in $SETTINGS_FILE"
  fi
fi

# --- Check 2: Event entry exists ---
if [[ -f "$SETTINGS_FILE" ]] && jq '.' "$SETTINGS_FILE" &>/dev/null; then
  EVENT_EXISTS=$(jq --arg e "$EVENT_NAME" '.hooks[$e] // null | type' "$SETTINGS_FILE" 2>/dev/null || echo '"null"')
  if [[ "$EVENT_EXISTS" == '"array"' ]]; then
    add_check "event-exists" "pass" "hooks.$EVENT_NAME is an array"

    # --- Check 3: Entry schema ---
    ENTRY_COUNT=$(jq --arg e "$EVENT_NAME" '.hooks[$e] | length' "$SETTINGS_FILE")
    SCHEMA_OK=true
    for ((i=0; i<ENTRY_COUNT; i++)); do
      HAS_MATCHER=$(jq --arg e "$EVENT_NAME" --argjson i "$i" '.hooks[$e][$i] | has("matcher")' "$SETTINGS_FILE")
      HAS_HOOKS=$(jq --arg e "$EVENT_NAME" --argjson i "$i" '.hooks[$e][$i] | has("hooks")' "$SETTINGS_FILE")
      if [[ "$HAS_MATCHER" != "true" || "$HAS_HOOKS" != "true" ]]; then
        SCHEMA_OK=false
        add_check "entry-schema[$i]" "fail" "Entry $i missing 'matcher' or 'hooks' field"
      fi
    done
    if [[ "$SCHEMA_OK" == "true" ]]; then
      add_check "entry-schema" "pass" "All $ENTRY_COUNT entries have matcher + hooks"
    fi

    # --- Check 4: Hook type ---
    HOOKS_TOTAL=$(jq --arg e "$EVENT_NAME" '[.hooks[$e][].hooks[]] | length' "$SETTINGS_FILE")
    TYPE_OK=true
    for ((j=0; j<HOOKS_TOTAL; j++)); do
      HOOK_TYPE=$(jq -r --arg e "$EVENT_NAME" --argjson j "$j" '[.hooks[$e][].hooks[]][$j].type // "missing"' "$SETTINGS_FILE")
      case "$HOOK_TYPE" in
        command|prompt|agent) ;;
        *)
          TYPE_OK=false
          add_check "hook-type[$j]" "fail" "Hook $j has invalid type: $HOOK_TYPE"
          ;;
      esac
    done
    if [[ "$TYPE_OK" == "true" ]]; then
      add_check "hook-types" "pass" "All $HOOKS_TOTAL hooks have valid type"
    fi

    # --- Check 5/6: Type-specific fields ---
    FIELDS_OK=true
    for ((j=0; j<HOOKS_TOTAL; j++)); do
      HOOK_TYPE=$(jq -r --arg e "$EVENT_NAME" --argjson j "$j" '[.hooks[$e][].hooks[]][$j].type // "missing"' "$SETTINGS_FILE")
      case "$HOOK_TYPE" in
        command)
          HAS_CMD=$(jq --arg e "$EVENT_NAME" --argjson j "$j" '[.hooks[$e][].hooks[]][$j] | has("command")' "$SETTINGS_FILE")
          if [[ "$HAS_CMD" != "true" ]]; then
            FIELDS_OK=false
            add_check "hook-fields[$j]" "fail" "Command hook $j missing 'command' field"
          fi
          ;;
        prompt|agent)
          HAS_PROMPT=$(jq --arg e "$EVENT_NAME" --argjson j "$j" '[.hooks[$e][].hooks[]][$j] | has("prompt")' "$SETTINGS_FILE")
          if [[ "$HAS_PROMPT" != "true" ]]; then
            FIELDS_OK=false
            add_check "hook-fields[$j]" "fail" "$HOOK_TYPE hook $j missing 'prompt' field"
          fi
          ;;
      esac
    done
    if [[ "$FIELDS_OK" == "true" ]]; then
      add_check "hook-fields" "pass" "All hooks have required type-specific fields"
    fi

  else
    add_check "event-exists" "fail" "hooks.$EVENT_NAME not found or not an array"
  fi
fi

# --- Script checks (if provided) ---
if [[ -n "$SCRIPT_PATH" ]]; then
  FULL_SCRIPT="$REPO_ROOT/$SCRIPT_PATH"

  # Check 7: Exists and executable
  if [[ -f "$FULL_SCRIPT" ]]; then
    add_check "script-exists" "pass" "Script exists: $SCRIPT_PATH"
    if [[ -x "$FULL_SCRIPT" ]]; then
      add_check "script-executable" "pass" "Script is executable"
    else
      add_check "script-executable" "fail" "Script is not executable. Run: chmod +x $SCRIPT_PATH"
    fi
  else
    add_check "script-exists" "fail" "Script not found: $FULL_SCRIPT"
  fi

  # Check 8: --help
  if [[ -x "$FULL_SCRIPT" ]]; then
    if "$FULL_SCRIPT" --help &>/dev/null; then
      add_check "script-help" "pass" "--help exits 0"
    else
      add_check "script-help" "fail" "--help did not exit 0"
    fi

    # Check 9: Synthetic input
    SYNTHETIC_INPUT='{"session_id":"test","cwd":"/tmp","hook_event_name":"'"$EVENT_NAME"'","tool_name":"Test","tool_input":{"command":"echo test","file_path":"/tmp/test.txt"}}'

    EXIT_CODE=0
    echo "$SYNTHETIC_INPUT" | "$FULL_SCRIPT" &>/dev/null || EXIT_CODE=$?
    if [[ "$EXIT_CODE" -eq 0 || "$EXIT_CODE" -eq 2 ]]; then
      add_check "script-synthetic-input" "pass" "Accepts synthetic JSON input (exit $EXIT_CODE)"
    else
      add_check "script-synthetic-input" "fail" "Unexpected exit code $EXIT_CODE on synthetic input (expected 0 or 2)"
    fi
  fi
fi

# --- Report ---
jq -n \
  --argjson passed "$PASSED" \
  --argjson failed "$FAILED" \
  --argjson checks "$CHECKS" \
  '{
    "passed": $passed,
    "failed": $failed,
    "total": ($passed + $failed),
    "status": (if $failed == 0 then "PASS" else "FAIL" end),
    "checks": $checks
  }'
