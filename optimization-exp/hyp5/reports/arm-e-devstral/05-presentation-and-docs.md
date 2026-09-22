## Summary

To add multi-currency support, the expense approval workflow will need to display both the original currency and the base currency in all output formatting, including print statements and documentation examples. Currently, the system only uses US dollars (`float`) implicitly.

## Findings

### F1. Expense Amount Display in Header

- **Location**: `src/main.py:69`
- **What it does today**: Displays the expense amount as USD in the workflow header
- **What the change would require**: Format to show both original currency and USD equivalent
- **Confidence**: confirmed

### F2. Batch Summary Amount Display

- **Location**: `src/main.py:183`
- **What it does today**: Shows amounts in USD only
- **What the change would require**: Format to show both currencies
- **Confidence**: confirmed

### F3. Documentation Example Amounts

- **Location**: `README.md:31-34`
- **What it does today**: Lists sample expenses with USD amounts only
- **What the change would require**: Show both original and USD amounts
- **Confidence**: confirmed

## What I could not determine

- None

## Files I read

- /Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/main.py
- /Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/agents.py
- /Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/README.md
- /Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/docs/research/agentic-patterns.md
- /Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/docs/research/business-logic-modeling.md
- /Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/docs/research/frameworks-overview.md
- /Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/docs/research/guardrails-and-hitl.md
