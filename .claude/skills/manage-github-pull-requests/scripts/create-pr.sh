#!/usr/bin/env bash
set -euo pipefail

# create-pr.sh — Creates a GitHub PR with conventional commit title,
# auto-populated template body, labels, assignee, reviewer, and issue linkage.

show_help() {
cat <<'HELP'
Usage: create-pr.sh --title TITLE [OPTIONS]

Creates a pull request with full convention enforcement.

Required:
  --title TITLE          PR title in conventional commit format: type(scope): description

Optional:
  --body BODY            Custom PR body (overrides template)
  --body-file FILE       Read body from file (overrides --body)
  --base BRANCH          Base branch (default: main)
  --labels LABELS        Comma-separated labels
  --assignee USER        GitHub username (default: @me)
  --reviewer REVIEWER    Reviewer user or team (default: Derivco/aurora-core)
  --closes ISSUES        Comma-separated issue numbers to close (e.g., 42,85)
  --addresses ISSUES     Comma-separated issue numbers to reference without closing
  --project PROJECT      Project name (default: Nebula)
  --draft                Create as draft PR
  --fill-body            Auto-populate body from PR template with provided details
  --description DESC     Description text to fill into the template body
  --change-type TYPE     Type of change: bug-fix, feature, breaking, docs, refactor, perf, test
  --dry-run              Print commands without executing
  --help                 Show this help

Output (JSON to stdout):
  { "number": 123, "url": "https://...", "draft": false, "issues": [42, 85] }

Title Format:
  type(scope): description
  Types: feat, fix, refactor, docs, chore, ci, perf, build
  Example: feat(frontend): add chat message retry button

Examples:
  create-pr.sh --title "feat(frontend): add retry button" --closes 42
  create-pr.sh --title "fix(ctx-svc): handle null context" --closes 85 --draft
  create-pr.sh --title "docs(skills): update PR workflow" --addresses 100
HELP
}

# --- Parse arguments ---
TITLE="" BODY="" BODY_FILE="" BASE="main" LABELS="" ASSIGNEE="@me"
REVIEWER="Derivco/aurora-core" CLOSES="" ADDRESSES="" PROJECT="Nebula"
DRAFT=false FILL_BODY=true DESCRIPTION="" CHANGE_TYPE="" DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title)       TITLE="$2"; shift 2 ;;
    --body)        BODY="$2"; FILL_BODY=false; shift 2 ;;
    --body-file)   BODY_FILE="$2"; FILL_BODY=false; shift 2 ;;
    --base)        BASE="$2"; shift 2 ;;
    --labels)      LABELS="$2"; shift 2 ;;
    --assignee)    ASSIGNEE="$2"; shift 2 ;;
    --reviewer)    REVIEWER="$2"; shift 2 ;;
    --closes)      CLOSES="$2"; shift 2 ;;
    --addresses)   ADDRESSES="$2"; shift 2 ;;
    --project)     PROJECT="$2"; shift 2 ;;
    --draft)       DRAFT=true; shift ;;
    --fill-body)   FILL_BODY=true; shift ;;
    --description) DESCRIPTION="$2"; shift 2 ;;
    --change-type) CHANGE_TYPE="$2"; shift 2 ;;
    --dry-run)     DRY_RUN=true; shift ;;
    --help)        show_help; exit 0 ;;
    *)             echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# --- Validate required fields ---
if [[ -z "$TITLE" ]]; then echo "Error: --title is required" >&2; exit 1; fi

# Validate conventional commit format
if ! echo "$TITLE" | grep -qE '^(feat|fix|refactor|docs|chore|ci|perf|build)(!?\(.+\))?: .+'; then
  echo "Error: title must follow conventional commit format: type(scope): description" >&2
  echo "  Types: feat, fix, refactor, docs, chore, ci, perf, build" >&2
  echo "  Example: feat(frontend): add chat message retry button" >&2
  exit 1
fi

# Warn if no issues linked
if [[ -z "$CLOSES" && -z "$ADDRESSES" ]]; then
  echo "Warning: no issues linked — PRs should reference at least one issue" >&2
fi

# --- Resolve body ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")

if [[ -n "$BODY_FILE" ]]; then
  if [[ ! -f "$BODY_FILE" ]]; then
    echo "Error: body file not found: $BODY_FILE" >&2; exit 1
  fi
  BODY=$(cat "$BODY_FILE")
elif [[ -z "$BODY" && "$FILL_BODY" == "true" ]]; then
  # Use PR template
  TEMPLATE_FILE="$REPO_ROOT/.github/pull_request_template.md"
  if [[ -f "$TEMPLATE_FILE" ]]; then
    BODY=$(cat "$TEMPLATE_FILE")
  else
    # Fallback to asset template
    ASSET_TEMPLATE="$SCRIPT_DIR/../assets/pr-body-template.md"
    if [[ -f "$ASSET_TEMPLATE" ]]; then
      BODY=$(cat "$ASSET_TEMPLATE")
    else
      BODY="## Description\n\n<!-- Describe the changes -->"
    fi
  fi

  # Fill in description if provided
  if [[ -n "$DESCRIPTION" ]]; then
    BODY=$(echo "$BODY" | sed "s|<!-- Provide a brief description of the changes in this pull request -->|$DESCRIPTION|")
  fi

  # Fill in change type checkboxes
  if [[ -n "$CHANGE_TYPE" ]]; then
    case "$CHANGE_TYPE" in
      bug-fix)   BODY=$(echo "$BODY" | sed 's/- \[ \] Bug fix/- [x] Bug fix/') ;;
      feature)   BODY=$(echo "$BODY" | sed 's/- \[ \] New feature/- [x] New feature/') ;;
      breaking)  BODY=$(echo "$BODY" | sed 's/- \[ \] Breaking change/- [x] Breaking change/') ;;
      docs)      BODY=$(echo "$BODY" | sed 's/- \[ \] Documentation update/- [x] Documentation update/') ;;
      refactor)  BODY=$(echo "$BODY" | sed 's/- \[ \] Refactoring/- [x] Refactoring/') ;;
      perf)      BODY=$(echo "$BODY" | sed 's/- \[ \] Performance improvement/- [x] Performance improvement/') ;;
      test)      BODY=$(echo "$BODY" | sed 's/- \[ \] Test coverage/- [x] Test coverage/') ;;
    esac
  fi
fi

# --- Append issue references to body ---
ISSUE_REFS=""
if [[ -n "$CLOSES" ]]; then
  IFS=',' read -ra CLOSE_ARR <<< "$CLOSES"
  for num in "${CLOSE_ARR[@]}"; do
    num=$(echo "$num" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    ISSUE_REFS="${ISSUE_REFS}Closes #${num}\n"
  done
fi
if [[ -n "$ADDRESSES" ]]; then
  IFS=',' read -ra ADDR_ARR <<< "$ADDRESSES"
  for num in "${ADDR_ARR[@]}"; do
    num=$(echo "$num" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    ISSUE_REFS="${ISSUE_REFS}Addresses #${num}\n"
  done
fi

if [[ -n "$ISSUE_REFS" ]]; then
  # Insert issue refs into Related Issues section or append to body
  if echo "$BODY" | grep -q "Related Issues"; then
    BODY=$(echo -e "$BODY" | sed "/## Related Issues/a\\
\\
$(echo -e "$ISSUE_REFS")")
  else
    BODY=$(echo -e "${BODY}\n\n## Related Issues\n\n${ISSUE_REFS}")
  fi
fi

# --- Build gh pr create command ---
CMD=(gh pr create --title "$TITLE" --body "$(echo -e "$BODY")" --base "$BASE" --assignee "$ASSIGNEE")

if [[ -n "$LABELS" ]]; then CMD+=(--label "$LABELS"); fi
if [[ -n "$PROJECT" ]]; then CMD+=(--project "$PROJECT"); fi
if [[ "$DRAFT" == "true" ]]; then CMD+=(--draft); fi

if [[ "$DRY_RUN" == "true" ]]; then
  echo "DRY RUN — would execute:" >&2
  printf '%q ' "${CMD[@]}" >&2
  echo "" >&2
  echo "Then: gh pr edit --add-reviewer $REVIEWER" >&2

  # Build issues array
  ISSUES_JSON="[]"
  if [[ -n "$CLOSES" ]]; then
    IFS=',' read -ra ARR <<< "$CLOSES"
    for n in "${ARR[@]}"; do
      n=$(echo "$n" | sed 's/[[:space:]]//g')
      ISSUES_JSON=$(echo "$ISSUES_JSON" | jq --argjson n "$n" '. + [$n]')
    done
  fi

  jq -n --arg draft "$DRAFT" --argjson issues "$ISSUES_JSON" \
    '{number: 0, url: "dry-run", draft: ($draft == "true"), issues: $issues}'
  exit 0
fi

# --- Step 1: Create PR ---
PR_URL=$("${CMD[@]}" 2>&1)
PR_NUMBER=$(echo "$PR_URL" | grep -oE '[0-9]+$')

if [[ -z "$PR_NUMBER" ]]; then
  echo "Error: failed to create PR. Output: $PR_URL" >&2
  exit 1
fi

echo "Created PR #$PR_NUMBER: $PR_URL" >&2

# --- Step 2: Add reviewer ---
if [[ -n "$REVIEWER" ]]; then
  gh pr edit "$PR_NUMBER" --add-reviewer "$REVIEWER" >&2 2>&1 || \
    echo "Warning: could not add reviewer '$REVIEWER' — team may not be accessible" >&2
fi

# --- Output ---
ISSUES_JSON="[]"
if [[ -n "$CLOSES" ]]; then
  IFS=',' read -ra ARR <<< "$CLOSES"
  for n in "${ARR[@]}"; do
    n=$(echo "$n" | sed 's/[[:space:]]//g')
    ISSUES_JSON=$(echo "$ISSUES_JSON" | jq --argjson n "$n" '. + [$n]')
  done
fi
if [[ -n "$ADDRESSES" ]]; then
  IFS=',' read -ra ARR <<< "$ADDRESSES"
  for n in "${ARR[@]}"; do
    n=$(echo "$n" | sed 's/[[:space:]]//g')
    ISSUES_JSON=$(echo "$ISSUES_JSON" | jq --argjson n "$n" '. + [$n]')
  done
fi

jq -n \
  --arg number "$PR_NUMBER" \
  --arg url "$PR_URL" \
  --arg draft "$DRAFT" \
  --argjson issues "$ISSUES_JSON" \
  '{number: ($number | tonumber), url: $url, draft: ($draft == "true"), issues: $issues}'
