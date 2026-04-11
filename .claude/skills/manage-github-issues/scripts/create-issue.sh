#!/usr/bin/env bash
set -euo pipefail

# create-issue.sh — Creates a single GitHub issue with full metadata.
# Uses three command approaches:
#   1. gh issue create  — title, body, labels, assignee, project
#   2. gh api GraphQL   — set project Type field
#   3. gh api REST/GraphQL — parent linkage

show_help() {
cat <<'HELP'
Usage: create-issue.sh --title TITLE --type TYPE [OPTIONS]

Creates a GitHub issue with full metadata: labels, type (via ProjectV2),
project assignment, assignee, and parent linkage.

Required:
  --title TITLE        Issue title
  --type TYPE          Issue type: Epic, Feature, Story, Task, Bug

Optional:
  --body BODY          Issue body (overrides template)
  --body-file FILE     Read body from file (overrides --body)
  --labels LABELS      Comma-separated labels (aurora always added)
  --assignee USER      GitHub username (default: @me)
  --project PROJECT    Project name (default: Nebula)
  --parent NUMBER      Parent issue number for linkage
  --milestone NAME     Milestone name
  --dry-run            Print commands without executing
  --help               Show this help

Output (JSON to stdout):
  { "number": 123, "url": "https://...", "type": "Feature", "parent": 42 }

Examples:
  create-issue.sh --title "Add retry logic" --type Feature --parent 42
  create-issue.sh --title "Fix null check" --type Bug --labels "bug"
  create-issue.sh --title "Sprint 14" --type Epic
HELP
}

# --- Parse arguments ---
TITLE="" TYPE="" BODY="" BODY_FILE="" LABELS="" ASSIGNEE="@me"
PROJECT="Nebula" PARENT="" MILESTONE="" DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title)    TITLE="$2"; shift 2 ;;
    --type)     TYPE="$2"; shift 2 ;;
    --body)     BODY="$2"; shift 2 ;;
    --body-file) BODY_FILE="$2"; shift 2 ;;
    --labels)   LABELS="$2"; shift 2 ;;
    --assignee) ASSIGNEE="$2"; shift 2 ;;
    --project)  PROJECT="$2"; shift 2 ;;
    --parent)   PARENT="$2"; shift 2 ;;
    --milestone) MILESTONE="$2"; shift 2 ;;
    --dry-run)  DRY_RUN=true; shift ;;
    --help)     show_help; exit 0 ;;
    *)          echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# --- Validate required fields ---
if [[ -z "$TITLE" ]]; then echo "Error: --title is required" >&2; exit 1; fi
if [[ -z "$TYPE" ]]; then echo "Error: --type is required" >&2; exit 1; fi

VALID_TYPES=("Epic" "Feature" "Story" "Task" "Bug")
type_valid=false
for vt in "${VALID_TYPES[@]}"; do
  if [[ "$TYPE" == "$vt" ]]; then type_valid=true; break; fi
done
if [[ "$type_valid" == "false" ]]; then
  echo "Error: --type must be one of: ${VALID_TYPES[*]}" >&2; exit 1
fi

# --- Validate type hierarchy if parent specified ---
if [[ -n "$PARENT" ]]; then
  PARENT_TYPE=$(gh api graphql -f query='
    query($number: Int!) {
      repository(owner: "'"$(gh repo view --json owner -q .owner.login)"'", name: "'"$(gh repo view --json name -q .name)"'") {
        issue(number: $number) { title }
      }
    }' -F "number=$PARENT" -q '.data.repository.issue.title' 2>/dev/null || echo "")

  # Type hierarchy: Epic→Feature/Story, Feature→Story/Task/Bug, Story→Task/Bug, Task→none, Bug→none
  case "$TYPE" in
    Epic)
      echo "Error: Epic cannot be a child issue" >&2; exit 1 ;;
  esac
  # Note: Full hierarchy validation requires knowing the parent's Type field,
  # which needs a GraphQL query against ProjectV2. The caller (SKILL.md workflow)
  # should validate this before invoking the script.
fi

# --- Resolve body ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/../assets"

if [[ -n "$BODY_FILE" ]]; then
  if [[ ! -f "$BODY_FILE" ]]; then
    echo "Error: body file not found: $BODY_FILE" >&2; exit 1
  fi
  BODY=$(cat "$BODY_FILE")
elif [[ -z "$BODY" ]]; then
  # Use type-specific template
  TEMPLATE_FILE="$ASSETS_DIR/template-$(echo "$TYPE" | tr '[:upper:]' '[:lower:]').md"
  if [[ -f "$TEMPLATE_FILE" ]]; then
    BODY=$(cat "$TEMPLATE_FILE")
  else
    BODY="## Description\n\n<!-- Describe the issue -->"
  fi
fi

# --- Prepend parent linkage to body ---
if [[ -n "$PARENT" ]]; then
  BODY="Part of #${PARENT}\n\n${BODY}"
fi

# --- Ensure aurora label is always included ---
if [[ -z "$LABELS" ]]; then
  LABELS="aurora"
elif [[ ! "$LABELS" =~ (^|,)aurora(,|$) ]]; then
  LABELS="aurora,$LABELS"
fi

# --- Build gh issue create command ---
CMD=(gh issue create --title "$TITLE" --body "$(echo -e "$BODY")" --label "$LABELS" --assignee "$ASSIGNEE" --project "$PROJECT")

if [[ -n "$MILESTONE" ]]; then
  CMD+=(--milestone "$MILESTONE")
fi

if [[ "$DRY_RUN" == "true" ]]; then
  echo "DRY RUN — would execute:" >&2
  printf '%q ' "${CMD[@]}" >&2
  echo "" >&2
  echo '{"number": 0, "url": "dry-run", "type": "'"$TYPE"'", "parent": "'"${PARENT:-null}"'"}'
  exit 0
fi

# --- Step 1: Create issue via gh issue create ---
ISSUE_URL=$(${CMD[@]} 2>&1)
ISSUE_NUMBER=$(echo "$ISSUE_URL" | grep -oE '[0-9]+$')

if [[ -z "$ISSUE_NUMBER" ]]; then
  echo "Error: failed to create issue. Output: $ISSUE_URL" >&2
  exit 1
fi

echo "Created issue #$ISSUE_NUMBER: $ISSUE_URL" >&2

# --- Step 2: Set Type field via GraphQL (ProjectV2) ---
# This requires finding the project, the Type field, and the option ID
OWNER=$(gh repo view --json owner -q .owner.login)
REPO=$(gh repo view --json name -q .name)

# Get the ProjectV2 item ID for our issue
PROJECT_DATA=$(gh api graphql -f query='
query($owner: String!, $repo: String!, $issueNumber: Int!) {
  repository(owner: $owner, name: $repo) {
    issue(number: $issueNumber) {
      projectItems(first: 10) {
        nodes {
          id
          project { title id }
        }
      }
    }
  }
}' -f owner="$OWNER" -f repo="$REPO" -F issueNumber="$ISSUE_NUMBER" 2>/dev/null || echo "{}")

PROJECT_ITEM_ID=$(echo "$PROJECT_DATA" | jq -r --arg proj "$PROJECT" '.data.repository.issue.projectItems.nodes[] | select(.project.title == $proj) | .id' 2>/dev/null || echo "")
PROJECT_ID=$(echo "$PROJECT_DATA" | jq -r --arg proj "$PROJECT" '.data.repository.issue.projectItems.nodes[] | select(.project.title == $proj) | .project.id' 2>/dev/null || echo "")

if [[ -n "$PROJECT_ITEM_ID" && -n "$PROJECT_ID" ]]; then
  # Get the Type field ID and option IDs
  TYPE_FIELD_DATA=$(gh api graphql -f query='
  query($projectId: ID!) {
    node(id: $projectId) {
      ... on ProjectV2 {
        field(name: "Type") {
          ... on ProjectV2SingleSelectField {
            id
            options { id name }
          }
        }
      }
    }
  }' -f projectId="$PROJECT_ID" 2>/dev/null || echo "{}")

  TYPE_FIELD_ID=$(echo "$TYPE_FIELD_DATA" | jq -r '.data.node.field.id // empty' 2>/dev/null || echo "")
  TYPE_OPTION_ID=$(echo "$TYPE_FIELD_DATA" | jq -r --arg t "$TYPE" '.data.node.field.options[] | select(.name == $t) | .id' 2>/dev/null || echo "")

  if [[ -n "$TYPE_FIELD_ID" && -n "$TYPE_OPTION_ID" ]]; then
    gh api graphql -f query='
    mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
      updateProjectV2ItemFieldValue(input: {
        projectId: $projectId
        itemId: $itemId
        fieldId: $fieldId
        value: { singleSelectOptionId: $optionId }
      }) {
        projectV2Item { id }
      }
    }' -f projectId="$PROJECT_ID" -f itemId="$PROJECT_ITEM_ID" -f fieldId="$TYPE_FIELD_ID" -f optionId="$TYPE_OPTION_ID" >/dev/null 2>&1

    echo "Set Type to '$TYPE' on project '$PROJECT'" >&2
  else
    echo "Warning: Could not find Type field or option '$TYPE' in project '$PROJECT'" >&2
  fi
else
  echo "Warning: Issue not found in project '$PROJECT' — may need manual project assignment" >&2
fi

# --- Output ---
jq -n \
  --arg number "$ISSUE_NUMBER" \
  --arg url "$ISSUE_URL" \
  --arg type "$TYPE" \
  --arg parent "${PARENT:-null}" \
  '{number: ($number | tonumber), url: $url, type: $type, parent: (if $parent == "null" then null else ($parent | tonumber) end)}'
