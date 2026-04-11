#!/usr/bin/env bash
set -euo pipefail

# add-comment.sh — Posts a comment on a GitHub issue.

show_help() {
cat <<'HELP'
Usage: add-comment.sh --number NUMBER --body BODY

Posts a comment on a GitHub issue.

Required:
  --number NUMBER      Issue number
  --body BODY          Comment body text

Optional:
  --body-file FILE     Read comment body from file (overrides --body)
  --help               Show this help

Output (JSON to stdout):
  { "number": 123, "comment_url": "https://..." }

Examples:
  add-comment.sh --number 42 --body "Fix deployed to staging"
  add-comment.sh --number 42 --body-file ./comment.md
HELP
}

# --- Parse arguments ---
NUMBER="" BODY="" BODY_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --number)    NUMBER="$2"; shift 2 ;;
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

if [[ -z "$BODY" ]]; then echo "Error: --body or --body-file is required" >&2; exit 1; fi

# --- Post comment ---
COMMENT_URL=$(gh issue comment "$NUMBER" --body "$BODY" 2>&1 | grep -oE 'https://[^ ]+' | head -1 || echo "")

echo "Posted comment on issue #$NUMBER" >&2

jq -n --arg number "$NUMBER" --arg url "${COMMENT_URL:-unknown}" \
  '{number: ($number | tonumber), comment_url: $url}'
