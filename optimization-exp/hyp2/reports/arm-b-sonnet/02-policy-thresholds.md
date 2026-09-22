Not monetary comparisons — index bounds and result count. Nothing further relevant in main.py.

I now have a complete picture of every amount-vs-limit comparison in my assigned area. Compiling the report.

## Summary

Multi-currency support would require every comparison in `PolicyAgent` (and the two hardcoded category-specific caps it applies) to convert the expense amount into the same currency as the policy limit before comparing — today all six comparisons found assume both sides are implicitly USD `float`. The receipt threshold check inside `check_receipt_attached` (tools.py) has the identical problem, and it is silent: nothing in the function signature or return value indicates a currency, so a naive multi-currency retrofit that only tags `state.expense["amount"]` with a currency would still compare a tagged amount against an untagged USD limit unless every call site is updated.

## Findings

### F1. Category max-expense limit check

- **Location**: `general-experimentation/agentic-workflows/src/agents.py:141`
- **What it does today**: `if amount > policy["max_single_expense"]:` — compares the raw expense amount (from `state.expense.get("amount", 0)`) directly against `policy["max_single_expense"]`, a bare USD float returned by `get_policy_rules(state.category)`.
- **What the change would require**: The expense amount must be converted to the policy's currency (or vice versa) before this comparison, using an exchange rate resolved for a defined point in time (e.g. submission date). Without conversion, a 3000 ZAR expense would be compared against a 3000 USD limit and pass when it should not.
- **Confidence**: confirmed

### F2. Pre-approval threshold check

- **Location**: `general-experimentation/agentic-workflows/src/agents.py:152`
- **What it does today**: `if amount > policy["requires_pre_approval_above"]:` — same pattern as F1, against `policy["requires_pre_approval_above"]`.
- **What the change would require**: Same currency-normalization requirement as F1 — convert to a common currency before comparing.
- **Confidence**: confirmed

### F3. Receipt-required threshold check (inside the tool itself)

- **Location**: `general-experimentation/agentic-workflows/src/tools.py:93`
- **What it does today**: `required = amount > threshold` inside `check_receipt_attached`, where `threshold = policy["receipt_required_above"]` and `amount = expense.get("amount", 0)`. Note this comparison happens inside the tool function, not in `PolicyAgent` — `PolicyAgent.run` (agents.py:164-176) only inspects the returned `compliant` boolean, it never re-checks the amount itself.
- **What the change would require**: `check_receipt_attached` would need currency context passed in (not just a bare `amount`), and would need to convert to the policy's currency before computing `required`. Because the conversion has to happen inside the tool function rather than in `PolicyAgent`, this is a second, separate call site that would need fixing even if `PolicyAgent`'s own two comparisons (F1, F2) were fixed.
- **Confidence**: confirmed

### F4. Per-person team-meal limit ($50, hardcoded)

- **Location**: `general-experimentation/agentic-workflows/src/agents.py:189`
- **What it does today**: `per_person = amount / attendees; if per_person > 50:` — `amount` is the expense's raw amount, and `50` is a hardcoded literal (not sourced from `get_policy_rules` or any policy data structure), implicitly USD.
- **What the change would require**: The `50` constant would need to become currency-aware (either converted per-comparison, or itself expressed as an amount+currency pair with its own conversion step). Since it's a bare literal in code rather than data, this is also a design decision, not just a data fix: is $50 meant to be a fixed policy figure requiring separate localization, or a value derived from an already-established base-currency limit?
- **Confidence**: confirmed

### F5. Per-meal alcohol cap ($30, hardcoded, parsed from free text)

- **Location**: `general-experimentation/agentic-workflows/src/agents.py:196-204` (comparison at line 200: `if alcohol_amount > 30:`)
- **What it does today**: Parses `state.expense["notes"]` by splitting on the literal `"$"` character to extract a dollar figure, then compares it against a hardcoded `30`.
- **What the change would require**: Two distinct problems. First, the same conversion problem as F4 (hardcoded USD literal vs. a potentially non-USD amount). Second, and more fragile: the extraction logic itself assumes the currency symbol in free-text notes is always `$` (`notes.split("$")`) — a note written as "alcohol €25" or "alcohol R450" would not be parsed at all, silently skipping the check rather than failing loudly. Multi-currency support would need either a structured (non-free-text) field for this sub-amount, or currency-symbol-aware parsing plus conversion.
- **Confidence**: confirmed

### F6. Auto-approval threshold check (uses `get_approval_thresholds`)

- **Location**: `general-experimentation/agentic-workflows/src/agents.py:393` (in `DecisionAgent.run`, not `PolicyAgent`, but it is the only place the output of `get_approval_thresholds` — one of my assigned tool functions — is actually compared rather than just printed)
- **What it does today**: `elif amount <= thresholds["auto_approve_up_to"] and not violations:` — compares the raw expense amount against `thresholds["auto_approve_up_to"]`, a bare USD float returned by `get_approval_thresholds(level)`.
- **What the change would require**: Same conversion requirement as F1/F2. Also worth noting: `thresholds["can_approve_up_to"]` (also returned by `get_approval_thresholds`, see `src/data.py:135-138`) is never compared against anything anywhere in the codebase — it is only interpolated into an observation string at agents.py:366 — so it carries no correctness risk today, but would need the same treatment if it is ever wired into a real comparison later.
- **Confidence**: confirmed

## What I could not determine

- Whether the intended design for multi-currency conversion is "convert amount to limit's currency" or "convert both to a shared base currency" is a design decision outside this codebase — nothing in `agents.py` or `tools.py` hints at an intended target architecture, since no currency concept exists yet anywhere in the code I read.
- Whether `get_policy_rules` and `get_approval_thresholds` return per-category/per-level limits that are meant to represent the same currency across all categories/levels, or could plausibly need different currencies per category — I only inspected the shape of `POLICIES`/`APPROVAL_THRESHOLDS` in `src/data.py` enough to confirm all values are bare floats (that structural detail is brief 1's territory, so I did not go further).

## Files I read

- general-experimentation/agentic-workflows/src/agents.py
- general-experimentation/agentic-workflows/src/tools.py
- general-experimentation/agentic-workflows/src/data.py (partial: POLICIES and APPROVAL_THRESHOLDS structure only)
- general-experimentation/agentic-workflows/src/main.py (partial: grepped for amount/currency/comparison usage only)
