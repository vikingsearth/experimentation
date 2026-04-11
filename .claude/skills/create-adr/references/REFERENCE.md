# ADR Domain Reference

## What is an ADR?

An **Architecture Decision Record (ADR)** captures a significant architectural decision along with its context and consequences. ADRs help teams remember *why* decisions were made, evaluate trade-offs systematically, share knowledge about system evolution, and avoid revisiting settled decisions.

## When to Create an ADR

Create an ADR when a decision:

- Affects system structure or architecture
- Has long-term consequences that are difficult to reverse
- Involves significant trade-offs between competing concerns
- Establishes team standards or conventions

**Don't** create an ADR for minor implementation details, temporary experiments, easily reversible decisions, or day-to-day feature work.

**Rule of thumb:** If the decision will be difficult to reverse or affects multiple teams, write an ADR.

## Quality Criteria

A good ADR:

1. **Is concise** — 1-2 pages, readable in ~5 minutes
2. **Focuses on rationale** — explains *why*, not *how* to implement
3. **Documents trade-offs honestly** — every option (including the chosen one) has listed pros and cons
4. **Uses active voice** — "We will adopt X because..." not "X was chosen"
5. **Is self-contained** — a new team member 2 years from now can understand the decision without additional context
6. **Links supplementary detail** — extensive technical analysis, benchmarks, or diagrams go in `adr-NNNN-supplementary/`, not inline

## Immutability Rules

- **Accepted ADRs are immutable** — do not edit the decision in an accepted ADR
- If a decision changes, create a **new ADR** that supersedes the old one
- Update the old ADR's status to `Superseded by ADR-NNNN`
- Minor corrections (typos, broken links) are acceptable without a new ADR

## Status Lifecycle

| Status | Meaning |
|--------|---------|
| **Proposed** | Under review, not yet approved |
| **Accepted** | Approved and being/has been implemented |
| **Deprecated** | No longer relevant, kept for history |
| **Superseded** | Replaced by a newer ADR (link to it) |

## Naming Convention

```
docs/adrs/adr-NNNN-short-title.md
```

- Sequential numbers with leading zeros: `0001`, `0002`, etc.
- Short title in kebab-case describes the decision
- Supplementary material: `docs/adrs/adr-NNNN-supplementary/`

## Required Sections

Every ADR must contain:

1. **Title** — `# ADR-NNNN: Short Title`
2. **Status** — Proposed | Accepted | Deprecated | Superseded
3. **Date** — YYYY-MM-DD
4. **Deciders** — Names or roles
5. **Service/Component** — What part of the system is affected
6. **Context** — 2-4 sentences on the problem
7. **Considered Options** — 2-4 options with pros/cons
8. **Decision** — 1-2 sentences, active voice
9. **Consequences** — Positive and negative/trade-offs

Optional sections: Validation, Related ADRs, Notes.
