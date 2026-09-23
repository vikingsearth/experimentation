## Summary

The proposed change would require identifying and handling potential currency mismatches in all instances where a monetary amount is compared against a policy limit or a fixed threshold. This includes ensuring that both sides of the comparison are converted to a common currency before the comparison is performed.

## Findings

### F1. Policy limit comparison
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:141`
- **What it does today**: Compares the expense amount against the maximum allowed amount for the category.
- **What the change would require**: The `amount` (from the expense) must be converted to the currency of the `max_single_expense` limit (or both must be converted to a base currency) before comparison.
- **Confidence**: confirmed

### F2. Pre-approval threshold comparison
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:152`
- **What it does today**: Compares the expense amount against the threshold for required pre-approval.
- **What the change would require**: The `amount` must be converted to the currency of the `requires_pre_approval_above` limit before comparison.
- **Confidence**: confirmed

### F3. Team meal per-person limit
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:189`
- **What it does today**: Compares the per-person cost of a team meal against a hardcoded threshold of 50.
- **What the change would require**: The comparison involves a hardcoded value (50). This needs to be either converted into a currency-aware value or the `amount` must be converted to the currency assumed by the threshold before the division and comparison.
- **Confidence**: confirmed

### F4. Alcohol limit
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:200`
- **What it does today**: Compares the alcohol amount extracted from the notes against a hardcoded threshold of 30.
- **What the change would require**: Similar to F3, the `alcohol_amount` must be converted to the currency assumed by the hardcoded threshold of 30 before the comparison.
- **Confidence**: confirmed

### F5. Receipt requirement threshold
- **Location**: `general-experimentation/agentic-workflows/src/tools.py:93`
- **What it does today**: Compares the expense amount against the threshold at which a receipt becomes required.
- **What the change would require**: The `amount` must be converted to the currency of the `threshold` before comparison.
- **Confidence**: confirmed

### F6. Auto-approval threshold
- **Location**: `general-itement/agentic-workflows/src/agents.py:393`
- **What it does today**: Compares the expense amount against the threshold for automatic approval based on the employee's level.
- **What the change would require**: The `amount` must be converted to the currency of the `auto_approve_up_to` limit before comparison.
- **Confidence**: confirmed

### F7. Risk assessment ratio
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:287`
- **What it does today**: Calculates the ratio of the amount to the policy limit to determine the risk factor.
- **What the change would require**: The `amount` must be converted to the currency of the `limit` before the division is performed to ensure the ratio is correct.
- **Confidence**: confirmed

## What I could not determine

- none

## Files I read
- general-experimentation/agentic-workflows/src/agents.py
- general-experimentation/agentic-workflows/src/tools.py
