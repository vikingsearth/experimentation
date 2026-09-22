## Summary

The introduction of multi-currency support would require updating calculation logic in both the `RiskAgent` and the `tools.py` module. Specifically, the system would need to ensure that all monetary values (expense amount, policy limits, and budget totals) are converted to a common base currency before any arithmetic operations—such as calculating ratios, determining budget utilization, or checking thresholds—are performed.

## Findings

### F1. Risk Score Calculation
- **Location**: `general-experimentation/agentic-workflows/src/tools.py:134-164`
- **What it does today**: Calculates a risk score based on `amount_ratio` (expense/limit), `violation_count`, `historical_flags`, `rejection_rate`, and `budget_utilization`.
- **What the change would require**: The `factors` dictionary must contain values normalized to a single currency before being passed to `calculate_risk_score`. Specifically, `amount_ratio` must be calculated using the amount and the limit in the same currency (or both converted to a base currency), and `budget_utilization` must be calculated from a budget and spending total in the same currency.
- **Confidence**: confirmed

### F2. Budget Calculation
- **Location**: `general-experiment_tokens/agentic-workflows/src/tools.py:180-192`
- **What it does today**: Calculates `utilization` as `spent_this_month` / `monthly_budget` for a department.
- **What the change would require**: Both `spent_this_month` and `monthly_budget` must be in the same currency (or converted to a base currency) before the division occurs to ensure the resulting `utilization` ratio is accurate.
- **Confidence**: confirmed

### F3. Expense Amount vs. Policy Limit
- **Location**: `general-experimentation/agentic-workflows/src/tools.py:88-93`
- **What it does today**: Determines if a receipt is required by checking if `amount > threshold`.
- **What the change would require**: The `amount` and the `threshold` (retrieved from `POLICIES`) must be in the same currency before comparison. If the expense is in a different currency than the policy's base currency, the `amount` must be converted before the check.
- **Confidence**: confirmed

### F4. Risk Assessment Logic
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:283-293`
- **What it does today**: Calculates the `ratio` of the expense amount to the policy limit to determine the `amount_ratio` factor.
- **What the change would require**: The `amount` (from `state.expense`) and `limit` (from `state.applicable_limit`) must be converted to a common currency before the division `ratio = amount / limit` occurs.
- **Confidence**: confirmed

### F5. Decision Rule Evaluation
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:393-400`
- **What it does today**: Compares `amount` against `thresholds["auto_approve_up_to"]`.
- **What the change would require**: The `amount` and the `auto_approve_up_to` threshold must be in the same currency before the comparison `amount <= thresholds["auto_approve_up_to"]` is performed.
- **Confidence**: confirmed

## What I could not determine

- none

## Files I read
- general-experimentation/agentic-workflows/src/agents.py
- general-experimentation/agentic-workflows/src/tools.py
