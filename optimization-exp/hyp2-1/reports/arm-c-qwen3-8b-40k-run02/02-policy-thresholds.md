```
## Summary

Adding multi-currency support would require modifying all comparisons between monetary values and limits/thresholds. These comparisons currently assume both sides are in the same currency (USD), but would need to convert values to a common base currency for accurate comparisons.

## Findings

### F1. PolicyAgent: Compare expense amount to policy limit
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:140`
- **What it does today**: Compares the expense amount (float) to a policy limit (float) to check if it exceeds the limit
- **What the change would require**: Both values would need to be converted to the same currency (e.g., USD) before comparison. The policy limit would need to be stored with its currency metadata
- **Confidence**: confirmed

### F2. PolicyAgent: Compare expense amount to pre-approval threshold
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:151`
- **What it does today**: Checks if the expense amount exceeds a pre-approval threshold (float)
- **What the change would require**: Both values would need to be converted to the same currency. The threshold would need to be stored with currency metadata
- **Confidence**: confirmed

### F3. DecisionAgent: Compare amount to approval thresholds
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:361`
- **What it does today**: Uses approval thresholds (float) to determine auto-approval limits
- **What the change would require**: Thresholds would need to be stored with currency metadata. Amounts would need to be converted to the same currency before comparison
- **Confidence**: confirmed

### F4. check_receipt_attached: Compare amount to receipt threshold
- **Location**: `general-experimentation/agentic-workflows/src/tools.py:94`
- **What it does today**: Checks if amount exceeds a receipt threshold (float)
- **What the change would require**: Both values would need to be in the same currency. The threshold would need to be stored with currency metadata
- **Confidence**: confirmed

### F5. RiskAgent: Compare amount to policy limit (amount ratio)
- **Location**: `general-experimentation/agentic-workflows/src/tools.py:134`
- **What it does today**: Calculates the ratio of expense amount to policy limit (both floats)
- **What the change would require**: Both values would need to be converted to the same currency. The policy limit would need to be stored with currency metadata
- **Confidence**: confirmed

## What I could not determine

- None

## Files I read

- general-experimentation/agentic-workflows/src/agents.py
- general-experimentation/agentic-workflows/src/tools.py
```
