# Skill Spec: next-steps

## Identity

- **Name**: next-steps
- **Purpose**: planning
- **Complexity**: full
- **Description**: Facilitates and persists ideation discussions about project next steps — feature upgrades, new services, architectural decisions, or any forward-looking topic. Maintains a timestamped scratchpad for live idea capture, generates concept documents for ideas that take shape, refines everything into a forest-level outcome summary, and supports pivots by archiving superseded artifacts. Use when brainstorming next steps, planning features, scoping work, or running iterative decision discussions.

## Behavior

- **Input**: A topic name, discussion points, or a directive (start/continue/refine/diff/review). Operations are inferrable from user context — a user saying "let's think about X" implies `start`, continuing to talk implies `continue`, "ok summarize where we are" implies `refine`, etc. Explicit directives are supported for users who want precise control.
- **Output format**: mixed (markdown scratchpads, concept docs, outcome docs)
- **Output structure**: Multiple artifacts per topic across a managed directory:
  - **Scratchpad** (per-topic): Timestamped append-only log of the running discussion. Each entry tagged with a section identifier (`[idea]`, `[decision]`, `[open-question]`, `[context]`, `[pivot]`, `[reference]`, etc.) for scannability.
  - **Concept docs** (per-topic, 0..n): When an idea takes shape during discussion — a design pattern, an architectural approach, a use case — the agent spins it out into a standalone doc under the topic's `docs/` directory (`.tmp/discussions/<topic>/docs/`, NOT the repository root `docs/`). Created from a generic template. These are the "trees" — specific artifacts the discussion produces.
  - **Outcome doc** (per-topic): The "forest" — a high-level summary synthesized from the scratchpad and concept docs when the discussion matures. Distilled goals, key decisions, next actions, and pointers to concept docs for depth.
- **Operations** (inferrable from context or stated explicitly):
  1. **start** — Create a new topic with a scratchpad. Initialize with context, goals, and first ideas.
  2. **continue** — Append timestamped entries to the active topic's scratchpad. Implicit when user keeps discussing an active topic. Explicit `continue <topic>` when switching between existing topics.
  3. **spin-out** — Extract a formed concept from the scratchpad into a standalone doc under `docs/`. Triggered when an idea has enough substance to stand alone.
  4. **refine** — Synthesize the scratchpad + concept docs into (or update) the outcome document.
  5. **diff** — Compare scratchpad content against concept docs and outcome to surface gaps: what was discussed but not captured, what was captured but not summarized.
  6. **pivot** — User changes direction. Current scratchpad is moved to `archive/`, a new scratchpad is started with a reference back to the archived one. Concept docs that are still relevant stay in `docs/`; superseded ones move to `archive/`.
  7. **review** — Scan all topics under `.tmp/discussions/`, output a quick summary (topic name, has-outcome, has-docs, last modified). Agent reads and summarises conversationally — not a formatted artifact.
- **External dependencies**: None (pure file operations + agent reasoning)

## Working Directory

Per ADR-0003 and ADR-0004, we do NOT use `.ai/`. Discussions live in `.tmp/discussions/`.

```
.tmp/discussions/
└── <topic-slug>/               # One topic, managed deeply
    ├── scratchpad.md            # Timestamped append-only discussion log
    ├── docs/                    # Concept documents spun out from discussion
    │   ├── <concept-slug>.md    # Created from generic template as ideas form
    │   └── ...
    ├── outcome.md               # Forest-level summary (created on refine)
    └── archive/                 # Superseded artifacts (old scratchpads, outdated concept docs)
        └── ...
```

Single-topic focus: the skill manages one topic at a time with depth and care. Other topics can exist in sibling directories and be resumed via `review` + `continue <topic>`, but the workflow is designed for deep engagement with one discussion at a time.

## File Plan

- **scripts/**:
  1. `init-topic.sh` — Creates the topic directory structure (`docs/`, `archive/`) + scratchpad from template. Validates slug, checks for duplicates.
  2. `review-topics.sh` — Scans `.tmp/discussions/`, outputs JSON summary per topic (name, has scratchpad, has outcome, doc count, last modified, archive item count).
- **references/**:
  1. `REFERENCE.md` — Conventions for scratchpad format (timestamped entries with section identifiers), concept doc format, outcome doc format, slug rules, discussion lifecycle, pivot mechanics.
  2. `discussion-guide.md` — Guidance for the agent on facilitating ideation: asking probing questions, capturing dissent, recognising when an idea is ready to spin out, tracking open threads, knowing when a topic is "done enough" to refine, handling pivots gracefully.
  3. `FORMS.md` — Structured intake forms: topic kick-off form (goals, constraints, initial context), pivot form (what changed, what to keep, what to archive), refine checklist (what to include in outcome).
- **assets/**:
  1. `scratchpad-template.md` — Starter scratchpad with header metadata (topic, created date, status) and the first timestamped entry placeholder. Section identifiers documented in-template.
  2. `outcome-template.md` — Starter outcome doc: Summary, Key Decisions, Rationale, Next Actions, Concept Doc Index, Deferred Items.
  3. `generic-template.md` — Generic concept doc template used for any document spun out of the discussion (design doc, pattern, use case, architecture note, etc.). Lightweight: Title, Context, Content, Related Discussion, Status.

## Edge Cases

- **Topic name collision**: If `.tmp/discussions/<slug>/` exists during `start`, ask user: resume existing topic or choose a new name?
- **Refine with thin scratchpad**: If the scratchpad has < 3 substantive entries, warn user it may be too early to refine. Offer to continue discussion instead.
- **Pivot preservation**: On pivot, the old scratchpad is archived (not deleted). A new scratchpad references the archived one so context isn't lost. Concept docs are individually assessed — relevant ones stay, superseded ones move to `archive/`.
- **Spin-out judgment**: The agent should suggest spin-outs when an idea has enough substance, but the user decides. Don't auto-create concept docs without confirmation.
- **Resume old topic**: `review` lists all topics. `continue <topic>` switches focus. The agent reads the existing scratchpad and concept docs to rebuild context before continuing.
- **Cross-topic references**: If a discussion references another topic, use a `Related: [[other-topic]]` link in the scratchpad. The agent should surface these during review.

## Resolved Questions

1. **Index auto-update**: Yes — auto-update on every operation. `review-topics.sh` serves as both the live scanner and the repair tool.
2. **Explicit vs implicit continue**: Implicit when the user keeps talking about the active topic. Explicit `continue <topic>` only when switching between topics.
3. **Scratchpad format**: Timestamped append-only log. Each entry includes a section identifier (`[idea]`, `[decision]`, `[open-question]`, `[context]`, `[pivot]`, etc.) for scannability without rigid structure.
4. **Diff operation**: Included. Compares scratchpad content against concept docs and outcome to surface gaps.
