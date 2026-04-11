# ADR Guide

> Comprehensive guide on what, when, and how for Architecture Decision Records. This is the full reference — see `REFERENCE.md` for a condensed summary.

## What is an ADR?

An **Architecture Decision Record (ADR)** is a document that captures a significant architectural decision made for the project, along with its context and consequences.

ADRs help teams:

- **Remember why** decisions were made (especially important when team members change)
- **Evaluate trade-offs** systematically before committing to a direction
- **Share knowledge** about the system's evolution
- **Avoid revisiting** settled decisions unnecessarily

## When to Create an ADR

Create an ADR when making decisions that:

- **Affect system structure or architecture** — e.g., choosing between microservices vs. monolith, selecting a state management library
- **Have long-term consequences** — e.g., adopting TypeScript for the entire codebase, standardizing on a testing framework
- **Involve significant trade-offs** — e.g., choosing between performance and developer experience
- **Establish team standards or conventions** — e.g., code style guidelines, API design conventions

**Don't create an ADR for:** minor implementation details, temporary experiments, easily reversible decisions, or day-to-day feature choices.

**Rule of thumb:** If the decision will be difficult to reverse or affects multiple teams, write an ADR.

## How to Create an ADR

### Step 1: Determine the Next Number

Check existing ADRs in `docs/adrs/` to find the next sequential number. Use format `adr-NNNN-short-title.md` with leading zeros.

### Step 2: Fill in Metadata

```markdown
# ADR-NNNN: Short Title

**Status:** Proposed
**Date:** YYYY-MM-DD
**Deciders:** Names or roles
**Service/Component:** What this affects
```

**Status options:** Proposed → Accepted → Deprecated | Superseded

### Step 3: Write the Context (2-4 sentences)

Answer: What problem are we solving? Why does this matter now? What constraints are driving this?

### Step 4: List Considered Options (2-4)

For each option: brief description, 1-2 pros, 1-2 cons. Be balanced — even the chosen option should have cons.

### Step 5: State the Decision (1-2 sentences)

Use active voice: "We will adopt X because..." not "X was chosen."

### Step 6: Document Consequences

**Positive:** What improves, what problems are solved, what capabilities are unlocked.
**Negative / Trade-offs:** What costs are introduced, what risks exist, what technical debt is created.

### Step 7: Validation (Optional)

How will you confirm this is working? Metrics, timeframe, success criteria.

### Step 8: Link Related ADRs

If this builds on, supersedes, or relates to other ADRs, link them.

## Best Practices

- **Keep it concise** — 1-2 pages, ~5 minute read
- **One decision per ADR** — if you're writing "and we will also...", split it
- **Write for future developers** — imagine someone joining in 2 years
- **Use full sentences** — ADRs are documentation, not bullet lists
- **Link supplementary material** — benchmarks, technical analysis, diagrams go in `adr-NNNN-supplementary/`

## Workflow

### Creating a New ADR

1. Create branch: `adr/short-descriptive-name`
2. Copy template from `assets/adr-template.md`
3. Write ADR following the steps above
4. Set status to "Proposed"
5. Create PR, request reviews
6. Iterate on feedback
7. Merge — change status to "Accepted"

### Superseding an Existing ADR

1. Create a new ADR with the updated decision
2. Reference the old ADR in "Related ADRs"
3. Update the old ADR's status to "Superseded by ADR-NNNN"

Minor corrections (typos, clarifications) are acceptable without creating a new ADR.
