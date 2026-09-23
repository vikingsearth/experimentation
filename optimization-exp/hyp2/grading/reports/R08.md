## Summary

Multi-currency support would touch a large surface of ad-hoc `f"${amount:.2f}"`-style formatting scattered across `agents.py`'s output helpers (`_thought`, `_action`, `_observation`, `_result`) and `main.py`'s summary/table printers — there is no single formatting function to patch, so every one of these sites would need a currency-aware formatter (original amount + code, plus a converted base-currency amount) instead of a bare `$`. The README's sample-expense table hardcodes plain-dollar amounts as "expected outcomes," which is the only documented example that asserts a specific amount; there are no automated tests in this codebase, so nothing else would need updating for correctness, only for consistency.

## Findings

### F1. Workflow header print shows bare dollar amount

- **Location**: `general-experimentation/agentic-workflows/src/main.py:69`
- **What it does today**: `print(f"  Expense: {expense.get('id')} -- ${expense.get('amount', 0):.2f}")` — always prefixes the raw float with a literal `$`.
- **What the change would require**: Show the expense's original currency and amount (e.g. `€450.00 EUR`) plus the converted base-currency amount (e.g. `≈ $486.00 USD`), replacing the hardcoded `$` literal with a currency-aware formatter.
- **Confidence**: confirmed

### F2. Batch summary table column is dollar-only

- **Location**: `general-experimentation/agentic-workflows/src/main.py:179-187`
- **What it does today**: Builds a fixed-width table with an `Amount` column formatted as `f"${s.expense.get('amount', 0):.2f}"` (line 183); header/separator at lines 179-180 assume a single short numeric column.
- **What the change would require**: Either two columns (original amount+currency, base-currency amount) or one wider column showing both, and the column width/format string would need reworking since currency-tagged strings (e.g. `450.00 EUR (≈$486 USD)`) are longer than `$450.00`.
- **Confidence**: confirmed

### F3. PolicyAgent's thought/observation/violation strings hardcode `$`

- **Location**: `general-experimentation/agentic-workflows/src/agents.py:133, 140, 142-146, 152-158, 164-171, 183-193, 196-204`
- **What it does today**: Every policy check builds a human-readable message with a literal `$`, e.g. line 133 `f"Found {len(policy['rules'])} rules, max=${policy['max_single_expense']:.0f}"`, line 140 `f"Expense is ${amount:.2f}. Limit is ${policy['max_single_expense']:.2f}."`, and the per-person/alcohol messages at lines 190 and 201. These messages are stored as violation/warning strings and surface later via `state.conditions` and `state.review_concerns`, which `_print_summary` prints at `main.py:114-122`.
- **What the change would require**: Since policy limits are presumably defined in a base currency while the expense may be in another, every one of these messages needs to show the expense's own amount+currency alongside the limit's amount+currency (and/or a converted comparison figure), otherwise a message like "Amount $680.00 exceeds limit of $500.00" is ambiguous or wrong once the expense amount isn't actually in USD.
- **Confidence**: confirmed

### F4. RiskAgent's spending-history and budget observations hardcode `$`

- **Location**: `general-experimentation/agentic-workflows/src/agents.py:257-261, 264, 274-279, 288-291`
- **What it does today**: `_observation(f"Last 30 days: ${history['total_30_days']:.0f} across ...")` (257-261), `state.log(self.name, "get_spending_history", f"total=${history['total_30_days']}")` (264), `_observation(f"Budget: ${budget['remaining']:.0f} remaining of ${budget['monthly_budget']:.0f} ...")` (274-279), and the amount-vs-limit ratio thought at 288-291.
- **What the change would require**: Spending history and department budgets are aggregate/base-currency figures; if the current expense is in a different currency, these lines need to clarify which currency each number is in (e.g. label budget figures as base-currency, and show the current expense's original-currency amount separately) to avoid presenting mismatched currencies as if they were comparable.
- **Confidence**: confirmed

### F5. DecisionAgent's threshold observation and rationale strings hardcode `$`

- **Location**: `general-experimentation/agentic-workflows/src/agents.py:365-367, 382-384, 396-400, 412-417, 421-425`
- **What it does today**: `_observation(f"Auto-approve up to ${thresholds['auto_approve_up_to']:.0f}, can approve up to ${thresholds['can_approve_up_to']:.0f}")` (365-367) and four separate `rationale = (...)` f-strings that each embed `${amount:.2f}` and `${thresholds[...]:.0f}` (382-384, 396-400, 412-417, 421-425). `state.decision_rationale` is what `_print_summary` prints at `main.py:112`.
- **What the change would require**: Approval thresholds are presumably base-currency; the rationale text would need to show both the expense's original-currency amount and its base-currency equivalent next to the threshold, e.g. "Amount €450.00 EUR (≈$486 USD) is within auto-approval threshold ($500 USD)."
- **Confidence**: confirmed

### F6. Audit trail entries print via `AuditEntry.__str__`, which pipes through pre-formatted `$` strings

- **Location**: `general-experimentation/agentic-workflows/src/state.py:26-27` (printed by `general-experimentation/agentic-workflows/src/main.py:135-137`)
- **What it does today**: `AuditEntry.__str__` returns `f"[{self.timestamp}] {self.agent}: {self.action} -- {self.detail}"`; `detail` is often one of the already-`$`-formatted strings produced in `agents.py` (e.g. `f"total=${history['total_30_days']}"` at `agents.py:264`, or the truncated rationale at `agents.py:433`).
- **What the change would require**: `__str__` itself doesn't format money, but since it's the terminal rendering point for every logged detail string, any currency-formatting fix must be made upstream at the `state.log(...)` call sites in `agents.py` (this file's own scope) rather than here — this is the one place that shows all the upstream fixes are necessary, not optional, since this print statement can't distinguish currencies on its own.
- **Confidence**: confirmed

### F7. README sample-expenses table asserts specific bare-dollar amounts

- **Location**: `general-experimentation/agentic-workflows/README.md:31-34`
- **What it does today**: A markdown table lists `$450`, `$680`, `$3,200`, `$2,800` as the amounts for `EXP-001`–`EXP-004` alongside their expected outcome (approved/rejected/escalated).
- **What the change would require**: This is the one documented example that asserts specific amounts. If any sample expense is changed to a non-USD currency (which the feature's own value proposition implies), this table would need an added currency column (or inline currency tags) and the "Expected Outcome" column would need re-verifying, since policy/risk thresholds compared against a converted amount could change the outcome shown.
- **Confidence**: confirmed

### F8. Unrelated `$` figures in research docs are not expense amounts

- **Location**: `general-experimentation/agentic-workflows/docs/research/agentic-patterns.md:10`
- **What it does today**: `"The global agentic AI market is projected to grow from $28B in 2024 to $127B by 2029"` — a market-sizing statistic in prose, unconnected to the expense workflow's data model.
- **What the change would require**: Nothing — this is not an expense amount or a workflow output, so it is unaffected by multi-currency support.
- **Confidence**: confirmed

## What I could not determine

- Whether a "base currency" concept is meant to be a fixed constant (e.g. always USD) or configurable; this affects whether every formatter above needs one converted figure or a user-selectable one. Not stated anywhere in code or docs I read.
- No test suite exists in this codebase (confirmed via `find ... -iname '*test*'` and `grep -rn "assert"` both returning nothing), so there are no executable assertions on amounts to update — only the README table (F7) is a documented example of a specific amount.

## Files I read

- general-experimentation/agentic-workflows/src/main.py
- general-experimentation/agentic-workflows/src/agents.py
- general-experimentation/agentic-workflows/src/state.py
- general-experimentation/agentic-workflows/src/tools.py (grep only, for `$`/format patterns)
- general-experimentation/agentic-workflows/README.md
- general-experimentation/agentic-workflows/docs/planning/plan.md
- general-experimentation/agentic-workflows/docs/research/agentic-patterns.md (grep only)
