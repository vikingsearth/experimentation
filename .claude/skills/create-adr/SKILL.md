---
name: create-adr
description: Guides creation of Architecture Decision Records through conversational intake, auto-generates ADR documents from the project template, and iterates with the user until the ADR is finalized. Use when creating a new ADR, documenting an architecture decision, or when the user mentions ADR creation.
compatibility: Designed for Claude Code with shell access.
metadata:
  author: nebula-aurora
  version: "0.1.0"
  purpose: development
  type: P1
disable-model-invocation: false
user-invocable: true
argument-hint: Describe the architecture decision you want to document
---

# Create ADR

Guides creation of Architecture Decision Records through conversational intake, generates ADR documents from the project template, and iterates with the user until the ADR is finalized.

## When to Use

- User wants to create a new ADR
- User wants to document an architecture decision
- User mentions "ADR", "architecture decision", or "decision record"
- User is evaluating technical options and needs to formalize the outcome

## Workflow

### Phase 1 — Discover & Scaffold

1. **Determine next number** — run `bash scripts/scaffold-adr.sh --next-number` to scan `docs/adrs/` and find the next sequential ADR number
2. **Get the title** — ask the user: _"What decision are you documenting? Give me a short title."_
3. **Scaffold the file** — run `bash scripts/scaffold-adr.sh <number> "<short-title>"` to create `docs/adrs/adr-NNNN-<short-title>.md` from the template

### Phase 2 — Intake, Generate, Iterate

Walk through the ADR sections conversationally. **Ask one question at a time**, wait for the user's response, then fill in that section of the scaffolded file.

**Question sequence** (see [references/adr-workflow.md](references/adr-workflow.md) for branching logic):

1. **Context** — _"What problem are you trying to solve? Why does this decision matter now?"_ (2-4 sentences)
2. **Options** — _"What options did you consider?"_ For each: name, 1-sentence description, 1-2 pros, 1-2 cons. If the user is unsure, offer to brainstorm alternatives.
3. **Decision** — _"Which option did you choose and why?"_ (1-2 sentences, active voice)
4. **Consequences** — _"What are the positive outcomes? What are the trade-offs or risks?"_
5. **Validation** — _"How will you know this decision is working?"_ (optional — skip if user has no metrics)
6. **Related ADRs** — _"Does this relate to or supersede any existing ADRs?"_
7. **Deciders & Service** — _"Who made this decision? Which service/component does it affect?"_

After filling all sections, **present the complete draft** and ask: _"Review the ADR and let me know what to change, or confirm it's good."_

**Iterate** — revise based on feedback. Multiple rounds are normal. Keep going until the user explicitly approves.

**Supplementary material** — if the ADR has extensive technical detail (benchmarks, diagrams, migration guides), suggest creating a `docs/adrs/adr-NNNN-supplementary/` directory and linking from the main ADR. See [assets/examples.md](assets/examples.md) for examples of simple vs. complex ADRs.

### Phase 3 — Finalize

1. **Validate** — run `bash scripts/validate-adr.sh docs/adrs/adr-NNNN-<short-title>.md` to check structural requirements
2. **Fix any issues** found by validation
3. **Commit** — `docs: add ADR-NNNN <title>` (conventional commit, imperative mood)

## Example Inputs

- "Create an ADR for adopting Effect-TS in the service layer"
- "I need to document our decision to use LiteLLM as an AI gateway"
- "We're choosing between Redis and Dapr for state management — help me write the ADR"
- "Create an ADR about switching from REST to gRPC for inter-service communication"

## Design Principles

- **One decision per ADR** — don't combine multiple decisions
- **Rationale over implementation** — focus on *why*, not *how*
- **Honest trade-offs** — every option gets pros AND cons, including the chosen one
- **ADRs are immutable** — if a decision changes, create a new ADR and mark the old one as "Superseded"
- **Concise** — target 1-2 pages, readable in ~5 minutes

## Edge Cases

- **Name collision**: If `docs/adrs/adr-NNNN-<title>.md` exists, the scaffold script auto-increments the number
- **User unsure about options**: Offer to brainstorm. Ask about the problem constraints and suggest 2-3 reasonable alternatives to evaluate.
- **Superseding an existing ADR**: Update the old ADR status to "Superseded by ADR-NNNN" and add it to Related ADRs in both documents
- **Minimal input**: If the user provides only a title, ask targeted follow-ups one at a time — don't dump a form
- **Complex ADR with supplementary material**: Suggest creating `docs/adrs/adr-NNNN-supplementary/` for technical analysis, benchmarks, diagrams. Link from the main ADR.

## File Map

| File | Purpose | When loaded |
|------|---------|-------------|
| `SKILL.md` | Router + workflow + design principles (this file) | On activation |
| `references/REFERENCE.md` | Domain context: ADR purpose, quality criteria, immutability | On activation |
| `references/FORMS.md` | Intake questions + review checklist | During intake |
| `references/adr-guide.md` | Full ADR creation guide (what/when/how) | On demand |
| `references/adr-workflow.md` | Conversational intake flow: question sequence, branching | During intake |
| `scripts/scaffold-adr.sh` | Discover next number + create ADR file from template | During scaffold |
| `scripts/validate-adr.sh` | Structural validation of completed ADR | During finalize |
| `assets/adr-template.md` | ADR document template | During scaffold |
| `assets/examples.md` | Reference examples: simple and complex ADRs | On demand |
