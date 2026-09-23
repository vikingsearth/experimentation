## Summary

The workflow has multiple entry points where monetary amounts enter the system as static data or test inputs. All amounts are currently bare `float` values without any currency information attached. To support multi-currency, each of these locations would need to be modified to carry currency metadata—either as a parallel currency field or as a structured type containing both amount and currency code.

## Findings

### F1. Employee monthly budgets

- **Location**: `src/data.py:15, 23, 31`
- **What it does today**: The `EMPLOYEES` dict defines `monthly_budget` as bare floats (5000.00, 15000.00, 2000.00). These are queried by the risk assessor to check budget constraints.
- **What the change would require**: Each `monthly_budget` entry would need to carry currency information. Options: (a) add a parallel `monthly_budget_currency` field per employee, or (b) change `monthly_budget` from `float` to a dict/tuple like `{"amount": 5000.00, "currency": "USD"}`.
- **Confidence**: confirmed

### F2. Policy threshold amounts

- **Location**: `src/data.py:38–40, 50–52, 61–63, 71–73, 81–83`
- **What it does today**: The `POLICIES` dict defines three numeric thresholds per category (`max_single_expense`, `requires_pre_approval_above`, `receipt_required_above`) as bare floats. PolicyAgent reads these to check violations.
- **What the change would require**: Each policy dict would need either parallel `*_currency` fields or a single `currency` field per category (or per policy dict). Consider: should all policies share one base currency, or can policies differ by category/region? This affects schema design.
- **Confidence**: confirmed

### F3. Policy rule amounts as embedded strings

- **Location**: `src/data.py:44, 46, 55, 56, 67`
- **What it does today**: Policy rule strings contain dollar amounts as string literals (e.g., "Hotel rates must not exceed $250/night", "Per diem meals: $75/day domestic"). These are read by humans/agents but not programmatically extracted or compared.
- **What the change would require**: Option (a): parse currency symbols from strings and extract amounts. Option (b): refactor rules into structured objects with amounts and currency. Currently unmaintainable for currency-aware comparisons; requires parsing or restructuring.
- **Confidence**: confirmed

### F4. Spending history amounts (aggregate data)

- **Location**: `src/data.py:94–97, 102–105, 110–113`
- **What it does today**: The `SPENDING_HISTORY` dict holds aggregate spending totals (`total_30_days`, `largest_single_expense`, category breakdowns) as bare floats. RiskAgent reads these to compute risk factors.
- **What the change would require**: Decision needed: should spending history store amounts in the currency they were originally submitted, or normalized to a base currency? If normalized, add `base_currency` field to each entry. If original currency, add `currency` field or parallel currency breakdown structure.
- **Confidence**: confirmed

### F5. Department budget amounts

- **Location**: `src/data.py:122–124, 127–129`
- **What it does today**: The `DEPARTMENT_BUDGETS` dict defines budget allocation, spending, and remaining amounts as floats. Used by RiskAgent to check budget pressure.
- **What the change would require**: Add `currency` field per department or at dict level. Requires decision: are department budgets in a single base currency, or does each department have its own currency context?
- **Confidence**: confirmed

### F6. Approval threshold amounts

- **Location**: `src/data.py:135–138`
- **What it does today**: The `APPROVAL_THRESHOLDS` dict defines per-level spending caps (`auto_approve_up_to`, `can_approve_up_to`) as floats. DecisionAgent uses these to check auto-approval eligibility.
- **What the change would require**: Add currency field. Key question: are thresholds the same for all currencies (e.g., auto-approve up to $100 USD or its equivalent), or currency-specific (e.g., $100 USD vs. €90 EUR)? Affects comparison logic.
- **Confidence**: confirmed

### F7. Sample expense amounts

- **Location**: `src/data.py:147, 156, 165, 174`
- **What it does today**: The `SAMPLE_EXPENSES` list contains test data where each expense dict has an `amount` field (450.00, 680.00, 3200.00, 2800.00). This is the mock equivalent of user-submitted expenses.
- **What the change would require**: Add a `currency` field to each expense dict (e.g., `"currency": "USD"`). This is the primary **entry point** where currency would first be captured. Real system would receive this from an API or form submission.
- **Confidence**: confirmed

### F8. Expense amount field in shared state

- **Location**: `src/state.py:41` (field definition), `src/state.py:87` (snapshot method accesses it)
- **What it does today**: `WorkflowState.expense` is a `dict[str, Any]` that holds the input expense, including its `amount` field. The `snapshot()` method extracts `self.expense.get("amount", 0)`.
- **What the change would require**: No change to the state field definition itself (it's already a flexible dict), but the agents and tools that read `state.expense["amount"]` must now also read `state.expense["currency"]` where present. The `snapshot()` method would need to include currency in its output.
- **Confidence**: confirmed

### F9. Policy limits accessed at runtime (tools.py)

- **Location**: `src/tools.py:73–80` (get_policy_rules returns a copy of POLICIES dict)
- **What it does today**: The `get_policy_rules()` tool returns threshold values from the `POLICIES` data. These numeric thresholds are then compared against expense amounts in agents.py.
- **What the change would require**: If currency is added to POLICIES in data.py, the tool automatically passes it through. But agents.py comparison logic (e.g., line 141: `if amount > policy["max_single_expense"]`) assumes both sides are in the same currency. Comparisons would need currency conversion logic or a guarantee that both operands share currency.
- **Confidence**: confirmed

### F10. Spending history queried at runtime (tools.py)

- **Location**: `src/tools.py:103–117` (get_spending_history returns a copy of SPENDING_HISTORY dict)
- **What it does today**: The tool returns aggregate spending data. RiskAgent uses it to fetch historical totals for risk scoring.
- **What the change would require**: If SPENDING_HISTORY is updated to include currency metadata, the tool passes it through. RiskAgent would need to know the currency of spending history to compare it meaningfully against the current expense currency.
- **Confidence**: confirmed

## What I could not determine

- Whether this workflow is intended to support true multi-currency (expenses in different currencies in a single workflow run) or if it is to support a single alternate currency at a time (e.g., "run this in EUR instead of USD"). The required schema differs significantly.
- Whether policy limits and budget allocations are pegged to USD and should be converted to other currencies, or whether each region/department has independent limits in its own currency.
- Whether numeric amounts are always given in cents/smallest units (to avoid floating-point precision issues) or remain as floats. The brief does not address this, but multi-currency support would make the issue more acute.

## Files I read

- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/requirements.txt`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/data.py`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/state.py`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/main.py`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/agents.py`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/tools.py`
