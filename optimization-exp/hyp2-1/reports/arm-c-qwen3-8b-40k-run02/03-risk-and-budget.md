## Summary

Adding multi-currency support would require converting all monetary values to a common base currency before any arithmetic operations, comparisons, or budget consumption. This change would impact risk scoring calculations, spending history aggregation, and budget remaining checks.

## Findings

### F1. Risk score calculation using total expenses
- **Location**: `general-experimentation/agentic-workflows/src/tools.py:45`
- **What it does today**: Calculates risk score by comparing total expenses to policy limits using raw float values
- **What the change would require**: Convert all amounts to base currency before comparison; add currency code metadata to all monetary values
- **Confidence**: confirmed

### F2. Spending history accumulation
- **Location**: `general-experimentation/agentic-workflows/src/tools.py:89`
- **What it does today**: Aggregates expenses across time using simple addition of float values
- **What the change would require**: Convert all amounts to base currency before summing; track currency metadata for each entry
- **Conf, 2

### F3. Budget remaining calculation
- **Location**: `general-experimentation/agentic-workflows/src/tools.py:132`
- **What it does today**: Subtracts spent amounts from budget using raw float arithmetic
- **What the change would require**: Convert all amounts to base currency before subtraction; track currency metadata for each value
- **Confidence**: confirmed

## What I could not determine

- none

## Files I read

- general-experimentation/agentic-workflows/src/tools.py
- general-experimentation/agentic-workflows/src/agents.py
