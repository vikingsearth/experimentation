## Summary

Adding multi-currency support to the expense approval workflow would require every monetary amount that's shown to users or documented in examples to display both the original currency and a base currency conversion. This affects printed summaries, policy check messages, risk assessment observations, decision rationales, and documentation tables. Each format string would need modification to include currency symbols/codes alongside amounts.

## Findings

### F1. Expense amount in workflow header

- **Location**: `src/main.py:69`
- **What it does today**: Prints the expense ID and amount in USD format: `Expense: {id} -- ${amount:.2f}`
- **What the change would require**: Extend to show: `Expense: {id} -- {amount} {original_currency} (${base_amount} USD)` or similar dual-currency format
- **Confidence**: confirmed

### F2. Batch summary table with amounts

- **Location**: `src/main.py:183`
- **What it does today**: Formats amount column as `f"${s.expense.get('amount', 0):.2f}"` in a summary table
- **What the change would require**: Modify table layout to show both original and base currency, e.g., add a currency code column or use format `amount (original_currency) / base_USD`
- **Confidence**: confirmed

### F3. Policy rule max expense observation

- **Location**: `src/agents.py:133`
- **What it does today**: `_observation(f"Found {len(policy['rules'])} rules, max=${policy['max_single_expense']:.0f}")`
- **What the change would require**: Prepend currency and show base amount: `max={max_single_expense} {currency} (${base_amount} USD)` or equivalent
- **Confidence**: confirmed

### F4. Expense vs limit thought process

- **Location**: `src/agents.py:140`
- **What it does today**: `_thought(f"Expense is ${amount:.2f}. Limit is ${policy['max_single_expense']:.2f}.")`
- **What the change would require**: Include original currency code and base currency: `Expense is {amount} {orig_currency} (${base_amount} USD). Limit is {limit} {limit_currency} (${base_limit} USD).`
- **Confidence**: confirmed

### F5. Policy violation message (amount exceeds limit)

- **Location**: `src/agents.py:142-145`
- **What it does today**: Formats violation as `f"Amount ${amount:.2f} exceeds {category} limit of ${policy['max_single_expense']:.2f}"`
- **What the change would require**: Include both currencies: `Amount {amount} {orig_currency} (${base_amount} USD) exceeds {category} limit of {limit} {limit_currency} (${base_limit} USD)`
- **Confidence**: confirmed

### F6. Pre-approval threshold warning message

- **Location**: `src/agents.py:152-155`
- **What it does today**: Formats as `f"Amount ${amount:.2f} exceeds pre-approval threshold of ${policy['requires_pre_approval_above']:.2f}"`
- **What the change would require**: Show dual currencies: `Amount {amount} {orig_currency} (${base_amount} USD) exceeds pre-approval threshold of {threshold} {threshold_currency} (${base_threshold} USD)`
- **Confidence**: confirmed

### F7. Pre-approval threshold in thought

- **Location**: `src/agents.py:158`
- **What it does today**: `_thought(f"This requires pre-approval (threshold: ${policy['requires_pre_approval_above']:.2f}).")`
- **What the change would require**: Include currency: `This requires pre-approval (threshold: {threshold} {currency} or ${base_threshold} USD).`
- **Confidence**: confirmed

### F8. Receipt requirement threshold message

- **Location**: `src/agents.py:169-170`
- **What it does today**: `f"Receipt required for amounts over ${receipt_result['threshold']:.2f} but none attached"`
- **What the change would require**: Add currency information: `Receipt required for amounts over {threshold} {currency} (${base_threshold} USD) but none attached`
- **Confidence**: confirmed

### F9. Per-person meal cost violation

- **Location**: `src/agents.py:190`
- **What it does today**: `f"Per-person cost ${per_person:.2f} exceeds $50 team meal limit"`
- **What the change would require**: Show dual currencies for both the actual cost and the limit: `Per-person cost {per_person} {currency} (${base_per_person} USD) exceeds 50 USD (base currency limit)`
- **Confidence**: confirmed

### F10. Alcohol amount violation

- **Location**: `src/agents.py:201`
- **What it does today**: `f"Alcohol amount ${alcohol_amount:.2f} exceeds $30 per-meal cap"`
- **What the change would require**: Show dual currencies: `Alcohol amount {alcohol_amount} {currency} (${base_alcohol} USD) exceeds 30 USD per-meal cap (base currency limit)`
- **Confidence**: confirmed

### F11. Spending history observation

- **Location**: `src/agents.py:258-260`
- **What it does today**: `_observation(f"Last 30 days: ${history['total_30_days']:.0f} across {count} expenses, {flagged} flagged")`
- **What the change would require**: Include currency: `Last 30 days: {total} {currency} (${base_total} USD) across {count} expenses, {flagged} flagged`
- **Confidence**: confirmed

### F12. Department budget observation

- **Location**: `src/agents.py:276-279`
- **What it does today**: `_observation(f"Budget: ${budget['remaining']:.0f} remaining of ${budget['monthly_budget']:.0f} ({utilization:.0%} used)")`
- **What the change would require**: Show both original and base currencies: `Budget: {remaining} {currency} (${base_remaining} USD) remaining of {total} {currency} (${base_total} USD) ({utilization:.0%} used)`
- **Confidence**: confirmed

### F13. Amount ratio in risk thinking

- **Location**: `src/agents.py:289-291`
- **What it does today**: `_thought(f"The expense is ${amount:.2f} against a limit of ${limit:.2f} (ratio: {ratio:.2f})...")`
- **What the change would require**: Include currencies: `The expense is {amount} {orig_currency} (${base_amount} USD) against a limit of {limit} {limit_currency} (${base_limit} USD) (ratio: {ratio:.2f})...`
- **Confidence**: confirmed

### F14. Amount ratio in risk factors list

- **Location**: `src/agents.py:312`
- **What it does today**: `f"Amount ratio: {ratio:.2f}x of policy limit"`
- **What the change would require**: If this stays, no change needed (it's a ratio). If expanded to show amounts: include both currencies
- **Confidence**: confirmed

### F15. Approval thresholds observation

- **Location**: `src/agents.py:365-366`
- **What it does today**: `_observation(f"Auto-approve up to ${thresholds['auto_approve_up_to']:.0f}, can approve up to ${thresholds['can_approve_up_to']:.0f}")`
- **What the change would require**: Add currency: `Auto-approve up to {threshold1} USD, can approve up to {threshold2} USD` (these are base thresholds, but should still be labeled as currency)
- **Confidence**: confirmed

### F16. Decision rationale (critical violation)

- **Location**: `src/agents.py:382-384`
- **What it does today**: `f"Expense of ${amount:.2f} has critical policy violation(s):..."`
- **What the change would require**: Include currencies: `Expense of {amount} {orig_currency} (${base_amount} USD) has critical policy violation(s):...`
- **Confidence**: confirmed

### F17. Decision rationale (auto-approval)

- **Location**: `src/agents.py:397-399`
- **What it does today**: `f"Amount ${amount:.2f} is within auto-approval threshold (${thresholds['auto_approve_up_to']:.0f}) for {level} level..."`
- **What the change would require**: Show both currencies: `Amount {amount} {orig_currency} (${base_amount} USD) is within auto-approval threshold ({threshold} USD) for {level} level...`
- **Confidence**: confirmed

### F18. Decision rationale (standard approval)

- **Location**: `src/agents.py:422-424`
- **What it does today**: `f"Amount ${amount:.2f} is within policy limits, no violations, risk is {risk}..."`
- **What the change would require**: Include currencies: `Amount {amount} {orig_currency} (${base_amount} USD) is within policy limits, no violations, risk is {risk}...`
- **Confidence**: confirmed

### F19. Sample expenses documentation table

- **Location**: `README.md:29-34`
- **What it does today**: Table with columns for ID, Description, Amount, Expected Outcome. Amounts shown as `$450`, `$680`, `$3,200`, `$2,800` with implicit USD currency
- **What the change would require**: Either add a Currency column to the table, or modify Amount column to show format like `450 USD` or `450 (USD)` to make currency explicit
- **Confidence**: confirmed

## What I could not determine

- Whether the base currency (USD) should always be the same or be configurable per workflow/deployment
- Whether conversion rates should be shown alongside amounts or if simple conversions are acceptable
- Whether there are any exported reports, API responses, or other output formats not visible in the main codebase files

## Files I read

- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/main.py`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/agents.py`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/tools.py`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/state.py`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/data.py`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/README.md`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/docs/planning/plan.md`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/docs/research/agentic-patterns.md`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/docs/research/business-logic-modeling.md`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/docs/research/frameworks-overview.md`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/docs/research/guardrails-and-hitl.md`
