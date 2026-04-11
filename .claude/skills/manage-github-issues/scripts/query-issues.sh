#!/usr/bin/env bash
set -euo pipefail

# query-issues.sh — Lists/searches issues with filters.
# Uses gh issue list for basic filters, GraphQL for project-field queries.

show_help() {
cat <<'HELP'
Usage: query-issues.sh [FILTERS...]

Lists and searches GitHub issues with filters.

Filters:
  --state STATE        open (default), closed, all
  --label LABEL        Filter by label (repeatable)
  --assignee USER      Filter by assignee (@me for current user)
  --milestone NAME     Filter by milestone
  --type TYPE          Filter by project Type field (Epic/Feature/Story/Task/Bug)
  --parent NUMBER      List children of a parent issue
  --search QUERY       Free-text search query
  --limit N            Maximum results (default: 30)
  --json               Output raw JSON (default: formatted table)
  --help               Show this help

Output:
  Table format (default): NUMBER | TYPE | TITLE | LABELS | ASSIGNEE | STATE
  JSON format (--json):   Array of issue objects

Examples:
  query-issues.sh --label "enhancement" --assignee "@me"
  query-issues.sh --type Feature --state open
  query-issues.sh --parent 42
  query-issues.sh --search "retry logic" --json
  query-issues.sh --milestone "Sprint 14" --limit 50
HELP
}

# --- Parse arguments ---
STATE="open" LABELS=() ASSIGNEE="" MILESTONE="" TYPE=""
PARENT="" SEARCH="" LIMIT=30 JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --state)     STATE="$2"; shift 2 ;;
    --label)     LABELS+=("$2"); shift 2 ;;
    --assignee)  ASSIGNEE="$2"; shift 2 ;;
    --milestone) MILESTONE="$2"; shift 2 ;;
    --type)      TYPE="$2"; shift 2 ;;
    --parent)    PARENT="$2"; shift 2 ;;
    --search)    SEARCH="$2"; shift 2 ;;
    --limit)     LIMIT="$2"; shift 2 ;;
    --json)      JSON_OUTPUT=true; shift ;;
    --help)      show_help; exit 0 ;;
    *)           echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

OWNER=$(gh repo view --json owner -q .owner.login)
REPO=$(gh repo view --json name -q .name)

# --- Build gh issue list command for basic queries ---
if [[ -z "$TYPE" && -z "$PARENT" ]]; then
  CMD=(gh issue list --state "$STATE" --limit "$LIMIT" --json number,title,labels,assignees,state,url)

  for label in "${LABELS[@]+"${LABELS[@]}"}"; do
    CMD+=(--label "$label")
  done

  if [[ -n "$ASSIGNEE" ]]; then CMD+=(--assignee "$ASSIGNEE"); fi
  if [[ -n "$MILESTONE" ]]; then CMD+=(--milestone "$MILESTONE"); fi
  if [[ -n "$SEARCH" ]]; then CMD+=(--search "$SEARCH"); fi

  ISSUES=$("${CMD[@]}" 2>/dev/null || echo "[]")

  if [[ "$JSON_OUTPUT" == "true" ]]; then
    echo "$ISSUES"
  else
    echo "$ISSUES" | jq -r '
      ["NUMBER", "TITLE", "LABELS", "ASSIGNEES", "STATE"],
      (.[] | [
        .number | tostring,
        (.title | if length > 50 then .[:47] + "..." else . end),
        ([.labels[].name] | join(",")),
        ([.assignees[].login] | join(",")),
        .state
      ]) | @tsv' | column -t -s $'\t'
  fi

# --- GraphQL for Type-filtered or parent-child queries ---
else
  if [[ -n "$PARENT" ]]; then
    # Find children by searching for "Part of #N" in body
    SEARCH_QUERY="is:issue repo:$OWNER/$REPO \"Part of #$PARENT\""
    if [[ "$STATE" != "all" ]]; then
      SEARCH_QUERY="$SEARCH_QUERY is:$STATE"
    fi

    ISSUES=$(gh api graphql -f query='
    query($searchQuery: String!, $limit: Int!) {
      search(query: $searchQuery, type: ISSUE, first: $limit) {
        nodes {
          ... on Issue {
            number
            title
            state
            labels(first: 10) { nodes { name } }
            assignees(first: 5) { nodes { login } }
            url
          }
        }
      }
    }' -f searchQuery="$SEARCH_QUERY" -F limit="$LIMIT" 2>/dev/null || echo '{"data":{"search":{"nodes":[]}}}')

    ISSUES=$(echo "$ISSUES" | jq '[.data.search.nodes[] | {
      number, title, state,
      labels: [.labels.nodes[].name],
      assignees: [.assignees.nodes[].login],
      url
    }]')

  elif [[ -n "$TYPE" ]]; then
    # Get all issues from the project, filter by Type field
    # First, get the project
    ALL_ISSUES=$(gh issue list --state "$STATE" --limit "$LIMIT" --json number,title,labels,assignees,state,url 2>/dev/null || echo "[]")

    # Filter by checking each issue's project Type (batch via GraphQL)
    ISSUE_NUMBERS=$(echo "$ALL_ISSUES" | jq -r '.[].number')

    FILTERED="[]"
    for num in $ISSUE_NUMBERS; do
      ITEM_TYPE=$(gh api graphql -f query='
      query($owner: String!, $repo: String!, $number: Int!) {
        repository(owner: $owner, name: $repo) {
          issue(number: $number) {
            projectItems(first: 5) {
              nodes {
                fieldValueByName(name: "Type") {
                  ... on ProjectV2ItemFieldSingleSelectValue { name }
                }
              }
            }
          }
        }
      }' -f owner="$OWNER" -f repo="$REPO" -F number="$num" -q '.data.repository.issue.projectItems.nodes[0].fieldValueByName.name' 2>/dev/null || echo "")

      if [[ "$ITEM_TYPE" == "$TYPE" ]]; then
        ITEM=$(echo "$ALL_ISSUES" | jq --argjson n "$num" '.[] | select(.number == $n)')
        FILTERED=$(echo "$FILTERED" | jq --argjson item "$ITEM" '. + [$item]')
      fi
    done
    ISSUES="$FILTERED"
  fi

  if [[ "$JSON_OUTPUT" == "true" ]]; then
    echo "$ISSUES"
  else
    echo "$ISSUES" | jq -r '
      ["NUMBER", "TITLE", "LABELS", "ASSIGNEES", "STATE"],
      (.[] | [
        .number | tostring,
        (.title | if length > 50 then .[:47] + "..." else . end),
        (.labels | if type == "array" then join(",") else "" end),
        (.assignees | if type == "array" then join(",") else "" end),
        .state
      ]) | @tsv' | column -t -s $'\t'
  fi
fi
