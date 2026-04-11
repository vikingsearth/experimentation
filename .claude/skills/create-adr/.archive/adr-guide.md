# ADR Instructions

## What is an ADR?

An **Architecture Decision Record (ADR)** is a document that captures a significant architectural decision made for the project, along with its context and consequences.

ADRs help teams:

- **Remember why** decisions were made (especially important when team members change)
- **Evaluate trade-offs** systematically before committing to a direction
- **Share knowledge** about the system's evolution
- **Avoid revisiting** settled decisions unnecessarily

## When to Create an ADR

Create an ADR when making decisions that:

✅ **Affect system structure or architecture**

- Example: Choosing between microservices vs. monolith
- Example: Selecting a state management library (Redux, Zustand, Context API)

✅ **Have long-term consequences**

- Example: Adopting TypeScript for the entire codebase
- Example: Standardizing on a specific testing framework

✅ **Involve significant trade-offs**

- Example: Choosing between performance and developer experience
- Example: Selecting between third-party service vs. in-house solution

✅ **Establish team standards or conventions**

- Example: Code style guidelines (Effect-TS patterns, error handling)
- Example: API design conventions (REST vs. GraphQL)

❌ **Don't create an ADR for:**

- Minor implementation details (variable naming, code formatting)
- Temporary decisions or experiments
- Decisions that can be easily reversed without cost
- Day-to-day feature implementation choices

**Rule of thumb:** If the decision will be difficult to reverse or affects multiple teams, write an ADR.

## How to Create an ADR

### Step 1: Use the Template

Copy the template from `.ai/templates/__adr-template.md` and create a new file:

```bash
# File naming convention: adr-NNNN-short-title.md
# Examples:
docs/adrs/adr-0001-websocket-refactoring.md
```

**Numbering:**

- Use sequential numbers: `0001`, `0002`, `0003`, etc.
- Include leading zeros for proper sorting
- Check existing ADRs to determine the next number

### Step 2: Fill in the Metadata

```markdown
# ADR-0005: Use Effect-TS for Service Layer

**Status:** Proposed
**Date:** 2026-02-12
**Deciders:** Engineering Team, Tech Lead
**Service/Component:** agent-proxy-svc, core services
```

**Status options:**

- **Proposed** - Under review, not yet approved
- **Accepted** - Approved and being/has been implemented
- **Deprecated** - No longer relevant but kept for historical context
- **Superseded** - Replaced by a newer ADR (link to the new one)

### Step 3: Write the Context (2-4 sentences)

Answer these questions:

- What problem are we trying to solve?
- Why does this decision matter now?
- What constraints or requirements are driving this?

**Example:**
> Our current service layer uses raw Promises with inconsistent error handling patterns. As the codebase grows, we need a standardized approach for composable effects, dependency injection, and type-safe error handling. Effect-TS provides these capabilities while maintaining functional programming principles.

### Step 4: List Considered Options (2-4 options)

For each option, provide:

- **Brief description** (one sentence)
- **Pros** (1-2 key advantages)
- **Cons** (1-2 key disadvantages)

**Be balanced** - acknowledge trade-offs honestly. Even the chosen option should have cons listed.

**Example:**

```markdown
1. **Effect-TS** - Functional effect system with built-in error handling
   - **Pros:** Type-safe errors, composable services, strong ecosystem
   - **Cons:** Learning curve for team, requires runtime setup

2. **NestJS with TypeScript** - Traditional OOP framework
   - **Pros:** Familiar patterns, large community, extensive documentation
   - **Cons:** Heavier runtime, less composable, manual error handling
```

### Step 5: State the Decision (1-2 sentences)

Use active voice and be clear:

✅ **Good:**
> We will adopt Effect-TS for all service layer code because it provides type-safe error handling and composable dependency injection that aligns with our functional programming goals.

❌ **Bad:**
> Effect-TS was chosen.

### Step 6: Document Consequences

List **both positive and negative** consequences:

**Positive:**

- Specific improvements enabled by this decision
- Problems this solves
- Capabilities unlocked

**Negative / Trade-offs:**

- Costs introduced (time, complexity, dependencies)
- Risks or limitations
- Technical debt created

**Be honest** - every decision has trade-offs. Documenting them helps future teams understand what was prioritized.

### Step 7: Add Validation (Optional)

How will you know this decision is working?

**Example:**
> We'll measure success by test coverage improvements (target: 85%+) and reduction in production errors related to unhandled exceptions. After 3 months, we'll review developer satisfaction via team survey.

### Step 8: Link Related ADRs

If this decision builds on, supersedes, or relates to other ADRs, link them:

```markdown
## Related ADRs

- ADR-0001: Use TypeScript (foundation for type-safe error handling)
- ADR-0003: Adopt Functional Programming Patterns (influenced this choice)
```

## Best Practices

### Keep It Concise

- **Target:** 1-2 pages maximum
- **Reading time:** Should be readable in ~5 minutes
- **Focus:** Capture the decision and rationale, not implementation details

### One Decision Per ADR

Don't combine multiple decisions into a single ADR. If you're writing "and we will also...", consider splitting it.

### Write for Future Developers

Imagine a new team member joining in 2 years:

- Will they understand *why* this decision was made?
- Will they understand what alternatives were considered?
- Will they know what consequences to watch for?

### Use Full Sentences

ADRs are documentation, not bullet lists. Write clear prose:

✅ **Good:**
> We will use React Context API for theme state because it's built into React and doesn't require external dependencies. This decision accepts potential performance issues if theme changes frequently.

❌ **Bad:**

> - React Context
> - No deps
> - Perf issues possible

### Link to Supplementary Material

If you have extensive technical analysis, benchmarks, or implementation guides:

- **Don't include them in the ADR**
- **Link to them** from the ADR

**Example:**

> See `/docs/designs/effect-ts-migration-guide.md` for implementation details and migration strategy.

## Workflow

### Creating a New ADR

1. **Create branch:** `adr/short-descriptive-name`
2. **Copy template:** From `.ai/templates/__adr-template.md`
3. **Write ADR:** Follow the template and instructions
4. **Set status to "Proposed"**
5. **Create PR:** Request review from relevant stakeholders
6. **Iterate:** Address feedback, update ADR
7. **Merge:** Once approved, change status to "Accepted"

### Updating an Existing ADR

**ADRs are immutable** - don't edit accepted ADRs to change the decision.

If a decision needs to change:

1. Create a **new ADR** with the updated decision
2. Reference the old ADR in "Related ADRs"
3. Update the old ADR's status to **"Superseded by ADR-XXXX"**

Minor corrections (typos, clarifications) are acceptable without creating a new ADR.

## Examples

See these ADRs for reference:

- `docs/adrs/adr-0001-websocket-refactoring.md` - Comprehensive refactoring decision
- `.ai/templates/__adr-template.md` - The template itself with annotations

## Tools

### Manual Creation

```bash
# Create new ADR file
cp .ai/templates/__adr-template.md docs/adrs/adr-0005-my-decision.md

# Edit with your preferred editor
code docs/adrs/adr-0005-my-decision.md
```

### ADR Creation Agent (Optional)

Use the Claude Code ADR agent for guided ADR creation:

```bash
# In Claude Code CLI
/adr
```

The agent will:

- Ask guiding questions about your decision
- Help you identify options and trade-offs
- Generate a draft ADR based on your answers
- Create a PR with the ADR for review

## Questions?

If you're unsure whether to create an ADR or how to structure it:

- **Ask in the team channel** - ADRs benefit from discussion
- **Start small** - It's better to capture something than nothing
- **Iterate** - ADRs can be refined through PR reviews

Remember: The goal is **shared understanding**, not perfect documentation.
