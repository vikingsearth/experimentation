#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
scaffold-adr.sh — Scaffold a new ADR file from the template.

Usage:
  bash scripts/scaffold-adr.sh --next-number
  bash scripts/scaffold-adr.sh <number> "<short-title>"

Modes:
  --next-number     Scan docs/adrs/ and print the next sequential ADR number.
                    Outputs JSON: {"next_number": "NNNN", "existing_count": N}

  <number> <title>  Create docs/adrs/adr-NNNN-<title>.md from the template.
                    Number can be with or without leading zeros (5 or 0005).
                    Title is converted to kebab-case.
                    Outputs JSON: {"file": "path", "number": "NNNN", "title": "..."}

Options:
  --help, -h        Show this help message.

Examples:
  bash scripts/scaffold-adr.sh --next-number
  bash scripts/scaffold-adr.sh 9 "adopt-effect-ts"
  bash scripts/scaffold-adr.sh 0009 "adopt effect ts"

Exit codes:
  0  Success
  1  Invalid arguments or file already exists
HELP
  exit 0
}

[[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && show_help

# --- Locate paths ---

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# Walk up to repo root: skills/create-adr/scripts -> skills/create-adr -> skills -> .claude -> repo
REPO_ROOT="$(cd "$SKILL_ROOT/../../.." && pwd)"
ADR_DIR="$REPO_ROOT/docs/adrs"
TEMPLATE_FILE="$SKILL_ROOT/assets/adr-template.md"

# --- Helper: find next number ---

find_next_number() {
  local max=0
  local count=0

  if [[ -d "$ADR_DIR" ]]; then
    for f in "$ADR_DIR"/adr-[0-9][0-9][0-9][0-9]-*.md; do
      [[ -f "$f" ]] || continue
      count=$((count + 1))
      # Extract number from filename
      num=$(basename "$f" | sed 's/^adr-0*//' | sed 's/-.*//')
      if [[ "$num" =~ ^[0-9]+$ ]] && [[ "$num" -gt "$max" ]]; then
        max="$num"
      fi
    done
  fi

  local next=$((max + 1))
  printf -v padded "%04d" "$next"
  echo "{\"next_number\": \"$padded\", \"existing_count\": $count}"
}

# --- Mode: --next-number ---

if [[ "${1:-}" == "--next-number" ]]; then
  find_next_number
  exit 0
fi

# --- Mode: create ADR ---

if [[ $# -lt 2 ]]; then
  echo "Error: requires <number> and <title> arguments." >&2
  echo "Usage: bash scripts/scaffold-adr.sh <number> \"<short-title>\"" >&2
  echo "       bash scripts/scaffold-adr.sh --next-number" >&2
  exit 1
fi

RAW_NUMBER="$1"
shift
RAW_TITLE="$*"

# Validate number
if ! [[ "$RAW_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "Error: number must be a positive integer. Received: $RAW_NUMBER" >&2
  exit 1
fi

# Pad number to 4 digits
printf -v PADDED_NUMBER "%04d" "$RAW_NUMBER"

# Convert title to kebab-case
KEBAB_TITLE=$(echo "$RAW_TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')

if [[ -z "$KEBAB_TITLE" ]]; then
  echo "Error: title cannot be empty after sanitization. Received: $RAW_TITLE" >&2
  exit 1
fi

FILENAME="adr-${PADDED_NUMBER}-${KEBAB_TITLE}.md"
FILEPATH="$ADR_DIR/$FILENAME"

# Check for collision
if [[ -f "$FILEPATH" ]]; then
  echo "Error: file already exists: $FILEPATH" >&2
  echo "Hint: run --next-number to find an available number." >&2
  exit 1
fi

# Ensure directory exists
mkdir -p "$ADR_DIR"

# Check template exists
if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo "Error: template not found: $TEMPLATE_FILE" >&2
  exit 1
fi

# Generate display title (Title Case from kebab)
DISPLAY_TITLE=$(echo "$KEBAB_TITLE" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')

# Today's date
TODAY=$(date +%Y-%m-%d)

# Read and hydrate template
CONTENT=$(cat "$TEMPLATE_FILE")
CONTENT=$(echo "$CONTENT" | sed "s/ADR-XXX/ADR-${PADDED_NUMBER}/g")
CONTENT=$(echo "$CONTENT" | sed "s/\\[Short Title of Decision\\]/${DISPLAY_TITLE}/g")
CONTENT=$(echo "$CONTENT" | sed "s/Proposed | Accepted | Deprecated | Superseded/Proposed/g")
CONTENT=$(echo "$CONTENT" | sed "s/YYYY-MM-DD/${TODAY}/g")

# Write file
echo "$CONTENT" > "$FILEPATH"

# Output result as JSON
cat <<EOF
{"file": "$FILEPATH", "number": "$PADDED_NUMBER", "title": "$DISPLAY_TITLE", "filename": "$FILENAME"}
EOF
