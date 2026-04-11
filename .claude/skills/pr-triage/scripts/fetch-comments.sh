#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
fetch-comments.sh — Fetch issue-level PR comments (top-level conversation)

Usage:
  bash scripts/fetch-comments.sh <owner> <repo> <pr-number>

Arguments:
  owner       Repository owner (e.g., "Derivco").
  repo        Repository name (e.g., "nebula-aurora").
  pr-number   The pull request number.

Output:
  JSON to stdout with structure:
  {
    "source": "issue-comments",
    "items": [{ "id", "body", "author", "author_type", "created_at", "url" }],
    "summary": { "total", "by_author_type": { "human", "bot" } },
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
  echo "Usage: bash scripts/fetch-comments.sh <owner> <repo> <pr-number>" >&2
  exit 2
fi

WARNINGS="[]"

add_warning() {
  WARNINGS=$(echo "$WARNINGS" | jq --arg w "$1" '. + [$w]')
}

# --- Bot detection jq filter (reusable) ---
BOT_FILTER='
  if .user.type == "Bot" then "bot"
  elif (.user.login // "" | test("\\[bot\\]$")) then "bot"
  elif (.user.login // "" | test("^(dependabot|github-actions|renovate|codecov|sonarcloud|copilot|claude-code|netlify|vercel)")) then "bot"
  else "human"
  end
'

ALL_ITEMS="[]"
FETCH_FAILED=false

echo "Fetching issue comments for PR #${PR_NUMBER}..." >&2

RESPONSE=$(gh api "/repos/${OWNER}/${REPO}/issues/${PR_NUMBER}/comments" --paginate 2>&1) || {
  add_warning "Failed to fetch issue comments. API error."
  echo "Warning: Failed to fetch issue comments." >&2
  FETCH_FAILED=true
}

if [[ "$FETCH_FAILED" == "false" ]]; then
  ALL_ITEMS=$(echo "$RESPONSE" | jq --arg bot_filter "$BOT_FILTER" '[.[] | {
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
    created_at: .created_at,
    url: .html_url
  }]')
fi

TOTAL=$(echo "$ALL_ITEMS" | jq 'length')
if [[ "$TOTAL" -eq 0 && "$FETCH_FAILED" == "true" ]]; then
  echo "Error: Failed to fetch any issue comments." >&2
  exit 1
fi

echo "Fetched ${TOTAL} issue comment(s)." >&2

echo "$ALL_ITEMS" | jq --argjson warnings "$WARNINGS" '{
  source: "issue-comments",
  items: .,
  summary: {
    total: (. | length),
    by_author_type: {
      human: ([.[] | select(.author_type == "human")] | length),
      bot: ([.[] | select(.author_type == "bot")] | length)
    }
  },
  warnings: $warnings
}'
