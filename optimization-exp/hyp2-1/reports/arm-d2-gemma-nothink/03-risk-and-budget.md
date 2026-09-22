## Summary

This change would require converting all "amount" and "budget" calculations from single floats into objects or pairs that include currency information. Specifically, risk scores and budget utilization ratios would need to be calculated using normalized values (converted to a base currency) to ensure that multi-currency submissions do not skew the results.

## Findings

### F1. Ratio Calculation
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:287`
- **What it does today**: Calculates a ratio of the expense amount to the policy limit (`ratio = amount / limit`).
- **What the change would require**: Both `amount` and `limit` would need to be in the same currency before division. Since `limit` is a policy constant (implicitly USD), the `amount` must be converted to the base currency if it is in a different currency.
- **Confidence**: confirmed

### F2. Budget Utilization Calculation
- **Location**: `general-experimentation/agentic-workflows/src/tools.py:191`
- **What it does today**: Calculates budget utilization as `spent_this_month / monthly_budget`.
- **What the change would require**: Both `spent_this_month` and `monthly_budget` must be in the same currency. If the system supports multiple currencies, both the expenditure and the budget must be normalized to a base currency to ensure the ratio is meaningful.
- **Confidence**: confirmed

### F3. Risk Score Factor Calculation (Amount)
- **Location**: `general-experimentation/agentic-workflows/src/tools.py:136`
- **What it does today**: Adds points to the risk score based on the `amount_ratio` (`min(int(ratio * 30), 40)`).
- **What the change would require**: The `ratio` (derived from `amount / limit`) must be based on normalized values to ensure that a large amount in a "weak" currency (e.g., Yen) doesn't result in a lower risk score than a smaller amount in a "strong" currency (e.g., USD).
- **Confidence**: confirmed

### F4. Risk Score Factor Calculation (Budget)
- **Location**: `general-experimentation/agentic-workflows/src/tools.py:153`
- **What it does today**: Adds points to the risk score based on the `budget_util` (the result of `check_budget_remaining`).
- **What the change would require**: The `budget_util` (ratio) must be calculated using normalized values so that a high spend in a foreign currency correctly reflects its impact on the budget.
- **Confidence**: confirmed

### F5. Meal Amount Calculation
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:199`
- **What it does today**: Parses a string to get an `alcohol_amount` and compares it to a hard-coded threshold of `30`.
- **What the change would require**: The `alcohol_amount` would need to be converted to the base currency before being compared to the `30` limit, otherwise, the threshold would be currency-dependent.
- **Confidence**: confirmed

### F6. Per-Person Meal Calculation
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:188`
- **What it does today**: Divides the total amount by the number of attendees (`per_person = amount / attendees`).
- **What the change would require**: While a simple division doesn't break the math for a single currency, the resulting `per_person` would need to be in the base currency if compared against a policy limit in the next step.
- **Confidence**: confirmed

## What I could not determine

- none

## Files I read

- general-experimentation/agentic-workflows/src/agents.py
- general-experimentation/agentic-workflows/src/tools.py
