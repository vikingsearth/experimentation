## Summary

Adding multi-currency support would require changing all hardcoded monetary values in `data.py` from simple floats to objects containing both a value and a currency code. Additionally, every entry point where an expense amount is extracted (e.g., `SAMPLE_EXPENSES` in `data.py` and `main.py`) would need to handle this structured data.

## Findings

### F1. Employee Monthly Budgets
- **Location**: `general-experimentation/agentic-workflows/src/data.py:15, 23, 31`
- **What it does today**: Defines the `monthly_budget` for each employee as a `float`.
- **What the change would require**: Each budget would need to be an object or dictionary containing a `value` and a `currency` (e.g., `{"amount": 5000.00, "currency": "USD"}`).
- **Confidence**: confirmed

### F2. Policy Limits and Thresholds
- **Location**: `general-experimentation/agentic-workflows/src/data.py:38, 39, 40, 46, 50, 51, 56, 61, 62, 63, 71, 72, 81, 82, 135, 136, 137, 138`
- **What it does today**: Defines various policy thresholds (e.g., `max_single_expense`, `requires_pre_approval_above`, `receipt_required_above`) and approval limits as `float` values.
- **What the change would require**: These would need to become objects or dictionaries containing both the `amount` and the `currency` to allow for comparison against expenses in different currencies.
- **Confidence**: confirmed

### F3. Spending History
- **Location**: `general-experimentation/agentic-workflows/src/data.py:94, 96, 97, 102, 104, 105, 110, 112, 113`
- **What it does today**: Records spending amounts (e.g., `total_30_days`, `largest_single_expense`) and category totals as `float` values.
- **What the change would require**: These fields would need to store a currency indicator or be transformed into objects containing `amount` and `currency`.
- **Confidence**: confirmed

### F4. Department Budgets
- **Location**: `general-experimentation/agentic-workflows/src/data.py:122, 123, 124, 127, 128, 129`
- **What it does today**: Stores `monthly_budget`, `spent_this_month`, and `remaining` as `float` values.
- **What the change would require**: These would need to be objects/dictionaries containing both an `amount` and a `currency`.
- **Confidence**: confirmed

### F5. Sample Expenses
- **Location**: `general-experimentation/agentic-workflows/src/data.py:147, 156, 165, 174`
- **What it does today**: The `amount` field in the `SAMPLE_EXPENSES` list is a `float`.
- **What the change would require**: The `amount` field would need to be an object/dictionary containing `amount` and `currency`.
- **Confidence**: confirmed

### F6. Main Execution & Printing
- **Location**: `general-experimentation/agentic-workflows/src/main.py:69, 183`
- **What it does today**: Extracts the `amount` from the expense dictionary and prints it as a formatted string (e.g., `f"${expense.get('amount', 0):.2f}"`).
- **What the change would require**: The logic to extract and format the amount would need to handle the currency code (e.g., `f"{expense.get('amount'):.2f} {expense.get('currency', 'USD')}"`).
- **Confidence**: confirmed

## What I could not determine

- None

## Files I read

- general-experimentation/agentic-workflows/src/data.py
- general-experimentation/agentic-workflows/src/main.py
- general-experimentation/agentic-workflows/src/tools.py
- general-experimentation/agentic-workflows/src/state.py
- general-experimentation/agentic-workflows/src/agents.py
