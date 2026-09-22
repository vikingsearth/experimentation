## Summary

Multi-currency would require currency-aware conversion at exactly two arithmetic points feeding the risk score — `amount / limit` in `RiskAgent.run` and `spent_this_month / monthly_budget` in `check_budget_remaining` — since both currently divide bare same-typed floats that are only valid when both operands share a currency. By contrast, `calculate_risk_score`'s own `score +=` lines sum dimensionless points (ratios, counts, rates already reduced to a 0–100 scale), so that function is currency-safe in itself provided its inputs were already computed correctly; the real risk is upstream, and I found no code anywhere in `src/` that actually builds the accumulated totals (`spent_this_month`, `total_30_days`) from individual expenses — those are static demo data, so the real "sum expenses across currencies" logic doesn't exist yet and would need to be designed with conversion built in from the start.

## Findings

### F1. `amount / limit` division drives up to 40 of 100 risk-score points

- **Location**: `general-experimentation/agentic-workflows/src/agents.py:285-293` (ratio computed and stored into `factors["amount_ratio"]`), consumed in `general-experimentation/agentic-workflows/src/tools.py:135-136`
- **What it does today**: `amount = state.expense.get("amount", 0)`; `limit = state.applicable_limit if state.applicable_limit > 0 else 1`; `ratio = amount / limit`. This ratio becomes `factors["amount_ratio"]`, which `calculate_risk_score` turns into `min(int(ratio * 30), 40)` points of the final score.
- **What the change would require**: `amount` and `applicable_limit` must be in the same currency before this division runs. Since a policy limit is presumably expressed in one fixed (base) currency while an expense could arrive in EUR/ZAR/etc., one operand needs conversion (via an FX rate resolved at a defined point in time) before line 287. Getting this wrong silently distorts the risk score/level for every non-base-currency expense — it is not merely a display bug, it changes the actual decision path.
- **Confidence**: confirmed

### F2. `spent_this_month / monthly_budget` division drives up to 15 more score points

- **Location**: `general-experimentation/agentic-workflows/src/tools.py:191`, consumed via `factors["budget_utilization"]` at `general-experimentation/agentic-workflows/src/agents.py:280` and scored at `general-experimentation/agentic-workflows/src/tools.py:151-153`
- **What it does today**: `budget["utilization"] = round(budget["spent_this_month"] / budget["monthly_budget"], 2)`. Both values come straight from the static `DEPARTMENT_BUDGETS` dict as bare floats. If `budget_util > 0.8`, `calculate_risk_score` adds `int((budget_util - 0.8) * 75)` points.
- **What the change would require**: `spent_this_month` is itself a running sum of every expense posted against a department this period (see F4) — it is only a valid numerator once every contributing expense has been converted into whatever currency `monthly_budget` is denominated in. The division at line 191 has no way to know or enforce that today; it silently assumes single-currency inputs.
- **Confidence**: confirmed

### F3. `calculate_risk_score`'s point summation is itself currency-safe, but depends entirely on upstream ratios being currency-consistent

- **Location**: `general-experimentation/agentic-workflows/src/tools.py:132-165`
- **What it does today**: Five `score += ...` lines (132, 136, 140, 144, 148, 153) accumulate into a single 0–100 `score`, then threshold it into `low`/`medium`/`high` at 30/60 (line 157). Every input to these five lines is already a dimensionless quantity — a ratio (`amount_ratio`, `budget_utilization`), a count (`violation_count`, `historical_flags`), or a rate (`rejection_rate`) — none is a raw currency amount being summed directly.
- **What the change would require**: Nothing inside this function needs to change to support multi-currency — it never adds two money values together. But it has an implicit, undocumented contract that every ratio handed to it was computed from currency-consistent operands (i.e., F1 and F2 must be fixed at the call site). This function is the wrong place to add currency handling; it's the right place to consider a defensive check/assert if the caller can't be trusted to uphold that contract.
- **Confidence**: confirmed

### F4. `get_spending_history` surfaces pre-accumulated monetary totals with no visible summing code and no currency tag

- **Location**: `general-experimentation/agentic-workflows/src/tools.py:103-117`, consumed at `general-experimentation/agentic-workflows/src/agents.py:256-264`
- **What it does today**: Returns `SPENDING_HISTORY[employee_id].copy()` (or a zeroed fallback), whose `total_30_days`, `largest_single_expense`, and per-category `categories` values are already-summed dollar figures — but the summing itself happens nowhere in code I could find; they are static literals in `data.py`. Of these fields, only `flagged_expenses` (a count) and `rejection_rate_90_days` (a rate) are actually fed into `factors` for scoring (`agents.py:262-263`); `total_30_days`, `largest_single_expense`, and `categories` are not currently used in any score or threshold calculation — `total_30_days` only reaches an `_observation` print and a `state.log` call (`agents.py:258, 264`), and `largest_single_expense`/`categories` are not read at all outside the function's own fallback construction.
- **What the change would require**: If any of these accumulated monetary fields is later wired into scoring (a natural extension), whatever builds `total_30_days`/`largest_single_expense`/`categories` at that point must convert each contributing expense to a common currency before summing — adding raw amounts across currencies is a distinct, separate defect from a same-currency comparison and would silently corrupt the total.
- **Confidence**: confirmed (which fields are/aren't consumed); inferred that a future accumulation step would need currency conversion, since the actual summing logic does not exist in this codebase to inspect directly

### F5. No code path anywhere in `src/` actually accumulates an expense into a running total or budget

- **Location**: N/A — this is an absence, verified via `grep -rn "spent_this_month\|total_30_days\|monthly_budget\|remaining" src/*.py` and `grep -n "SPENDING_HISTORY\|DEPARTMENT_BUDGETS" src/main.py`
- **What it does today**: `SPENDING_HISTORY` and `DEPARTMENT_BUDGETS` are static dictionaries defined once in `data.py`; every consumer (`get_spending_history`, `check_budget_remaining`) only reads and `.copy()`s them, then divides. No line in `agents.py`, `tools.py`, `state.py`, or `main.py` writes a new value back into either structure or adds a submitted expense's `amount` into `spent_this_month`/`total_30_days`.
- **What the change would require**: The actual "accumulate a total" and "consume a budget" write operations that a real (non-demo) system needs don't exist yet in this codebase. When they are built, they are exactly where currency conversion must be designed in from the start (convert each expense to the ledger's base currency, then add) — retrofitting conversion after the fact, once callers already assume bare-float addition, would be considerably harder.
- **Confidence**: confirmed (absence verified by exhaustive grep across all five source files)

## What I could not determine

- Whether any code outside `general-experimentation/agentic-workflows/src/` (e.g., a test file or a script not part of the five-agent pipeline) writes to `SPENDING_HISTORY` or `DEPARTMENT_BUDGETS` — I only searched the `src/` files named in the brief plus `main.py`.
- What currency each department's `monthly_budget` and each employee's `SPENDING_HISTORY` figures are meant to represent today (the brief marks `data.py`'s contents as out of scope for me, so I did not investigate this further than the two `data.py` excerpts needed to confirm F2/F4/F5).

## Files I read

- general-experimentation/agentic-workflows/src/agents.py
- general-experimentation/agentic-workflows/src/tools.py
- general-experimentation/agentic-workflows/src/data.py
- general-experimentation/agentic-workflows/src/state.py
- general-experimentation/agentic-workflows/src/main.py
