## Summary

This change requires the `WorkflowState` to include a currency identifier for both the original expense amount and the policy limits to ensure calculations remain accurate across different currencies. The `AuditEntry` and `snapshot` methods must also be updated to preserve and expose this currency information throughout the pipeline.

## Findings

### F1. AuditEntry.detail

- **Location**: `general-experimentation/agentic-workflows/src/state.py:24`
- **What it does today**: Stores a string describing the action taken by an agent.
- **What the change would require**: It would need to include a currency symbol or code (e.g., "USD", "EUR") whenever a monetary amount is included in the description.
- **Confidence**: confirmed

### F2. WorkflowState.expense

- **Location**: `general-experimentation/agentic-workflows/src/state.py:41`
- **What it does today**: A dictionary containing the raw expense data, including the `amount` field.
- **What the change would require**: The dictionary would need a `currency` key to accompany the `amount` value, ensuring the original currency is preserved.
- **Confidence**: confirmed

### F3. WorkflowState.applicable_limit

- **Location**: `general-experimentation/agentic-workflows/src/state.py:50`
- **What it does today**: A float representing the spending limit for the expense.
- **What the change would require**: It would need to be clearly defined in a base currency (e.g., USD) or accompanied by a currency identifier to allow for correct comparison against the input amount.
- **Confidence**: confirmed

### F4. WorkflowState.snapshot

- **Location**: `general-experimentation/agentic-workflows/src/state.py:82`
- **What it does today**: Returns a dictionary of the current state for reporting and serialization.
- **What the change would require**: The "amount" field in the returned dictionary would need to be paired with a "currency" field to prevent loss of context.
- **Confidence**: confirmed

## What I could not determine

- none

## Files I read

- general-experimentation/agentic-workflows/src/state.py
- general-experimentation/agentic-workflows/src/main.py
