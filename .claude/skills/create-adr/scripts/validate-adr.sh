#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
validate-adr.sh — Validate an ADR file against structural requirements.

Usage:
  bash scripts/validate-adr.sh <adr-file-path>

Checks:
  1.  Filename matches pattern: adr-NNNN-<kebab-title>.md
  2.  Title heading exists: # ADR-NNNN: <title>
  3.  Status field is present and valid
  4.  Date field is present and formatted YYYY-MM-DD
  5.  Deciders field is present and non-empty
  6.  Service/Component field is present and non-empty
  7.  Context section exists and has content (2+ sentences)
  8.  Considered Options section exists with at least 2 options
  9.  Each option has Pros and Cons
  10. Decision section exists and uses active voice
  11. Consequences section has both Positive and Negative subsections
  12. File length is reasonable (target: 30-150 lines)
  13. No unfilled placeholder markers remain

Output:
  JSON object with pass/fail status and details for each check.
  Diagnostics go to stderr, structured result to stdout.

Exit codes:
  0  All checks pass
  1  One or more checks failed
  2  File not found or invalid arguments
HELP
  exit 0
}

[[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && show_help

# --- Validate arguments ---

if [[ $# -lt 1 ]]; then
  echo "Error: ADR file path is required." >&2
  echo "Usage: bash scripts/validate-adr.sh <adr-file-path>" >&2
  exit 2
fi

ADR_FILE="$1"

if [[ ! -f "$ADR_FILE" ]]; then
  echo "Error: file not found: $ADR_FILE" >&2
  exit 2
fi

# --- Validation state ---

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
CHECKS="[]"

add_check() {
  local name="$1"
  local status="$2"  # pass, fail, warn
  local message="$3"

  case "$status" in
    pass) PASS_COUNT=$((PASS_COUNT + 1)) ;;
    fail) FAIL_COUNT=$((FAIL_COUNT + 1)); echo "FAIL: $name — $message" >&2 ;;
    warn) WARN_COUNT=$((WARN_COUNT + 1)); echo "WARN: $name — $message" >&2 ;;
  esac

  # Build JSON array manually (no jq dependency)
  local entry="{\"name\": \"$name\", \"status\": \"$status\", \"message\": \"$message\"}"
  if [[ "$CHECKS" == "[]" ]]; then
    CHECKS="[$entry]"
  else
    CHECKS="${CHECKS%]}, $entry]"
  fi
}

CONTENT=$(cat "$ADR_FILE")
FILENAME=$(basename "$ADR_FILE")
LINE_COUNT=$(wc -l < "$ADR_FILE" | tr -d ' ')

# --- Check 1: Filename pattern ---

if [[ "$FILENAME" =~ ^adr-[0-9]{4}-[a-z0-9]([a-z0-9-]*[a-z0-9])?\.md$ ]]; then
  add_check "filename-pattern" "pass" "Matches adr-NNNN-kebab-title.md"
else
  add_check "filename-pattern" "fail" "Expected adr-NNNN-kebab-title.md, got: $FILENAME"
fi

# --- Check 2: Title heading ---

if echo "$CONTENT" | grep -qE '^# ADR-[0-9]{4}:'; then
  add_check "title-heading" "pass" "Title heading found"
else
  add_check "title-heading" "fail" "Missing title heading (expected: # ADR-NNNN: Title)"
fi

# --- Check 3: Status field ---

if echo "$CONTENT" | grep -qE '^\*\*Status:\*\* (Proposed|Accepted|Deprecated|Superseded)'; then
  add_check "status-field" "pass" "Valid status found"
else
  add_check "status-field" "fail" "Missing or invalid Status field (expected: Proposed, Accepted, Deprecated, or Superseded)"
fi

# --- Check 4: Date field ---

if echo "$CONTENT" | grep -qE '^\*\*Date:\*\* [0-9]{4}-[0-9]{2}-[0-9]{2}'; then
  add_check "date-field" "pass" "Date field found with YYYY-MM-DD format"
else
  add_check "date-field" "fail" "Missing or invalid Date field (expected: YYYY-MM-DD)"
fi

# --- Check 5: Deciders ---

if echo "$CONTENT" | grep -qE '^\*\*Deciders:\*\* .+'; then
  DECIDERS_VALUE=$(echo "$CONTENT" | grep -oE '^\*\*Deciders:\*\* .+' | sed 's/\*\*Deciders:\*\* //')
  if echo "$DECIDERS_VALUE" | grep -qE '^\['; then
    add_check "deciders-field" "fail" "Deciders field has placeholder value"
  else
    add_check "deciders-field" "pass" "Deciders field populated"
  fi
else
  add_check "deciders-field" "fail" "Missing Deciders field"
fi

# --- Check 6: Service/Component ---

if echo "$CONTENT" | grep -qE '^\*\*Service/Component:\*\* .+'; then
  SVC_VALUE=$(echo "$CONTENT" | grep -oE '^\*\*Service/Component:\*\* .+' | sed 's/\*\*Service\/Component:\*\* //')
  if echo "$SVC_VALUE" | grep -qE '^\['; then
    add_check "service-field" "fail" "Service/Component field has placeholder value"
  else
    add_check "service-field" "pass" "Service/Component field populated"
  fi
else
  add_check "service-field" "fail" "Missing Service/Component field"
fi

# --- Check 7: Context section ---

if echo "$CONTENT" | grep -qE '^## Context'; then
  # Count sentences (rough: periods followed by space or end of line)
  CONTEXT_BLOCK=$(echo "$CONTENT" | sed -n '/^## Context/,/^## /p' | tail -n +2 | sed '$d')
  SENTENCE_COUNT=$(echo "$CONTEXT_BLOCK" | grep -oE '\. |\.($)' | wc -l | tr -d ' ')
  if [[ "$SENTENCE_COUNT" -ge 2 ]]; then
    add_check "context-section" "pass" "Context section with $SENTENCE_COUNT+ sentences"
  elif [[ -n "$(echo "$CONTEXT_BLOCK" | tr -d '[:space:]')" ]]; then
    add_check "context-section" "warn" "Context section exists but may be too brief ($SENTENCE_COUNT sentences detected)"
  else
    add_check "context-section" "fail" "Context section is empty"
  fi
else
  add_check "context-section" "fail" "Missing Context section"
fi

# --- Check 8: Considered Options (at least 2) ---

if echo "$CONTENT" | grep -qE '^## Considered Options'; then
  OPTION_COUNT=$(echo "$CONTENT" | grep -cE '^\d+\. \*\*' || true)
  if [[ "$OPTION_COUNT" -ge 2 ]]; then
    add_check "options-count" "pass" "$OPTION_COUNT options listed"
  else
    add_check "options-count" "fail" "Need at least 2 options, found $OPTION_COUNT"
  fi
else
  add_check "options-count" "fail" "Missing Considered Options section"
fi

# --- Check 9: Options have Pros and Cons ---

PROS_COUNT=$(echo "$CONTENT" | grep -cE '\*\*Pros:\*\*' || true)
CONS_COUNT=$(echo "$CONTENT" | grep -cE '\*\*Cons:\*\*' || true)

if [[ "$PROS_COUNT" -ge 2 && "$CONS_COUNT" -ge 2 ]]; then
  add_check "options-pros-cons" "pass" "Options have Pros ($PROS_COUNT) and Cons ($CONS_COUNT)"
elif [[ "$PROS_COUNT" -ge 1 && "$CONS_COUNT" -ge 1 ]]; then
  add_check "options-pros-cons" "warn" "Some options may be missing Pros/Cons (found $PROS_COUNT Pros, $CONS_COUNT Cons)"
else
  add_check "options-pros-cons" "fail" "Options missing Pros and/or Cons markers"
fi

# --- Check 10: Decision section ---

if echo "$CONTENT" | grep -qE '^## Decision'; then
  DECISION_BLOCK=$(echo "$CONTENT" | sed -n '/^## Decision/,/^## /p' | tail -n +2 | sed '$d')
  if echo "$DECISION_BLOCK" | grep -qiE '(we will|we chose|we adopt|we are|we have decided)'; then
    add_check "decision-voice" "pass" "Decision uses active voice"
  elif [[ -n "$(echo "$DECISION_BLOCK" | tr -d '[:space:]')" ]]; then
    add_check "decision-voice" "warn" "Decision section exists but may not use active voice (expected 'We will...')"
  else
    add_check "decision-voice" "fail" "Decision section is empty"
  fi
else
  add_check "decision-voice" "fail" "Missing Decision section"
fi

# --- Check 11: Consequences section ---

HAS_POSITIVE=false
HAS_NEGATIVE=false

echo "$CONTENT" | grep -qE '^### Positive' && HAS_POSITIVE=true
echo "$CONTENT" | grep -qE '^### Negative' && HAS_NEGATIVE=true

if $HAS_POSITIVE && $HAS_NEGATIVE; then
  add_check "consequences" "pass" "Both Positive and Negative/Trade-offs subsections present"
elif echo "$CONTENT" | grep -qE '^## Consequences'; then
  add_check "consequences" "warn" "Consequences section exists but missing Positive and/or Negative subsections"
else
  add_check "consequences" "fail" "Missing Consequences section"
fi

# --- Check 12: File length ---

if [[ "$LINE_COUNT" -ge 30 && "$LINE_COUNT" -le 150 ]]; then
  add_check "file-length" "pass" "$LINE_COUNT lines (target: 30-150)"
elif [[ "$LINE_COUNT" -lt 30 ]]; then
  add_check "file-length" "warn" "$LINE_COUNT lines — may be too brief (target: 30-150)"
elif [[ "$LINE_COUNT" -le 200 ]]; then
  add_check "file-length" "warn" "$LINE_COUNT lines — consider moving detail to supplementary docs (target: 30-150)"
else
  add_check "file-length" "warn" "$LINE_COUNT lines — strongly consider supplementary docs (target: 30-150)"
fi

# --- Check 13: No unfilled placeholders ---

PLACEHOLDER_COUNT=$(echo "$CONTENT" | grep -cE '\[.*\]' | tr -d ' ')
# Filter out markdown links (which use [...](...)
BARE_PLACEHOLDERS=$(echo "$CONTENT" | grep -oE '\[[A-Z][^\]]*\]' | grep -v '](.*)'  | grep -cvE '^\[ADR' || true)

if [[ "$BARE_PLACEHOLDERS" -eq 0 ]]; then
  add_check "no-placeholders" "pass" "No unfilled placeholder markers found"
else
  add_check "no-placeholders" "warn" "$BARE_PLACEHOLDERS potential placeholder markers found — review for unfilled sections"
fi

# --- Output summary ---

OVERALL="pass"
[[ "$FAIL_COUNT" -gt 0 ]] && OVERALL="fail"

cat <<EOF
{
  "file": "$ADR_FILE",
  "overall": "$OVERALL",
  "summary": {"pass": $PASS_COUNT, "fail": $FAIL_COUNT, "warn": $WARN_COUNT, "total": $((PASS_COUNT + FAIL_COUNT + WARN_COUNT))},
  "checks": $CHECKS
}
EOF

[[ "$FAIL_COUNT" -eq 0 ]] && exit 0 || exit 1
