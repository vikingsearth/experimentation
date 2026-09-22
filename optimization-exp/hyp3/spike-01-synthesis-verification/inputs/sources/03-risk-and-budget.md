Based on my investigation of the codebase, I can now provide my findings on how multi-currency support would affect risk scoring and budget tracking.

## Summary

Multiple currency support would require significant changes to arithmetic operations that currently assume all amounts are in a single currency. Risk scoring depends on dividing expense amounts by policy limits, accumulating spending across multiple expenses, and calculating budget utilization percentages. Each of these operations would fail or produce incorrect results when mixing currencies without explicit conversion to a common base currency.

## Findings

### F1. Amount-to-Limit Ratio for Risk Derivation

- **Location**: `agents.py:287`
- **What it does today**: Creates a ratio by dividing expense amount by the applicable policy limit: `ratio = amount / limit`. This ratio becomes a primary input to risk score calculation.
- **What the change would require**: Both the expense amount and the policy limit must be in the same currency before division. If expense is submitted in EUR but limit is defined in USD, the calculated ratio would be semantically meaningless (e.g., dividing 500 EUR by 3000 USD yields 0.167 as a ratio, when the true currency-adjusted ratio might be 0.05). The ratio must be computed after converting the expense amount to the limit's currency or vice versa.
- **Confidence**: confirmed

### F2. Risk Score Point Calculation from Amount Ratio

- **Location**: `tools.py:136` and `tools.py:159`
- **What it does today**: Translates the amount_ratio (from F1) into risk score points: `score += min(int(ratio * 30), 40)` and the breakdown stores `"amount_factor": min(int(ratio * 30), 40)`. This contributes 0-40 points to the final 0-100 risk score.
- **What the change would require**: This calculation is only valid if the ratio input is already normalized to a single currency (the work of F1 must be done correctly first). No additional currency logic is needed here, but the correctness of risk scoring depends entirely on F1 being currency-aware.
- **Confidence**: confirmed

### F3. Budget Utilization Ratio Calculation

- **Location**: `tools.py:191`
- **What it does today**: Calculates the fraction of monthly budget spent by dividing spent amount by budget: `budget["utilization"] = round(budget["spent_this_month"] / budget["monthly_budget"], 2)`. This yields a scalar between 0 and 1 (or higher if over budget).
- **What the change would require**: If `spent_this_month` is an accumulation of expenses in mixed currencies (see F5), this ratio becomes meaningless. For example, if Engineering department spent 40,000 USD this month but the monthly_budget is stated in USD as 50,000, the utilization is 0.8. But if some of those 40,000 is actually 30,000 USD + 25,000 EUR (which might equal different value in USD after conversion), the true utilization ratio is wrong. The function must either (a) store spent_this_month broken down by currency, or (b) receive a pre-converted total in the base currency.
- **Confidence**: confirmed

### F4. Budget Utilization Threshold in Risk Scoring

- **Location**: `tools.py:152-153` and `tools.py:163`
- **What it does today**: Uses the budget_utilization ratio (from F3) to conditionally add risk points: `if budget_util > 0.8: score += int((budget_util - 0.8) * 75)`. This adds 0-15 points when the department has less than 20% budget remaining.
- **What the change would require**: This threshold comparison depends on budget_utilization being correctly calculated from amounts in the same currency (F3). If F3 produces an incorrect ratio due to mixed currencies, this risk score contribution will be wrong. The threshold comparison itself (> 0.8) is scope of another brief, but the input to it must be currency-normalized.
- **Confidence**: confirmed

### F5. Spending History Total Accumulation

- **Location**: `tools.py:103-117` (function) and `data.py:93-117` (data)
- **What it does today**: Returns `"total_30_days"` as a single accumulated float across all expenses in the past 30 days, plus a `"categories"` dict with amounts summed by category (e.g., `{"travel": 1800.00, "meals": 600.00}`).
- **What the change would require**: These totals cannot sum expenses in mixed currencies without conversion. For example, if an employee spent 1500 USD on travel and 300 EUR on meals in the same 30 days, the function cannot return `"total_30_days": 1800.00` without specifying which currency or converting both to a base currency first. The `"categories"` dict would need to either store per-currency totals (e.g., `{"travel": {"USD": 1500.00}, "meals": {"EUR": 300.00}}`) or be converted to a single base currency. This is a fundamental data structure change, not just a calculation change.
- **Confidence**: confirmed

### F6. Department Budget Consumption and Remaining Calculation

- **Location**: `data.py:120-131` (data) and `tools.py:178-192` (function)
- **What it does today**: Stores department-level budget tracking with `"spent_this_month"` (accumulated float) and `"remaining"` (monthly_budget - spent_this_month, implicitly calculated). For example, Engineering has `monthly_budget: 50000.00` and `spent_this_month: 44000.00`, implying `remaining: 6000.00`.
- **What the change would require**: If the Engineering department receives expenses in multiple currencies (some in USD, some in EUR), the `spent_this_month` cannot be a single number without conversion logic. The system must either (a) maintain a list of {currency, amount} pairs for spent_this_month, (b) convert all incoming expenses to a base currency before accumulating, or (c) track budgets per currency. The `remaining` value becomes meaningless if spent_this_month is ambiguous about its currency composition.
- **Confidence**: confirmed

### F7. Risk Factors Accumulation (Historical Flags)

- **Location**: `agents.py:262` and `agents.py:314`
- **What it does today**: Collects historical flag count (`factors["historical_flags"] = history["flagged_expenses"]`) and uses it in risk scoring. The `calculate_risk_score` function multiplies this by 10 and caps it at 15 points: `score += min(flags * 10, 15)`.
- **What the change would require**: While flagged_expenses is a count (unitless), the expenses are likely flagged based on amount thresholds (e.g., "expenses over 1000" or "expenses over limit"). If those thresholds are currency-specific (e.g., "over 1000 USD"), historical flags would need to include or be filtered by their original currency context to remain meaningful when evaluating a new expense in a different currency. The risk accumulation itself is just a count, but its validity depends on currency-aware flagging upstream.
- **Confidence**: inferred

## What I could not determine

- Whether there is a conversion rate function or external currency service available in the codebase (I did not search the full directory tree for external integrations)
- Whether historical spending amounts in SPENDING_HISTORY are already marked with their currency in the real system (the mock data has no currency field)
- Whether the DecisionAgent's threshold comparisons (e.g., line 393: `amount <= thresholds["auto_approve_up_to"]`) would need currency conversion before comparison, or if those are out of scope per the brief

## Files I read

- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/agents.py`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/tools.py`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/state.py`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/data.py`
