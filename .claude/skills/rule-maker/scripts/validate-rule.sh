#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
validate-rule.sh — Validate a .claude/rules/ rule file.

Usage:
  bash scripts/validate-rule.sh <rule-path>

Arguments:
  rule-path   Path to the rule file to validate (e.g., ".claude/rules/effect-ts.md").

Checks:
  1. File exists and has .md extension
  2. Frontmatter format is valid YAML (if present)
  3. Only recognized field (paths) in frontmatter
  4. paths values are valid glob patterns (no backslashes, no trailing slashes, non-empty)
  5. File has content after frontmatter
  6. No Windows-style paths in content
  7. File size within guidelines (<200 lines recommended)

Output:
  JSON to stdout:
  {
    "path": "<rule-path>",
    "valid": true|false,
    "checks": [
      {"check": "name", "status": "pass|fail|warn", "message": "..."}
    ],
    "summary": "pass|warn|fail"
  }
  Diagnostics to stderr.

Exit codes:
  0  Success (pass or warn)
  1  Validation failures found
  2  Invalid arguments
HELP
  exit 0
}

[[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && show_help

RULE_PATH="${1:-}"
if [[ -z "$RULE_PATH" ]]; then
  echo "Error: rule-path is required." >&2
  echo "Usage: bash scripts/validate-rule.sh <rule-path>" >&2
  exit 2
fi

CHECKS="[]"
OVERALL="pass"

add_check() {
  local name="$1" status="$2" message="$3"
  CHECKS=$(echo "$CHECKS" | jq --arg n "$name" --arg s "$status" --arg m "$message" \
    '. + [{"check": $n, "status": $s, "message": $m}]')
  if [[ "$status" == "fail" ]]; then
    OVERALL="fail"
  elif [[ "$status" == "warn" && "$OVERALL" != "fail" ]]; then
    OVERALL="warn"
  fi
}

# --- Check 1: File exists ---
if [[ ! -f "$RULE_PATH" ]]; then
  add_check "file-exists" "fail" "File not found: ${RULE_PATH}"
  jq -n --arg path "$RULE_PATH" --argjson checks "$CHECKS" --arg summary "$OVERALL" \
    '{path: $path, valid: false, checks: $checks, summary: $summary}'
  exit 1
fi
add_check "file-exists" "pass" "File found"

# --- Check 2: .md extension ---
if [[ "$RULE_PATH" == *.md ]]; then
  add_check "md-extension" "pass" "Has .md extension"
else
  add_check "md-extension" "fail" "Missing .md extension"
fi

# --- Check 3: Read file content ---
CONTENT=$(cat "$RULE_PATH")
LINE_COUNT=$(echo "$CONTENT" | wc -l | tr -d ' ')

# --- Check 4: Frontmatter format ---
HAS_FRONTMATTER=false
if echo "$CONTENT" | head -1 | grep -q "^---$"; then
  # Find closing ---
  CLOSING_LINE=$(echo "$CONTENT" | tail -n +2 | grep -n "^---$" | head -1 | cut -d: -f1)
  if [[ -n "$CLOSING_LINE" ]]; then
    HAS_FRONTMATTER=true
    FRONTMATTER=$(echo "$CONTENT" | head -n "$((CLOSING_LINE + 1))" | tail -n +"2" | head -n "$((CLOSING_LINE - 1))")
    add_check "frontmatter-format" "pass" "Valid frontmatter delimiters found"

    # --- Check 5: Only recognized fields ---
    UNKNOWN_FIELDS=$(echo "$FRONTMATTER" | grep -E "^[a-zA-Z]" | grep -v "^paths:" | grep -v "^  - " || true)
    if [[ -z "$UNKNOWN_FIELDS" ]]; then
      add_check "recognized-fields" "pass" "Only recognized fields (paths)"
    else
      FIELD_NAMES=$(echo "$UNKNOWN_FIELDS" | sed 's/:.*//' | tr '\n' ', ' | sed 's/,$//')
      add_check "recognized-fields" "warn" "Unrecognized fields: ${FIELD_NAMES}"
    fi

    # --- Check 6: Validate paths patterns ---
    if echo "$FRONTMATTER" | grep -q "^paths:"; then
      PATH_PATTERNS=$(echo "$FRONTMATTER" | grep -E '^\s+- ' | sed 's/^\s*- //' | sed 's/^"//' | sed 's/"$//')
      INVALID_PATTERNS=""

      while IFS= read -r pattern; do
        [[ -z "$pattern" ]] && continue

        # Check for Windows backslashes
        if echo "$pattern" | grep -q '\\'; then
          INVALID_PATTERNS="${INVALID_PATTERNS}${pattern} (backslash), "
        fi

        # Check for trailing slash
        if [[ "$pattern" == */ ]]; then
          INVALID_PATTERNS="${INVALID_PATTERNS}${pattern} (trailing slash), "
        fi

        # Check for empty pattern
        if [[ -z "${pattern// /}" ]]; then
          INVALID_PATTERNS="${INVALID_PATTERNS}(empty pattern), "
        fi
      done <<< "$PATH_PATTERNS"

      if [[ -z "$INVALID_PATTERNS" ]]; then
        PATTERN_COUNT=$(echo "$PATH_PATTERNS" | grep -c . || true)
        add_check "paths-valid" "pass" "${PATTERN_COUNT} valid glob pattern(s)"
      else
        add_check "paths-valid" "fail" "Invalid patterns: ${INVALID_PATTERNS%%, }"
      fi
    fi
  else
    add_check "frontmatter-format" "fail" "Opening --- found but no closing ---"
  fi
fi

if [[ "$HAS_FRONTMATTER" == "false" ]]; then
  add_check "frontmatter-format" "pass" "No frontmatter (unconditional rule)"
fi

# --- Check 7: Has content after frontmatter ---
if [[ "$HAS_FRONTMATTER" == "true" ]]; then
  BODY_START=$((CLOSING_LINE + 2))
  BODY=$(echo "$CONTENT" | tail -n +"$BODY_START")
  BODY_TRIMMED=$(echo "$BODY" | sed '/^$/d')
  if [[ -n "$BODY_TRIMMED" ]]; then
    add_check "has-content" "pass" "Content found after frontmatter"
  else
    add_check "has-content" "warn" "No content after frontmatter — rule is empty"
  fi
else
  BODY_TRIMMED=$(echo "$CONTENT" | sed '/^$/d')
  if [[ -n "$BODY_TRIMMED" ]]; then
    add_check "has-content" "pass" "Content found"
  else
    add_check "has-content" "warn" "File is empty"
  fi
fi

# --- Check 8: No Windows paths in content ---
if echo "$CONTENT" | grep -qE '\\\\[a-zA-Z]'; then
  add_check "no-windows-paths" "fail" "Windows-style paths detected in content"
else
  add_check "no-windows-paths" "pass" "No Windows-style paths"
fi

# --- Check 9: File size ---
if [[ "$LINE_COUNT" -le 200 ]]; then
  add_check "file-size" "pass" "${LINE_COUNT} lines (within guidelines)"
elif [[ "$LINE_COUNT" -le 300 ]]; then
  add_check "file-size" "warn" "${LINE_COUNT} lines (consider splitting — guideline is <200)"
else
  add_check "file-size" "warn" "${LINE_COUNT} lines (strongly consider splitting — guideline is <200)"
fi

# --- Output ---
VALID=$([[ "$OVERALL" != "fail" ]] && echo "true" || echo "false")

jq -n --arg path "$RULE_PATH" --argjson valid "$VALID" \
  --argjson checks "$CHECKS" --arg summary "$OVERALL" \
  '{path: $path, valid: $valid, checks: $checks, summary: $summary}'

if [[ "$OVERALL" == "fail" ]]; then
  exit 1
fi
