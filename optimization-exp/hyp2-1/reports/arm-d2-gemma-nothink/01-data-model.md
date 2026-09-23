## Summary

This change would require updating all static monetary values in `src/data.py` from simple `float` types to a structure that includes a currency identifier. Since the system currently uses no external libraries (standard library only), these would need to be represented as dictionaries or named tuples containing both a value and a currency code.

## Findings

### F1. Employee Monthly Budgets
- **Location**: `general-experimentation/agentic-workflows/src/data.py:15, 23, 31`
- **What it does today**: Defines the monthly budget for each employee as a `float`.
- **What the change would require**: Each budget would need to be an object/dictionary containing a `value` (float) and a `currency` (e.g., "USD").
- **Confidence**: confirmed

### F2. Policy Thresholds
- **Location**: `general-experimentation/agentic-workflows/src/data.py:38, 39, 40, 46, 50, 51, 52, 55, 56, 61, 62, 63, 71, 72, 73, 81, 82, 83`
- **What it does today**: Sets various policy limits (max_single_expense, requirements_pre_approval_above, etc.) as `float` values.
- **What the change would require**: These values need to be updated to a structure that carries currency, as policy limits might need to be defined in a specific base currency or the local currency of the employee.
- **Confidence**: confirmed

### F3. Spending History
- **Location**: `general-experimentation/agentic-workflows/src/data.py:94, 96, 97, 102, 104, 105, 110, 112, 113`
- **What it does today**: Tracks historical spending and aggregate totals as `float` values.
- **What the change would require**: These values would need a currency identifier to correctly associate past spending with the specific currency in which it occurred.
- **Confidence**: confirmed

### F4. Department Budgets
- **Location**: `general-experimentation/agentic-workflows/src/data.py:122, 123, 124, 127, 128, 129`
- **What it does today**: Defines the total monthly budget and amount spent for each department as `float` values.
- **What the change would require**: These would need to be updated to a structure containing both value and currency.
- **Confidence**: confirmed

### F5. Approval Thresholds
- **Location**: `general-experimentation/agentic-workflows/src/data.py:135, 136, 137, 138`
- **What it does today**: Defines the auto-approval and manual-approval limits for various employee levels as `float` values.
- **What the change would require**: These would need to be updated to a structure containing both value and currency.
- **Confidence**: confirmed

### F6. Sample Expense Submissions
- **Location**: `general-experimentation/agentic-workflows/src/data.py:147, 156, 165, 174`
- **What it does today**: The "amount" field in each expense dictionary is a `float`.
- **What the change would require**: The "amount" field in these dictionaries needs to be replaced with a structure (e.g., a dictionary or a class) that includes the currency code.
- **Confidence**: confirmed

## What I could not determine

- none

## Files I read

- general-experimentation/agentic-workflows/src/data.py
- general-experimentation/agentic-workflows/requirements.txt
