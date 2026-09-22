## Summary

To support multi-currency, every instance of a monetary value currently represented as a `float` must be transformed into a structured data type (such as a dictionary or a dataclass) that encapsulates both the numerical value and a currency identifier (e.g., "USD", "EUR"). This change is required for both the static configuration data and the input data used to seed the system.

## Findings

### F1. Employee Monthly Budgets

- **Location**: `general-experimentation/agentic-workflows/src/data.py:15, 23, 31`
- **What it does today**: Defines the `monthly_budget` for each employee as a `float`.
- **What the change would require**: Each `monthly_budget` should be a structure (e.g., a `dict`) containing an `amount` and a `currency` code.
- **Confidence**: confirmed

### F2. Policy Thresholds

- **Location**: `general-experimentation/agentic-workflows/src/data.py:38-40, 50-53, 61-63, 71-73, 81-83`
- **What it does today**: Defines several thresholds (`max_single_expense`, `requires_pre_approval_above`, `receipt_required_above`) as `float` values within the `POLICIES` dictionary.
- **What the change would require**: These fields should be changed from `float` to a structure (e.g., a `dict`) containing both the value and the currency code.
- **Confidence**: confirmed

### F3. Policy Rules (Internal Values)

- **Location**: `general-experimentation/agentic-workflows/src/data.py:46, 55, 56, 67`
- **What it does today**: These are strings within the `rules` list. Some contain specific monetary values (e.g., "$75", "$100", "$50", "$30", "$1000").
- **What the change would require**: Since these are currently embedded in strings, they would need to be extracted or the rule definitions updated to reference a structured monetary type rather than a hardcoded value in a string.
- **Confidence**: confirmed

### F4. Spending History Data

- **Location**: `general-experimentation/agentic-workflows/src/data.py:94, 96, 97, 102, 104, 105, 110, 112, 113`
- **What it does today**: Defines spending metrics (`total_30_days`, `largest_single_expense`, and individual category totals) as `float` values.
- **What the change would require**: These values should be changed from `float` to a structure (e.g., a `dict`) containing both the amount and the currency code.
- **Confidence**: confirmed

### F5. Department Budgets

- **Location**: `general-experimentation/agentic-workflows/src/data.py:122, 123, 124, 127, 128, 129`
- **What it does today**: Defines department-level metrics (`monthly_budget`, `spent_this_month`, and `remaining`) as `float` values.
- **What the change would require**: These fields should be changed from `float` to a structure (e.g., a `dict`) containing both the amount and the currency code.
- **Confidence**: confirmed

### F6. Approval Thresholds

- **Location**: `general-experimentation/agentic-workflows/src/data.py:135, 136, 137, 138`
- **What it does today**: Defines the `auto_approve_up_to` and `can_approve_up_to` limits as `float` values.
- **What the change would require**: These fields should be changed from `float` to a structure (e.g., a `dict`) containing both the amount and the currency code.
- **Confidence**: confirmed

### F7. Sample Expense Submissions

- **Location**: `general-experimentation/agentic-workflows/src/data.py:147, 156, 165, 174`
- **What it does today**: The `amount` field in the `SAMPLE_EXPENSES` list is a `float`. This is the primary entry point for expenses into the system.
- **What the change would require**: The `amount` field should be changed from `float` to a structure (e.g., a `dict`) containing both the amount and the currency code.
- **Confidence**: confirmed

## What I could not determine

- none

## Files I read
- general-experimentation/agentic-workflows/src/data.py
- general-experimentation/agentic-workflows/src/state.py
- general-experimentation/agentic-workflows/src/tools.py
- general-experimentation/agentic-workflows/src/main.py
- general-experimentation/agentic-workflows/requirements.txt
