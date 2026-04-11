# Create Hooks — Reference

## Event Catalogue

Claude Code supports 17 lifecycle events. This table summarises each event, what it's for, and whether it supports matchers.

| Event | When it fires | Matcher filters | Can block? |
|-------|--------------|----------------|------------|
| `SessionStart` | Session begins or resumes | `startup`, `resume`, `clear`, `compact` | No |
| `UserPromptSubmit` | User submits a prompt | No matcher | Yes |
| `PreToolUse` | Before a tool call executes | Tool name (`Bash`, `Edit\|Write`, `mcp__.*`) | Yes |
| `PermissionRequest` | Permission dialog appears | Tool name | Yes |
| `PostToolUse` | After a tool call succeeds | Tool name | No (tool already ran) |
| `PostToolUseFailure` | After a tool call fails | Tool name | No |
| `Notification` | Claude Code sends notification | `permission_prompt`, `idle_prompt`, `auth_success` | No |
| `SubagentStart` | Subagent is spawned | Agent type | No |
| `SubagentStop` | Subagent finishes | Agent type | Yes |
| `Stop` | Claude finishes responding | No matcher | Yes |
| `TeammateIdle` | Teammate about to go idle | No matcher | Yes (exit 2) |
| `TaskCompleted` | Task being marked completed | No matcher | Yes (exit 2) |
| `ConfigChange` | Config file changes | `user_settings`, `project_settings`, etc. | Yes |
| `WorktreeCreate` | Worktree being created | No matcher | Yes |
| `WorktreeRemove` | Worktree being removed | No matcher | No |
| `PreCompact` | Before context compaction | `manual`, `auto` | No |
| `SessionEnd` | Session terminates | `clear`, `logout`, etc. | No |

## Hook Type Comparison

| Type | Mechanism | When to use | Script needed? |
|------|-----------|-------------|---------------|
| `command` | Runs a shell command | Deterministic checks, formatters, file ops, notifications | Yes (external) or No (inline one-liner) |
| `prompt` | Single-turn LLM evaluation | Judgment-based yes/no decisions | No — inline config |
| `agent` | Subagent with tool access (Read, Grep, Glob) | Multi-step verification requiring file inspection | No — inline config |

### When does a command hook need an external script?

**Use an external script** (`scripts/hook-scripts/<name>.sh`) when:
- The hook parses JSON input from stdin with `jq`
- The hook has conditional logic (if/else on input fields)
- The hook produces structured JSON output
- The hook is more than ~2 shell commands

**Use an inline command** when:
- Simple one-liner (e.g., `npx prettier --write "$TOOL_INPUT_FILE_PATH"`)
- Piped command with `jq` for simple extraction (e.g., the existing CLAUDE.md protection hook)
- No structured JSON output needed

## Decision Flowchart

```
User intent
    │
    ├─ "Block/prevent X before it happens"
    │   └─ PreToolUse (matcher = tool name)
    │       ├─ Simple check? → command (inline)
    │       ├─ Complex check? → command (script)
    │       └─ Judgment needed? → prompt
    │
    ├─ "Do X after file edits"
    │   └─ PostToolUse (matcher = Edit|Write)
    │       └─ command (inline or script)
    │
    ├─ "Do X after shell commands"
    │   └─ PostToolUse (matcher = Bash)
    │       └─ command (inline or script)
    │
    ├─ "Notify me when Claude needs input"
    │   └─ Notification (matcher = * or specific type)
    │       └─ command (inline, platform-specific)
    │
    ├─ "Inject context at session start"
    │   └─ SessionStart (matcher = startup or *)
    │       └─ command (script — outputs context)
    │
    ├─ "Verify work before Claude stops"
    │   └─ Stop
    │       ├─ Simple check? → prompt
    │       └─ File verification? → agent
    │
    ├─ "Protect files from edits"
    │   └─ PreToolUse (matcher = Edit|Write)
    │       └─ command (script — checks file path)
    │
    ├─ "Auto-approve safe operations"
    │   └─ PreToolUse (matcher = specific tool)
    │       └─ command (script — returns permissionDecision)
    │
    └─ "Log/audit everything"
        └─ PostToolUse (matcher = * or specific)
            └─ command (script, async: true)
```

## Settings File Merge Strategy

Hook config lives in `.claude/settings.json` under the `hooks` key. Structure:

```json
{
  "hooks": {
    "<EventName>": [
      {
        "matcher": "<regex>",
        "hooks": [
          { "type": "command", "command": "..." }
        ]
      }
    ]
  }
}
```

### Merge rules

1. **Read** the full `.claude/settings.json`
2. **Preserve** all non-hook keys (e.g., `permissions`)
3. If `hooks.<EventName>` doesn't exist, create it as an empty array
4. **Append** the new matcher group to the array — never replace existing entries
5. If a matcher group with the same matcher value already exists, **append** the new hook handler to that group's `hooks` array
6. **Write** back with 2-space indentation

### Config file locations (precedence)

| Location | Scope | Shareable |
|----------|-------|-----------|
| `~/.claude/settings.json` | All projects | No |
| `.claude/settings.json` | This project | Yes (committed) |
| `.claude/settings.local.json` | This project | No (gitignored) |

This skill writes to `.claude/settings.json` (project-level, shareable) by default.

## Copilot Cross-Tool Note

Copilot can ingest Claude Code hooks via the VS Code setting `chat.useClaudeMdFile`. This means hooks defined in `.claude/settings.json` can be picked up by Copilot without separate `.github/hooks/*.json` files. Copilot hooks are in Preview and this skill does not generate them directly.

## Related Docs

- [Hooks Guide](../../../docs/context/ai-tooling/claude-code/hooks-guide.md)
- [Hooks Reference](../../../docs/context/ai-tooling/claude-code/hooks-reference.md)
- [Copilot Hooks](../../../docs/context/ai-tooling/github-copilot/hooks.md)
- [ADR-0004 Supplementary: Automation Taxonomy](../../../docs/adrs/adr-0004-supplementary/automation-taxonomy.md)
