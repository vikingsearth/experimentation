#!/usr/bin/env bash
# scaffold-hook.sh — Generate a hook handler script from template
#
# Creates a hook script at scripts/hook-scripts/<name>.sh using the
# command-hook-template.sh asset, with event-specific placeholders hydrated.

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="$SKILL_DIR/assets/command-hook-template.sh"
REPO_ROOT="$(cd "$SKILL_DIR/../../.." && pwd)"
TARGET_DIR="$REPO_ROOT/scripts/hook-scripts"

# --- Help ---
show_help() {
  cat <<'HELP'
scaffold-hook.sh — Generate a hook handler script from template

USAGE
  scaffold-hook.sh --name <hook-name> --event <EventName> [OPTIONS]

REQUIRED
  --name <name>       Hook name (kebab-case, e.g., "block-rm-rf")
  --event <event>     Claude Code event name (e.g., "PreToolUse")

OPTIONS
  --matcher <regex>   Matcher pattern (default: "")
  --purpose <text>    One-line purpose description
  --force             Overwrite existing script
  --dry-run           Show what would be created without writing
  --help              Show this help

OUTPUT
  Creates scripts/hook-scripts/<name>.sh with event-specific boilerplate.
  Prints the path to the created script on stdout.

EXAMPLES
  scaffold-hook.sh --name block-rm --event PreToolUse --matcher Bash --purpose "Block rm -rf commands"
  scaffold-hook.sh --name format-on-save --event PostToolUse --matcher "Edit|Write" --purpose "Run prettier after edits"
HELP
}

# --- Parse args ---
HOOK_NAME=""
EVENT_NAME=""
MATCHER=""
PURPOSE=""
FORCE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)     HOOK_NAME="$2"; shift 2 ;;
    --event)    EVENT_NAME="$2"; shift 2 ;;
    --matcher)  MATCHER="$2"; shift 2 ;;
    --purpose)  PURPOSE="$2"; shift 2 ;;
    --force)    FORCE=true; shift ;;
    --dry-run)  DRY_RUN=true; shift ;;
    --help|-h)  show_help; exit 0 ;;
    *)          echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# --- Validate ---
if [[ -z "$HOOK_NAME" ]]; then
  echo "Error: --name is required" >&2
  exit 1
fi

if [[ -z "$EVENT_NAME" ]]; then
  echo "Error: --event is required" >&2
  exit 1
fi

if ! [[ "$HOOK_NAME" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "Error: hook name must be kebab-case (e.g., block-rm-rf)" >&2
  exit 1
fi

if [[ ! -f "$TEMPLATE" ]]; then
  echo "Error: template not found at $TEMPLATE" >&2
  exit 1
fi

TARGET_FILE="$TARGET_DIR/${HOOK_NAME}.sh"

if [[ -f "$TARGET_FILE" && "$FORCE" != "true" ]]; then
  echo "Error: $TARGET_FILE already exists. Use --force to overwrite." >&2
  exit 1
fi

# --- Dry run ---
if [[ "$DRY_RUN" == "true" ]]; then
  echo "=== DRY RUN ===" >&2
  echo "Would create: $TARGET_FILE" >&2
  echo "Event: $EVENT_NAME" >&2
  echo "Matcher: ${MATCHER:-'(none)'}" >&2
  echo "Purpose: ${PURPOSE:-'(none)'}" >&2
  exit 0
fi

# --- Create ---
mkdir -p "$TARGET_DIR"

# Escape sed replacement-special characters in user-provided values
escape_sed() { printf '%s\n' "$1" | sed 's/[&/\]/\\&/g'; }
SAFE_MATCHER=$(escape_sed "${MATCHER}")
SAFE_PURPOSE=$(escape_sed "${PURPOSE}")

sed \
  -e "s|{{HOOK_NAME}}|${HOOK_NAME}|g" \
  -e "s|{{EVENT_NAME}}|${EVENT_NAME}|g" \
  -e "s|{{MATCHER}}|${SAFE_MATCHER}|g" \
  -e "s|{{PURPOSE}}|${SAFE_PURPOSE}|g" \
  "$TEMPLATE" > "$TARGET_FILE"

chmod +x "$TARGET_FILE"

echo "$TARGET_FILE"
