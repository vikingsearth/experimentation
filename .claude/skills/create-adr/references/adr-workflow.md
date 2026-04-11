# ADR Conversational Intake Workflow

Defines the question sequence, branching logic, and brainstorm helpers for the conversational intake phase.

## Conversation Flow

```
User pitches idea
       │
       ▼
┌─────────────────────┐
│ Extract what's given │───── Has title? ─── No ──► Ask for title
│ from the pitch       │         │
└─────────────────────┘       Yes
                                │
                                ▼
                    ┌──────────────────────┐
                    │ Scaffold the ADR file │
                    └──────────────────────┘
                                │
                                ▼
                    ┌──────────────────────┐
                    │ Ask: Context          │◄─── "What problem? Why now?"
                    └──────────────────────┘
                                │
                                ▼
                    ┌──────────────────────┐
                    │ Ask: Options          │◄─── "What did you consider?"
                    │ (brainstorm if stuck) │
                    └──────────────────────┘
                                │
                                ▼
                    ┌──────────────────────┐
                    │ Ask: Decision         │◄─── "Which option and why?"
                    └──────────────────────┘
                                │
                                ▼
                    ┌──────────────────────┐
                    │ Ask: Consequences     │◄─── "What improves? Trade-offs?"
                    └──────────────────────┘
                                │
                                ▼
                    ┌──────────────────────┐
                    │ Optional: Validation  │◄─── "How will you know it works?"
                    │ Optional: Related ADRs│◄─── "Relates to existing ADRs?"
                    │ Optional: Deciders    │◄─── "Who decided? What service?"
                    └──────────────────────┘
                                │
                                ▼
                    ┌──────────────────────┐
                    │ Present full draft    │
                    │ Ask for feedback      │
                    └──────────────────────┘
                                │
                          ┌─────┴─────┐
                      Approved    Feedback
                          │           │
                          ▼           ▼
                      Finalize    Revise & re-present
                                      │
                                      └──► (loop back to present)
```

## Question Sequence

Ask **one question at a time**. After the user responds, fill in that section of the ADR before asking the next question.

### 1. Title (if not provided)

> "What decision are you documenting? Give me a short title."

Fill in: `# ADR-NNNN: <title>` heading.

### 2. Context

> "What problem are you trying to solve? Why does this decision matter now? Include any constraints or requirements driving this."

Target: 2-4 sentences. Fill in the Context section.

### 3. Considered Options

> "What options did you consider? For each, give me a name, one-sentence description, and 1-2 pros and cons."

If the user provides fewer than 2 options, prompt for more. If the user is stuck, use **brainstorm mode** (see below).

### 4. Decision

> "Which option did you choose and why?"

Target: 1-2 sentences in active voice. Fill in the Decision section.

### 5. Consequences

> "What are the positive outcomes of this decision? And what are the trade-offs or risks?"

Fill in both Positive and Negative/Trade-offs subsections.

### 6. Optional Sections

Ask these if relevant, skip if not:

- **Validation**: "How will you know this decision is working? Any metrics or timeframe?"
- **Related ADRs**: "Does this build on or supersede any existing ADRs?"
- **Deciders**: "Who made this decision?" (default to user's name + "Engineering Team" if not specified)
- **Service/Component**: "Which part of the system does this affect?"

## Branching Logic

### Detailed Pitch

If the user's initial message contains substantial detail (problem description, options, rationale):

1. Extract answers from the pitch
2. Pre-fill the ADR sections
3. Present what was extracted and ask: "I've filled in what I could from your description. Review it and let me know what to adjust or what's missing."

### Minimal Input (Title Only)

If the user provides only a title:

1. Acknowledge the title, scaffold the file
2. Start with Context (question 2)
3. Proceed through the sequence normally

### Superseding an Existing ADR

If the user mentions replacing or updating an existing ADR:

1. Ask which ADR is being superseded
2. Read the old ADR for context
3. Pre-fill Related ADRs section
4. After the new ADR is finalized, update the old ADR's status to "Superseded by ADR-NNNN"

## Brainstorm Mode

When the user is unsure about options, help them brainstorm:

1. **Ask about constraints**: "What are the hard requirements? What can't change?"
2. **Ask about known alternatives**: "Have you seen any approaches in other projects or tools?"
3. **Ask about what's been ruled out**: "Is there anything you've already considered and rejected?"
4. **Suggest common patterns**: Based on the problem domain, suggest 2-3 reasonable alternatives
5. **Pro/con together**: For each option, work through pros and cons conversationally

## Iteration Protocol

After presenting the complete draft:

- Accept natural language feedback: "Change the context to mention X", "Add another con to option 2", "The decision wording should be stronger"
- Apply changes to the file immediately
- Re-present the updated sections (not the full ADR unless requested)
- Ask: "Anything else to change, or is this good?"
- Continue until explicit approval

## Supplementary Material Detection

Suggest a supplementary directory when:

- The ADR discussion reveals extensive technical analysis (benchmarks, performance data)
- The user wants to include diagrams or visual aids
- Migration guides or step-by-step implementation plans emerge
- The ADR body would exceed 2 pages with the detail included

Template: "This ADR has enough technical depth to warrant a supplementary directory. I'll create `docs/adrs/adr-NNNN-supplementary/` and link the detailed analysis from the main ADR."
