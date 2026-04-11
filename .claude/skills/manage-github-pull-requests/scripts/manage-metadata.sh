#!/usr/bin/env bash
set -euo pipefail

# manage-metadata.sh — Umbrella script for all PR metadata operations.
# Routes sub-operations to the correct command approach:
#   --labels      → gh pr edit
#   --assignee    → gh pr edit
#   --reviewer    → gh pr edit
#   --draft/ready → gh pr ready / gh api GraphQL
#   --base        → gh pr edit
#   --project     → gh api GraphQL
#   --milestone   → gh pr edit / gh api REST

show_help() {
cat <<'HELP'
Usage: manage-metadata.sh --number NUMBER [OPERATIONS...]

Manages all metadata on a GitHub pull request.

Required:
  --number NUMBER          PR number to modify

Operations (combine as needed):
  --add-labels L1,L2       Add labels (comma-separated)
  --remove-labels L1,L2    Remove labels (comma-separated)

  --assignee USER          Set assignee
  --add-assignee USER      Add an assignee
  --remove-assignee USER   Remove an assignee

  --add-reviewer USER      Add a reviewer (user or team like Derivco/aurora-core)
  --remove-reviewer USER   Remove a reviewer

  --ready                  Mark PR as ready for review (from draft)
  --draft                  Convert PR to draft

  --base BRANCH            Change base branch
  --project PROJECT        Add PR to a project
  --milestone NAME         Set milestone

Other:
  --dry-run                Print operations without executing
  --help                   Show this help

Output (JSON to stdout):
  { "number": 123, "operations": [{"op": "add-labels", "status": "ok"}, ...] }

Examples:
  manage-metadata.sh --number 142 --add-labels "enhancement,qol" --add-reviewer "Derivco/aurora-core"
  manage-metadata.sh --number 142 --ready
  manage-metadata.sh --number 142 --draft
  manage-metadata.sh --number 142 --remove-labels "bug" --add-labels "enhancement"
HELP
}

# --- Parse arguments ---
NUMBER="" DRY_RUN=false
ADD_LABELS="" REMOVE_LABELS=""
ASSIGNEE="" ADD_ASSIGNEE="" REMOVE_ASSIGNEE=""
ADD_REVIEWER="" REMOVE_REVIEWER=""
READY=false DRAFT=false
BASE="" PROJECT="" MILESTONE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --number)          NUMBER="$2"; shift 2 ;;
    --add-labels)      ADD_LABELS="$2"; shift 2 ;;
    --remove-labels)   REMOVE_LABELS="$2"; shift 2 ;;
    --assignee)        ASSIGNEE="$2"; shift 2 ;;
    --add-assignee)    ADD_ASSIGNEE="$2"; shift 2 ;;
    --remove-assignee) REMOVE_ASSIGNEE="$2"; shift 2 ;;
    --add-reviewer)    ADD_REVIEWER="$2"; shift 2 ;;
    --remove-reviewer) REMOVE_REVIEWER="$2"; shift 2 ;;
    --ready)           READY=true; shift ;;
    --draft)           DRAFT=true; shift ;;
    --base)            BASE="$2"; shift 2 ;;
    --project)         PROJECT="$2"; shift 2 ;;
    --milestone)       MILESTONE="$2"; shift 2 ;;
    --dry-run)         DRY_RUN=true; shift ;;
    --help)            show_help; exit 0 ;;
    *)                 echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$NUMBER" ]]; then echo "Error: --number is required" >&2; exit 1; fi

RESULTS="[]"

add_result() {
  local op="$1" status="$2" detail="${3:-}"
  RESULTS=$(echo "$RESULTS" | jq --arg op "$op" --arg status "$status" --arg detail "$detail" \
    '. + [{ op: $op, status: $status } + (if $detail != "" then { detail: $detail } else {} end)]')
}

# --- Labels via gh pr edit ---
if [[ -n "$ADD_LABELS" ]]; then
  echo "Adding labels: $ADD_LABELS" >&2
  if [[ "$DRY_RUN" == "false" ]]; then
    gh pr edit "$NUMBER" --add-label "$ADD_LABELS" >&2 2>&1 && \
      add_result "add-labels" "ok" "$ADD_LABELS" || add_result "add-labels" "error" "Failed"
  else
    add_result "add-labels" "dry-run" "$ADD_LABELS"
  fi
fi

if [[ -n "$REMOVE_LABELS" ]]; then
  echo "Removing labels: $REMOVE_LABELS" >&2
  if [[ "$DRY_RUN" == "false" ]]; then
    gh pr edit "$NUMBER" --remove-label "$REMOVE_LABELS" >&2 2>&1 && \
      add_result "remove-labels" "ok" "$REMOVE_LABELS" || add_result "remove-labels" "error" "Failed"
  else
    add_result "remove-labels" "dry-run" "$REMOVE_LABELS"
  fi
fi

# --- Assignee ---
if [[ -n "$ASSIGNEE" ]]; then
  echo "Setting assignee: $ASSIGNEE" >&2
  if [[ "$DRY_RUN" == "false" ]]; then
    gh pr edit "$NUMBER" --add-assignee "$ASSIGNEE" >&2 2>&1 && \
      add_result "assignee" "ok" "$ASSIGNEE" || add_result "assignee" "error" "$ASSIGNEE"
  else
    add_result "assignee" "dry-run" "$ASSIGNEE"
  fi
fi

if [[ -n "$ADD_ASSIGNEE" ]]; then
  echo "Adding assignee: $ADD_ASSIGNEE" >&2
  if [[ "$DRY_RUN" == "false" ]]; then
    gh pr edit "$NUMBER" --add-assignee "$ADD_ASSIGNEE" >&2 2>&1 && \
      add_result "add-assignee" "ok" "$ADD_ASSIGNEE" || add_result "add-assignee" "error" "$ADD_ASSIGNEE"
  else
    add_result "add-assignee" "dry-run" "$ADD_ASSIGNEE"
  fi
fi

if [[ -n "$REMOVE_ASSIGNEE" ]]; then
  echo "Removing assignee: $REMOVE_ASSIGNEE" >&2
  if [[ "$DRY_RUN" == "false" ]]; then
    gh pr edit "$NUMBER" --remove-assignee "$REMOVE_ASSIGNEE" >&2 2>&1 && \
      add_result "remove-assignee" "ok" "$REMOVE_ASSIGNEE" || add_result "remove-assignee" "error" "$REMOVE_ASSIGNEE"
  else
    add_result "remove-assignee" "dry-run" "$REMOVE_ASSIGNEE"
  fi
fi

# --- Reviewer ---
if [[ -n "$ADD_REVIEWER" ]]; then
  echo "Adding reviewer: $ADD_REVIEWER" >&2
  if [[ "$DRY_RUN" == "false" ]]; then
    gh pr edit "$NUMBER" --add-reviewer "$ADD_REVIEWER" >&2 2>&1 && \
      add_result "add-reviewer" "ok" "$ADD_REVIEWER" || add_result "add-reviewer" "error" "$ADD_REVIEWER"
  else
    add_result "add-reviewer" "dry-run" "$ADD_REVIEWER"
  fi
fi

if [[ -n "$REMOVE_REVIEWER" ]]; then
  echo "Removing reviewer: $REMOVE_REVIEWER" >&2
  if [[ "$DRY_RUN" == "false" ]]; then
    gh pr edit "$NUMBER" --remove-reviewer "$REMOVE_REVIEWER" >&2 2>&1 && \
      add_result "remove-reviewer" "ok" "$REMOVE_REVIEWER" || add_result "remove-reviewer" "error" "$REMOVE_REVIEWER"
  else
    add_result "remove-reviewer" "dry-run" "$REMOVE_REVIEWER"
  fi
fi

# --- Draft / Ready ---
if [[ "$READY" == "true" ]]; then
  echo "Marking PR as ready for review" >&2
  if [[ "$DRY_RUN" == "false" ]]; then
    gh pr ready "$NUMBER" >&2 2>&1 && \
      add_result "ready" "ok" || add_result "ready" "error" "Failed to mark ready"
  else
    add_result "ready" "dry-run"
  fi
fi

if [[ "$DRAFT" == "true" ]]; then
  echo "Converting PR to draft" >&2
  if [[ "$DRY_RUN" == "false" ]]; then
    # gh pr ready --undo is not available — use GraphQL
    OWNER=$(gh repo view --json owner -q .owner.login)
    REPO=$(gh repo view --json name -q .name)
    PR_NODE_ID=$(gh api "repos/$OWNER/$REPO/pulls/$NUMBER" --jq '.node_id' 2>/dev/null || echo "")
    if [[ -n "$PR_NODE_ID" ]]; then
      gh api graphql -f query='
      mutation($prId: ID!) {
        convertPullRequestToDraft(input: { pullRequestId: $prId }) {
          pullRequest { isDraft }
        }
      }' -f prId="$PR_NODE_ID" >/dev/null 2>&1 && \
        add_result "draft" "ok" || add_result "draft" "error" "GraphQL mutation failed"
    else
      add_result "draft" "error" "Could not get PR node ID"
    fi
  else
    add_result "draft" "dry-run"
  fi
fi

# --- Base branch ---
if [[ -n "$BASE" ]]; then
  echo "Changing base branch to: $BASE" >&2
  if [[ "$DRY_RUN" == "false" ]]; then
    gh pr edit "$NUMBER" --base "$BASE" >&2 2>&1 && \
      add_result "base" "ok" "$BASE" || add_result "base" "error" "$BASE"
  else
    add_result "base" "dry-run" "$BASE"
  fi
fi

# --- Project ---
if [[ -n "$PROJECT" ]]; then
  echo "Adding to project: $PROJECT" >&2
  if [[ "$DRY_RUN" == "false" ]]; then
    OWNER=$(gh repo view --json owner -q .owner.login)
    REPO=$(gh repo view --json name -q .name)

    PROJECT_QUERY=$(gh api graphql -f query='
    query($owner: String!) {
      organization(login: $owner) {
        projectsV2(first: 20) { nodes { id title } }
      }
    }' -f owner="$OWNER" 2>/dev/null || \
    gh api graphql -f query='
    query($owner: String!) {
      user(login: $owner) {
        projectsV2(first: 20) { nodes { id title } }
      }
    }' -f owner="$OWNER" 2>/dev/null || echo "{}")

    TARGET_PROJECT_ID=$(echo "$PROJECT_QUERY" | jq -r --arg p "$PROJECT" '.. | .nodes? // [] | .[] | select(.title == $p) | .id' 2>/dev/null | head -1)

    if [[ -n "$TARGET_PROJECT_ID" ]]; then
      PR_NODE_ID=$(gh api "repos/$OWNER/$REPO/pulls/$NUMBER" --jq '.node_id' 2>/dev/null || echo "")
      if [[ -n "$PR_NODE_ID" ]]; then
        gh api graphql -f query='
        mutation($projectId: ID!, $contentId: ID!) {
          addProjectV2ItemById(input: { projectId: $projectId, contentId: $contentId }) {
            item { id }
          }
        }' -f projectId="$TARGET_PROJECT_ID" -f contentId="$PR_NODE_ID" >/dev/null 2>&1 && \
          add_result "project" "ok" "$PROJECT" || add_result "project" "error" "Failed to add to project"
      else
        add_result "project" "error" "Could not get PR node ID"
      fi
    else
      add_result "project" "error" "Project '$PROJECT' not found"
    fi
  else
    add_result "project" "dry-run" "$PROJECT"
  fi
fi

# --- Milestone ---
if [[ -n "$MILESTONE" ]]; then
  echo "Setting milestone: $MILESTONE" >&2
  if [[ "$DRY_RUN" == "false" ]]; then
    gh pr edit "$NUMBER" --milestone "$MILESTONE" >&2 2>&1 && \
      add_result "milestone" "ok" "$MILESTONE" || add_result "milestone" "error" "$MILESTONE"
  else
    add_result "milestone" "dry-run" "$MILESTONE"
  fi
fi

# --- Output ---
jq -n --arg number "$NUMBER" --argjson operations "$RESULTS" \
  '{number: ($number | tonumber), operations: $operations}'
