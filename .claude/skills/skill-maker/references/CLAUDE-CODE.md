# Claude Code Skill Extensions

> Claude Code extends the Agent Skills spec with additional frontmatter fields and features.
> Source: [code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills)

## Additional Frontmatter Fields

These fields are Claude Code-specific and supplement the base Agent Skills spec.

| Field | Default | Description |
| ----- | ------- | ----------- |
| `disable-model-invocation` | `false` | `true` = only user can invoke via `/name`. Removes from Claude's context entirely. Use for side-effect workflows (deploy, commit, send). |
| `user-invocable` | `true` | `false` = hidden from `/` menu. Only Claude can invoke. Use for background knowledge skills. |
| `argument-hint` | — | Autocomplete hint: `[issue-number]`, `[filename] [format]`. |
| `model` | inherited | Override model when skill is active. |
| `context` | — | `fork` = run in isolated subagent context. Skill content becomes the subagent prompt. No conversation history access. |
| `agent` | `general-purpose` | Subagent type when `context: fork`. Options: `Explore`, `Plan`, `general-purpose`, or custom from `.claude/agents/`. |
| `hooks` | — | Hooks scoped to this skill's lifecycle. |

## Invocation Control Matrix

| Frontmatter | User can invoke | Claude can invoke | Context behavior |
| ----------- | --------------- | ----------------- | ---------------- |
| (defaults) | Yes | Yes | Description in context, full skill on invocation |
| `disable-model-invocation: true` | Yes | No | Description NOT in context |
| `user-invocable: false` | No | Yes | Description in context |

## String Substitutions

Available in skill content — replaced at invocation time:

| Variable | Description |
| -------- | ----------- |
| `$ARGUMENTS` | All args passed when invoking. Auto-appended as `ARGUMENTS: <value>` if not present in content. |
| `$ARGUMENTS[N]` / `$N` | Specific arg by 0-based index. `$0` = first, `$1` = second, etc. |
| `${CLAUDE_SESSION_ID}` | Current session ID. Useful for logging/correlation. |

## Dynamic Context Injection

The `` !`command` `` syntax runs shell commands **before** content is sent to Claude. Output replaces the placeholder.

```markdown
Current branch: !`git branch --show-current`
Changed files: !`git diff --name-only`
```

## Subagent Execution

With `context: fork`, the skill runs in an isolated context:

1. New context created (no conversation history)
2. Skill content becomes the subagent's task prompt
3. `agent` field determines tools and model
4. Results summarized and returned to main conversation

Only use `context: fork` for skills with explicit task instructions, not reference/guideline skills.

## allowed-tools (NOT SUPPORTED)

> **Warning**: `allowed-tools` is defined in the Agent Skills spec but is **not supported by Claude Code**. Including it in frontmatter will produce IDE warnings. Do not use this field.

The spec defines the following format for reference only:

```yaml
allowed-tools: Read Grep Glob                    # Named tools
allowed-tools: Bash(git:*) Bash(npm:*)           # Bash with prefix patterns
allowed-tools: Skill(commit) Skill(review-pr *)  # Specific skills
```

## Skill Location Precedence

| Priority | Location | Applies to |
| -------- | -------- | ---------- |
| 1 (highest) | Enterprise managed settings | All users in org |
| 2 | `~/.claude/skills/` | All your projects |
| 3 | `.claude/skills/` | This project |
| 4 | Plugin `skills/` | Where plugin enabled |

Skills with the same name: higher priority wins. Plugin skills are namespaced (`plugin:skill`).

## Project Conventions (nebula-aurora)

From this repo's existing skills and scaffold script:

- **Purpose taxonomy**: `meta-skill`, `development`, `admin`, `utility`, `other`
- **Type field**: Priority indicator (`P0`, `P1`, `P2`)
- **Author**: `nebula-aurora` for team skills, personal name for individual skills
- **Version**: semver string in metadata (`"1.0.0"`)
