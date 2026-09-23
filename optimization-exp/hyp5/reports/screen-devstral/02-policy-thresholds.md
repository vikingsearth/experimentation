## Summary

The policy thresholds and comparisons in the expense approval workflow currently assume all amounts are in US dollars. To add multi-currency support, we need to identify and update every comparison between an expense amount and a policy limit to handle potentially different currencies.

## Findings

### F1. Single Expense Limit Check

- **Location**: `agents.py:140-141`
- **What it does today**: Compares the expense amount against `policy["max_single_expense"]` to check if it exceeds the limit.
- **What the change would require**: Need to convert both values to a common currency before comparison, or handle currency conversion for either the expense amount or the policy limit.
- **Confidence**: confirmed

### F2. Pre-Approval Threshold Check

- **Location**: `agents.py:152-153`
- **What it does today**: Checks if the expense amount exceeds `policy["requires_pre_approval_above"]`.
- **What the change would require**: Similar to F1, both values need to be in the same currency for accurate comparison.
- **Confidence**: confirmed

### F3. Receipt Required Threshold Check

- **Location**: `tools.py:91`
- **What it does today**: Compares the expense amount against `policy["receipt_required_above"]`.
- **What the change would require**: Both values need to be in the same currency for accurate comparison.
- **Confidence**: confirmed

### F4. Team Meal Per-Person Limit Check

- **Location**: `agents.py:188-189`
- **What it does today**: Divides the total expense amount by the number of attendees to check if the per-person cost exceeds $50.
- **What the change would require**: The total expense amount needs to be converted to USD before dividing by attendees if the policy limit is in USD.
- **Confidence**: confirmed

### F5. Alcohol Amount Limit Check

- **Location**: `agents.py:198-199`
- **What it does today**: Extracts and compares the alcohol amount against a $30 limit.
- **What the change would require**: The extracted alcohol amount needs to be converted to USD before comparison if it's in a different currency.
- **Confidence**: confirmed

## What I could not determine

- How the policy limits are defined and stored (this might be in brief 1).
- How the approval thresholds are defined and stored (this might be in brief 1).
- How the department budgets are defined and stored (this might be in brief 1).

## Files I read

- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/agents.py`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/tools.py`
