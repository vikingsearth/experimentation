---
name: create-hooks
description: Creates and manages Claude Code hooks through guided intake — selects lifecycle events, configures matchers, generates hook handler scripts, updates settings files, validates the result, and documents hooks in .claude/HOOKS.md. Use when creating a new hook, adding automation to AI tool lifecycle events, or when the user mentions hooks, lifecycle automation, or .claude/settings.json hooks configuration.
compatibility: Designed for Claude Code with shell access. Requires jq for script generation and validation.
metadata:
  author: nebula-aurora
  version: "0.1.0"
  purpose: meta-skill
  type: P0
disable-model-invocation: false
user-invocable: true
argument-hint: Describe what you want automated (e.g., "format files after edits", "block rm -rf")
---

# Create Hooks

Creates Claude Code hooks through guided intake — from intent to working hook with validated scripts, merged config, and documented registry entry.

## When to Use

- User wants to automate something at an AI tool lifecycle event (file edits, session start, tool invocation, etc.)
- User mentions "hook", "lifecycle automation", or `.claude/settings.json` hooks
- User wants to enforce invariants, run formatters, block commands, inject context, or send notifications automatically
- User asks to "run X after edits", "block Y before execution", "notify when Z happens"

## Workflow

### Step 1 — Intake

Classify the user's intent. Determine:

1. **Lifecycle event** — which of the 17 Claude Code events to hook into. Consult [references/REFERENCE.md](references/REFERENCE.md) for the event catalogue and decision flowchart.
2. **Matcher** — regex filter for when the hook fires (e.g., `Edit|Write` for file edit tools, `Bash` for shell commands). Some events don't support matchers.
3. **Hook type** — `command` (shell script), `prompt` (LLM yes/no), or `agent` (subagent with tool access). Most hooks are `command` type.
4. **Script need** — Does the hook need an external script in `scripts/hook-scripts/`? Complex command hooks with JSON parsing, multi-step logic, or conditional output need a script. Simple one-liner commands and prompt/agent hooks are config-only.
5. **Async** — Does the hook need to block, or can it run in the background? (Relevant for logging/notification hooks.)

If the user's intent maps clearly to a known pattern in [references/hook-patterns.md](references/hook-patterns.md), use that pattern as a starting point.

If anything is ambiguous, ask targeted questions — don't guess the event or matcher.

### Step 2 — Generate Script (conditional)

Only if the hook needs an external script:

1. Read [references/event-schemas.md](references/event-schemas.md) for the target event's input/output JSON schema
2. Use [assets/command-hook-template.sh](assets/command-hook-template.sh) as the starting template
3. Tailor the script to the specific event — parse the correct input fields, produce the correct output fields, use appropriate exit codes
4. Write the script to `scripts/hook-scripts/<hook-name>.sh`
5. Run `chmod +x scripts/hook-scripts/<hook-name>.sh`

Script conventions:
- Read JSON from stdin using `jq`
- Data to stdout, diagnostics to stderr
- Exit 0 = success, exit 2 = blocking error, other = non-blocking warning
- Support `--help` and `--dry-run` flags
- Reference via `$CLAUDE_PROJECT_DIR/scripts/hook-scripts/<name>.sh` in config

For prompt/agent hooks, skip this step — construct the config directly in Step 3.

### Step 3 — Generate Config

Build the JSON hook entry. Use [assets/config-snippet-template.json](assets/config-snippet-template.json) as the base structure.

For **command hooks with scripts**:
```json
{
  "matcher": "<regex>",
  "hooks": [{
    "type": "command",
    "command": "\"$CLAUDE_PROJECT_DIR\"/scripts/hook-scripts/<hook-name>.sh"
  }]
}
```

For **command hooks with inline commands** (no external script):
```json
{
  "matcher": "<regex>",
  "hooks": [{
    "type": "command",
    "command": "<inline-command>"
  }]
}
```

For **prompt hooks**, use [assets/prompt-hook-template.json](assets/prompt-hook-template.json).
For **agent hooks**, use [assets/agent-hook-template.json](assets/agent-hook-template.json).

Add `"timeout"` if non-default. Add `"async": true` for background hooks. Add platform overrides (`"osx"`, `"linux"`, `"windows"`) if needed.

### Step 4 — Merge Config

Run the merge script to non-destructively add the hook to `.claude/settings.json`:

```bash
bash .claude/skills/create-hooks/scripts/merge-config.sh \
  --event "<EventName>" \
  --config '<json-hook-entry>' \
  --dry-run  # Preview first
```

Then without `--dry-run` to apply. The script:
- Creates `.claude/settings.json` with `{ "hooks": {} }` if it doesn't exist
- Preserves all non-hook keys
- Appends to the event's hook array (never replaces existing hooks)
- Writes back with consistent JSON formatting

### Step 5 — Validate

Run the validation script:

```bash
bash .claude/skills/create-hooks/scripts/validate-hook.sh \
  --event "<EventName>" \
  --settings ".claude/settings.json" \
  --script "scripts/hook-scripts/<hook-name>.sh"  # omit if no script
```

The validator checks:
- `.claude/settings.json` is valid JSON with correct hook schema
- The event entry exists and has the expected structure
- If a script was generated: it's executable, has `--help`, accepts synthetic event JSON on stdin, and exits with expected code

If validation fails, report the failures and fix them before proceeding.

### Step 6 — Document

Append a documentation entry to `.claude/HOOKS.md` using [assets/hook-doc-template.md](assets/hook-doc-template.md). Each entry captures:
- Hook name and purpose
- Event and matcher
- Hook type
- Script path (if any)
- Configuration snippet
- Testing notes

If `.claude/HOOKS.md` doesn't exist, create it with a header.

## Example Inputs

- "Format code with prettier after every file edit"
- "Block any command containing rm -rf"
- "Send a desktop notification when Claude needs input"
- "Inject project context at session start"
- "Protect .env files from being edited"
- "Run eslint after TypeScript file edits"
- "Audit all tool invocations to a log file"

## Edge Cases

- **Event already has hooks**: Non-destructive merge — `merge-config.sh` appends to the existing array, never replaces
- **Script path conflict**: If `scripts/hook-scripts/<name>.sh` already exists, confirm with user: overwrite, rename, or abort
- **No `jq` installed**: Scripts detect missing `jq` and error with install instructions
- **`.claude/settings.json` doesn't exist**: Created automatically with `{ "hooks": {} }`
- **`.claude/settings.json` has non-hook content**: Only the `hooks` subtree is touched — all other keys preserved
- **Prompt/agent hooks**: No script file needed — config is inline JSON. Skip script generation
- **Platform-specific commands**: Use `osx`/`linux`/`windows` override fields in config instead of single `command`
- **Async hooks**: Ask if the hook should block or run in background (`"async": true`)
- **Copilot compatibility**: This skill targets Claude Code only. Copilot can ingest Claude hooks via VS Code setting `chat.useClaudeMdFile`

## File References

| File | Purpose |
|------|---------|
| [references/REFERENCE.md](references/REFERENCE.md) | Event catalogue, hook type comparison, decision flowchart, merge strategy |
| [references/event-schemas.md](references/event-schemas.md) | Per-event input/output JSON schemas — lookup table for script generation |
| [references/hook-patterns.md](references/hook-patterns.md) | Proven hook patterns with use cases, skeletons, and gotchas |
| [references/FORMS.md](references/FORMS.md) | Structured intake form for complex hook requests |
| [scripts/scaffold-hook.sh](scripts/scaffold-hook.sh) | Generates hook handler scripts from template |
| [scripts/merge-config.sh](scripts/merge-config.sh) | Non-destructive merge of hook entries into settings.json |
| [scripts/validate-hook.sh](scripts/validate-hook.sh) | Structural validation of hooks and scripts |
| [assets/command-hook-template.sh](assets/command-hook-template.sh) | Starter template for command hook scripts |
| [assets/prompt-hook-template.json](assets/prompt-hook-template.json) | Template for prompt hook config |
| [assets/agent-hook-template.json](assets/agent-hook-template.json) | Template for agent hook config |
| [assets/config-snippet-template.json](assets/config-snippet-template.json) | Template for settings.json hook entry |
| [assets/hook-doc-template.md](assets/hook-doc-template.md) | Documentation template for HOOKS.md entries |
