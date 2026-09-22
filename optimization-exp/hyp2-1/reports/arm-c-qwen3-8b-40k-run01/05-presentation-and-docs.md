## Summary

Adding multi-currency support would require all human-facing monetary displays to show both the original currency and the base currency. This includes print statements, summaries, and documentation examples.

## Findings

### F1. Initial Expense Summary
- **Location**: `general-experimentation/agentic-workflows/src/main.py:69`
- **What it does today**: Displays the expense ID and amount as USD float with two decimal places
- **What the change would require**: Show both original currency (e.g., EUR) and base currency (USD) with explicit conversion
- **Confidence**: confirmed

### F2. Final Workflow Summary
- **Location**: `general-experimentation/agentic-workflows/src/main.py:99-113`
- **What it does today**: Prints decision status, risk level, and rationale with USD amounts
- **What the change would require**: Display both original and base currency values in all numeric displays
- **Confidence**: confirmed

### F3. Batch Summary Table
- **Location**: `general-experimentation/agentic-workflows/src/main.py:179-188`
- **What it does today**: Formats amounts as USD strings in a tabular output
- **What the change would require**: Show both original and base currency values in all numeric displays
- **Confidence**: confirmed

## What I could not determine

- None

## Files I read

- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/main.py`
