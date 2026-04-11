# ADR Intake & Review Forms

## Intake Form

Use these questions during the conversational intake phase. Ask **one at a time** — don't dump the full list.

### Required Questions

```markdown
1. Title:        What decision are you documenting? (short title)
2. Context:      What problem are you trying to solve? Why now? (2-4 sentences)
3. Options:      What options did you consider?
                 For each: name, description, 1-2 pros, 1-2 cons
4. Decision:     Which option did you choose and why? (1-2 sentences)
5. Consequences: What improves? What are the trade-offs or risks?
```

### Optional Questions

```markdown
6. Validation:     How will you know this is working? (metrics, timeframe)
7. Related ADRs:   Does this build on or supersede existing ADRs?
8. Deciders:       Who made this decision? (names or roles)
9. Service:        Which service/component does this affect?
10. Supplementary: Is there extensive technical detail that needs its own document?
```

### Branching Logic

- If **user is unsure about options** → offer to brainstorm: ask about constraints, known alternatives, and what they've ruled out
- If **user provides only a title** → start with Context (question 2)
- If **user provides a detailed pitch** → extract answers from the pitch, confirm, then ask for missing sections
- If **the ADR supersedes an existing one** → ask which ADR, update that ADR's status too
- If **technical detail is extensive** → suggest supplementary directory

## Review Checklist

Use this after the draft is complete, before finalizing.

### Structure

- [ ] Title follows `# ADR-NNNN: Short Title` format
- [ ] Status is set to `Proposed`
- [ ] Date is set (YYYY-MM-DD)
- [ ] Deciders are listed
- [ ] Service/Component is specified
- [ ] Horizontal rule separates metadata from body

### Content Quality

- [ ] Context explains the problem in 2-4 sentences
- [ ] At least 2 options are considered
- [ ] Each option has pros AND cons (including the chosen one)
- [ ] Decision uses active voice ("We will..." not "X was chosen")
- [ ] Decision rationale is 1-2 sentences
- [ ] Positive consequences are listed
- [ ] Negative consequences / trade-offs are listed
- [ ] Overall length is 1-2 pages

### Best Practices

- [ ] One decision per ADR (not multiple bundled)
- [ ] Focuses on rationale, not implementation details
- [ ] Trade-offs are honest (chosen option has cons too)
- [ ] Written so a new team member in 2 years can understand it
- [ ] Supplementary detail is linked, not inline
- [ ] No time-sensitive language ("currently", "recently")
