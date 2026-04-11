#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
validate.sh — Validate an Agent Skill directory against the spec.

Usage:
  bash scripts/validate.sh <skill-path>

Arguments:
  skill-path   Required. Path to the skill directory (e.g., ".claude/skills/my-skill").

Checks:
  1.  SKILL.md exists
  2.  Frontmatter has name and description
  3.  Name matches directory name
  4.  Name is valid kebab-case (1-64 chars)
  5.  Description is non-empty and <= 1024 chars
  6.  Body is <= 500 lines (warning, not failure)
  7.  No Windows-style paths in file references
  8.  Subdirectories are recognized (scripts/, references/, assets/)
  9.  No consecutive hyphens in name
  10. No reserved words in name ("anthropic", "claude")
  11. Check for user-invocable typo (user-invocable)
  12. Frontmatter keys are recognized
  13. allowed-tools is not present (unsupported by Claude Code)
  14. Body has "When to Use" section (warn)
  15. Body has "Workflow" section (warn)
  16. Body has "Edge Cases" section (warn)
  17. Body has "Example Inputs" or example content (warn)
  18. Body has "File References" or file reference links (warn)

Output:
  JSON object with pass/warn/fail results per check.

Exit codes:
  0  All checks pass (warnings ok)
  1  One or more checks failed
  2  Invalid arguments
HELP
  exit 0
}


[[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && show_help

SKILL_PATH="${1:-}"

if [[ -z "$SKILL_PATH" ]]; then
  echo "Error: skill-path is required."
  echo "Usage: bash scripts/validate.sh <skill-path>"
  exit 2
fi

if [[ ! -d "$SKILL_PATH" ]]; then
  echo "Error: directory not found: $SKILL_PATH"
  exit 2
fi

SKILL_FILE="$SKILL_PATH/SKILL.md"
DIR_NAME="$(basename "$SKILL_PATH")"
HAS_FAILURES=false
HAS_WARNINGS=false

results=()

add_result() {
  local check="$1" status="$2" message="$3"
  results+=("{\"check\":\"$check\",\"status\":\"$status\",\"message\":\"$message\"}")
  [[ "$status" == "fail" ]] && HAS_FAILURES=true
  [[ "$status" == "warn" ]] && HAS_WARNINGS=true
  return 0
}

# --- Check 1: SKILL.md exists ---

if [[ ! -f "$SKILL_FILE" ]]; then
  add_result "skill-md-exists" "fail" "SKILL.md not found in $SKILL_PATH"
  # Cannot continue without the file
  printf '{"results":[%s],"summary":"fail"}\n' "$(IFS=,; echo "${results[*]}")"
  exit 1
fi

add_result "skill-md-exists" "pass" "SKILL.md found"

# --- Extract frontmatter ---

# Read between first and second --- lines only (awk stops after second ---)
FRONTMATTER=$(awk '/^---$/{n++} n==1 && !/^---$/{print} n>=2{exit}' "$SKILL_FILE") || true

if [[ -z "$FRONTMATTER" ]]; then
  add_result "frontmatter-present" "fail" "No YAML frontmatter found (missing --- delimiters)"
  printf '{"results":[%s],"summary":"fail"}\n' "$(IFS=,; echo "${results[*]}")"
  exit 1
fi

add_result "frontmatter-present" "pass" "Frontmatter found"

# --- Check 2: name field ---

NAME_VALUE=$(echo "$FRONTMATTER" | grep -E '^name:' | head -1 | sed 's/^name:[[:space:]]*//' | tr -d '"' | tr -d "'") || true

if [[ -z "$NAME_VALUE" ]]; then
  add_result "name-present" "fail" "name field missing from frontmatter"
else
  add_result "name-present" "pass" "name: $NAME_VALUE"

  # Check 3: name matches directory
  if [[ "$NAME_VALUE" != "$DIR_NAME" ]]; then
    add_result "name-matches-dir" "fail" "name '$NAME_VALUE' does not match directory '$DIR_NAME'"
  else
    add_result "name-matches-dir" "pass" "name matches directory"
  fi

  # Check 4: name is valid kebab-case
  KEBAB_REGEX='^[a-z0-9]+(-[a-z0-9]+)*$'
  if ! [[ "$NAME_VALUE" =~ $KEBAB_REGEX ]]; then
    add_result "name-format" "fail" "name is not valid kebab-case: $NAME_VALUE"
  elif [[ ${#NAME_VALUE} -gt 64 ]]; then
    add_result "name-format" "fail" "name exceeds 64 characters: ${#NAME_VALUE}"
  else
    add_result "name-format" "pass" "name is valid kebab-case (${#NAME_VALUE} chars)"
  fi

  # Check 9: no consecutive hyphens
  if [[ "$NAME_VALUE" == *--* ]]; then
    add_result "name-no-consecutive-hyphens" "fail" "name contains consecutive hyphens: $NAME_VALUE"
  else
    add_result "name-no-consecutive-hyphens" "pass" "no consecutive hyphens"
  fi

  # Check 10: no reserved words
  if [[ "$NAME_VALUE" == *anthropic* || "$NAME_VALUE" == *claude* ]]; then
    add_result "name-no-reserved-words" "fail" "name contains reserved word (anthropic/claude): $NAME_VALUE"
  else
    add_result "name-no-reserved-words" "pass" "no reserved words in name"
  fi
fi

# --- Check 5: description field ---

DESC_VALUE=$(echo "$FRONTMATTER" | grep -E '^description:' | head -1 | sed 's/^description:[[:space:]]*//') || true

if [[ -z "$DESC_VALUE" ]]; then
  add_result "description-present" "fail" "description field missing from frontmatter"
else
  DESC_LEN=${#DESC_VALUE}
  if [[ $DESC_LEN -gt 1024 ]]; then
    add_result "description-length" "fail" "description exceeds 1024 chars: $DESC_LEN"
  else
    add_result "description-length" "pass" "description is $DESC_LEN chars"
  fi
  add_result "description-present" "pass" "description present"
fi

# --- Check 6: body line count ---

BODY_START=$(grep -n '^---$' "$SKILL_FILE" | sed -n '2p' | cut -d: -f1) || true
if [[ -n "$BODY_START" ]]; then
  TOTAL_LINES=$(wc -l < "$SKILL_FILE" | tr -d ' ')
  BODY_LINES=$((TOTAL_LINES - BODY_START))
  if [[ $BODY_LINES -gt 500 ]]; then
    add_result "body-length" "warn" "SKILL.md body is $BODY_LINES lines (recommended: < 500)"
  else
    add_result "body-length" "pass" "SKILL.md body is $BODY_LINES lines"
  fi
fi

# --- Check 7: Windows-style paths ---

win_paths_found=false
if (set +o pipefail; grep -rn '\\' "$SKILL_PATH"/*.md 2>/dev/null | grep -v '\\n' | grep -q '\\\\' 2>/dev/null); then
  win_paths_found=true
fi
if $win_paths_found; then
  add_result "no-windows-paths" "warn" "Possible Windows-style backslash paths detected"
else
  add_result "no-windows-paths" "pass" "No Windows-style paths"
fi

# --- Check 8: recognized subdirectories ---

UNRECOGNIZED=()
for dir in "$SKILL_PATH"/*/; do
  [[ ! -d "$dir" ]] && continue
  dirname="$(basename "$dir")"
  case "$dirname" in
    scripts|references|assets|examples) ;;
    *) UNRECOGNIZED+=("$dirname") ;;
  esac
done

if [[ ${#UNRECOGNIZED[@]} -gt 0 ]]; then
  add_result "recognized-dirs" "warn" "Unrecognized subdirectories: ${UNRECOGNIZED[*]}"
else
  add_result "recognized-dirs" "pass" "All subdirectories recognized"
fi

# --- Check 11: user-invocable typo detection ---

if echo "$FRONTMATTER" | grep -qE '^user-invocable:'; then
  add_result "invocable-typo" "warn" "Found 'user-invocable' — the correct field name is 'user-invocable'"
else
  add_result "invocable-typo" "pass" "No invocable typo detected"
fi

# --- Check 12: recognized frontmatter keys ---

KNOWN_KEYS="name|description|license|compatibility|metadata|disable-model-invocation|user-invocable|argument-hint|model|context|agent|hooks"

UNKNOWN_KEYS=()
while IFS= read -r line; do
  # Only check top-level keys (not indented)
  if [[ "$line" =~ ^[a-zA-Z] ]]; then
    key=$(echo "$line" | cut -d: -f1 | tr -d ' ')
    if ! echo "$key" | grep -qE "^($KNOWN_KEYS)$"; then
      UNKNOWN_KEYS+=("$key")
    fi
  fi
done <<< "$FRONTMATTER"

if [[ ${#UNKNOWN_KEYS[@]} -gt 0 ]]; then
  add_result "recognized-keys" "warn" "Unknown frontmatter keys: ${UNKNOWN_KEYS[*]}"
else
  add_result "recognized-keys" "pass" "All frontmatter keys recognized"
fi

# --- Checks 14-18: recommended body sections ---

if [[ -n "$BODY_START" ]]; then
  BODY_CONTENT=$(tail -n +"$((BODY_START + 1))" "$SKILL_FILE")

  # Check 14: When to Use
  if echo "$BODY_CONTENT" | grep -qiE '^##\s+(When to Use|When To Use)'; then
    add_result "section-when-to-use" "pass" "When to Use section found"
  else
    add_result "section-when-to-use" "warn" "Missing recommended section: When to Use"
  fi

  # Check 15: Workflow
  if echo "$BODY_CONTENT" | grep -qiE '^##\s+Workflow'; then
    add_result "section-workflow" "pass" "Workflow section found"
  else
    add_result "section-workflow" "warn" "Missing recommended section: Workflow"
  fi

  # Check 16: Edge Cases
  if echo "$BODY_CONTENT" | grep -qiE '^##\s+Edge Cases'; then
    add_result "section-edge-cases" "pass" "Edge Cases section found"
  else
    add_result "section-edge-cases" "warn" "Missing recommended section: Edge Cases"
  fi

  # Check 17: Example Inputs
  if echo "$BODY_CONTENT" | grep -qiE '^##\s+Example (Inputs|Usage)'; then
    add_result "section-examples" "pass" "Example Inputs section found"
  else
    add_result "section-examples" "warn" "Missing recommended section: Example Inputs"
  fi

  # Check 18: File References
  if echo "$BODY_CONTENT" | grep -qiE '^##\s+File (References|Map)'; then
    add_result "section-file-refs" "pass" "File References section found"
  else
    add_result "section-file-refs" "warn" "Missing recommended section: File References"
  fi
fi

# --- Check 13: allowed-tools must not be present ---

if echo "$FRONTMATTER" | grep -qE '^allowed-tools:'; then
  add_result "no-allowed-tools" "fail" "allowed-tools is defined in the Agent Skills spec but NOT supported by Claude Code — remove it"
else
  add_result "no-allowed-tools" "pass" "No unsupported allowed-tools field"
fi

# --- Output ---

SUMMARY="pass"
$HAS_FAILURES && SUMMARY="fail"
$HAS_WARNINGS && [[ "$SUMMARY" != "fail" ]] && SUMMARY="warn"

printf '{"results":[%s],"summary":"%s"}\n' "$(IFS=,; echo "${results[*]}")" "$SUMMARY"

$HAS_FAILURES && exit 1
exit 0
