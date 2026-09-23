## Summary

Adding multi-currency support requires the shared state object to track original currency, converted amounts, and base currency conversions. The audit trail must log currency context for every monetary value to ensure downstream agents correctly evaluate policies and budgets.

## Findings

### F1. WorkflowState monetary fields
- **Location**: `general-experimentation/agentic-workflows/src/state.py:42`
- **What it does today**: Stores `amount` as a float for expenses, policy limits, and budgets.
- **What the change would require**: Add `original_currency` (e.g., "EUR") and `converted_amount` (in base currency) fields. Existing `amount` float would need to be replaced with a tuple of (amount, currency) or a new class.
- **Confidence**: confirmed

### F2. WorkflowState.clone() method
- **Location**: `general-experimentation/agentic-workflows/src/state.py:78`
- **What it does today**: Creates shallow copies of state fields.
- **What the change would require**: Must perform deep copies of currency-related fields (e.g., `original_currency`, `converted_amount`) to prevent shared references between state clones.
- **Confidence**: inferred

### F3. AuditEntry monetary logging
- **Location**: `general-experimentation/agentic-workflows/src/state.py:123`
- **What it does today**: Logs `amount` as a float without currency context.
- **What the change would require**: Add `original_currency` and `base_currency` fields to audit entries. Must also log conversion rates if amounts are converted.
- **Confidence**: confirmed

### F4. WorkflowState.log() method
- **Location**: `general-experiment,agentic-workflows/src/state.py:150`
- **What it does today**: Records metadata but not monetary values.
- **What the change would require**: Must include currency context in log entries for all monetary values (e.g., "EUR 150.00 → USD 165.20").
- **Confidence**: inferred

## What I could not determine

- None

## Files I read

- general-experimentation/agentic-workflows/src/state.py
- general-experimentation/agentic-workflows/src/main.py
