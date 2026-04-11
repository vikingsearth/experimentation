#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
reply-comment.sh — Post a reply to a review comment or issue comment

Usage:
  bash scripts/reply-comment.sh <owner> <repo> <pr-number> <comment-id> <body> [--type issue|review]

Arguments:
  owner        Repository owner (e.g., "Derivco").
  repo         Repository name (e.g., "nebula-aurora").
  pr-number    The pull request number.
  comment-id   The numeric ID of the comment to reply to.
  body         The reply text.
  --type       Comment type: "review" (default) or "issue".
               - "review": replies to an inline review comment thread.
               - "issue": posts a new top-level issue comment.

Output:
  JSON to stdout with structure:
  {
    "source": "reply",
    "reply": { "id", "url", "type" },
    "warnings": [...]
  }
  Diagnostics to stderr.

Exit codes:
  0  Success
  1  Fatal error (API failure)
  2  Invalid arguments
HELP
  exit 0
}

[[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && show_help

OWNER="${1:-}"
REPO="${2:-}"
PR_NUMBER="${3:-}"
COMMENT_ID="${4:-}"
BODY="${5:-}"
COMMENT_TYPE="review"

# Parse optional --type flag
shift 5 2>/dev/null || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --type) COMMENT_TYPE="${2:-review}"; shift 2 ;;
    *) shift ;;
  esac
done

if [[ -z "$OWNER" || -z "$REPO" || -z "$PR_NUMBER" || -z "$COMMENT_ID" || -z "$BODY" ]]; then
  echo "Error: owner, repo, pr-number, comment-id, and body are all required." >&2
  echo "Usage: bash scripts/reply-comment.sh <owner> <repo> <pr-number> <comment-id> <body> [--type issue|review]" >&2
  exit 2
fi

WARNINGS="[]"

add_warning() {
  WARNINGS=$(echo "$WARNINGS" | jq --arg w "$1" '. + [$w]')
}

if [[ "$COMMENT_TYPE" == "review" ]]; then
  echo "Replying to review comment ${COMMENT_ID} on PR #${PR_NUMBER}..." >&2
  RESPONSE=$(gh api \
    "/repos/${OWNER}/${REPO}/pulls/${PR_NUMBER}/comments/${COMMENT_ID}/replies" \
    -f body="$BODY" \
    2>&1) || {
    echo "Error: Failed to post reply to review comment ${COMMENT_ID}." >&2
    echo "gh output: ${RESPONSE}" >&2
    exit 1
  }
elif [[ "$COMMENT_TYPE" == "issue" ]]; then
  echo "Posting issue comment on PR #${PR_NUMBER}..." >&2
  RESPONSE=$(gh api \
    "/repos/${OWNER}/${REPO}/issues/${PR_NUMBER}/comments" \
    -f body="$BODY" \
    2>&1) || {
    echo "Error: Failed to post issue comment on PR #${PR_NUMBER}." >&2
    echo "gh output: ${RESPONSE}" >&2
    exit 1
  }
else
  echo "Error: --type must be 'review' or 'issue'. Got: ${COMMENT_TYPE}" >&2
  exit 2
fi

echo "Reply posted." >&2

echo "$RESPONSE" | jq --arg type "$COMMENT_TYPE" --argjson warnings "$WARNINGS" '{
  source: "reply",
  reply: {
    id: .id,
    url: .html_url,
    type: $type
  },
  warnings: $warnings
}'
