#!/usr/bin/env bash
set -euo pipefail

# query-prs.sh — Queries pull requests with filters and formatting.

show_help() {
cat <<'HELP'
Usage: query-prs.sh [OPTIONS]

Lists and queries pull requests with various filters.

Filters:
  --state STATE          PR state: open (default), closed, merged, all
  --author AUTHOR        Filter by author
  --assignee USER        Filter by assignee
  --label LABEL          Filter by label (comma-separated for multiple)
  --base BRANCH          Filter by base branch
  --head BRANCH          Filter by head branch
  --search QUERY         GitHub search query string
  --limit N              Max results (default: 30)

Display:
  --number NUMBER        View a specific PR in detail
  --json                 Output raw JSON
  --checks NUMBER        Show status checks for a PR
  --files NUMBER         Show changed files for a PR
  --reviews NUMBER       Show review status for a PR
  --help                 Show this help

Output (JSON to stdout):
  [{ "number": 123, "title": "...", "author": "...", "state": "OPEN", ... }]

Examples:
  query-prs.sh                                    # List open PRs
  query-prs.sh --state all --author octocat       # All PRs by author
  query-prs.sh --number 142                       # View specific PR
  query-prs.sh --checks 142                       # CI status checks
  query-prs.sh --files 142                        # Changed files
  query-prs.sh --reviews 142                      # Review status
  query-prs.sh --label "enhancement" --limit 10
HELP
}

# --- Parse arguments ---
STATE="open" AUTHOR="" ASSIGNEE="" LABEL="" BASE="" HEAD=""
SEARCH="" LIMIT="30" VIEW_NUMBER="" JSON_OUT=false
CHECKS="" FILES="" REVIEWS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --state)    STATE="$2"; shift 2 ;;
    --author)   AUTHOR="$2"; shift 2 ;;
    --assignee) ASSIGNEE="$2"; shift 2 ;;
    --label)    LABEL="$2"; shift 2 ;;
    --base)     BASE="$2"; shift 2 ;;
    --head)     HEAD="$2"; shift 2 ;;
    --search)   SEARCH="$2"; shift 2 ;;
    --limit)    LIMIT="$2"; shift 2 ;;
    --number)   VIEW_NUMBER="$2"; shift 2 ;;
    --json)     JSON_OUT=true; shift ;;
    --checks)   CHECKS="$2"; shift 2 ;;
    --files)    FILES="$2"; shift 2 ;;
    --reviews)  REVIEWS="$2"; shift 2 ;;
    --help)     show_help; exit 0 ;;
    *)          echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# --- View specific PR ---
if [[ -n "$VIEW_NUMBER" ]]; then
  gh pr view "$VIEW_NUMBER" --json number,title,author,state,isDraft,body,labels,assignees,reviewRequests,reviewDecision,url,headRefName,baseRefName,mergeable,createdAt,updatedAt | \
    jq '{
      number, title, state, draft: .isDraft,
      author: .author.login,
      url, head: .headRefName, base: .baseRefName,
      mergeable, reviewDecision,
      labels: [.labels[].name],
      assignees: [.assignees[].login],
      reviewers: [.reviewRequests[]? | .login // .name // .slug],
      created: .createdAt, updated: .updatedAt,
      body: (.body | if length > 500 then .[0:500] + "..." else . end)
    }'
  exit 0
fi

# --- Status checks ---
if [[ -n "$CHECKS" ]]; then
  gh pr checks "$CHECKS" --json name,state,conclusion,startedAt,completedAt 2>/dev/null | \
    jq '[.[] | {name, state, conclusion, started: .startedAt, completed: .completedAt}]' || \
    echo "[]"
  exit 0
fi

# --- Changed files ---
if [[ -n "$FILES" ]]; then
  gh pr view "$FILES" --json files | \
    jq '[.files[] | {path: .path, additions: .additions, deletions: .deletions}]'
  exit 0
fi

# --- Reviews ---
if [[ -n "$REVIEWS" ]]; then
  gh api "repos/{owner}/{repo}/pulls/$REVIEWS/reviews" --jq \
    '[.[] | {author: .user.login, state: .state, submitted: .submitted_at, body: (.body | if length > 200 then .[0:200] + "..." else . end)}]' 2>/dev/null || echo "[]"
  exit 0
fi

# --- List PRs ---
CMD=(gh pr list --limit "$LIMIT" --json number,title,author,state,isDraft,labels,headRefName,updatedAt,url)

case "$STATE" in
  open)   CMD+=(--state open) ;;
  closed) CMD+=(--state closed) ;;
  merged) CMD+=(--state merged) ;;
  all)    CMD+=(--state all) ;;
  *)      echo "Error: invalid state '$STATE'" >&2; exit 1 ;;
esac

if [[ -n "$AUTHOR" ]]; then CMD+=(--author "$AUTHOR"); fi
if [[ -n "$ASSIGNEE" ]]; then CMD+=(--assignee "$ASSIGNEE"); fi
if [[ -n "$LABEL" ]]; then CMD+=(--label "$LABEL"); fi
if [[ -n "$BASE" ]]; then CMD+=(--base "$BASE"); fi
if [[ -n "$HEAD" ]]; then CMD+=(--head "$HEAD"); fi
if [[ -n "$SEARCH" ]]; then CMD+=(--search "$SEARCH"); fi

RESULT=$("${CMD[@]}" 2>/dev/null || echo "[]")

if [[ "$JSON_OUT" == "true" ]]; then
  echo "$RESULT"
else
  echo "$RESULT" | jq '[.[] | {
    number, title,
    author: .author.login,
    state: (if .isDraft then "DRAFT" else .state end),
    labels: [.labels[].name],
    branch: .headRefName,
    updated: .updatedAt,
    url
  }]'
fi
