## Summary

The shared state object (`WorkflowState`) and audit trail (`AuditEntry`) would need significant changes to carry currency through the pipeline. Today, the state holds monetary amounts as bare `float` values in multiple places: the expense amount, policy limits, and the applicable limit field. Without currency attached at the state level, every agent downstream loses the currency information and cannot correctly compare or convert amounts. The audit trail's detail strings would also need to record currency when logging monetary decisions.

## Findings

### F1. Expense amount in state lacks currency field

- **Location**: `src/state.py:41`
- **What it does today**: `WorkflowState.expense` is a `dict[str, Any]` that flows from `main.py` line 64 through the workflow. The expense dict originates from `data.py` (e.g., line 147: `"amount": 450.00`) with no currency field.
- **What the change would require**: Add a `currency` field to every expense dict in `SAMPLE_EXPENSES`, and ensure it flows alongside the `amount`. The state must preserve this currency when receiving the expense dict.
- **Confidence**: confirmed

### F2. Policy limit field in state has no currency annotation

- **Location**: `src/state.py:50`
- **What it does today**: `applicable_limit: float = 0.0` stores only a number. It is populated by `PolicyAgent.run()` at `agents.py:137` from `policy["max_single_expense"]`, which comes from `data.py` lines 38, 50, 61, 71, 81 (all USD values with no currency annotation).
- **What the change would require**: Convert `applicable_limit` to carry currency information (e.g., a tuple `(amount: float, currency: str)` or a `Money` dataclass). The state must also track what currency the policy limits are defined in — today it is implicit USD. If comparing a EUR expense against a USD policy limit, conversion is needed here.
- **Confidence**: confirmed

### F3. Snapshot method extracts amount without currency

- **Location**: `src/state.py:82-94`
- **What it does today**: The `snapshot()` method returns a dict with `"amount": self.expense.get("amount", 0)` (line 87) — a bare float. This is used for reporting and is the serializable state view.
- **What the change would require**: The snapshot must also include the expense currency (e.g., add `"currency": self.expense.get("currency", "USD")`). If the state has converted amounts to a base currency for comparison, the snapshot should capture both original and converted amounts.
- **Confidence**: confirmed

### F4. Clone method does not explicitly preserve nested dict currencies

- **Location**: `src/state.py:96-98`
- **What it does today**: The `clone()` method uses `copy.deepcopy(self)`, which will preserve currency fields if they exist in the expense dict. However, if currency is added as a new top-level field on `WorkflowState`, the deepcopy will preserve it correctly.
- **What the change would require**: No explicit change needed to `clone()` itself, but the design must ensure all fields that hold monetary values (including nested dicts like `expense`) include a currency reference before cloning. Testing of clone with multi-currency expenses is essential.
- **Confidence**: confirmed

### F5. Log method detail string has no structured currency field

- **Location**: `src/state.py:72-80`
- **What it does today**: The `log()` method appends an `AuditEntry` to `audit_trail`. The `AuditEntry` class (lines 18-27) has a `detail: str` field. Agents log monetary decisions via strings like `agents.py:264` (`f"total=${history['total_30_days']}"`) and `agents.py:281` (`f"utilization={budget['utilization']}"`), but currency is not recorded separately.
- **What the change would require**: Consider adding a `currency: str = "USD"` field to `AuditEntry` so every audit entry can record the currency context of the decision. Alternatively, include the currency in every detail string that mentions a monetary value (e.g., `"amount=450.00 EUR"` instead of `"amount=450.00"`).
- **Confidence**: inferred

### F6. PolicyAgent compares amounts without currency conversion

- **Location**: `src/agents.py:136-149`
- **What it does today**: Extracts `amount` as a bare float (line 136), then compares directly: `if amount > policy["max_single_expense"]` (line 141). Both operands are floats with no currency information.
- **What the change would require**: Before comparison, convert the expense amount to the policy's base currency. The agent must call a currency conversion service (or tool) if `expense.get("currency")` differs from the policy's currency (today implicitly USD). Store the converted amount and original currency for the audit trail.
- **Confidence**: confirmed

### F7. PolicyAgent calculates per-person and alcohol limits without currency awareness

- **Location**: `src/agents.py:188-206`
- **What it does today**: Divides the total amount by attendees (line 188) to compute per-person cost, then compares to a hardcoded `$50` limit (line 190). Parses alcohol amounts from notes and compares to a `$30` cap (lines 199-201). All comparisons are numeric with no currency handling.
- **What the change would require**: Convert or validate that per-person and alcohol thresholds are in the same currency as the expense. If the expense is in EUR, the `$50` and `$30` limits must be converted to EUR before comparison (or stored as multi-currency policy limits).
- **Confidence**: confirmed

### F8. RiskAgent calculates amount ratio without currency normalization

- **Location**: `src/agents.py:285-293`
- **What it does today**: Calculates `ratio = amount / limit` (line 287) where `amount` is from the expense and `limit` is from `state.applicable_limit`. If these are in different currencies, the ratio is meaningless (e.g., `450 EUR / 3000 USD` is not a valid policy comparison).
- **What the change would require**: Ensure both `amount` and `limit` are in the same currency before calculating the ratio. This likely requires conversion of one operand. The state must guarantee that `applicable_limit` is either stored with its currency or pre-converted to the expense's currency.
- **Confidence**: confirmed

### F9. DecisionAgent compares amount against thresholds without currency handling

- **Location**: `src/agents.py:349, 393-399`
- **What it does today**: Extracts `amount` (line 349) and compares it against `thresholds["auto_approve_up_to"]` and `thresholds["can_approve_up_to"]` (line 393), which come from `data.py:135-138` (hardcoded USD values).
- **What the change would require**: Convert the expense amount to USD (or the threshold currency) before comparison. The agent must know what currency the thresholds are in and convert the expense amount if needed.
- **Confidence**: confirmed

### F10. Tools return monetary values without currency context

- **Location**: `src/tools.py:88, 103-117, 178-192`
- **What it does today**: Functions like `check_receipt_attached()` (line 88), `get_spending_history()` (lines 103-117), and `check_budget_remaining()` (lines 178-192) return dicts with bare float values (e.g., `"total_30_days": 0.0`). No currency information is included in the return dict.
- **What the change would require**: Each tool must return a currency field alongside monetary values, or the state must infer/enforce a consistent currency when receiving tool results. For example, `check_budget_remaining()` should return `{"monthly_budget": 50000.0, "currency": "USD", ...}`.
- **Confidence**: confirmed

### F11. Snapshot method does not capture converted/base currency amount

- **Location**: `src/state.py:82-94`
- **What it does today**: Returns only the original amount from the expense dict (line 87).
- **What the change would require**: If the system stores both original currency and converted base currency in the state, the snapshot must include both (e.g., `"amount": 450.0, "amount_usd": 450.0, "currency": "EUR"`). This ensures the audit trail and summary reports show both representations.
- **Confidence**: inferred

### F12. Batch summary display assumes all amounts are in the same currency

- **Location**: `src/main.py:179-187`
- **What it does today**: Prints a summary table with all amounts formatted as `${s.expense.get('amount', 0):.2f}` (line 183), assuming all are in USD.
- **What the change would require**: Display the currency alongside each amount (e.g., `EUR 450.00` or `$450.00` with a header indicating mixed currencies). The snapshot must provide the currency information for this to work.
- **Confidence**: confirmed

## What I could not determine

- Whether the system is expected to support a single base currency (e.g., always convert to USD for storage and comparison) or maintain multiple currencies throughout
- Whether currency conversion rates are expected to be provided as a tool or passed in as static data
- Whether historical spending amounts in `SPENDING_HISTORY` (data.py lines 92-117) and approval thresholds (data.py lines 134-139) are all USD or could be currency-specific per employee/department

## Files I read

- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/state.py`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/main.py`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/data.py`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/agents.py`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/tools.py`
