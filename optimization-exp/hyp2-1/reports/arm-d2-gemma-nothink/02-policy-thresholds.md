## Summary

The proposed change requires updating several comparisons in the `PolicyAgent` and `RiskAgent` logic. These comparisons currently assume all monetary values are in a single currency (USD), and would need to account for currency conversion before comparing an expense amount against a policy limit or a required receipt threshold.

## Findings

### F1. Policy Limit Check

- **Location**: `general-experimentation/agentic-workflows/src/agents.py:141`
- **What it does today**: Compares the expense amount (`amount`) directly against the policy maximum (`policy["max_single_expense"]`).
- **What the change would require**: The `amount` (from the expense) and the `max_single_expense` (from the policy) must be converted to a common base currency before comparison.
- **Confidence**: confirmed

### F2. Pre-approval Threshold Check

- **Location**: `general-experimentation/agentic-workflows/src/agents.py:152`
- **What it does today**: Compares the expense amount against a pre-approval threshold (`policy["requires_pre_approval_above"]`).
- **What the change would require**: Both the expense amount and the threshold must be converted to a common currency before comparison.
- **Confidence**: confirmed

### F3. Receipt Requirement Check

- **Location**: `general-experimentation/agentic-workflows/src/tools.py:93`
- **What it does today**: Compares the expense amount against `policy["receipt_required_above"]` to determine if a receipt is mandatory.
- **What the change would require**: Both the expense amount and the policy threshold must be converted to a common currency before the comparison.
- **Confidence**: confirmed

### F4. Amount Ratio Calculation

- **Location**: `general-experimentation/agentic-workflows/src/agents.py:287`
- **What it does today**: Calculates a ratio by dividing the expense amount by the policy limit (`ratio = amount / limit`).
- **What the change would require**: Both the amount and the limit must be converted to the same currency before the division to ensure the ratio is meaningful.
- **Confidence**: confirmed

## What I could not determine

- none

## Files I read

- general-experimentation/agentic-workflows/src/agents.py
- general-experimentation/agentic-workflows/src/tools.py
