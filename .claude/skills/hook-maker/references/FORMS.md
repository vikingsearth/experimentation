# Create Hooks — Intake & Review Forms

## Intake Form

Use for complex hook requests or when the user's intent is ambiguous. For straightforward requests ("format after edits"), skip this and ask targeted questions.

```markdown
## Hook Request

### Intent
- **What to automate**: <describe the behavior — e.g., "run prettier after file edits">
- **When it should fire**: <lifecycle event, or describe timing>
- **What it should affect**: <specific tools, file patterns, or all>

### Classification
- **Event**: <one of the 17 Claude Code events — see REFERENCE.md>
- **Matcher**: <regex or * — see event-schemas.md for what each event filters>
- **Hook type**: <command | prompt | agent>
- **Needs external script**: <yes — complex logic / no — inline or prompt/agent>

### Configuration
- **Async**: <yes (non-blocking) | no (blocking, default)>
- **Timeout**: <seconds, or default (600 for command, 30 for prompt, 60 for agent)>
- **Platform-specific**: <yes — needs osx/linux/windows overrides | no>
- **Script name**: <hook-name.sh — kebab-case, descriptive>

### Blocking Behavior (if applicable)
- **Can block?**: <yes — should prevent the action | no — informational only>
- **Block condition**: <what triggers blocking — e.g., "file matches .env pattern">
- **Block message**: <feedback shown to Claude when blocked>
```

## Review Form

After hook creation, verify these items before considering the hook complete.

```markdown
## Hook Review

### Generated Artifacts
- **Script**: <path or "none (inline/prompt/agent)">
- **Config entry**: <event + matcher summary>
- **HOOKS.md entry**: <confirmed added>

### Validation Results
- **settings.json valid JSON**: <pass/fail>
- **Hook schema correct**: <pass/fail>
- **Script executable**: <pass/fail or N/A>
- **Script --help works**: <pass/fail or N/A>
- **Synthetic input accepted**: <pass/fail or N/A>
- **Exit code correct**: <pass/fail or N/A>

### Open Items
- <any issues, follow-ups, or adjustments needed>
```
