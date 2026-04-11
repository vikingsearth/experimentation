---
name: plan-next-steps
description: Facilitates and persists ideation discussions about project next steps — feature upgrades, new services, architectural decisions, or any forward-looking topic. Maintains a timestamped scratchpad for live idea capture, generates concept documents for ideas that take shape, refines everything into a forest-level outcome summary, and supports pivots by archiving superseded artifacts. Use when brainstorming next steps, planning features, scoping work, or running iterative decision discussions.
compatibility: Designed for Claude Code and GitHub Copilot with shell access.
metadata:
  author: nebula-aurora
  version: "0.1.0"
  purpose: planning
  type: P1
disable-model-invocation: false
user-invocable: true
argument-hint: "Give the topic you want to discuss (e.g., 'the next service', 'the auth redesign', 'the memory upgrade')"
---

# Next Steps

Ideation and discussion tracker for project next steps. Manages a timestamped scratchpad, concept documents, and an outcome summary per topic.

## When to Use

- User wants to brainstorm or scope a feature, service, upgrade, or architectural decision
- User says "let's think about...", "what should we do next for...", "I want to plan..."
- User wants to resume a previous discussion topic
- User wants to capture and refine ideas iteratively over multiple sessions

## Design Principles

**Three-layer artifact model:**

| Layer | Metaphor | File | Purpose |
|-------|----------|------|---------|
| Scratchpad | Animals in the forest | `scratchpad.md` | Running timestamped discussion log — raw ideas, decisions, questions, pivots |
| Concept docs | Trees | `docs/<concept>.md` | Standalone artifacts spun out when an idea takes shape — designs, patterns, use cases, etc. |
| Outcome | The forest | `outcome.md` | High-level summary synthesized from scratchpad + concept docs |

**Single-topic deep focus**: The skill manages one topic at a time with depth and care. Other topics can exist and be resumed, but the workflow is designed for deep engagement with one discussion.

**Operations are inferrable**: The user does not need to learn explicit commands. The agent infers the operation from context. Explicit directives are supported for users who want control.

## Workflow

### Operation Detection

Infer the operation from context. Fall back to asking if truly ambiguous.

| User says... | Operation |
|-------------|-----------|
| "let's think about X", "I want to plan X" | **start** |
| (keeps discussing the active topic) | **continue** |
| "can you pull that idea out into a doc?" | **spin-out** |
| "ok where are we?", "summarize this" | **refine** |
| "what did we miss?", "any gaps?" | **diff** |
| "scratch that", "let's pivot", "new direction" | **pivot** |
| "what topics do we have?", "show me discussions" | **review** |
| "let's go back to X", "resume X" | **continue** (with topic switch) |

### Operations

1. **start** — Initialize a new topic.
   - Run `bash scripts/init-topic.sh "<topic-slug>"` to create the directory structure.
   - Read the created `scratchpad.md` and begin capturing the user's initial context, goals, and ideas as timestamped entries.
   - Each scratchpad entry is a timestamped line with a section identifier: `[idea]`, `[decision]`, `[open-question]`, `[context]`, `[pivot]`, `[reference]`.

2. **continue** — Append to the active topic's scratchpad.
   - Read the existing scratchpad to rebuild context.
   - Append new timestamped entries as the discussion progresses.
   - Implicit when user keeps talking about the active topic. Explicit `continue <topic>` when switching.

3. **spin-out** — Extract a formed concept into a standalone document.
   - When an idea has enough substance to stand alone, create a new doc under `.tmp/discussions/<topic>/docs/` using [assets/generic-template.md](assets/generic-template.md).
   - Add a `[reference]` entry in the scratchpad linking to the new doc.
   - The user decides when to spin out — suggest it when appropriate, but don't auto-create.

4. **refine** — Synthesize scratchpad + concept docs into the outcome document.
   - Read scratchpad and all concept docs.
   - Create or update `outcome.md` using [assets/outcome-template.md](assets/outcome-template.md).
   - The outcome is the "forest view" — high-level summary with pointers to concept docs for depth.
   - If the scratchpad has < 3 substantive entries, warn the user it may be too early.

5. **diff** — Gap analysis across the three layers.
   - Compare scratchpad entries against concept docs and outcome.
   - Surface: ideas discussed but not captured in docs, docs not referenced in outcome, open questions without resolution.
   - Present findings conversationally, not as a formal report.

6. **pivot** — Change direction.
   - Move current `scratchpad.md` to `archive/` with a date prefix (e.g., `archive/2026-03-13--scratchpad.md`).
   - Start a new scratchpad with a `[pivot]` entry referencing the archived one.
   - Assess concept docs individually: relevant ones stay in `docs/`, superseded ones move to `archive/`.

7. **review** — List all discussion topics.
   - Run `bash scripts/review-topics.sh` to scan `.tmp/discussions/`.
   - Summarize findings conversationally: topic names, whether they have outcomes, doc counts, last modified.

### Facilitation Guidelines

Read [references/discussion-guide.md](references/discussion-guide.md) when facilitating discussions. Key principles:

- Ask probing questions to deepen ideas, don't just transcribe
- Capture dissent and trade-offs, not just the winning idea
- Recognise when an idea is ready to spin out into a concept doc
- Track open threads and surface them periodically
- Know when a topic is "done enough" to refine

## Example Inputs

- "let's think about what the next service should be"
- "I want to plan the memory feature upgrade"
- "continue the auth redesign discussion"
- "pull out the event sourcing idea into its own doc"
- "ok summarize where we are on this"
- "actually, scratch that approach — let's pivot to CQRS instead"
- "what discussions do we have going?"

## Edge Cases

- **Topic name collision**: If `.tmp/discussions/<slug>/` exists during `start`, ask user: resume existing topic or choose a new name?
- **Thin scratchpad refine**: If < 3 substantive entries, warn and offer to continue instead.
- **Pivot preservation**: Old scratchpad archived, not deleted. New scratchpad references the old one.
- **Spin-out judgment**: Suggest spin-outs when appropriate, but user decides. Don't auto-create concept docs.
- **Resume old topic**: `review` lists topics. `continue <topic>` switches focus. Read existing scratchpad + docs to rebuild context.
- **Cross-topic references**: Use `Related: [[other-topic]]` links in scratchpad. Surface during review.

## File References

| File | Purpose | When loaded |
|------|---------|-------------|
| `references/REFERENCE.md` | Scratchpad format, doc conventions, slug rules, lifecycle | On activation |
| `references/discussion-guide.md` | Agent facilitation guidance | During discussions |
| `references/FORMS.md` | Intake forms for start, pivot, refine | On structured operations |
| `scripts/init-topic.sh` | Creates topic directory + scratchpad from template | On start |
| `scripts/review-topics.sh` | Scans topics, outputs JSON summary | On review |
| `assets/scratchpad-template.md` | Starter scratchpad with section identifiers | On start |
| `assets/outcome-template.md` | Starter outcome doc | On refine |
| `assets/generic-template.md` | Generic concept doc template | On spin-out |
