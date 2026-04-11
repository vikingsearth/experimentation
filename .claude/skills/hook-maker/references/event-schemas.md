# Create Hooks — Event Input/Output Schemas

Per-event JSON schemas. Consult this when generating hook scripts to know what fields arrive on stdin and what fields to return on stdout.

## Common Input Fields (all events)

```json
{
  "session_id": "string",
  "transcript_path": "string — path to conversation JSON",
  "cwd": "string — current working directory",
  "permission_mode": "default | plan | acceptEdits | dontAsk | bypassPermissions",
  "hook_event_name": "string — event name that fired"
}
```

## Common Output Fields (all events)

```json
{
  "continue": true,           // false = stop Claude entirely
  "stopReason": "string",     // shown to user when continue=false
  "suppressOutput": false,    // true = hide stdout from verbose mode
  "systemMessage": "string"   // warning shown to user
}
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success — parse stdout as JSON |
| 2 | Blocking error — stop processing, feed stderr to Claude |
| Other | Non-blocking warning — show warning, continue |

---

## PreToolUse

**Fires**: Before a tool call executes.
**Matcher**: Tool name — `Bash`, `Edit`, `Write`, `Read`, `Glob`, `Grep`, `Task`, `WebFetch`, `WebSearch`, `mcp__<server>__<tool>`.

### Input (additional fields)

```json
{
  "tool_name": "string",
  "tool_input": {
    // Bash: { "command": "string", "description": "string", "timeout": number }
    // Edit: { "file_path": "string", "old_string": "string", "new_string": "string" }
    // Write: { "file_path": "string", "content": "string" }
    // Read: { "file_path": "string" }
  },
  "tool_use_id": "string"
}
```

### Output (hookSpecificOutput)

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow | deny | ask",
    "permissionDecisionReason": "string — shown to user",
    "updatedInput": {},          // optional — modified tool input
    "additionalContext": "string" // optional — extra context for Claude
  }
}
```

**Permission priority** (most restrictive wins across multiple hooks): `deny` > `ask` > `allow`.

---

## PostToolUse

**Fires**: After a tool call succeeds.
**Matcher**: Tool name.

### Input (additional fields)

```json
{
  "tool_name": "string",
  "tool_input": { /* same as PreToolUse */ },
  "tool_use_id": "string",
  "tool_response": "string — tool output"
}
```

### Output

```json
{
  "decision": "block",    // optional — block further processing
  "reason": "string",     // feedback to Claude
  "additionalContext": "string"
}
```

---

## PostToolUseFailure

**Fires**: After a tool call fails.
**Matcher**: Tool name.

Same input as PostToolUse. Same output format. Cannot block (tool already failed).

---

## UserPromptSubmit

**Fires**: When user submits a prompt, before processing.
**Matcher**: None.

### Input (additional fields)

```json
{
  "prompt": "string — the submitted prompt"
}
```

### Output

```json
{
  "decision": "block",        // optional — prevents processing
  "reason": "string",         // feedback
  "additionalContext": "string"
}
```

On exit 0 without `decision: "block"`, stdout text is added as context for Claude.

---

## SessionStart

**Fires**: When a session begins or resumes.
**Matcher**: `startup`, `resume`, `clear`, `compact`.

### Input (additional fields)

```json
{
  "source": "string — startup | resume | clear | compact",
  "model": "string",
  "agent_type": "string — optional"
}
```

### Output

On exit 0, stdout text is added as context for Claude. Use `additionalContext` in `hookSpecificOutput` for structured injection.

**Special**: `CLAUDE_ENV_FILE` environment variable is available (only in SessionStart). Write `export KEY=VALUE` lines to persist env vars.

---

## Stop

**Fires**: When Claude finishes responding.
**Matcher**: None.

### Input (additional fields)

```json
{
  "stop_hook_active": false  // true if this is a re-entry from a previous Stop hook
}
```

### Output

```json
{
  "decision": "block",  // prevents Claude from stopping — continues conversation
  "reason": "string"
}
```

**Important**: Check `stop_hook_active` to prevent infinite loops — if `true`, exit 0 immediately.

---

## Notification

**Fires**: When Claude Code sends a notification.
**Matcher**: `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog`.

### Input (additional fields)

```json
{
  "notification_type": "string"
}
```

No decision control. Used for side effects (desktop notifications, logging).

---

## PermissionRequest

**Fires**: When a permission dialog appears.
**Matcher**: Tool name.

### Input (additional fields)

```json
{
  "tool_name": "string",
  "tool_input": {}
}
```

### Output (hookSpecificOutput)

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PermissionRequest",
    "decision": {
      "behavior": "allow | deny"
    }
  }
}
```

**Note**: Does NOT fire in non-interactive mode (`-p`). Use PreToolUse for automated decisions.

---

## SubagentStart / SubagentStop

**Fires**: When subagents are spawned/completed.
**Matcher**: Agent type.

### Input (additional fields)

```json
{
  "agent_id": "string",
  "agent_type": "string"
}
```

SubagentStop can block with `decision: "block"`. Can inject `additionalContext`.

---

## ConfigChange

**Fires**: When a config file changes during session.
**Matcher**: `user_settings`, `project_settings`, `local_settings`, `policy_settings`, `skills`.

Can block with `decision: "block"` (except `policy_settings`).

---

## PreCompact

**Fires**: Before context compaction.
**Matcher**: `manual`, `auto`.

No decision control. Used for side effects (exporting context, saving state).

---

## SessionEnd

**Fires**: When session terminates.
**Matcher**: `clear`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other`.

No decision control. Used for cleanup, reports, notifications.

---

## TeammateIdle / TaskCompleted

**Fires**: When teammate goes idle / task marked complete.
**Matcher**: None.

Block with exit code 2 (stderr fed back as feedback). No JSON decision control.

---

## WorktreeCreate / WorktreeRemove

**Fires**: When worktrees are created/removed.
**Matcher**: None.

WorktreeCreate: hook prints absolute path to created worktree on stdout. Non-zero exit = creation fails.
WorktreeRemove: No decision control. Failures logged in debug mode only.
