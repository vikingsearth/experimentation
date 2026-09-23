## Summary

Adding multi-currency support would require modifying all comparisons between monetary amounts and policy limits. These comparisons currently assume both values are in the same currency (likely USD), but would need to convert values to a common currency before comparison.

## Findings

### F1. PolicyAgent: Check against single expense limit
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:141`
- **What it does today**: Compares expense amount to policy's `max_single_expense` (USD)
- **What the change would require**: Convert both values to a common currency (e.g., USD) using exchange rates before comparison
- **Confidence**: confirmed

### F2. PolicyAgent: Check against pre-approval threshold
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:152`
- **What it does today**: Compares expense amount to pre-approval threshold (USD)
- **What the change would require**: Convert both values to a common currency using exchange rates before comparison
- **Confidence**: confirmed

### F3. DecisionAgent: Check auto-approval threshold
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:393`
- **What it does today**: Compares expense amount to auto-approval threshold (USD)
- **What the change would require**: Convert both values to a common currency using exchange rates before comparison
- **Confidence**: confirmed

### F4. DecisionAgent: Check policy limits
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:419`
- **What it does today**: Compares expense amount to policy limits (USD)
- **What the change would require**: Convert both values to a common currency using exchange rates before comparison
- **Confidence**: confirmed

### F5. RiskAgent: Amount ratio calculation
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:287`
- **What it does today**: Compares expense amount to policy limit (USD) to calculate ratio
- **What the change would require**: Convert both values to a common currency using exchange rates before calculation
- **Confidence**: confirmed

## What I could not determine

- None

## Files I read

- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/agents.py`
