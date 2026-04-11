#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
fetch-review-threads.sh — Fetch review threads with resolution status (GraphQL)

Usage:
  bash scripts/fetch-review-threads.sh <owner> <repo> <pr-number>

Arguments:
  owner       Repository owner (e.g., "Derivco").
  repo        Repository name (e.g., "nebula-aurora").
  pr-number   The pull request number.

Output:
  JSON to stdout with structure:
  {
    "source": "review-threads",
    "items": [{
      "thread_id", "is_resolved", "is_outdated", "resolved_by",
      "path", "line",
      "comments": [{ "id", "database_id", "body", "author", "created_at", "url" }]
    }],
    "summary": { "total", "resolved", "unresolved", "outdated", "files_affected" },
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
  echo "Usage: bash scripts/fetch-review-threads.sh <owner> <repo> <pr-number>" >&2
  exit 2
fi

WARNINGS="[]"

add_warning() {
  WARNINGS=$(echo "$WARNINGS" | jq --arg w "$1" '. + [$w]')
}

QUERY='
query($owner: String!, $name: String!, $number: Int!, $cursor: String) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      reviewThreads(first: 100, after: $cursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          resolvedBy { login }
          comments(first: 100) {
            nodes {
              id
              databaseId
              body
              author { login }
              createdAt
              url
            }
          }
        }
      }
    }
  }
}
'

ALL_ITEMS="[]"
FETCH_FAILED=false
CURSOR=""
PAGE=1

echo "Fetching review threads for PR #${PR_NUMBER}..." >&2

while true; do
  echo "  Fetching page ${PAGE}..." >&2

  if [[ -z "$CURSOR" ]]; then
    RESPONSE=$(gh api graphql \
      -f query="$QUERY" \
      -f owner="$OWNER" \
      -f name="$REPO" \
      -F number="$PR_NUMBER" \
      2>&1) || {
      add_warning "Failed to fetch review threads page ${PAGE}. Partial data returned."
      echo "Warning: fetch failed on page ${PAGE}." >&2
      FETCH_FAILED=true
      break
    }
  else
    RESPONSE=$(gh api graphql \
      -f query="$QUERY" \
      -f owner="$OWNER" \
      -f name="$REPO" \
      -F number="$PR_NUMBER" \
      -f cursor="$CURSOR" \
      2>&1) || {
      add_warning "Failed to fetch review threads page ${PAGE}. Partial data returned."
      echo "Warning: fetch failed on page ${PAGE}." >&2
      FETCH_FAILED=true
      break
    }
  fi

  # Check for GraphQL errors
  GQL_ERRORS=$(echo "$RESPONSE" | jq -r '.errors // empty')
  if [[ -n "$GQL_ERRORS" ]]; then
    ERROR_MSG=$(echo "$RESPONSE" | jq -r '.errors[0].message // "Unknown GraphQL error"')
    add_warning "GraphQL error: ${ERROR_MSG}"
    echo "Warning: GraphQL error: ${ERROR_MSG}" >&2
    FETCH_FAILED=true
    break
  fi

  # Extract threads from this page
  PAGE_ITEMS=$(echo "$RESPONSE" | jq '[
    .data.repository.pullRequest.reviewThreads.nodes[] | {
      thread_id: .id,
      is_resolved: .isResolved,
      is_outdated: .isOutdated,
      resolved_by: (.resolvedBy.login // null),
      path: .path,
      line: .line,
      comments: [
        .comments.nodes[] | {
          id: .id,
          database_id: .databaseId,
          body: .body,
          author: .author.login,
          created_at: .createdAt,
          url: .url
        }
      ]
    }
  ]')

  ALL_ITEMS=$(echo "$ALL_ITEMS" "$PAGE_ITEMS" | jq -s '.[0] + .[1]')

  # Check pagination
  HAS_NEXT=$(echo "$RESPONSE" | jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.hasNextPage')
  if [[ "$HAS_NEXT" != "true" ]]; then
    break
  fi

  CURSOR=$(echo "$RESPONSE" | jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.endCursor')
  PAGE=$((PAGE + 1))
done

TOTAL=$(echo "$ALL_ITEMS" | jq 'length')
if [[ "$TOTAL" -eq 0 && "$FETCH_FAILED" == "true" ]]; then
  echo "Error: Failed to fetch any review threads." >&2
  exit 1
fi

echo "Fetched ${TOTAL} review thread(s)." >&2

echo "$ALL_ITEMS" | jq --argjson warnings "$WARNINGS" '{
  source: "review-threads",
  items: .,
  summary: {
    total: (. | length),
    resolved: ([.[] | select(.is_resolved == true)] | length),
    unresolved: ([.[] | select(.is_resolved == false)] | length),
    outdated: ([.[] | select(.is_outdated == true)] | length),
    files_affected: ([.[].path] | unique | length)
  },
  warnings: $warnings
}'
