# Skill Spec: create-hooks

## Identity

- **Name**: create-hooks
- **Purpose**: meta-skill
- **Complexity**: full
- **Description**: Creates and manages Claude Code and Copilot Agent Hooks through guided intake — selects lifecycle events, configures matchers, generates hook handler scripts, updates settings files, and validates the result. Use when creating a new hook, adding automation to AI tool lifecycle events, or when the user mentions hooks, lifecycle automation, or `.claude/settings.json` hooks configuration.

## Behavior

- **Input**: User describes what they want automated (e.g., "format files after edits", "block dangerous commands", "inject context at session start"). May optionally specify event, matcher, or hook type.
- **Output format**: mixed — generates JSON config snippet + optional shell script + documentation snippet
- **Output structure**: Multiple artifacts:
  1. Optional: Hook handler script written to `scripts/hook-scripts/<hook-name>.sh` (or `.js`) - dependent on script complexity and whether the hook type is `command` (requires script) vs `prompt`/`agent` (config-only)
  2. JSON snippet merged into `.claude/settings.json` under `hooks.<event>`
  3. Documentation snippet appended to `.claude/HOOKS.md` — a hook registry/inventory file
- **Operations**:
  1. **Intake** — classify the user's intent into a lifecycle event + matcher + hook type (command/prompt/agent). Determine whether the hook needs an external script (complex command hooks) or can be expressed inline (simple commands, prompt/agent hooks)
  2. **Generate script** (conditional) — if the hook requires an external script, create the hook handler script from a template in `scripts/hook-scripts/`, tailored to the event's input/output schema. Skip for inline commands and prompt/agent hooks
  3. **Generate config** — produce the JSON hook entry with correct matcher, command path (or inline command), timeout, and platform overrides
  4. **Merge config** — read existing `.claude/settings.json`, merge the new hook entry non-destructively (preserve existing hooks on the same event), write back
  5. **Validate** — structural validation: if a script was generated, check it is executable, has `--help`, feed it synthetic event JSON on stdin, verify exit code and output JSON structure. For all hooks, validate the merged settings.json is valid JSON with correct hook schema
  6. **Document** — append a documentation entry to `.claude/HOOKS.md` describing the new hook (event, matcher, purpose, script path if any, configuration, and testing notes)
- **External dependencies**: `jq` (JSON processing in hook scripts), `bash` (script runtime), standard coreutils

## File Plan

### scripts/

| Script | Responsibility |
|--------|---------------|
| `scripts/scaffold-hook.sh` | Creates hook handler script from template — takes event name, hook name, hook type, and generates the script file at `scripts/hook-scripts/` with correct boilerplate for that event's input/output schema. Only invoked for hooks that need an external script (complex command hooks) |
| `scripts/merge-config.sh` | Reads `.claude/settings.json`, merges a new hook entry into the correct event array without clobbering existing hooks, writes back with consistent formatting. Supports `--dry-run` to preview the merge |
| `scripts/validate-hook.sh` | Structural validation of a generated hook: checks merged `settings.json` is valid JSON with correct hook schema. If an external script was generated, checks it is executable, has `--help`, feeds it synthetic event JSON on stdin, and verifies exit code and output JSON structure. Reports pass/fail per check |

### references/

| File | Topic |
|------|-------|
| `references/REFERENCE.md` | Master reference — event catalogue summary (all 17 Claude Code events + 8 Copilot events), hook type comparison (command vs prompt vs agent), decision flowchart for choosing event + type, and the settings file merge strategy |
| `references/event-schemas.md` | Per-event input/output JSON schemas — what fields each event receives on stdin, what fields it can return on stdout, exit code behavior. Organised as a lookup table the agent consults when generating scripts |
| `references/hook-patterns.md` | Proven hook implementation patterns — auto-format after edit, block dangerous commands, file protection, context injection, notification, audit logging. Each pattern includes: use case, event, matcher, script skeleton, and gotchas |
| `references/FORMS.md` | Structured intake form for hook creation — collects event, matcher, hook type, script location, timeout, platform overrides, documentation preferences |

### assets/

| Asset | Purpose |
|-------|---------|
| `assets/command-hook-template.sh` | Starter template for `type: "command"` hooks — reads JSON from stdin via `jq`, processes based on event fields, outputs JSON to stdout, handles exit codes correctly. Includes `--help`, `--dry-run`, and standard error handling boilerplate |
| `assets/prompt-hook-template.json` | Template for `type: "prompt"` hook config — the JSON structure with prompt field, model field, and placeholders for `$ARGUMENTS` |
| `assets/agent-hook-template.json` | Template for `type: "agent"` hook config — the JSON structure with prompt field, model field, agent type, and tool access |
| `assets/config-snippet-template.json` | Template for the hook entry in `.claude/settings.json` — parameterised with event, matcher, type, command, timeout |
| `assets/hook-doc-template.md` | Documentation template — generates a markdown description of a hook for inclusion in team docs or a hook registry. Captures: event, matcher, purpose, script path, configuration, and testing notes |

## Edge Cases

- **Event already has hooks**: Non-destructive merge — append to existing array, never replace. `merge-config.sh` reads the full array and appends.
- **Script path conflict**: If `scripts/hook-scripts/<name>.sh` already exists, prompt user: overwrite, rename, or abort.
- **No `jq` available**: Scripts should detect missing `jq` and error with install instructions. The validate script checks for `jq` as a prerequisite.
- **`.claude/settings.json` doesn't exist**: Create it with the minimal structure `{ "hooks": {} }` before merging.
- **`.claude/settings.json` has non-hook content**: Preserve all existing keys — only touch the `hooks` subtree.
- **Copilot vs Claude Code hook**: This skill targets Claude Code hooks only (`.claude/settings.json`). Copilot can ingest Claude hooks via the `chat.useClaudeMdFile` VS Code setting. The REFERENCE.md should note this cross-tool path but the skill does not generate `.github/hooks/*.json` files.
- **Prompt/agent hook type**: These don't need a separate script file — they're inline in the config JSON. The skill should detect this and skip script generation, instead constructing the JSON config directly.
- **Multiple platforms**: If the user needs platform-specific commands (macOS vs Linux vs Windows), the config snippet should use the `osx`/`linux`/`windows` override fields instead of a single `command`.
- **Hook references external script**: The existing pattern (see `post-init-claude-md.sh`) puts scripts in `scripts/hook-scripts/` and references them via `$CLAUDE_PROJECT_DIR`. The skill should follow this convention.
- **Async hooks**: Some hooks can run async (`"async": true`). The skill should ask if the hook needs to block or can run in the background (relevant for logging/notification hooks).

## Resolved Decisions

- **Hook script location convention**: All hook scripts go in `scripts/hook-scripts/`. No configurable override — one convention.
- **Hook inventory/registry file**: `.claude/HOOKS.md` — always updated (non-optional). Every hook creation appends a documentation entry.
- **Validation depth**: Structural — feed synthetic event JSON on stdin, verify exit code and output JSON structure. Integration testing (triggering hooks in a live session) is out of scope.
- **Copilot hook support scope**: Claude Code only (`.claude/settings.json`). Copilot can ingest Claude hooks via VS Code setting `chat.useClaudeMdFile`. No `.github/hooks/*.json` generation.
