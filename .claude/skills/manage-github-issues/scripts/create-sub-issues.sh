#!/usr/bin/env bash
set -euo pipefail

# create-sub-issues.sh — Batch-creates sub-issues under a parent issue.
# Validates child type is allowed per hierarchy, then loops create-issue.sh.

show_help() {
cat <<'HELP'
Usage: create-sub-issues.sh --parent NUMBER --type TYPE --titles "Title1|Title2|..."

Batch-creates sub-issues under a parent issue. Validates child type
(Epic cannot be a child), then creates each issue via create-issue.sh.

Required:
  --parent NUMBER      Parent issue number
  --type TYPE          Type for all children: Task, Bug, Story, Feature
  --titles LIST        Pipe-separated list of issue titles

Optional:
  --labels LABELS      Comma-separated labels applied to all children
  --assignee USER      GitHub username for all children (default: @me)
  --project PROJECT    Project name (default: Nebula)
  --dry-run            Print commands without executing
  --help               Show this help

Output (JSON array to stdout):
  [{ "number": 123, "url": "...", "type": "Task", "parent": 42 }, ...]

Type Hierarchy Rules:
  Epic    → can parent Feature, Story
  Feature → can parent Story, Task, Bug
  Story   → can parent Task, Bug
  Task    → no children allowed
  Bug     → no children allowed

Examples:
  create-sub-issues.sh --parent 85 --type Task --titles "Implement API|Write tests|Update docs"
  create-sub-issues.sh --parent 42 --type Feature --titles "Auth flow|Dashboard" --labels "enhancement"
HELP
}

# --- Parse arguments ---
PARENT="" TYPE="" TITLES="" LABELS="" ASSIGNEE="@me" PROJECT="Nebula" DRY_RUN=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --parent)   PARENT="$2"; shift 2 ;;
    --type)     TYPE="$2"; shift 2 ;;
    --titles)   TITLES="$2"; shift 2 ;;
    --labels)   LABELS="$2"; shift 2 ;;
    --assignee) ASSIGNEE="$2"; shift 2 ;;
    --project)  PROJECT="$2"; shift 2 ;;
    --dry-run)  DRY_RUN="--dry-run"; shift ;;
    --help)     show_help; exit 0 ;;
    *)          echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# --- Validate ---
if [[ -z "$PARENT" ]]; then echo "Error: --parent is required" >&2; exit 1; fi
if [[ -z "$TYPE" ]]; then echo "Error: --type is required" >&2; exit 1; fi
if [[ -z "$TITLES" ]]; then echo "Error: --titles is required" >&2; exit 1; fi

# Children that cannot have children themselves
if [[ "$TYPE" == "Epic" ]]; then
  echo "Error: Epic cannot be a child type" >&2; exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Split titles and create each ---
IFS='|' read -ra TITLE_ARRAY <<< "$TITLES"

RESULTS="[]"
SUCCESS=0
FAILED=0

for title in "${TITLE_ARRAY[@]}"; do
  # Trim whitespace
  title=$(echo "$title" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  if [[ -z "$title" ]]; then continue; fi

  echo "Creating: $title" >&2

  CMD=("$SCRIPT_DIR/create-issue.sh" --title "$title" --type "$TYPE" --parent "$PARENT" --assignee "$ASSIGNEE" --project "$PROJECT")
  if [[ -n "$LABELS" ]]; then CMD+=(--labels "$LABELS"); fi
  if [[ -n "$DRY_RUN" ]]; then CMD+=($DRY_RUN); fi

  if RESULT=$(bash "${CMD[@]}" 2>/dev/null); then
    RESULTS=$(echo "$RESULTS" | jq --argjson item "$RESULT" '. + [$item]')
    SUCCESS=$((SUCCESS + 1))
  else
    echo "  Failed to create: $title" >&2
    FAILED=$((FAILED + 1))
  fi
done

echo "" >&2
echo "Created $SUCCESS of $((SUCCESS + FAILED)) sub-issues under #$PARENT" >&2
if [[ $FAILED -gt 0 ]]; then
  echo "Warning: $FAILED issue(s) failed to create" >&2
fi

echo "$RESULTS"
