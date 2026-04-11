#!/usr/bin/env bash
set -euo pipefail

# manage-metadata.sh — Umbrella script for all issue metadata operations.
# Routes sub-operations to the correct command approach:
#   --labels    → gh api REST
#   --assignee  → gh issue edit
#   --type      → gh api GraphQL (ProjectV2)
#   --project   → gh api GraphQL (ProjectV2)
#   --milestone → gh issue edit
#   --parent    → gh api GraphQL / body edit
#   --remove-parent → gh api GraphQL / body edit

show_help() {
cat <<'HELP'
Usage: manage-metadata.sh --number NUMBER [OPERATIONS...]

Manages all metadata on a GitHub issue. Each flag routes to the
correct command approach (gh issue CLI, REST API, or GraphQL API).

Required:
  --number NUMBER        Issue number to modify

Operations (combine as needed):
  --add-labels L1,L2     Add labels (comma-separated)
  --remove-labels L1,L2  Remove labels (comma-separated)
  --set-labels L1,L2     Replace all labels with these

  --assignee USER        Set assignee (use @me for current user)
  --add-assignee USER    Add an assignee
  --remove-assignee USER Remove an assignee

  --type TYPE            Set the project Type field (Epic/Feature/Story/Task/Bug)
  --project PROJECT      Add issue to a project (default lookup: Nebula)
  --milestone NAME       Set milestone

  --parent NUMBER        Link as child of parent issue
  --remove-parent        Remove parent linkage

Other:
  --dry-run              Print operations without executing
  --help                 Show this help

Output (JSON to stdout):
  { "number": 123, "operations": [{"op": "add-labels", "status": "ok"}, ...] }

Examples:
  manage-metadata.sh --number 42 --add-labels "enhancement,qol" --assignee "@me"
  manage-metadata.sh --number 42 --type Story --parent 30
  manage-metadata.sh --number 42 --remove-labels "bug" --add-labels "enhancement"
  manage-metadata.sh --number 42 --remove-parent
HELP
}

# --- Parse arguments ---
NUMBER="" DRY_RUN=false
ADD_LABELS="" REMOVE_LABELS="" SET_LABELS=""
ASSIGNEE="" ADD_ASSIGNEE="" REMOVE_ASSIGNEE=""
TYPE="" PROJECT="" MILESTONE=""
PARENT="" REMOVE_PARENT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --number)          NUMBER="$2"; shift 2 ;;
    --add-labels)      ADD_LABELS="$2"; shift 2 ;;
    --remove-labels)   REMOVE_LABELS="$2"; shift 2 ;;
    --set-labels)      SET_LABELS="$2"; shift 2 ;;
    --assignee)        ASSIGNEE="$2"; shift 2 ;;
    --add-assignee)    ADD_ASSIGNEE="$2"; shift 2 ;;
    --remove-assignee) REMOVE_ASSIGNEE="$2"; shift 2 ;;
    --type)            TYPE="$2"; shift 2 ;;
    --project)         PROJECT="$2"; shift 2 ;;
    --milestone)       MILESTONE="$2"; shift 2 ;;
    --parent)          PARENT="$2"; shift 2 ;;
    --remove-parent)   REMOVE_PARENT=true; shift ;;
    --dry-run)         DRY_RUN=true; shift ;;
    --help)            show_help; exit 0 ;;
    *)                 echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$NUMBER" ]]; then echo "Error: --number is required" >&2; exit 1; fi

OWNER=$(gh repo view --json owner -q .owner.login)
REPO=$(gh repo view --json name -q .name)
RESULTS="[]"

add_result() {
  local op="$1" status="$2" detail="${3:-}"
  RESULTS=$(echo "$RESULTS" | jq --arg op "$op" --arg status "$status" --arg detail "$detail" \
    '. + [{ op: $op, status: $status } + (if $detail != "" then { detail: $detail } else {} end)]')
}

# --- Labels via REST API ---
if [[ -n "$SET_LABELS" ]]; then
  echo "Setting labels: $SET_LABELS" >&2
  if [[ "$DRY_RUN" == "false" ]]; then
    LABEL_JSON=$(echo "$SET_LABELS" | tr ',' '\n' | jq -R . | jq -s '{labels: .}')
    gh api "repos/$OWNER/$REPO/issues/$NUMBER/labels" --method PUT --input - <<< "$LABEL_JSON" >/dev/null 2>&1 && \
      add_result "set-labels" "ok" "$SET_LABELS" || add_result "set-labels" "error" "API call failed"
  else
    add_result "set-labels" "dry-run" "$SET_LABELS"
  fi
fi

if [[ -n "$ADD_LABELS" ]]; then
  echo "Adding labels: $ADD_LABELS" >&2
  if [[ "$DRY_RUN" == "false" ]]; then
    LABEL_JSON=$(echo "$ADD_LABELS" | tr ',' '\n' | jq -R . | jq -s '{labels: .}')
    gh api "repos/$OWNER/$REPO/issues/$NUMBER/labels" --method POST --input - <<< "$LABEL_JSON" >/dev/null 2>&1 && \
      add_result "add-labels" "ok" "$ADD_LABELS" || add_result "add-labels" "error" "API call failed"
  else
    add_result "add-labels" "dry-run" "$ADD_LABELS"
  fi
fi

if [[ -n "$REMOVE_LABELS" ]]; then
  IFS=',' read -ra LABELS_ARR <<< "$REMOVE_LABELS"
  for label in "${LABELS_ARR[@]}"; do
    label=$(echo "$label" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    echo "Removing label: $label" >&2
    if [[ "$DRY_RUN" == "false" ]]; then
      # URL-encode the label name
      encoded_label=$(printf '%s' "$label" | jq -sRr @uri)
      gh api "repos/$OWNER/$REPO/issues/$NUMBER/labels/$encoded_label" --method DELETE >/dev/null 2>&1 && \
        add_result "remove-label" "ok" "$label" || add_result "remove-label" "error" "$label"
    else
      add_result "remove-label" "dry-run" "$label"
    fi
  done
fi

# --- Assignee via gh issue edit ---
if [[ -n "$ASSIGNEE" ]]; then
  echo "Setting assignee: $ASSIGNEE" >&2
  if [[ "$DRY_RUN" == "false" ]]; then
    gh issue edit "$NUMBER" --add-assignee "$ASSIGNEE" >&2 2>&1 && \
      add_result "assignee" "ok" "$ASSIGNEE" || add_result "assignee" "error" "$ASSIGNEE"
  else
    add_result "assignee" "dry-run" "$ASSIGNEE"
  fi
fi

if [[ -n "$ADD_ASSIGNEE" ]]; then
  echo "Adding assignee: $ADD_ASSIGNEE" >&2
  if [[ "$DRY_RUN" == "false" ]]; then
    gh issue edit "$NUMBER" --add-assignee "$ADD_ASSIGNEE" >&2 2>&1 && \
      add_result "add-assignee" "ok" "$ADD_ASSIGNEE" || add_result "add-assignee" "error" "$ADD_ASSIGNEE"
  else
    add_result "add-assignee" "dry-run" "$ADD_ASSIGNEE"
  fi
fi

if [[ -n "$REMOVE_ASSIGNEE" ]]; then
  echo "Removing assignee: $REMOVE_ASSIGNEE" >&2
  if [[ "$DRY_RUN" == "false" ]]; then
    gh issue edit "$NUMBER" --remove-assignee "$REMOVE_ASSIGNEE" >&2 2>&1 && \
      add_result "remove-assignee" "ok" "$REMOVE_ASSIGNEE" || add_result "remove-assignee" "error" "$REMOVE_ASSIGNEE"
  else
    add_result "remove-assignee" "dry-run" "$REMOVE_ASSIGNEE"
  fi
fi

# --- Milestone via gh issue edit ---
if [[ -n "$MILESTONE" ]]; then
  echo "Setting milestone: $MILESTONE" >&2
  if [[ "$DRY_RUN" == "false" ]]; then
    gh issue edit "$NUMBER" --milestone "$MILESTONE" >&2 2>&1 && \
      add_result "milestone" "ok" "$MILESTONE" || add_result "milestone" "error" "$MILESTONE"
  else
    add_result "milestone" "dry-run" "$MILESTONE"
  fi
fi

# --- Type via GraphQL (ProjectV2 single-select field) ---
if [[ -n "$TYPE" ]]; then
  VALID_TYPES=("Epic" "Feature" "Story" "Task" "Bug")
  type_valid=false
  for vt in "${VALID_TYPES[@]}"; do
    if [[ "$TYPE" == "$vt" ]]; then type_valid=true; break; fi
  done
  if [[ "$type_valid" == "false" ]]; then
    echo "Error: --type must be one of: ${VALID_TYPES[*]}" >&2
    add_result "type" "error" "Invalid type: $TYPE"
  else
    echo "Setting Type to: $TYPE" >&2
    if [[ "$DRY_RUN" == "false" ]]; then
      PROJ_NAME="${PROJECT:-Nebula}"

      # Find project item ID
      PROJECT_DATA=$(gh api graphql -f query='
      query($owner: String!, $repo: String!, $issueNumber: Int!) {
        repository(owner: $owner, name: $repo) {
          issue(number: $issueNumber) {
            projectItems(first: 10) {
              nodes { id project { title id } }
            }
          }
        }
      }' -f owner="$OWNER" -f repo="$REPO" -F issueNumber="$NUMBER" 2>/dev/null || echo "{}")

      PROJECT_ITEM_ID=$(echo "$PROJECT_DATA" | jq -r --arg p "$PROJ_NAME" '.data.repository.issue.projectItems.nodes[] | select(.project.title == $p) | .id' 2>/dev/null || echo "")
      PROJECT_ID=$(echo "$PROJECT_DATA" | jq -r --arg p "$PROJ_NAME" '.data.repository.issue.projectItems.nodes[] | select(.project.title == $p) | .project.id' 2>/dev/null || echo "")

      if [[ -n "$PROJECT_ITEM_ID" && -n "$PROJECT_ID" ]]; then
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
              projectId: $projectId, itemId: $itemId, fieldId: $fieldId,
              value: { singleSelectOptionId: $optionId }
            }) { projectV2Item { id } }
          }' -f projectId="$PROJECT_ID" -f itemId="$PROJECT_ITEM_ID" -f fieldId="$TYPE_FIELD_ID" -f optionId="$TYPE_OPTION_ID" >/dev/null 2>&1 && \
            add_result "type" "ok" "$TYPE" || add_result "type" "error" "GraphQL mutation failed"
        else
          add_result "type" "error" "Type field or option '$TYPE' not found in project"
        fi
      else
        add_result "type" "error" "Issue not found in project '$PROJ_NAME'"
      fi
    else
      add_result "type" "dry-run" "$TYPE"
    fi
  fi
fi

# --- Project via GraphQL ---
if [[ -n "$PROJECT" ]]; then
  echo "Adding to project: $PROJECT" >&2
  if [[ "$DRY_RUN" == "false" ]]; then
    # Find the project ID by name
    PROJECT_QUERY=$(gh api graphql -f query='
    query($owner: String!) {
      organization(login: $owner) {
        projectsV2(first: 20) {
          nodes { id title }
        }
      }
    }' -f owner="$OWNER" 2>/dev/null || \
    gh api graphql -f query='
    query($owner: String!) {
      user(login: $owner) {
        projectsV2(first: 20) {
          nodes { id title }
        }
      }
    }' -f owner="$OWNER" 2>/dev/null || echo "{}")

    TARGET_PROJECT_ID=$(echo "$PROJECT_QUERY" | jq -r --arg p "$PROJECT" '.. | .nodes? // [] | .[] | select(.title == $p) | .id' 2>/dev/null | head -1)

    if [[ -n "$TARGET_PROJECT_ID" ]]; then
      ISSUE_NODE_ID=$(gh api "repos/$OWNER/$REPO/issues/$NUMBER" --jq '.node_id' 2>/dev/null || echo "")
      if [[ -n "$ISSUE_NODE_ID" ]]; then
        gh api graphql -f query='
        mutation($projectId: ID!, $contentId: ID!) {
          addProjectV2ItemById(input: { projectId: $projectId, contentId: $contentId }) {
            item { id }
          }
        }' -f projectId="$TARGET_PROJECT_ID" -f contentId="$ISSUE_NODE_ID" >/dev/null 2>&1 && \
          add_result "project" "ok" "$PROJECT" || add_result "project" "error" "Failed to add to project"
      else
        add_result "project" "error" "Could not get issue node ID"
      fi
    else
      add_result "project" "error" "Project '$PROJECT' not found"
    fi
  else
    add_result "project" "dry-run" "$PROJECT"
  fi
fi

# --- Parent linkage ---
if [[ -n "$PARENT" ]]; then
  echo "Linking to parent: #$PARENT" >&2
  if [[ "$DRY_RUN" == "false" ]]; then
    # Prepend "Part of #N" to body if not already present
    CURRENT_BODY=$(gh issue view "$NUMBER" --json body -q .body 2>/dev/null || echo "")
    if [[ ! "$CURRENT_BODY" =~ "Part of #$PARENT" ]]; then
      NEW_BODY="Part of #${PARENT}

${CURRENT_BODY}"
      gh issue edit "$NUMBER" --body "$NEW_BODY" >&2 2>&1 && \
        add_result "parent" "ok" "#$PARENT" || add_result "parent" "error" "Failed to update body"
    else
      add_result "parent" "ok" "#$PARENT (already linked)"
    fi
  else
    add_result "parent" "dry-run" "#$PARENT"
  fi
fi

if [[ "$REMOVE_PARENT" == "true" ]]; then
  echo "Removing parent linkage" >&2
  if [[ "$DRY_RUN" == "false" ]]; then
    CURRENT_BODY=$(gh issue view "$NUMBER" --json body -q .body 2>/dev/null || echo "")
    # Remove "Part of #N" lines
    NEW_BODY=$(echo "$CURRENT_BODY" | sed '/^Part of #[0-9]*/d' | sed '/^$/{ N; /^\n$/d; }')
    gh issue edit "$NUMBER" --body "$NEW_BODY" >&2 2>&1 && \
      add_result "remove-parent" "ok" || add_result "remove-parent" "error" "Failed to update body"
  else
    add_result "remove-parent" "dry-run"
  fi
fi

# --- Output ---
jq -n --arg number "$NUMBER" --argjson operations "$RESULTS" \
  '{number: ($number | tonumber), operations: $operations}'
