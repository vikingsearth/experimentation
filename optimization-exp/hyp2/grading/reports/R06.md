This confirms tools.py only re-exposes data from `data.py` (no additional static monetary constants of its own) — it's a pass-through layer, which is out of scope per the brief (what agents do with amounts). No other file defines monetary data or accepts monetary input; `main.py`'s `--expense` CLI flag only selects an index into `SAMPLE_EXPENSES`, it does not accept an amount.

I now have everything needed to write the report.

## Summary

Every monetary value in this codebase enters as a bare `float` field inside dictionaries defined in `src/data.py` — there is no separate input pathway (no CLI amount flag, no user prompt, no file/API ingestion); `main.py --expense N` only selects an index into the existing `SAMPLE_EXPENSES` list. Adding multi-currency support means every one of these dict literals (employee budgets, policy limits, spending history, department budgets, approval thresholds, and sample expenses) would need to become a structured `{amount, currency}` pair (or a small `Money` dataclass) instead of a lone float, and the currency for policy/budget/threshold data would additionally need a documented assumption (i.e., that all "static" company data is in one designated base currency, e.g. USD) since those values represent a single company standard, not a submitted, foreign-currency transaction.

## Findings

### F1. Employee monthly budgets

- **Location**: `general-experimentation/agentic-workflows/src/data.py:15,23,31` (inside the `EMPLOYEES` dict, key `monthly_budget`)
- **What it does today**: Each employee record has a bare `monthly_budget: float` (e.g. `5000.00`) with no currency marker.
- **What the change would require**: `monthly_budget` would need to become a currency-aware value, e.g. `{"value": 5000.00, "currency": "USD"}` or a `Money(amount, currency)` type. Since this is a company-defined budget rather than a user submission, the currency is implicitly the company's base/reporting currency — that assumption would need to be made explicit rather than left implicit as it is today.
- **Confidence**: confirmed

### F2. Policy limits per category

- **Location**: `general-experimentation/agentic-workflows/src/data.py:38-40,50-52,61-63,71-73,81-83` (inside `POLICIES`, keys `max_single_expense`, `requires_pre_approval_above`, `receipt_required_above` for each of `travel`, `meals`, `equipment`, `software`, `other`)
- **What it does today**: Each category has three bare-float thresholds with no currency.
- **What the change would require**: All three fields, across all five categories (15 values total), would need the same currency-aware shape as F1. Because these are policy ceilings compared against a submitted expense, the design would also need to settle whether policy limits are defined once in a base currency (requiring conversion before comparison) or per-currency (requiring a limit set per currency) — that decision affects the shape but is a policy-checking concern, not this brief's scope.
- **Confidence**: confirmed

### F3. Policy free-text rules embedding dollar amounts

- **Location**: `general-experimentation/agentic-workflows/src/data.py:44,46,55,56,67` (inside `POLICIES[*]["rules"]`, plain strings such as `"Hotel rates must not exceed $250/night for domestic, $350/night for international"`, `"Per diem meals: $75/day domestic, $100/day international"`, `"Team meals limited to $50 per person"`, `"Alcohol reimbursement capped at $30 per meal"`, `"Equipment over $1000 must be tagged as company asset"`)
- **What it does today**: These are free-text human-readable rule strings with dollar amounts hardcoded inline as text (`$250`, `$350`, `$75`, `$100`, `$50`, `$30`, `$1000`) — they are not structured data at all, just prose.
- **What the change would require**: As plain strings these amounts are not programmatically evaluated (nothing in this dict parses them back out — that would be a policy-agent concern, out of scope here), but if the workflow is to enforce them correctly for non-USD expenses, they would need to move out of free text into structured fields (each becoming its own `{value, currency}` entry, analogous to F2) rather than being interpolated into a description string with a hardcoded `$` sign.
- **Confidence**: inferred (confirmed that the strings exist and contain hardcoded `$`; the "not evaluated programmatically" claim is inferred from `data.py` alone, since checking how `rules` is consumed is out of this brief's scope)

### F4. Spending history totals

- **Location**: `general-experimentation/agentic-workflows/src/data.py:94-97,102-105,110-113` (inside `SPENDING_HISTORY`, keys `total_30_days`, `largest_single_expense`, and the nested `categories` dict, for `EMP-042`, `EMP-010`, `EMP-077`)
- **What it does today**: Bare floats recording historical spend, both as a per-employee total/largest-single-expense and broken down per category, with no currency.
- **What the change would require**: Every one of these values would need to become currency-aware. Because this is aggregated history (sums across potentially many original transactions), it raises an added structural question this brief flags but does not resolve: if underlying expenses were submitted in different currencies, this aggregate must clearly be a base-currency rollup, not a single original currency — i.e., this data point can never carry a single "original" currency the way a fresh expense submission can.
- **Confidence**: confirmed

### F5. Department budgets

- **Location**: `general-experimentation/agentic-workflows/src/data.py:122-124,127-129` (inside `DEPARTMENT_BUDGETS`, keys `monthly_budget`, `spent_this_month`, `remaining`, for `Engineering` and `Sales`)
- **What it does today**: Three bare floats per department, no currency.
- **What the change would require**: Same currency-aware shape as F1/F4. Same base-currency-rollup consideration as F4 applies to `spent_this_month` and `remaining` since department spend aggregates expenses from potentially multiple employees/currencies.
- **Confidence**: confirmed

### F6. Approval thresholds by employee level

- **Location**: `general-experimentation/agentic-workflows/src/data.py:135-138` (inside `APPROVAL_THRESHOLDS`, keys `auto_approve_up_to`, `can_approve_up_to`, for `Individual Contributor`, `Manager`, `Director`, `VP`)
- **What it does today**: Bare floats, no currency, keyed by seniority level rather than by person or department.
- **What the change would require**: Same currency-aware shape as the above. As a company-wide policy constant (not a transaction), this is unambiguously base-currency data — the least ambiguous of the six static tables in that respect.
- **Confidence**: confirmed

### F7. Sample expense submissions — the actual entry point for transaction amounts

- **Location**: `general-experimentation/agentic-workflows/src/data.py:147,156,165,174` (inside `SAMPLE_EXPENSES`, key `amount`, for `EXP-001` through `EXP-004`)
- **What it does today**: Each sample expense dict has a single bare `amount: float` field (e.g. `450.00`, `680.00`, `3200.00`, `2800.00`) representing what a real user would submit. This is the one place in the whole codebase that models a genuine incoming transaction (as opposed to static company policy/reference data).
- **What the change would require**: This is the field that most directly needs a `currency` sibling key, e.g. `{"amount": 450.00, "currency": "USD"}`, since this is the only place representing an actual submitted expense in the mock data — everywhere a real system would accept a new expense, this shape (amount + currency) is what would need to be captured at submission time. Note: `EXP-002`'s `notes` field also embeds a dollar sub-amount as free text (`"Includes $120 in alcohol"`, line 159) — same free-text caveat as F3.
- **Confidence**: confirmed

### F8. No external input pathway beyond static sample data

- **Location**: `general-experimentation/agentic-workflows/src/main.py:150-155` (the `--expense` argparse argument) and `:160-167` (its use)
- **What it does today**: The only CLI argument is `--expense <int>`, which selects an index into `SAMPLE_EXPENSES` (from F7) — it does not accept a new amount, currency, or any other expense field. There is no user-input prompt, file upload, or API endpoint anywhere in the codebase that constructs a new expense at runtime.
- **What the change would require**: If multi-currency submission is to be usable beyond the four hardcoded samples, a real input path (CLI flags for amount+currency, a config/JSON loader, etc.) would need to be added — none currently exists. This is a gap in the current system, not something that needs "converting" for currency support; it needs building from scratch.
- **Confidence**: confirmed

### F9. Dependency availability for currency handling

- **Location**: `general-experimentation/agentic-workflows/requirements.txt:1-9`
- **What it does today**: The file states the project has zero external dependencies ("This project uses only Python standard library -- no external dependencies") and Python 3.9+ is required. It lists `langgraph`, `langchain`, `anthropic`, and `openai` only as *suggestions* for a future LLM-powered extension — none are currently installed or imported.
- **What the change would require**: Standard library alone (as of 3.9+) has no built-in currency/money type or exchange-rate mechanism. A currency implementation would either need to be hand-rolled (e.g. a small `Money` dataclass plus a hardcoded/mock static exchange-rate table, mirroring the style of `data.py`) to stay dependency-free and in keeping with the project's stated convention, or the project would need to add a new dependency (e.g. `babel`, `py-moneyed`, `forex-python`) — which the brief instructions require calling out explicitly as a significant change, since it breaks the "standard library only" constraint stated in this same file.
- **Confidence**: confirmed

## What I could not determine

- Whether any exchange-rate source (live or static) is expected/desired is not addressed anywhere in the codebase — there is no existing precedent for how a conversion rate would be sourced or stored.
- none (beyond the above)

## Files I read

- general-experimentation/agentic-workflows/src/data.py
- general-experimentation/agentic-workflows/requirements.txt
- general-experimentation/agentic-workflows/src/main.py
- general-experimentation/agentic-workflows/src/tools.py
