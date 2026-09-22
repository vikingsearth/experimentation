## Summary

Adding multi-currency support would require every monetary value in data.py to track both numeric value and currency code. This affects employee budgets, policy limits, spending history, department budgets, approval thresholds, and sample expenses.

## Findings

### F1. Employee monthly budgets
- **Location**: `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/data.py:15`
- **What it does today**: Stores float value for employee monthly budget
- **What the change would require**: Store tuple of (currency_code, amount) instead of float
- **Confidence**: confirmed

### F2. Policy max single expense
- **Location**: `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/data.py:38`
- **What it does today**: Stores float value for maximum single expense per category
- **What the change would require**: Store tuple of (currency_code, amount) instead of float
- **Confidence**: confirmed

### F3. Spending history totals
- **Location**: `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/data.py:94`
- **What it does today**: Stores float values for total spending and category breakdowns
- **What the change would require**: Store tuples of (currency_code, amount) for all numeric values
- **Confidence**: confirmed

### F4. Department budgets
- **Location**: `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/data.py:122`
- **What it does today**: Stores float values for departmental budgeting
- **What the change would require**: Store tuples of (currency_code, amount) for all numeric values
- **Confidence**: confirmed

### F5. Approval thresholds
- **Location**: `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/data.py:135`
- **What it does today**: Stores float values for approval limits
- **What the change would require**: Store tuples of (currency_code, amount) for all numeric values
- **Confidence**: confirmed

### F6. Sample expense amounts
- **Location**: `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/data.py:143`
- **What it does today**: Stores float values for sample expense amounts
- **What the change would require**: Store tuples of (currency_code, amount) for all numeric values
- **Confidence**: confirmed

## What I could not determine

- none

## Files I read

- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/data.py`
