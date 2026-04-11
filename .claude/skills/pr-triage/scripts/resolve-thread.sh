#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
resolve-thread.sh — Resolve a review thread via GraphQL mutation

Usage:
  bash scripts/resolve-thread.sh <thread-id>

Arguments:
  thread-id   The GraphQL node ID of the review thread (e.g., "PRRT_kwDOABC123").
              This is NOT a numeric ID — it's the `id` field from reviewThreads query.

Output:
  JSON to stdout with structure:
  {
    "source": "resolve-thread",
    "thread": { "id", "is_resolved", "resolved_by" },
    "warnings": [...]
  }
  Diagnostics to stderr.

Exit codes:
  0  Success
  1  Fatal error (mutation failed)
  2  Invalid arguments
HELP
  exit 0
}

[[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && show_help

THREAD_ID="${1:-}"

if [[ -z "$THREAD_ID" ]]; then
  echo "Error: thread-id is required." >&2
  echo "Usage: bash scripts/resolve-thread.sh <thread-id>" >&2
  exit 2
fi

WARNINGS="[]"

add_warning() {
  WARNINGS=$(echo "$WARNINGS" | jq --arg w "$1" '. + [$w]')
}

MUTATION='
mutation($threadId: ID!) {
  resolveReviewThread(input: { threadId: $threadId }) {
    thread {
      id
      isResolved
      resolvedBy { login }
    }
  }
}
'

echo "Resolving thread ${THREAD_ID}..." >&2

RESPONSE=$(gh api graphql \
  -f query="$MUTATION" \
  -f threadId="$THREAD_ID" \
  2>&1) || {
  echo "Error: Failed to resolve thread ${THREAD_ID}." >&2
  echo "gh output: ${RESPONSE}" >&2
  exit 1
}

# Check for GraphQL errors
GQL_ERRORS=$(echo "$RESPONSE" | jq -r '.errors // empty')
if [[ -n "$GQL_ERRORS" ]]; then
  ERROR_MSG=$(echo "$RESPONSE" | jq -r '.errors[0].message // "Unknown GraphQL error"')
  echo "Error: GraphQL mutation failed: ${ERROR_MSG}" >&2
  exit 1
fi

echo "Thread resolved." >&2

echo "$RESPONSE" | jq --argjson warnings "$WARNINGS" '{
  source: "resolve-thread",
  thread: {
    id: .data.resolveReviewThread.thread.id,
    is_resolved: .data.resolveReviewThread.thread.isResolved,
    resolved_by: .data.resolveReviewThread.thread.resolvedBy.login
  },
  warnings: $warnings
}'
