#!/usr/bin/env bash
set -euo pipefail

# add-comment.sh — Adds a comment to a GitHub PR.

show_help() {
cat <<'HELP'
Usage: add-comment.sh --number NUMBER --body BODY

Adds a comment to a pull request.

Required:
  --number NUMBER      PR number
  --body BODY          Comment body (Markdown supported)

Optional:
  --body-file FILE     Read comment body from file (overrides --body)
  --help               Show this help

Output (JSON to stdout):
  { "number": 123, "comment_url": "https://..." }

Examples:
  add-comment.sh --number 142 --body "LGTM! Tested locally."
  add-comment.sh --number 142 --body-file ./review-notes.md
HELP
}

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

# Add comment
gh pr comment "$NUMBER" --body "$BODY" >&2

echo "Added comment to PR #$NUMBER" >&2

jq -n --arg number "$NUMBER" \
  '{number: ($number | tonumber), commented: true}'
