```
## Summary

This change would require updating several hardcoded currency symbols ($) and related formatting logic in `main.py` and `agents.py`. Specifically, it would require expanding all monetary output points to include both the original currency and the base currency to ensure clarity for users.

## Findings

### F1. Expense amount display in main loop
- **Location**: `general-experimentation/agentic-workflows/src/main.py:69`
- **What it does today**: Prints the amount prefixed with a dollar sign: `print(f"  Expense: {expense.get('id')} -- ${expense.get('amount', 0):.2f}")`
- **What the change would require**: Replace the fixed `$` with a dynamic currency symbol and potentially include the base currency equivalent if the original currency differs.
- **Confidence**: confirmed

### F2. Policy check messages in PolicyAgent
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:133`
- **What it does today**: Displays the max single expense as a dollar amount: `_observation(f"Found {len(policy['rules'])} rules, max=${policy['max_single_expense']:.0f}")`
- **What the change would require**: Update to show the currency of the policy limit.
- **Confidence**: confirmed

### F3. Policy violation amount reporting
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:143`
- **What it does today**: Reports the amount and limit in dollars: `f"Amount ${amount:.2f} exceeds {state.category} limit of ${policy['max_single_expense']:.2f}"`
- **What the change would require**: Update to display the currency of the current expense and the policy's limit currency.
- **Confidence**: confirmed

### F4. Pre-approval threshold warnings
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:154`
- **What it does today**: Shows the pre-approval limit in dollars: `f"Amount ${amount:.2f} exceeds pre-approval threshold of ${policy['requires_pre_approval_above']:.2f}"`
- **What the change would require**: Update to include currency symbols for both current amount and threshold.
- **Confidence**: confirmed

### F5. Receipt threshold notice
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:169`
- **What it does today**: Prints a requirement notice: `f"Receipt required for amounts over ${receipt_result['threshold']:.2f} but none attached"`
- **What the change would require**: Update to include the currency of the receipt threshold.
- **Confidence**: confirmed

### F6. Meal/Alcohol specific caps
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:190`
- **What it does today**: `msg = f"Per-person cost ${per_person:.2f} exceeds $50 team meal limit"`
- **What the change would require**: Update to reflect the currency of the specific meal cap.
- **Confidence**: confirmed

### F7. Alcohol limit check
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:201`
- **What it does today**: `msg = f"Alcohol amount ${alcohol_amount:.2f} exceeds $30 per-meal cap"`
- **What the change would require**: Update to include the currency for the alcohol cap.
- **Confidence**: confirmed

### F8. Risk assessment summary
- **Location**: `general-itementation/agentic-workflows/src/agents.py:258`
- **What it does today**: `f"Last 30 days: ${history['total_30_days']:.0f} across ..."`
- **What the change would require**: Update to show the currency for the historical spending total.
- **Confidence**: confirmed

### F9. Budget pressure report
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:276`
- **What it does today**: `f"Budget: ${budget['remaining']:.0f} remaining of ${budget['monthly_budget']:.0f} ..."`
- **What the change would require**: Update to show the currency of the budget.
- **Confidence**: confirmed

### F10. Amount ratio thought
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:289`
- **What it does today**: `f"[Iteration {iteration}] The expense is ${amount:.2f} against a limit of ${limit:.2f} ..."`
- **What the change would require**: Update to include currency symbols for both amount and limit.
- **Confidence**: confirmed

### F11. Batch Summary Header
- **Location**: `general-experimentation/agentic-workflows/src/main.py:179`
- **What it does today**: Prints a table header. (No amount shown, but the column for amount is established here).
- **What the change would require**: The table header remains the same, but the data row logic must handle multi-currency.
- **Confidence**: confirmed

### F12. Batch Summary Rows
- **Location**: `general-experimentation/agentic-workflows/src/main.py:187`
- **What it does today**: Prints the amount in the summary table: `print(f"  {eid:<10} {amt:>10} {risk:>8} {dec:<25} {rev}")`
- **What the change would require**: The amount `amt` (derived from `state.expense['amount']`) must now include or accompany a currency identifier.
- **Confidence**: confirmed

### F13. Decision thresholds
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:365`
- **What it does today**: `f"Auto-approve up to ${thresholds['auto_approve_up_to']:.0f}, can approve up to ${thresholds['can_approve_up_to']:.0f}"`
- **What the change would require**: Update to reflect the correct currency for these thresholds.
- **Confidence**: confirmed

### F14. Decision logic rationales
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:382`
- **What it does today**: `f"Expense of ${amount:.2f} has critical policy violation(s): ..."`
- **What the change would require**: Update currency for the amount.
- **Confidence**: confirmed

### F15. Decision logic (auto-approve)**
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:397`
- **What it does today**: `f"Amount ${amount:.2f} is within auto-approval threshold (${thresholds['auto_approve_up_to']:.0f}) ..."`
- **What the change would require**: Update currency for amount and threshold.
- **Confidence**: confirmed

### F16. Decision logic (standard)**
- **Location**: `general-experimentation/agentic-workflows/src/agents.py:422`
- **What it does today**: `f"Amount ${amount:.2f} is within policy limits, ..."`
- **What the change would require**: Update currency for the amount.
- **Confidence**: confirmed

### F17. README.md Overview**
- **Location**: `general-experimentation/agentic-workflows/README.md`
- **What it does today**: Provides general documentation.
- **What the change would require**: Update any examples or text that refer to currency limits or amounts to reflect the new multi-currency system.
- **Confidence**: inferred (based on general scope of documentation updates).

## What I could not determine

- The specific mapping between currency codes (e.g., "USD" to "$") or how the "base currency" is determined for display in a multi-currency context.

## Files I read

- general-experimentation/agentic-workflows/src/main.py
- general-experimentation/agentic-workflows/src/agents.py
- general-experimentation/agentic-workflows/README.md
```
