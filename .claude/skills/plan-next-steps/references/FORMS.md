# Next Steps Forms

Structured intake forms for operations that benefit from upfront structure. The agent uses these internally when gathering information — the user does not need to fill in forms manually.

## Topic Kick-Off Form

Used during `start` to capture initial context. The agent gathers this information conversationally and records it in the first scratchpad entries.

```markdown
## Topic Kick-Off

### Required
- **Topic**: <descriptive name — will be slugified>
- **Context**: <what's the current state? what prompted this discussion?>
- **Goals**: <what does success look like? what are we trying to decide?>

### Optional
- **Constraints**: <time, budget, technical, team, or architectural constraints>
- **Related topics**: <links to other discussions or docs that inform this one>
- **Initial ideas**: <anything the user already has in mind>
- **Audience**: <who will consume the outcome? just the team? stakeholders?>
```

## Pivot Form

Used during `pivot` to capture what changed and what to preserve. The agent gathers this conversationally.

```markdown
## Pivot

- **What changed**: <why is the direction shifting?>
- **What to keep**: <which ideas, concept docs, or decisions still apply?>
- **What to archive**: <what's superseded by the new direction?>
- **New direction**: <brief description of where we're heading now>
```

## Refine Checklist

Used during `refine` to ensure the outcome doc is complete. The agent uses this as an internal checklist.

```markdown
## Refine Checklist

- [ ] Summary captures the topic's purpose in 1-2 sentences
- [ ] All key decisions from scratchpad are included
- [ ] Rationale for decisions is documented (not just the decision)
- [ ] Next actions are concrete and actionable
- [ ] Concept doc index references all docs in `docs/` with brief descriptions
- [ ] Deferred items are captured (ideas discussed but not pursued)
- [ ] Open questions are either resolved or explicitly listed as open
```

## Diff Checklist

Used during `diff` to systematically compare layers.

```markdown
## Diff Checklist

- [ ] Scan scratchpad for `[idea]` entries not captured in any concept doc
- [ ] Scan scratchpad for `[decision]` entries not reflected in outcome
- [ ] Scan scratchpad for `[open-question]` entries without resolution
- [ ] Check each concept doc is referenced in outcome's concept doc index
- [ ] Check for `[action]` entries not reflected in outcome's next actions
- [ ] Flag any concept docs that seem outdated relative to later scratchpad entries
```
