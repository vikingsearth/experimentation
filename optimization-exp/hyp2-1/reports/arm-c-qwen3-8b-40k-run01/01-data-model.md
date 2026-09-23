## Summary

This change would require all static monetary values and input fields to carry currency metadata. The system currently uses float values without currency context, so every numeric monetary value would need to be paired with a currency code.

## Findings

### F1. Employee Monthly Budgets
- **Location**: `general-experimentation/agentic-workflows/src/data.py:15`, `data.py:23`, `data.py:31`
- **What it does today**: Stores float values representing monthly budgets for employees
- **What the change would require**: Store tuples of (amount, currency_code) instead of floats
- **Confidence**: confirmed

### F2. Policy Expense Limits
- **Location**: `general-experimentation/agentic-workflows/src/data.py:38`, `data.py:50`, `data.py:61`, `data.py:71`, `data.py:81`
- **What it does today**: Defines maximum single expense limits as float values
- **What the change would require**: Store tuples of (amount, currency_code) for all policy limits
- **Confidence**: confirmed

### F3. Spending History Metrics
- **Location**: `general-experimentation/agentic-workflows/src/data.py:94`, `data.py:102`, `data.py:110`
- **What it does today**: Tracks total spending and category breakdowns using float values
- **What the change would require**: Store all numeric values as tuples of (amount, currency_code)
- **Confidence**: confirmed

### F4. Department Budgets
- **Location**: `general-experimentation/agentic-workflows/src/data.py:122`, `data.py:128`
- **What it does today**: Stores departmental budget limits as float values
- **What the change would require**: Store tuples of (amount, currency_code) instead of floats
- **Confidence**: confirmed

### F5. Approval Thresholds
- **Location**: `general-experimentation/agentic-workflows/src/data.py:135`, `data.py:136`, `data.py:137`, `data.py:138`
- **What it does today**: Defines approval limits as float values
- **What the change would require**: Store tuples of (amount, currency_code) for all thresholds
- **Confidence**: confirmed

### F6. Sample Expense Submissions
- **Location**: `general-experimentation/agentic-workflows/src/data.py:142`, `data.py:144`, `data.py:152`, `data.py:160`, `data.py:170`
- **What it does today**: Captures expense amounts as float values in input data
- **What the change would require**: Collect both amount and currency code for every expense submission
- **Confidence**: confirmed

## What I could not determine

- none

## Files I read

- general-experimentation/agentic-workflows/src/data.py
