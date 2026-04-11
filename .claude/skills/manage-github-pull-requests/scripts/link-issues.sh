#!/usr/bin/env bash
set -euo pipefail

# link-issues.sh — Manages issue references in PR body.
# Adds "Closes #N" or "Addresses #N", removes stale references, validates issues exist.

show_help() {
cat <<'HELP'
Usage: link-issues.sh --number NUMBER [OPTIONS]

Manages issue references in a PR body.

Required:
  --number NUMBER          PR number to modify

Operations (at least one required):
  --closes ISSUES          Comma-separated issue numbers to add as "Closes #N"
  --addresses ISSUES       Comma-separated issue numbers to add as "Addresses #N"
  --remove ISSUES          Comma-separated issue numbers to remove from body
  --list                   List currently linked issues (no modification)
  --help                   Show this help

Output (JSON to stdout):
  { "number": 123, "linked": [{"issue": 42, "type": "closes"}, ...] }

Examples:
  link-issues.sh --number 142 --closes 42,85
  link-issues.sh --number 142 --addresses 100
  link-issues.sh --number 142 --remove 42
  link-issues.sh --number 142 --list
HELP
}

# --- Parse arguments ---
NUMBER="" CLOSES="" ADDRESSES="" REMOVE="" LIST=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --number)    NUMBER="$2"; shift 2 ;;
    --closes)    CLOSES="$2"; shift 2 ;;
    --addresses) ADDRESSES="$2"; shift 2 ;;
    --remove)    REMOVE="$2"; shift 2 ;;
    --list)      LIST=true; shift ;;
    --help)      show_help; exit 0 ;;
    *)           echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$NUMBER" ]]; then echo "Error: --number is required" >&2; exit 1; fi

# --- Get current PR body ---
CURRENT_BODY=$(gh pr view "$NUMBER" --json body -q .body 2>/dev/null || echo "")

# --- List mode ---
if [[ "$LIST" == "true" ]]; then
  LINKED="[]"
  while IFS= read -r line; do
    if echo "$line" | grep -qiE '^\s*(closes|fixes|resolves)\s+#([0-9]+)'; then
      num=$(echo "$line" | grep -oE '#[0-9]+' | tr -d '#')
      LINKED=$(echo "$LINKED" | jq --arg n "$num" '. + [{"issue": ($n | tonumber), "type": "closes"}]')
    elif echo "$line" | grep -qiE '^\s*(addresses|references|relates to|part of)\s+#([0-9]+)'; then
      num=$(echo "$line" | grep -oE '#[0-9]+' | tr -d '#')
      LINKED=$(echo "$LINKED" | jq --arg n "$num" '. + [{"issue": ($n | tonumber), "type": "addresses"}]')
    fi
  done <<< "$CURRENT_BODY"

  jq -n --arg number "$NUMBER" --argjson linked "$LINKED" \
    '{number: ($number | tonumber), linked: $linked}'
  exit 0
fi

if [[ -z "$CLOSES" && -z "$ADDRESSES" && -z "$REMOVE" ]]; then
  echo "Error: at least one of --closes, --addresses, or --remove is required" >&2; exit 1
fi

NEW_BODY="$CURRENT_BODY"

# --- Remove issue references ---
if [[ -n "$REMOVE" ]]; then
  IFS=',' read -ra REMOVE_ARR <<< "$REMOVE"
  for num in "${REMOVE_ARR[@]}"; do
    num=$(echo "$num" | sed 's/[[:space:]]//g')
    echo "Removing reference to #$num" >&2
    NEW_BODY=$(echo "$NEW_BODY" | grep -viE "(closes|fixes|resolves|addresses|references|relates to|part of)\s+#${num}\b" || echo "$NEW_BODY")
  done
fi

# --- Add Closes references ---
if [[ -n "$CLOSES" ]]; then
  IFS=',' read -ra CLOSE_ARR <<< "$CLOSES"
  for num in "${CLOSE_ARR[@]}"; do
    num=$(echo "$num" | sed 's/[[:space:]]//g')
    # Validate issue exists
    if ! gh issue view "$num" --json number >/dev/null 2>&1; then
      echo "Warning: issue #$num not found — skipping" >&2
      continue
    fi
    # Check if already referenced
    if echo "$NEW_BODY" | grep -qiE "(closes|fixes|resolves)\s+#${num}\b"; then
      echo "Issue #$num already linked as closes" >&2
      continue
    fi
    echo "Adding: Closes #$num" >&2
    if echo "$NEW_BODY" | grep -q "## Related Issues"; then
      NEW_BODY=$(echo -e "${NEW_BODY}\nCloses #${num}")
    else
      NEW_BODY=$(echo -e "${NEW_BODY}\n\n## Related Issues\n\nCloses #${num}")
    fi
  done
fi

# --- Add Addresses references ---
if [[ -n "$ADDRESSES" ]]; then
  IFS=',' read -ra ADDR_ARR <<< "$ADDRESSES"
  for num in "${ADDR_ARR[@]}"; do
    num=$(echo "$num" | sed 's/[[:space:]]//g')
    if ! gh issue view "$num" --json number >/dev/null 2>&1; then
      echo "Warning: issue #$num not found — skipping" >&2
      continue
    fi
    if echo "$NEW_BODY" | grep -qiE "(addresses|references)\s+#${num}\b"; then
      echo "Issue #$num already linked as addresses" >&2
      continue
    fi
    echo "Adding: Addresses #$num" >&2
    if echo "$NEW_BODY" | grep -q "## Related Issues"; then
      NEW_BODY=$(echo -e "${NEW_BODY}\nAddresses #${num}")
    else
      NEW_BODY=$(echo -e "${NEW_BODY}\n\n## Related Issues\n\nAddresses #${num}")
    fi
  done
fi

# --- Update PR body ---
gh pr edit "$NUMBER" --body "$NEW_BODY" >&2

echo "Updated issue links on PR #$NUMBER" >&2

# --- Build output ---
LINKED="[]"
while IFS= read -r line; do
  if echo "$line" | grep -qiE '^\s*(closes|fixes|resolves)\s+#([0-9]+)'; then
    num=$(echo "$line" | grep -oE '#[0-9]+' | tr -d '#')
    LINKED=$(echo "$LINKED" | jq --arg n "$num" '. + [{"issue": ($n | tonumber), "type": "closes"}]')
  elif echo "$line" | grep -qiE '^\s*(addresses|references|relates to|part of)\s+#([0-9]+)'; then
    num=$(echo "$line" | grep -oE '#[0-9]+' | tr -d '#')
    LINKED=$(echo "$LINKED" | jq --arg n "$num" '. + [{"issue": ($n | tonumber), "type": "addresses"}]')
  fi
done <<< "$NEW_BODY"

jq -n --arg number "$NUMBER" --argjson linked "$LINKED" \
  '{number: ($number | tonumber), linked: $linked}'
