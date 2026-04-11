#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
fetch-review-comments.sh — Fetch inline code review comments on a PR

Usage:
  bash scripts/fetch-review-comments.sh <owner> <repo> <pr-number>

Arguments:
  owner       Repository owner (e.g., "Derivco").
  repo        Repository name (e.g., "nebula-aurora").
  pr-number   The pull request number.

Output:
  JSON to stdout with structure:
  {
    "source": "review-comments",
    "items": [{ "id", "body", "author", "author_type", "path", "line", "side", "diff_hunk", "in_reply_to_id", "created_at", "url" }],
    "summary": { "total", "by_author_type": { "human", "bot" }, "files_affected": N },
    "warnings": [...]
  }
  Diagnostics to stderr.

Exit codes:
  0  Success (possibly with warnings for partial data)
  1  Fatal error (no data could be fetched)
  2  Invalid arguments
HELP
  exit 0
}

[[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && show_help

OWNER="${1:-}"
REPO="${2:-}"
PR_NUMBER="${3:-}"

if [[ -z "$OWNER" || -z "$REPO" || -z "$PR_NUMBER" ]]; then
  echo "Error: owner, repo, and pr-number are all required." >&2
  echo "Usage: bash scripts/fetch-review-comments.sh <owner> <repo> <pr-number>" >&2
  exit 2
fi

WARNINGS="[]"

add_warning() {
  WARNINGS=$(echo "$WARNINGS" | jq --arg w "$1" '. + [$w]')
}

ALL_ITEMS="[]"
FETCH_FAILED=false

echo "Fetching review comments for PR #${PR_NUMBER}..." >&2

RESPONSE=$(gh api "/repos/${OWNER}/${REPO}/pulls/${PR_NUMBER}/comments" --paginate 2>&1) || {
  add_warning "Failed to fetch review comments. API error."
  echo "Warning: Failed to fetch review comments." >&2
  FETCH_FAILED=true
}

if [[ "$FETCH_FAILED" == "false" ]]; then
  ALL_ITEMS=$(echo "$RESPONSE" | jq '[.[] | {
    id: .id,
    body: .body,
    author: .user.login,
    author_type: (
      if .user.type == "Bot" then "bot"
      elif (.user.login // "" | test("\\[bot\\]$")) then "bot"
      elif (.user.login // "" | test("^(dependabot|github-actions|renovate|codecov|sonarcloud|copilot|claude-code|netlify|vercel)")) then "bot"
      else "human"
      end
    ),
    path: .path,
    line: (.line // .original_line // null),
    side: .side,
    diff_hunk: .diff_hunk,
    in_reply_to_id: .in_reply_to_id,
    created_at: .created_at,
    url: .html_url
  }]')
fi

TOTAL=$(echo "$ALL_ITEMS" | jq 'length')
if [[ "$TOTAL" -eq 0 && "$FETCH_FAILED" == "true" ]]; then
  echo "Error: Failed to fetch any review comments." >&2
  exit 1
fi

echo "Fetched ${TOTAL} review comment(s)." >&2

echo "$ALL_ITEMS" | jq --argjson warnings "$WARNINGS" '{
  source: "review-comments",
  items: .,
  summary: {
    total: (. | length),
    by_author_type: {
      human: ([.[] | select(.author_type == "human")] | length),
      bot: ([.[] | select(.author_type == "bot")] | length)
    },
    files_affected: ([.[].path] | unique | length)
  },
  warnings: $warnings
}'
