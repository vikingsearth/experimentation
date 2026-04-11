# Skill Maker Forms

Structured intake forms for each mode. Copy the relevant form and fill in values.

## Create — Intake Form (Reference)

Use for complex skills or when requirements are ambiguous. For straightforward requests, skip this and ask targeted follow-up questions instead.

```markdown
## New Skill Request

### Required
- **Name**: <kebab-case, 1-64 chars, lowercase alphanumeric + hyphens>
- **Description**: <what it does + when to use it, third person, max 1024 chars>
- **Purpose**: <meta-skill | development | admin | utility | other>

### Invocation
- **User-invocable**: <yes (default) | no>
- **Model-invocable**: <yes (default) | no>
- **Argument hint**: <e.g., [issue-number] or leave blank>

### Structure
- **Needs scripts/**: <yes | no>
- **Needs references/**: <yes | no>
- **Needs assets/**: <yes | no>

### Context
- **Compatibility**: <environment requirements, or leave blank>
- **Execution context**: <inline (default) | fork>
- **Agent type**: <general-purpose | Explore | Plan | custom name> (only if fork)
```

## Update — Change Form

```markdown
## Skill Update Request

- **Target skill**: <skill-name>
- **Change type**: <metadata | instructions | files | structural>
- **What to change**: <specific description>
- **Version bump**: <patch (default) | minor | major>
- **Reason**: <why this change is needed>
```
