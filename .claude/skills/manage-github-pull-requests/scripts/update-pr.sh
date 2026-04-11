#!/usr/bin/env bash
set -euo pipefail

# update-pr.sh — Updates PR title or body content via gh pr edit.

show_help() {
cat <<'HELP'
Usage: update-pr.sh --number NUMBER [--title TITLE] [--body BODY]

Updates a pull request's title or body content.

Required:
  --number NUMBER      PR number to update

Optional (at least one required):
  --title TITLE        New PR title (must follow conventional commit format)
  --body BODY          New PR body
  --body-file FILE     Read new body from file
  --help               Show this help

Output (JSON to stdout):
  { "number": 123, "updated": ["title", "body"] }

Examples:
  update-pr.sh --number 142 --title "feat(frontend): update retry logic"
  update-pr.sh --number 142 --body-file ./updated-description.md
HELP
}

# --- Parse arguments ---
NUMBER="" TITLE="" BODY="" BODY_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --number)    NUMBER="$2"; shift 2 ;;
    --title)     TITLE="$2"; shift 2 ;;
    --body)      BODY="$2"; shift 2 ;;
    --body-file) BODY_FILE="$2"; shift 2 ;;
    --help)      show_help; exit 0 ;;
    *)           echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$NUMBER" ]]; then echo "Error: --number is required" >&2; exit 1; fi

if [[ -n "$BODY_FILE" ]]; then
  if [[ ! -f "$BODY_FILE" ]]; then
    echo "Error: body file not found: $BODY_FILE" >&2; exit 1
  fi
  BODY=$(cat "$BODY_FILE")
fi

if [[ -z "$TITLE" && -z "$BODY" ]]; then
  echo "Error: at least one of --title, --body, or --body-file is required" >&2; exit 1
fi

# Validate title format if provided
if [[ -n "$TITLE" ]]; then
  if ! echo "$TITLE" | grep -qE '^(feat|fix|refactor|docs|chore|ci|perf|build|test)(\(.+\))?!?: .+'; then
    echo "Error: title must follow conventional commit format: type(scope): description" >&2
    exit 1
  fi
fi

# --- Build command ---
CMD=(gh pr edit "$NUMBER")
UPDATED=()

if [[ -n "$TITLE" ]]; then
  CMD+=(--title "$TITLE")
  UPDATED+=("title")
fi

if [[ -n "$BODY" ]]; then
  CMD+=(--body "$BODY")
  UPDATED+=("body")
fi

# --- Execute ---
"${CMD[@]}" >&2

echo "Updated PR #$NUMBER: ${UPDATED[*]}" >&2

UPDATED_JSON=$(printf '%s\n' "${UPDATED[@]}" | jq -R . | jq -s .)
jq -n --arg number "$NUMBER" --argjson updated "$UPDATED_JSON" \
  '{number: ($number | tonumber), updated: $updated}'
