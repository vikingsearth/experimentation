## Summary

Currency information does not exist anywhere in `WorkflowState` today: the two monetary fields (`expense["amount"]` and `applicable_limit`) are bare floats, and the audit trail records money only as pre-formatted strings with a hardcoded `$` sign baked in at each call site. To carry currency through the pipeline without loss, the state object needs new fields to hold the original currency, the original amount, and a converted base-currency amount side by side (never overwriting one with the other), and the audit trail needs entries that carry currency as structured data rather than as text baked into `detail`.

## Findings

### F1. `expense` dict carries the only "original" monetary value, with no currency key

- **Location**: `src/state.py:41` (field definition), populated at `src/main.py:64` (`WorkflowState(expense=expense, ...)`), sample shape at `src/data.py:143-178`
- **What it does today**: `expense: dict[str, Any]` is a free-form dict. Every sample in `SAMPLE_EXPENSES` (`src/data.py:143-178`) has an `"amount"` key (e.g. `"amount": 450.00` at line 147) and no `"currency"` key anywhere. `WorkflowState` itself does not validate or normalize this dict's contents — it stores whatever `main.py` hands it.
- **What the change would require**: The input contract for `expense` would need a `"currency"` key (e.g. ISO 4217 code) alongside `"amount"`, and since `expense` is an untyped `dict[str, Any]`, nothing in `state.py` currently enforces that key's presence — that enforcement would have to be added somewhere (either at construction or by a new validation step), or the multi-currency change silently degrades to "assume USD" for any expense missing the key.
- **Confidence**: confirmed

### F2. `applicable_limit` is a bare float with no currency tag

- **Location**: `src/state.py:50`
- **What it does today**: `applicable_limit: float = 0.0`, set once by the policy agent (`state.applicable_limit = policy["max_single_expense"]`, `src/agents.py:137`) and later read back for a ratio calculation (`src/agents.py:286`). Nothing on `WorkflowState` records what currency this limit is denominated in.
- **What the change would require**: If policy limits stay defined in a single base currency (plausible, since limits are organizational policy) while the expense arrives in another currency, comparisons against `applicable_limit` become meaningless without both values being in the same currency. `WorkflowState` would need either (a) an explicit `applicable_limit_currency` field, or (b) a contract that `applicable_limit` is always base-currency and the expense amount must be converted to base currency before any comparison — but the state object currently has no field to hold that converted amount at all (see F1/F3), so the comparison in `src/agents.py:286` has nowhere to safely pull a same-currency value from.
- **Confidence**: confirmed (field and usage), inferred (the downstream comparison risk — out of scope per the brief, noted only because it constrains what the state object must supply)

### F3. `snapshot()` serializes amount without currency, unsuitable for checkpointing mixed-currency state

- **Location**: `src/state.py:82-94`, specifically line 87 (`"amount": self.expense.get("amount", 0)`)
- **What it does today**: Builds a plain dict for checkpointing/serialization. It pulls `amount` straight out of `expense` with no currency, and does not surface `applicable_limit` at all.
- **What the change would require**: The snapshot would need to include currency alongside every monetary value it emits (at minimum the expense's original currency, and ideally the base-currency equivalent) so that a serialized/checkpointed snapshot remains self-describing. As written, a snapshot of a EUR expense and a snapshot of a USD expense would be structurally indistinguishable.
- **Confidence**: confirmed

### F4. `AuditEntry.detail` and `WorkflowState.log()` only accept a flat string — currency gets baked in as text, or lost

- **Location**: `src/state.py:18-28` (`AuditEntry` dataclass, `timestamp`/`agent`/`action`/`detail` all strings), `src/state.py:72-80` (`log()` method, `detail: str` parameter)
- **What it does today**: `log()` takes a plain string and stores it verbatim. Every call site that mentions money hardcodes a `$` sign directly into an f-string before it ever reaches `log()` — e.g. `src/agents.py:140` (`f"Expense is ${amount:.2f}. Limit is ${policy['max_single_expense']:.2f}."`), `src/agents.py:143-144`, `src/agents.py:154-155`, `src/agents.py:169`, `src/agents.py:190`, `src/agents.py:201`, `src/agents.py:258`, `src/agents.py:264` (`f"total=${history['total_30_days']}"`), `src/agents.py:276-277`, `src/agents.py:289-290`, `src/agents.py:365-366`, `src/agents.py:382`, `src/agents.py:397-398`, `src/agents.py:422`. In every one of these, the currency symbol is a hardcoded literal `$`, not derived from any state field (there is currently no field to derive it from).
- **What the change would require**: `AuditEntry`/`log()` accept only opaque strings, so once a caller formats `f"${amount:.2f}"` the audit trail permanently loses the ability to know what currency that number was in — it becomes unparseable free text. To carry currency through the audit trail without loss, either (a) `AuditEntry` needs structured optional fields for amount + currency alongside `detail` (so a downstream consumer — e.g. brief 5's summary — could reformat correctly), or (b) every call site enumerated above needs to stop hardcoding `$` and instead format using a currency-aware helper fed by state data, or (c) both. This is a change to more than a dozen call sites plus the `AuditEntry`/`log()` signatures, not a localized fix.
- **Confidence**: confirmed

### F5. `clone()` itself needs no structural change, but only if new fields are added as ordinary dataclass fields

- **Location**: `src/state.py:96-98`
- **What it does today**: `copy.deepcopy(self)` — a generic deep copy of the whole dataclass instance, including `audit_trail` and any nested dicts.
- **What the change would require**: Nothing extra, provided any new currency-related fields (original currency, base-currency amount, per-limit currency, etc.) are added as plain dataclass fields with simple types (`str`, `float`) or standard containers — `deepcopy` handles those automatically. This only becomes a risk if a future implementation stored something non-deepcopy-friendly (e.g. a live exchange-rate-fetching client) directly on `WorkflowState`, which nothing in the current code suggests.
- **Confidence**: confirmed (current behavior), inferred (that it remains sufficient — depends on implementation choices not yet made)

## What I could not determine

- Whether `policy["max_single_expense"]` and other policy/budget thresholds referenced via `state.applicable_limit` are meant to be a single global currency or per-category — that dict's definition lives outside `state.py`/`main.py` and is out of scope for this brief (static data, assigned to another investigator).
- Whether any exchange-rate source/service exists or is planned anywhere in this codebase — I found no reference to FX rates, conversion tables, or a currency-conversion utility in `state.py` or `main.py`.

## Files I read

- /Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/state.py
- /Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/main.py
- /Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/data.py (lines 140-179, sample expense shape only)
