#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
validate-plan.sh — Validate a development plan file against structural requirements.

Usage:
  bash scripts/validate-plan.sh [plan-path]

Arguments:
  plan-path   Path to the plan file. Defaults to ".tmp/state/plan.md".

Checks:
  1. File exists and is non-empty
  2. Has "User Requirement" section
  3. Has "Files affected" list
  4. Has at least one USE CASE
  5. Has at least one FEATURE
  6. Has "Continuous Validation" or "Integration Verification" section
  7. Has "CURRENT STATUS" section
  8. Has checklist items (- [ ] or - [x] or ✅)
  9. CURRENT STATUS has at least one status marker

Output:
  JSON to stdout:
  {
    "valid": true|false,
    "path": "<path>",
    "checks": { "name": true|false, ... },
    "summary": { "passed": N, "failed": N, "total": N },
    "warnings": [...]
  }
  Diagnostics to stderr.

Exit codes:
  0  All checks passed
  1  One or more checks failed
  2  Invalid arguments (file not found)
HELP
  exit 0
}

[[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && show_help

PLAN_PATH="${1:-.tmp/state/plan.md}"
WARNINGS="[]"

add_warning() {
  WARNINGS=$(echo "$WARNINGS" | jq --arg w "$1" '. + [$w]')
}

if [[ ! -f "$PLAN_PATH" ]]; then
  echo "Error: Plan file not found at ${PLAN_PATH}" >&2
  jq -n --arg path "$PLAN_PATH" '{valid: false, path: $path, checks: {}, summary: {passed: 0, failed: 1, total: 1}, warnings: ["File not found"]}'
  exit 2
fi

CONTENT=$(cat "$PLAN_PATH")
PASSED=0
FAILED=0

check() {
  local name="$1"
  local result="$2"
  if [[ "$result" == "true" ]]; then
    PASSED=$((PASSED + 1))
  else
    FAILED=$((FAILED + 1))
    echo "FAIL: ${name}" >&2
  fi
}

# Check 1: Non-empty
[[ -s "$PLAN_PATH" ]] && C1="true" || C1="false"
check "file_non_empty" "$C1"

# Check 2: User Requirement section
echo "$CONTENT" | grep -qi "user requirement" && C2="true" || C2="false"
check "has_user_requirement" "$C2"

# Check 3: Files affected
echo "$CONTENT" | grep -qi "files affected" && C3="true" || C3="false"
check "has_files_affected" "$C3"

# Check 4: At least one USE CASE
echo "$CONTENT" | grep -qi "use case" && C4="true" || C4="false"
check "has_use_case" "$C4"

# Check 5: At least one FEATURE
echo "$CONTENT" | grep -qi "feature" && C5="true" || C5="false"
check "has_feature" "$C5"

# Check 6: Validation section
(echo "$CONTENT" | grep -qi "continuous validation" || echo "$CONTENT" | grep -qi "integration verification") && C6="true" || C6="false"
check "has_validation_section" "$C6"

# Check 7: CURRENT STATUS section
echo "$CONTENT" | grep -qi "current status" && C7="true" || C7="false"
check "has_current_status" "$C7"

# Check 8: Has checklist items
(echo "$CONTENT" | grep -qE '^\s*- \[[ xX]\]|^\s*-?\s*✅' ) && C8="true" || C8="false"
check "has_checklist_items" "$C8"

# Check 9: CURRENT STATUS has markers
STATUS_SECTION=$(echo "$CONTENT" | sed -n '/[Cc][Uu][Rr][Rr][Ee][Nn][Tt] [Ss][Tt][Aa][Tt][Uu][Ss]/,$p')
(echo "$STATUS_SECTION" | grep -qE '^\s*- \[[ xX]\]|^\s*-?\s*✅' ) && C9="true" || C9="false"
check "status_has_markers" "$C9"

TOTAL=$((PASSED + FAILED))
VALID="true"
[[ "$FAILED" -gt 0 ]] && VALID="false"

jq -n \
  --argjson valid "$VALID" \
  --arg path "$PLAN_PATH" \
  --argjson c1 "$C1" --argjson c2 "$C2" --argjson c3 "$C3" \
  --argjson c4 "$C4" --argjson c5 "$C5" --argjson c6 "$C6" \
  --argjson c7 "$C7" --argjson c8 "$C8" --argjson c9 "$C9" \
  --argjson passed "$PASSED" --argjson failed "$FAILED" --argjson total "$TOTAL" \
  --argjson warnings "$WARNINGS" \
  '{
    valid: $valid,
    path: $path,
    checks: {
      file_non_empty: $c1,
      has_user_requirement: $c2,
      has_files_affected: $c3,
      has_use_case: $c4,
      has_feature: $c5,
      has_validation_section: $c6,
      has_current_status: $c7,
      has_checklist_items: $c8,
      status_has_markers: $c9
    },
    summary: { passed: $passed, failed: $failed, total: $total },
    warnings: $warnings
  }'

[[ "$FAILED" -eq 0 ]] && exit 0 || exit 1
