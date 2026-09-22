## Summary

The change requires replacing all instances of raw `float` values representing currency with a structure that includes both a value and a currency code. Every definition in `src/data.py` currently using a float for budgets, limits, and amounts would need to be updated to this new format.

## Findings

### F1. Employee Monthly Budgets

- **Location**: `general-experimentation/agentic-workflows/src/data.py:15, 23, 31`
- **What it does today**: Defines the `monthly_budget` for employees as a `float`.
- **What the change would require**: The value would need to be a structure (e.g., a dictionary or a dataclass) containing both the amount and the currency (e.g., `{"amount": 5000.00, "currency": "USD"}`).
- **Confidence**: confirmed

### F2. Expense Policy Limits

- **Location**: `general-experimentation/agentic-workflows/src/data.py:38, 39, 40, 46, 50, 51, 52, 55, 56, 61, 62, 63, 67, 71, 72, 73, 81, 82, 83`
- **What it does today**: Defines various policy thresholds (maximums, approval triggers, receipt requirements) as `float` values.
- **What the change would require**: Each threshold would need to be a structure containing both the value and the currency.
- **Confidence**: confirmed

### F3. Spending History

- **Location**: `general-experimentation/agentic-workflows/src/data.py:94, 96, 97, 102, 104, 105, 110, 112, 113`
- **What it does today**: Records historical spending amounts and category totals as `float` values.
- **What the change would require**: These values would need to be structured to include currency, as the spent amounts and category totals could originate in various currencies.
- **Confidence**: confirmed

### F4. Department Budgets

- **Location**: `general-experimentation/agentic-workflows/src/data.py:122, 123, 124, 127, 128, 129`
- **What it does today**: Stores monthly budget totals and actual spending for departments as `float` values.
- **What the change would require**: These values would need to be structured to include currency.
- **Confidence**: confirmed

### F5. Approval Thresholds

- **Location**: `general-experimentation/agentic-workflows/src/data.py:135, 136, 137, 138`
- **What it does today**: Defines auto-approval and manual approval limits for different employee roles as `float` values.
- **What the change would require**: These threshold limits would need to be structured to include currency.
- **Confidence**: confirmed

### F6. Sample Expense Submissions

- **Location**: `general-experimentation/agentic-workflows/src/data.py:147, 156, 165, 174`
- **What it does today**: Contains a list of sample expenses where the `amount` field is a `float`.
- **What the change would require**: The `amount` field in these dictionaries would need to be a structure containing both the value and the currency.
- **Confidence**: confirmed

## What I could not determine

- none

## Files I read

- general-experimentation/agentic-workflows/src/data.py
- general-experimentation/agentic-workflows/requirements.txt
