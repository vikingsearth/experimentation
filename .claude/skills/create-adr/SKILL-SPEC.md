# Skill Spec: create-adr

## Identity

- **Name**: create-adr
- **Purpose**: development
- **Complexity**: standard
- **Description**: Guides creation of Architecture Decision Records through conversational intake, auto-generates ADR documents from the project template, and iterates with the user until the ADR is finalized. Use when creating a new ADR, documenting an architecture decision, or when the user mentions ADR creation.

## Behavior

- **Input**: User pitches an architecture decision idea via natural language (optionally with a short title)
- **Output format**: Markdown ADR document following the project template
- **Output structure**: Primary artifact — `docs/adrs/adr-NNNN-<short-title>.md`. Complex ADRs may also produce a `docs/adrs/adr-NNNN-supplementary/` directory with supporting docs (diagrams, technical analysis, benchmarks).
- **Operations**:
  1. **Discover** — scan `docs/adrs/` for existing ADRs, determine next sequential number
  2. **Scaffold** — create the ADR file from template at `docs/adrs/adr-NNNN-<short-title>.md` with placeholder sections
  3. **Intake + Generate + Iterate** — conversational loop: ask guiding questions, fill in ADR sections progressively, present the draft, accept feedback, revise until user approves. Agent and user go back and forth refining context, options, decision rationale, and consequences.
  4. **Finalize** — validate the ADR, commit with conventional commit message (`docs: add ADR-NNNN <title>`)
- **External dependencies**: Git CLI (for branch creation and commit), filesystem access

## File Plan

- **SKILL.md** — router, workflow steps, design principles, file references
- **scripts/**:
  - `scaffold-adr.sh` — determines next ADR number, creates the file from template, outputs the file path
  - `validate-adr.sh` — validates an ADR file against structural requirements (required sections, metadata fields, naming convention, length guidelines)
- **references/**:
  - `REFERENCE.md` — domain context: ADR purpose, when to create one, quality criteria, immutability rules
  - `FORMS.md` — structured intake form (questions to ask) and review form (validation checklist for the draft)
  - `adr-guide.md` — full comprehensive guide on what/when/how for ADRs
  - `adr-workflow.md` — conversational intake workflow: question sequence, branching logic, brainstorm helpers
- **assets/**:
  - `adr-template.md` — the ADR document template
  - `examples.md` — reference examples pointing to existing ADRs: simple (ADR-0005, ADR-0006) and complex with supplementary material (ADR-0003, ADR-0007)

## Edge Cases

- **Name collision**: If `docs/adrs/adr-NNNN-<title>.md` already exists, increment the number
- **User unsure about options**: Offer to brainstorm alternatives based on the problem context
- **Superseding an existing ADR**: Update the old ADR's status to "Superseded by ADR-NNNN" and link in Related ADRs
- **Minimal input**: If the user provides only a title, ask targeted follow-ups for each missing section rather than dumping a form
- **Supplementary material**: If the decision has extensive technical detail, suggest creating a `docs/adrs/adr-NNNN-supplementary/` directory and linking from the ADR
