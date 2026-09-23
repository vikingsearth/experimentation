## Summary

The addition of multi-currency support would require significant changes to the calculation of risk scores and the tracking of budget sums. Specifically, any logic that sums multiple expenses (like total spending or budget consumption) must account for currency conversions to ensure the resulting totals are meaningful, while any ratio calculations (like amount vs. limit or budget utilization) must ensure that both values are in the same currency before the division occurs.

## Findings

### F1. Spending history total
- **Location**: `general-experimentation/agentic-workflows/src/tools.py:110`
- **What it does today**: Returns the `total_30_days` as a sum of the user's expenditures over the last 30 days.
- **What the change would require**: Since this is an accumulation of potentially many different transactions, the system would need to convert each transaction into a common base currency (e.g., USD) before summing them to provide a meaningful total.
- **Confidence**: confirmed

### F2. Budget consumption
- **Location**: `general-experimentation/agentic-workflows/src/tools.py:185`
- **What it does today**: Returns `spent_this_month` as a sum of all costs incurred by a department.
- **What the change would require**: As an accumulation of multiple transactions from potentially different sources/locations, these values must be normalized to a base currency before being summed.
- **Confidence**: confirmed

### F3. Budget utilization ratio
- **Location**: `general-experimentation/agentic-workflows/src/tools.py:191`
- **What it does today**: Calculates the `utilization` ratio by dividing `spent_this_month` by `monthly_budget`.
- **What the change would require**: The calculation requires that both `spent_this_month` and `monthly_budget` are expressed in the same currency. If the `spent_this_month` is derived from a multi-currency pool, it must be converted to the base currency of the `monthly_budget` before the division.
- **Confidence**: confirmed

### F4. Per-person cost derivation
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:188`
- **What it does today**: Calculates `per_person` by dividing the total `amount` of a meal by the number of attendees.
- **What the change would require**: Since `amount` is a single transaction value, this derivation is mathematically sound as long as the `amount` is known in its original currency. However, for reporting or comparison purposes, the currency would need to be tracked.
- **Confidence**: confirmed

### F5. Amount ratio for risk
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:287`
- **What it does today**: Calculates a `ratio` of the current expense `amount` against the `limit` (policy limit).
- **What the change would require**: Both the `amount` and the `limit` must be in the same currency before the division. If the claim is in a different currency than the policy's base currency, the `amount` must be converted to the policy's currency before the ratio is calculated.
- **Confidence**: confirmed

### F6. Risk score calculation
- **Location**: `general-experimentation/agentic-workflows/src/tools.py:155`
- **What it does today**: Calculates the final `score` (0-100) and `level` based on several factors, including the `ratio` and `budget_util`.
- **What the change would require**: The calculation depends on the `ratio` and `budget_util` (see F3 and F5). These values must be correctly calculated using consistent currency conversions before they are used to derive the final risk score.
- **Confidence**: confirmed

## What I could not determine

- none

## Files I read
- general-experimentation/agentic-workflows/src/agents.py
- general-experimentation/agentic-workflows/src/tools.py
