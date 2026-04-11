# Create Hooks — Proven Patterns

Ready-to-use hook patterns. Each includes: use case, event, matcher, implementation, and gotchas.

---

## Pattern 1: Auto-Format After Edits

**Use case**: Run prettier/eslint after every file write or edit.
**Event**: `PostToolUse` | **Matcher**: `Edit|Write` | **Type**: command (inline)

### Config

```json
{
  "matcher": "Edit|Write",
  "hooks": [
    {
      "type": "command",
      "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write 2>/dev/null || true"
    }
  ]
}
```

### Gotchas

- `|| true` prevents non-zero exit from blocking Claude
- Only formats the edited file, not all files
- Won't work if prettier isn't installed — add a check or use `which npx`

---

## Pattern 2: Block Dangerous Commands

**Use case**: Prevent `rm -rf`, `DROP TABLE`, or other destructive commands.
**Event**: `PreToolUse` | **Matcher**: `Bash` | **Type**: command (script)

### Script skeleton

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Check against blocked patterns
BLOCKED_PATTERNS=("rm -rf" "DROP TABLE" "DROP DATABASE" "truncate" "--no-verify")
for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qi "$pattern"; then
    echo "Blocked: command contains '$pattern'" >&2
    exit 2
  fi
done

exit 0
```

### Gotchas

- Case-insensitive matching (`-qi`) catches variations
- Exit 2 blocks the tool call and feeds stderr to Claude
- Add patterns incrementally — too many blocks slow down workflow

---

## Pattern 3: Protect Files From Edits

**Use case**: Prevent editing `.env`, `package-lock.json`, or other protected files.
**Event**: `PreToolUse` | **Matcher**: `Edit|Write` | **Type**: command (script)

### Script skeleton

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

PROTECTED_PATTERNS=(".env" "package-lock.json" ".git/" "node_modules/")
for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "Blocked: $FILE_PATH matches protected pattern '$pattern'" >&2
    exit 2
  fi
done

exit 0
```

### Gotchas

- Uses substring matching — `.env.example` would also be blocked. Use exact matching if needed.
- Consider `.claude/settings.local.json` for personal file protection

---

## Pattern 4: Desktop Notification

**Use case**: Get notified when Claude needs input (permission prompt, idle).
**Event**: `Notification` | **Matcher**: `*` | **Type**: command (inline, platform-specific)

### Config

```json
{
  "matcher": "",
  "hooks": [
    {
      "type": "command",
      "osx": "osascript -e 'display notification \"Claude Code needs your attention\" with title \"Claude Code\"'",
      "linux": "notify-send 'Claude Code' 'Claude Code needs your attention'",
      "command": "echo 'Notification hook fired' >&2"
    }
  ]
}
```

### Gotchas

- Use platform overrides (`osx`, `linux`) for cross-platform teams
- `command` is the fallback if no platform match
- Consider filtering matcher to `permission_prompt|idle_prompt` to reduce noise

---

## Pattern 5: Context Injection at Session Start

**Use case**: Inject project-specific context, git state, or environment info when a session starts.
**Event**: `SessionStart` | **Matcher**: `startup` | **Type**: command (script)

### Script skeleton

```bash
#!/usr/bin/env bash
set -euo pipefail

# Output goes to Claude as context
echo "## Current Project State"
echo "- Branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
echo "- Changed files: $(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')"
echo "- Last commit: $(git log --oneline -1 2>/dev/null || echo 'none')"

# Persist env vars if needed
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PROJECT_ROOT=$PWD" >> "$CLAUDE_ENV_FILE"
fi

exit 0
```

### Gotchas

- stdout is injected as context for Claude — keep it concise
- `CLAUDE_ENV_FILE` is only available in SessionStart hooks
- Use matcher `startup` to avoid re-injecting on resume/clear

---

## Pattern 6: Audit Trail / Logging

**Use case**: Log every tool invocation to a file for audit purposes.
**Event**: `PostToolUse` | **Matcher**: `*` | **Type**: command (script, async)

### Script skeleton

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
LOG_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/hook-audit.log"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TOOL=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
SESSION=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

echo "$TIMESTAMP | session=$SESSION | tool=$TOOL" >> "$LOG_FILE"
exit 0
```

### Config (with async)

```json
{
  "matcher": "",
  "hooks": [
    {
      "type": "command",
      "command": "\"$CLAUDE_PROJECT_DIR\"/scripts/hook-scripts/audit-log.sh",
      "async": true
    }
  ]
}
```

### Gotchas

- Use `async: true` so logging doesn't slow down the workflow
- Log file grows unbounded — consider rotation or max size checks
- `$CLAUDE_PROJECT_DIR` provides portable path to project root

---

## Pattern 7: Verify Before Stopping (Prompt Hook)

**Use case**: Ask Claude to verify it completed all tasks before stopping.
**Event**: `Stop` | **Matcher**: none | **Type**: prompt

### Config

```json
{
  "hooks": [
    {
      "type": "prompt",
      "prompt": "Review the conversation. Did the agent complete all requested tasks? Are there any TODO items, unfinished steps, or unresolved questions? If everything is done, respond ok=true. If not, respond ok=false with a reason explaining what's incomplete."
    }
  ]
}
```

### Gotchas

- Check `stop_hook_active` in command hooks to prevent infinite loops — prompt hooks handle this automatically
- Stop hooks fire every time Claude finishes responding, not just at task completion
- Consumes a model call each time — consider if the overhead is worthwhile

---

## Pattern 8: CLAUDE.md Protection (Real Example)

**Use case**: Guard CLAUDE.md from `/init` overwriting the complementary ownership header.
**Event**: `PostToolUse` | **Matcher**: `Write|Edit` | **Type**: command (inline + external script)

### Actual config (from this project)

```json
{
  "matcher": "Write|Edit",
  "hooks": [
    {
      "type": "command",
      "command": "jq -r '.tool_input.file_path // empty' | grep -q 'CLAUDE\\.md$' && sh $CLAUDE_PROJECT_DIR/scripts/hook-scripts/post-init-claude-md.sh || true"
    }
  ]
}
```

### Pattern analysis

- **Inline pre-filter**: `jq` + `grep` checks if the edited file is CLAUDE.md before calling the script
- **External script**: Complex re-injection logic lives in a separate `.sh` file
- **`|| true`**: Ensures non-matching files don't cause errors
- **`$CLAUDE_PROJECT_DIR`**: Portable path to project root

This is the hybrid pattern — inline command for filtering, external script for complex logic.
