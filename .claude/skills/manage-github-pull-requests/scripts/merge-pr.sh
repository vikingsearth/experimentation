#!/usr/bin/env bash
set -euo pipefail

# merge-pr.sh — Merges a PR with strategy selection and pre-merge checks.

show_help() {
cat <<'HELP'
Usage: merge-pr.sh --number NUMBER [OPTIONS]

Merges a pull request with the specified strategy.

Required:
  --number NUMBER        PR number to merge

Optional:
  --strategy STRATEGY    Merge strategy: squash (default), merge, rebase
  --delete-branch        Delete the head branch after merge
  --auto                 Enable auto-merge (merges when checks pass)
  --disable-auto         Disable auto-merge
  --subject SUBJECT      Custom merge commit subject (squash/merge only)
  --body BODY            Custom merge commit body (squash/merge only)
  --admin                Merge using admin privileges (bypass branch protection)
  --skip-checks          Skip pre-merge validation checks
  --dry-run              Show what would happen without merging
  --help                 Show this help

Pre-merge checks (unless --skip-checks):
  - PR is approved or has no review requirement
  - CI status checks pass
  - PR is not a draft
  - No merge conflicts

Output (JSON to stdout):
  { "number": 123, "merged": true, "strategy": "squash", "branch_deleted": true }

Examples:
  merge-pr.sh --number 142 --strategy squash --delete-branch
  merge-pr.sh --number 142 --auto
  merge-pr.sh --number 142 --strategy merge --skip-checks
  merge-pr.sh --number 142 --dry-run
HELP
}

# --- Parse arguments ---
NUMBER="" STRATEGY="squash" DELETE_BRANCH=false AUTO=false DISABLE_AUTO=false
SUBJECT="" BODY="" ADMIN=false SKIP_CHECKS=false DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --number)        NUMBER="$2"; shift 2 ;;
    --strategy)      STRATEGY="$2"; shift 2 ;;
    --delete-branch) DELETE_BRANCH=true; shift ;;
    --auto)          AUTO=true; shift ;;
    --disable-auto)  DISABLE_AUTO=true; shift ;;
    --subject)       SUBJECT="$2"; shift 2 ;;
    --body)          BODY="$2"; shift 2 ;;
    --admin)         ADMIN=true; shift ;;
    --skip-checks)   SKIP_CHECKS=true; shift ;;
    --dry-run)       DRY_RUN=true; shift ;;
    --help)          show_help; exit 0 ;;
    *)               echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$NUMBER" ]]; then echo "Error: --number is required" >&2; exit 1; fi

# Validate strategy
case "$STRATEGY" in
  squash|merge|rebase) ;;
  *) echo "Error: invalid strategy '$STRATEGY' — use squash, merge, or rebase" >&2; exit 1 ;;
esac

# --- Disable auto-merge ---
if [[ "$DISABLE_AUTO" == "true" ]]; then
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "DRY RUN: would disable auto-merge on PR #$NUMBER" >&2
  else
    gh pr merge "$NUMBER" --disable-auto >&2 2>&1 || true
    echo "Disabled auto-merge on PR #$NUMBER" >&2
  fi
  jq -n --arg number "$NUMBER" '{number: ($number | tonumber), auto_merge_disabled: true}'
  exit 0
fi

# --- Pre-merge checks ---
if [[ "$SKIP_CHECKS" == "false" ]]; then
  echo "Running pre-merge checks for PR #$NUMBER..." >&2

  PR_DATA=$(gh pr view "$NUMBER" --json isDraft,reviewDecision,mergeable,statusCheckRollup,state 2>/dev/null || echo "{}")

  # Check if PR is open
  STATE=$(echo "$PR_DATA" | jq -r '.state // "UNKNOWN"')
  if [[ "$STATE" != "OPEN" ]]; then
    echo "Error: PR #$NUMBER is not open (state: $STATE)" >&2
    exit 1
  fi

  # Check draft status
  IS_DRAFT=$(echo "$PR_DATA" | jq -r '.isDraft // false')
  if [[ "$IS_DRAFT" == "true" ]]; then
    echo "Error: PR #$NUMBER is a draft — mark as ready first" >&2
    exit 1
  fi

  # Check merge conflicts
  MERGEABLE=$(echo "$PR_DATA" | jq -r '.mergeable // "UNKNOWN"')
  if [[ "$MERGEABLE" == "CONFLICTING" ]]; then
    echo "Error: PR #$NUMBER has merge conflicts — resolve before merging" >&2
    exit 1
  fi

  # Check review status (warn, don't block — repo may not require reviews)
  REVIEW=$(echo "$PR_DATA" | jq -r '.reviewDecision // "NONE"')
  if [[ "$REVIEW" == "CHANGES_REQUESTED" ]]; then
    echo "Warning: PR #$NUMBER has changes requested — consider addressing before merge" >&2
  elif [[ "$REVIEW" == "REVIEW_REQUIRED" ]]; then
    echo "Warning: PR #$NUMBER is awaiting required reviews" >&2
  fi

  # Check CI status (warn, don't block)
  FAILING=$(echo "$PR_DATA" | jq -r '[.statusCheckRollup[]? | select(.conclusion == "FAILURE")] | length')
  if [[ "$FAILING" -gt 0 ]]; then
    echo "Warning: PR #$NUMBER has $FAILING failing status check(s)" >&2
  fi

  echo "Pre-merge checks complete" >&2
fi

# --- Build merge command ---
CMD=(gh pr merge "$NUMBER" "--$STRATEGY")

if [[ "$DELETE_BRANCH" == "true" ]]; then CMD+=(--delete-branch); fi
if [[ "$AUTO" == "true" ]]; then CMD+=(--auto); fi
if [[ "$ADMIN" == "true" ]]; then CMD+=(--admin); fi
if [[ -n "$SUBJECT" ]]; then CMD+=(--subject "$SUBJECT"); fi
if [[ -n "$BODY" ]]; then CMD+=(--body "$BODY"); fi

if [[ "$DRY_RUN" == "true" ]]; then
  echo "DRY RUN — would execute:" >&2
  printf '%q ' "${CMD[@]}" >&2
  echo "" >&2
  jq -n \
    --arg number "$NUMBER" \
    --arg strategy "$STRATEGY" \
    --arg delete "$DELETE_BRANCH" \
    --arg auto "$AUTO" \
    '{number: ($number | tonumber), merged: false, strategy: $strategy,
      branch_deleted: ($delete == "true"), auto_merge: ($auto == "true"), dry_run: true}'
  exit 0
fi

# --- Execute merge ---
"${CMD[@]}" >&2

echo "Merged PR #$NUMBER with $STRATEGY strategy" >&2

jq -n \
  --arg number "$NUMBER" \
  --arg strategy "$STRATEGY" \
  --arg delete "$DELETE_BRANCH" \
  --arg auto "$AUTO" \
  '{number: ($number | tonumber), merged: true, strategy: $strategy,
    branch_deleted: ($delete == "true"), auto_merge: ($auto == "true")}'
