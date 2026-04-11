#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
review-topics.sh — Scan .tmp/discussions/ and output a JSON summary of all topics.

Usage:
  bash scripts/review-topics.sh

Output (stdout):
  JSON object with:
  - topics[]: array of topic objects
  - summary: { total, with_outcome, with_docs, with_archive }

Each topic object:
  {
    "slug": "topic-name",
    "has_scratchpad": true/false,
    "has_outcome": true/false,
    "doc_count": N,
    "archive_count": N,
    "last_modified": "YYYY-MM-DD HH:MM"
  }

Exit codes:
  0  Success (even if no topics exist)
  1  Error
HELP
  exit 0
}

[[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && show_help

# --- Locate paths ---

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$SKILL_ROOT/../../.." && pwd)"

DISCUSSIONS_DIR="$REPO_ROOT/.tmp/discussions"

# --- Handle no discussions directory ---

if [[ ! -d "$DISCUSSIONS_DIR" ]]; then
  cat <<JSON
{
  "topics": [],
  "summary": {
    "total": 0,
    "with_outcome": 0,
    "with_docs": 0,
    "with_archive": 0
  }
}
JSON
  exit 0
fi

# --- Scan topics ---

TOPICS_JSON="["
FIRST=true
TOTAL=0
WITH_OUTCOME=0
WITH_DOCS=0
WITH_ARCHIVE=0

for topic_dir in "$DISCUSSIONS_DIR"/*/; do
  [[ -d "$topic_dir" ]] || continue

  SLUG=$(basename "$topic_dir")
  HAS_SCRATCHPAD=false
  HAS_OUTCOME=false
  DOC_COUNT=0
  ARCHIVE_COUNT=0

  [[ -f "$topic_dir/scratchpad.md" ]] && HAS_SCRATCHPAD=true
  [[ -f "$topic_dir/outcome.md" ]] && HAS_OUTCOME=true && WITH_OUTCOME=$((WITH_OUTCOME + 1))

  if [[ -d "$topic_dir/docs" ]]; then
    DOC_COUNT=$(find "$topic_dir/docs" -maxdepth 1 -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')
    [[ "$DOC_COUNT" -gt 0 ]] && WITH_DOCS=$((WITH_DOCS + 1))
  fi

  if [[ -d "$topic_dir/archive" ]]; then
    ARCHIVE_COUNT=$(find "$topic_dir/archive" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')
    [[ "$ARCHIVE_COUNT" -gt 0 ]] && WITH_ARCHIVE=$((WITH_ARCHIVE + 1))
  fi

  # Get last modified time of topic directory (most recent file)
  LAST_MODIFIED=$(find "$topic_dir" -type f -exec stat -f '%m %Sm' -t '%Y-%m-%d %H:%M' {} + 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
  [[ -z "$LAST_MODIFIED" ]] && LAST_MODIFIED="unknown"

  TOTAL=$((TOTAL + 1))

  if $FIRST; then
    FIRST=false
  else
    TOPICS_JSON+=","
  fi

  TOPICS_JSON+=$(cat <<TOPIC

  {
    "slug": "$SLUG",
    "has_scratchpad": $HAS_SCRATCHPAD,
    "has_outcome": $HAS_OUTCOME,
    "doc_count": $DOC_COUNT,
    "archive_count": $ARCHIVE_COUNT,
    "last_modified": "$LAST_MODIFIED"
  }
TOPIC
)
done

TOPICS_JSON+=$'\n]'

# --- Output ---

cat <<JSON
{
  "topics": $TOPICS_JSON,
  "summary": {
    "total": $TOTAL,
    "with_outcome": $WITH_OUTCOME,
    "with_docs": $WITH_DOCS,
    "with_archive": $WITH_ARCHIVE
  }
}
JSON
