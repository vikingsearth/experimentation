# Next Steps Reference

Conventions for the next-steps skill: file formats, naming, lifecycle states, and discussion mechanics.

## Scratchpad Format

The scratchpad (`scratchpad.md`) is a timestamped append-only log. Each entry follows this format:

```markdown
### YYYY-MM-DD HH:MM — [identifier]

Content of the entry.
```

### Section Identifiers

| Identifier | When to use |
|------------|-------------|
| `[context]` | Background information, constraints, current state |
| `[idea]` | A new idea or proposal |
| `[decision]` | A decision made during discussion |
| `[open-question]` | Something unresolved that needs further thought |
| `[pivot]` | Direction change — references what changed and why |
| `[reference]` | Link to a concept doc, external resource, or related topic |
| `[trade-off]` | Explicit trade-off analysis between options |
| `[action]` | A concrete next step or task identified |

Entries are append-only. Never edit or delete previous entries — the log is a historical record. To correct a previous entry, add a new entry that references and updates it.

## Concept Doc Format

Concept docs live in `.tmp/discussions/<topic>/docs/` and are created from `assets/generic-template.md`. They represent ideas that have enough substance to stand alone.

### Naming

- Use kebab-case slugs: `event-sourcing-approach.md`, `auth-redesign-pattern.md`
- The name should reflect the concept, not the discussion sequence
- No numbering prefixes — ordering is not meaningful

### When to Spin Out

An idea is ready to spin out when:
- It has a clear enough shape to explain independently
- It would benefit from its own structure (context, rationale, trade-offs)
- The scratchpad entry is growing too large for inline capture
- The user explicitly asks to pull it out

Don't spin out:
- Vague ideas still being explored (keep in scratchpad)
- Simple decisions that fit in one scratchpad entry
- Meta/process observations

## Outcome Doc Format

The outcome (`outcome.md`) is the forest-level summary created from `assets/outcome-template.md`. It synthesizes the scratchpad and concept docs into a coherent picture.

### When to Create/Update

- First created during a `refine` operation
- Updated on subsequent `refine` calls as the discussion evolves
- Should reference concept docs by relative path, not duplicate their content

### Quality Bar

The outcome should answer:
1. What was the topic about? (1-2 sentences)
2. What decisions were made?
3. What's the rationale?
4. What are the next actions?
5. What was deferred?
6. Where are the details? (concept doc index)

## Topic Slug Rules

- Kebab-case: lowercase alphanumeric + hyphens
- 1-64 characters
- Descriptive: `auth-redesign`, `memory-feature-v2`, `next-service-evaluation`
- Avoid generic names: `discussion-1`, `topic-a`, `stuff`

## Discussion Lifecycle

```
start → continue (repeat) → spin-out (0..n) → refine → done
                    ↓
                  pivot → continue (repeat) → ...
```

States are implicit — there's no status field. The presence of files indicates state:
- Scratchpad only → active discussion, early stage
- Scratchpad + docs → active discussion, ideas forming
- Scratchpad + docs + outcome → refined, potentially complete
- Files in archive/ → pivot occurred, previous direction preserved

## Archive Mechanics

The `archive/` directory within a topic holds superseded artifacts:

- **On pivot**: Old scratchpad moves to `archive/YYYY-MM-DD--scratchpad.md`. Outdated concept docs move to `archive/` with their original names.
- **Archive is append-only**: Never delete from archive. It's the history of direction changes.
- **Naming**: Date-prefixed for scratchpads (`2026-03-13--scratchpad.md`), original names for concept docs.

## Cross-Topic References

When one discussion references another, add a scratchpad entry:

```markdown
### 2026-03-13 14:30 — [reference]

Related topic: [[auth-redesign]] — the event sourcing approach discussed here
may interact with the auth token lifecycle from that discussion.
```

The `[[topic-slug]]` syntax is a convention for discoverability. The agent should surface these during `review`.
|-------|-----------------|
| Example input 1 | Expected shape |
