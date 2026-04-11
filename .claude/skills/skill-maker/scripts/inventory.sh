#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
inventory.sh — List all Agent Skills in the repository with metadata.

Usage:
  bash scripts/inventory.sh [search-path]

Arguments:
  search-path  Optional. Root directory to scan. Defaults to repo root.
              Scans for all .claude/skills/*/SKILL.md patterns.

Output:
  JSON array of skill objects with extracted metadata.

Exit codes:
  0  Success (even if no skills found)
HELP
  exit 0
}

[[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && show_help

# --- Locate search root ---

SEARCH_ROOT="${1:-}"

if [[ -z "$SEARCH_ROOT" ]]; then
  # Try to find git root
  if git rev-parse --show-toplevel &>/dev/null; then
    SEARCH_ROOT="$(git rev-parse --show-toplevel)"
  else
    SEARCH_ROOT="$(pwd)"
  fi
fi

# --- Find all SKILL.md files ---

SKILL_FILES=()
while IFS= read -r -d '' file; do
  SKILL_FILES+=("$file")
done < <(find "$SEARCH_ROOT" -path '*/.claude/skills/*/SKILL.md' -not -path '*/node_modules/*' -print0 2>/dev/null)

if [[ ${#SKILL_FILES[@]} -eq 0 ]]; then
  echo '{"skills":[],"count":0}'
  exit 0
fi

# --- Extract metadata from each skill ---

skills=()

for skill_file in "${SKILL_FILES[@]}"; do
  skill_dir="$(dirname "$skill_file")"
  dir_name="$(basename "$skill_dir")"
  rel_path="${skill_file#"$SEARCH_ROOT"/}"

  # Extract frontmatter fields (|| true guards for grep no-match under pipefail)
  frontmatter=$(awk '/^---$/{n++} n==1 && !/^---$/{print} n>=2{exit}' "$skill_file") || true

  name=$(echo "$frontmatter" | grep -E '^name:' | head -1 | sed 's/^name:[[:space:]]*//' | tr -d '"' | tr -d "'") || true
  description=$(echo "$frontmatter" | grep -E '^description:' | head -1 | sed 's/^description:[[:space:]]*//' | tr -d '"') || true
  version=$(echo "$frontmatter" | grep -E '^\s*version:' | head -1 | sed 's/.*version:[[:space:]]*//' | tr -d '"' | tr -d "'") || true
  purpose=$(echo "$frontmatter" | grep -E '^\s*purpose:' | head -1 | sed 's/.*purpose:[[:space:]]*//' | tr -d '"' | tr -d "'") || true
  user_invocable=$(echo "$frontmatter" | grep -E '^user-invocable:' | head -1 | sed 's/^user-invocable:[[:space:]]*//') || true
  model_invocable=$(echo "$frontmatter" | grep -E '^disable-model-invocation:' | head -1 | sed 's/^disable-model-invocation:[[:space:]]*//') || true

  # Count files in subdirectories
  scripts_count=$(find "$skill_dir/scripts" -type f 2>/dev/null | wc -l | tr -d ' ') || true
  refs_count=$(find "$skill_dir/references" -type f 2>/dev/null | wc -l | tr -d ' ') || true
  assets_count=$(find "$skill_dir/assets" -type f 2>/dev/null | wc -l | tr -d ' ') || true

  # Body line count
  body_start=$(grep -n '^---$' "$skill_file" | sed -n '2p' | cut -d: -f1) || true
  total_lines=$(wc -l < "$skill_file" | tr -d ' ')
  body_lines=0
  [[ -n "$body_start" ]] && body_lines=$((total_lines - body_start))

  # Build JSON (escaping description for safety)
  escaped_desc=$(echo "$description" | sed 's/"/\\"/g' | head -c 120)

  skills+=("{\"name\":\"${name:-$dir_name}\",\"path\":\"$rel_path\",\"version\":\"${version:-unset}\",\"purpose\":\"${purpose:-unset}\",\"user_invocable\":\"${user_invocable:-true}\",\"model_invocable_disabled\":\"${model_invocable:-false}\",\"body_lines\":$body_lines,\"scripts\":$scripts_count,\"references\":$refs_count,\"assets\":$assets_count,\"description\":\"$escaped_desc\"}")
done

# --- Output ---

printf '{"skills":[%s],"count":%d}\n' "$(IFS=,; echo "${skills[*]}")" "${#skills[@]}"
