#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
get-review-scope.sh — Extract changed files and diff from git for code review.

USAGE:
  bash get-review-scope.sh [OPTIONS]

OPTIONS:
  --staged           Show only staged changes (git diff --cached)
  --branch <base>    Diff against a base branch (e.g., main, origin/main)
  --files <path...>  Review specific files (space-separated, must be last flag)
  --name-only        Output only file names, no diff content
  --help             Show this help message

OUTPUT (JSON to stdout):
  {
    "mode": "unstaged|staged|branch|files",
    "base": "<branch or empty>",
    "files": ["file1.ts", "file2.vue"],
    "stats": { "total": N, "added": N, "modified": N, "deleted": N },
    "diff": "<full diff text>"
  }

EXAMPLES:
  bash get-review-scope.sh                     # Unstaged changes
  bash get-review-scope.sh --staged            # Staged changes
  bash get-review-scope.sh --branch main       # Diff against main
  bash get-review-scope.sh --files src/app.ts  # Specific files
HELP
}

# --- Parse arguments ---
MODE="unstaged"
BASE=""
FILES=()
NAME_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help)
      show_help
      exit 0
      ;;
    --staged)
      MODE="staged"
      shift
      ;;
    --branch)
      MODE="branch"
      BASE="${2:?Error: --branch requires a base branch name}"
      shift 2
      ;;
    --files)
      MODE="files"
      shift
      while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
        FILES+=("$1")
        shift
      done
      if [[ ${#FILES[@]} -eq 0 ]]; then
        echo '{"error": "--files requires at least one file path"}' >&2
        exit 1
      fi
      ;;
    --name-only)
      NAME_ONLY=true
      shift
      ;;
    *)
      echo "{\"error\": \"Unknown option: $1. Use --help for usage.\"}" >&2
      exit 1
      ;;
  esac
done

# --- Verify git repo ---
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo '{"error": "Not inside a git repository"}' >&2
  exit 1
fi

# --- Build diff command ---
case "$MODE" in
  unstaged)
    DIFF_CMD="git diff"
    NAMES_CMD="git diff --name-status"
    ;;
  staged)
    DIFF_CMD="git diff --cached"
    NAMES_CMD="git diff --cached --name-status"
    ;;
  branch)
    if ! git rev-parse --verify "$BASE" >/dev/null 2>&1; then
      echo "{\"error\": \"Base branch '$BASE' not found\"}" >&2
      exit 1
    fi
    MERGE_BASE=$(git merge-base "$BASE" HEAD 2>/dev/null || echo "$BASE")
    DIFF_CMD="git diff $MERGE_BASE"
    NAMES_CMD="git diff --name-status $MERGE_BASE"
    ;;
  files)
    file_args=""
    for f in "${FILES[@]}"; do
      file_args="$file_args $f"
    done
    DIFF_CMD="git diff --$file_args"
    NAMES_CMD="git diff --name-status --$file_args"
    # For specific files, also check staged
    DIFF_CMD="git diff HEAD --$file_args"
    NAMES_CMD="git diff HEAD --name-status --$file_args"
    ;;
esac

# --- Extract file names and statuses ---
ADDED=0
MODIFIED=0
DELETED=0
FILE_LIST=""

while IFS=$'\t' read -r status filepath; do
  [[ -z "$status" ]] && continue
  case "$status" in
    A*) ADDED=$((ADDED + 1)) ;;
    M*) MODIFIED=$((MODIFIED + 1)) ;;
    D*) DELETED=$((DELETED + 1)) ;;
    R*) MODIFIED=$((MODIFIED + 1)) ;;
    *)  MODIFIED=$((MODIFIED + 1)) ;;
  esac
  # Escape for JSON
  escaped=$(printf '%s' "$filepath" | sed 's/\\/\\\\/g; s/"/\\"/g')
  if [[ -n "$FILE_LIST" ]]; then
    FILE_LIST="$FILE_LIST, \"$escaped\""
  else
    FILE_LIST="\"$escaped\""
  fi
done < <(eval "$NAMES_CMD" 2>/dev/null || true)

TOTAL=$((ADDED + MODIFIED + DELETED))

# --- Extract diff content ---
DIFF_CONTENT=""
if [[ "$NAME_ONLY" != "true" ]]; then
  DIFF_CONTENT=$(eval "$DIFF_CMD" 2>/dev/null || true)
fi

# --- Escape diff for JSON ---
escaped_diff=$(printf '%s' "$DIFF_CONTENT" | python3 -c "
import sys, json
text = sys.stdin.read()
print(json.dumps(text), end='')
" 2>/dev/null || echo '""')

# --- Escape base for JSON ---
escaped_base=$(printf '%s' "$BASE" | sed 's/\\/\\\\/g; s/"/\\"/g')

# --- Output JSON ---
cat <<EOF
{
  "mode": "$MODE",
  "base": "$escaped_base",
  "files": [$FILE_LIST],
  "stats": {
    "total": $TOTAL,
    "added": $ADDED,
    "modified": $MODIFIED,
    "deleted": $DELETED
  },
  "diff": $escaped_diff
}
EOF
