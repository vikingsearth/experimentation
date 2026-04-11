---
paths:
  - "docs/adrs/adr-*.md"
---

# ADR Writing Standards

Standards for Architecture Decision Records in `docs/adrs/`.

## When to Create an ADR

- Decisions that **affect system structure or architecture** (e.g., microservices vs monolith, state management library)
- Decisions with **long-term consequences** (e.g., adopting TypeScript, standardizing a testing framework)
- Decisions involving **significant trade-offs** (e.g., performance vs developer experience)
- Decisions that **establish team standards** (e.g., API design conventions, code style)

**Don't create ADRs for**: minor implementation details, temporary experiments, easily reversible decisions, day-to-day feature choices.

## File Naming & Location

- **Format**: `docs/adrs/adr-NNNN-short-title.md` (leading zeros, kebab-case)
- **Supplementary material**: `docs/adrs/adr-NNNN-supplementary/` (benchmarks, technical analysis, diagrams)
- **Sequential numbering**: Check existing ADRs for the next number

## Required Metadata

```markdown
# ADR-NNNN: Short Title

**Status:** Proposed
**Date:** YYYY-MM-DD
**Deciders:** Names or roles
**Service/Component:** What this affects
```

**Status lifecycle**: Proposed → Accepted → Deprecated | Superseded

## Required Sections

### Context (2-4 sentences)
What problem are we solving? Why now? What constraints are driving this?

### Considered Options (2-4 options)
Each option: brief description, 1-2 pros, 1-2 cons. Be balanced — even the chosen option should have cons.

### Decision (1-2 sentences)
Active voice: "We will adopt X because..." — not "X was chosen."

### Consequences
- **Positive**: What improves, what problems are solved, what capabilities are unlocked
- **Negative / Trade-offs**: What costs, risks, or technical debt are introduced

## Optional Sections

- **Validation**: How will you confirm this is working? Metrics, timeframe, success criteria
- **Related ADRs**: Links to ADRs this builds on, supersedes, or relates to

## Best Practices

- **Concise**: 1-2 pages, ~5 minute read
- **One decision per ADR** — if you're writing "and we will also...", split it
- **Write for future developers** — imagine someone joining in 2 years
- **Use full sentences** — ADRs are documentation, not bullet lists
- **Link supplementary material** — benchmarks and technical analysis go in `adr-NNNN-supplementary/`, not inline

## Superseding an ADR

1. Create a new ADR with the updated decision
2. Reference the old ADR in "Related ADRs"
3. Update the old ADR's status to "Superseded by ADR-NNNN"

Minor corrections (typos, clarifications) don't require a new ADR.
