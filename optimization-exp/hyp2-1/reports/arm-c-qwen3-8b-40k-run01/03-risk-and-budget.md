## Summary

Adding multi-currency support would require converting all monetary values to a base currency before any arithmetic operations or comparisons. This change would impact risk scoring calculations, spending history aggregation, and budget remaining checks, as these operations depend on accurate currency alignment.

## Findings

### F1. Risk score calculation in RiskAgent
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:42`
- **What it does today**: Uses raw float values from expenses to compute risk scores via linear scaling (e.g., `amount * 0.1`).
- **What the change would require**: All amounts must be converted to the base currency (e.g., USD) before scaling, and the base currency must be explicitly tracked.
- **Confidence**: inferred

### F2. Spending history aggregation in get_spending_history
- **Location**: `general-experimentation/agentic-workflows/src/tools.py:112`
- **What it does today**: Sums raw float values from historical expenses to compute total spending.
- **What the change would require**: All amounts must be converted to the base currency before summation, and the function must track currency codes for each entry.
- **Confidence**: inferred

### F3. Budget remaining check in check_budget_remaining
- **Location**: `general-experimentation/agentic-workflows/src/tools.py:189`
- **What it does today**: Compares current spending to a budget limit using raw float values.
- **What the change would require**: Both the budget limit and current spending must be in the same currency (e.g., USD), with explicit currency codes for both values.
- **Conf
- **Confidence**: inferred

## What I could not determine

- none

## Files I read

- general-experimentation/agentic-workflows/src/agents.py
- general-experimentation/agentic-workflows/src/tools.py
