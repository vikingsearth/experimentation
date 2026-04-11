#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
fetch-pr-metadata.sh — Fetch PR metadata (title, state, author, branches, change stats)

Usage:
  bash scripts/fetch-pr-metadata.sh <pr-number>

Arguments:
  pr-number   The pull request number (required).

Output:
  JSON to stdout with structure:
  {
    "source": "pr-metadata",
    "pr": { "number", "title", "state", "author", "url", "base", "head", "additions", "deletions", "changedFiles" },
    "warnings": [...]
  }
  Diagnostics to stderr.

Exit codes:
  0  Success
  1  Fatal error (PR not found or API failure)
  2  Invalid arguments
HELP
  exit 0
}

[[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && show_help

PR_NUMBER="${1:-}"

if [[ -z "$PR_NUMBER" ]]; then
  echo "Error: pr-number is required." >&2
  echo "Usage: bash scripts/fetch-pr-metadata.sh <pr-number>" >&2
  exit 2
fi

WARNINGS="[]"

add_warning() {
  WARNINGS=$(echo "$WARNINGS" | jq --arg w "$1" '. + [$w]')
}

echo "Fetching PR #${PR_NUMBER} metadata..." >&2

RESPONSE=$(gh pr view "$PR_NUMBER" --json number,title,state,author,url,baseRefName,headRefName,additions,deletions,changedFiles 2>&1) || {
  echo "Error: Failed to fetch PR #${PR_NUMBER}. Is the PR number correct?" >&2
  echo "gh output: ${RESPONSE}" >&2
  exit 1
}

echo "PR metadata fetched." >&2

echo "$RESPONSE" | jq --argjson warnings "$WARNINGS" '{
  source: "pr-metadata",
  pr: {
    number: .number,
    title: .title,
    state: .state,
    author: .author.login,
    url: .url,
    base: .baseRefName,
    head: .headRefName,
    additions: .additions,
    deletions: .deletions,
    changedFiles: .changedFiles
  },
  warnings: $warnings
}'
