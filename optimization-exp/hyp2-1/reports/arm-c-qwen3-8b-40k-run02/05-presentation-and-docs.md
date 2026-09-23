## Summary

Adding multi-currency support would require updating all instances where monetary amounts are formatted for humans, printed, or described in documentation to show both the original currency and the base currency. This includes print statements, summary outputs, and any documentation examples.

## Findings

### F1. Expense Summary Print in `main.py`
- **Location**: `general-experimentation/agentic-workflows/src/main.py:70`
- **What it does today**: Formats the expense amount as a USD value with two decimal places.
- **What the change would require**: Display both the original currency (e.g., EUR) and the base currency (USD) with their respective amounts.
- **Confidence**: confirmed

### F2. Final Result Summary in `main.py`
- **Location**: `general-experimentation/agentic-workflows/src/main.py:98`
- **What it does today**: Prints the final decision with a risk level and review status.
- **What the change would require**: Include the original currency amount alongside the base currency amount in the summary.
- **Confidence**: confirmed

### F3. Batch Summary Table in `main.py`
- **Location**: `general-experimentation/agentic-workflows/src/main.py:179`
- **What it does today**: Displays expense amounts in a table formatted as USD.
- **What the change would require**: Show both the original currency and the base currency amounts in the table.
- **Confidence**: confirmed

### F4. Policy Check Output in `agents.py`
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:140`
- **What it does today**: Compares the expense amount against a policy limit in USD.
- **What the change would require**: Use the original currency amount and convert it to the base currency for comparison.
- **Confidence**: confirmed

### F5. Risk Assessment Output in `agents.py`
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:286`
- **What it does today**: Calculates the risk score based on the expense amount in USD.
- **What the change would require**: Use the original currency amount and convert it to the base currency for risk calculation.
- **Confidence**: confirmed

## What I could not determine

- None

## Files I read

- `general-experimentation/agentic-workflows/src/main.py`
- `general-experimentation/agentic-workflows/src/agents.py`
