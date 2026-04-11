#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
{{SCRIPT_NAME}} — {{SCRIPT_PURPOSE}}

Usage:
  bash scripts/{{SCRIPT_NAME}} <required-arg> [optional-arg]

Arguments:
  required-arg   Description of required argument.
  optional-arg   Description of optional argument. Defaults to "default".

Output:
  JSON to stdout with structure:
  {
    "source": "{{SOURCE_NAME}}",
    "items": [...],
    "summary": { "total": N, ... },
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

REQUIRED_ARG="${1:-}"
OPTIONAL_ARG="${2:-default}"

if [[ -z "$REQUIRED_ARG" ]]; then
  echo "Error: required-arg is required." >&2
  echo "Usage: bash scripts/{{SCRIPT_NAME}} <required-arg> [optional-arg]" >&2
  exit 2
fi

# --- Warnings accumulator (for graceful degradation) ---

WARNINGS="[]"

add_warning() {
  WARNINGS=$(echo "$WARNINGS" | jq --arg w "$1" '. + [$w]')
}

# --- Bot detection helper (use in jq transforms) ---
# Detects bots via: user.type == "Bot", login suffix [bot], known bot names.
# Example jq usage:
#   author_type: (
#     if .user.type == "Bot" then "bot"
#     elif (.user.login // "" | test("\\[bot\\]$")) then "bot"
#     elif (.user.login // "" | test("^(dependabot|github-actions|renovate|codecov|sonarcloud|copilot|claude-code)")) then "bot"
#     else "human"
#     end
#   )

# --- Main logic ---
# Fetch with graceful degradation:
#   - On success: append to results
#   - On partial failure (e.g., page N fails): keep pages 1..N-1, add warning, break
#   - On total failure (no data at all): exit 1

ALL_ITEMS="[]"
FETCH_FAILED=false

echo "Fetching data..." >&2

# Example: paginated fetch with graceful degradation
# PAGE=1
# while true; do
#   RESPONSE=$(some_api_call 2>&1) || {
#     add_warning "Failed to fetch page ${PAGE}. Partial data returned."
#     echo "Warning: fetch failed on page ${PAGE}." >&2
#     FETCH_FAILED=true
#     break
#   }
#   # ... process RESPONSE, append to ALL_ITEMS ...
#   PAGE=$((PAGE + 1))
# done

# Fatal only if zero data was fetched
TOTAL=$(echo "$ALL_ITEMS" | jq 'length')
if [[ "$TOTAL" -eq 0 && "$FETCH_FAILED" == "true" ]]; then
  echo "Error: Failed to fetch any data." >&2
  exit 1
fi

echo "Fetched ${TOTAL} item(s)." >&2

# --- Output with summary stats ---

echo "$ALL_ITEMS" | jq --argjson warnings "$WARNINGS" '{
  source: "{{SOURCE_NAME}}",
  items: .,
  summary: {
    total: (. | length)
  },
  warnings: $warnings
}'
