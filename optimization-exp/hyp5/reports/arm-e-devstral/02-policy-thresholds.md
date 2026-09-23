## Summary

The expense approval workflow currently uses implicit US dollars for all monetary amounts. To add multi-currency support, every comparison between an amount and a limit or threshold would need to be currency-aware. This would require:

1. Storing currency information with each amount
2. Converting amounts to a common base currency for comparisons
3. Updating all comparison logic to handle currency conversion

## Findings

### F1. PolicyAgent: amount vs policy limit

- **Location**: `agents.py:140-142`
- **What it does today**: Compares the expense amount against the category's maximum single expense limit.
- **What the change would require**: The comparison must convert both values to the same currency before comparing.
- **Confidence**: confirmed

### F2. PolicyAgent: amount vs pre-approval threshold

- **Location**: `agents.py:152-156`
- **What it does today**: Checks if the expense amount exceeds the pre-approval threshold.
- **What the change would require**: Both values must be in the same currency before comparison.
- **Confidence**: confirmed

### F3. PolicyAgent: per-person meal limit

- **Location**: `agents.py:188-191`
- **What it does today**: Divides the total meal cost by attendee count to check per-person limit.
- **What the change would require**: The total amount must be in the base currency before division.
- **Confidence**: confirmed

### F4. PolicyAgent: alcohol amount limit

- **Location**: `agents.py:198-203`
- **What it does today**: Checks if the alcohol portion of a meal expense exceeds $30.
- **What the change would require**: The extracted alcohol amount must be converted to base currency.
- **Confidence**: confirmed

### F5. DecisionAgent: amount vs approval thresholds

- **Location**: `agents.py:393-394`
- **What it does today**: Compares expense amount against auto-approval and approval limits for the employee's level.
- **What the change would require**: Expense amount and threshold must be in the same currency.
- **Confidence**: confirmed

### F6. check_receipt_attached: amount vs receipt threshold

- **Location**: `tools.py:88-93`
- **What it does today**: Checks if the expense amount exceeds the threshold requiring a receipt.
- **What the change would require**: Both values must be in the same currency before comparison.
- **Confidence**: confirmed

### F7. calculate_risk_score: amount ratio

- **Location**: `tools.py:135-136`
- **What it does today**: Calculates the expense amount as a ratio of the policy limit.
- **What the change would require**: Both values must be in the same currency before division.
- **Confidence**: confirmed

## What I could not determine

- None

## Files I read

- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/agents.py`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/tools.py`
