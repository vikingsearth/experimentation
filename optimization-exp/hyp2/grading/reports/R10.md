## Summary

Adding multi-currency support would expose six critical comparison points where amounts in different currencies are evaluated against policy limits and thresholds, all of which would break. The PolicyAgent's core checks compare an incoming expense amount directly against policy-defined limits and thresholds, assuming both are in the same currency (USD). Similarly, the approval decision logic in DecisionAgent and the receipt requirement check in tools.py would all fail if the sides of the comparison use different currencies. Team meal limits and alcohol caps, hardcoded as USD values, would also produce incorrect verdicts.

## Findings

### F1. Policy maximum expense limit comparison

- **Location**: `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/agents.py:141`
- **What it does today**: Compares the expense amount directly to the category's `policy["max_single_expense"]`, which is stored as a USD float in the POLICIES dict (e.g., 3000.00 for travel). If the expense amount exceeds this limit, it records a violation.
- **What the change would require**: If the incoming expense is in EUR, a direct numeric comparison to a USD limit is incorrect. The code would need to convert either the expense amount to USD or the policy limit to the expense currency before the comparison. The system must know which currency each value is in, then apply an exchange rate to normalize them to a common currency (likely USD as the base).
- **Confidence**: confirmed

### F2. Pre-approval threshold comparison

- **Location**: `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/agents.py:152`
- **What it does today**: Compares the expense amount to `policy["requires_pre_approval_above"]` (USD value, e.g., 1500.00 for travel). If exceeded, a warning is recorded requiring pre-approval.
- **What the change would require**: Currency-aware comparison. If the expense is in EUR and the threshold is in USD, the numeric comparison is invalid. Same conversion logic as F1: normalize both sides to a common currency before comparing.
- **Confidence**: confirmed

### F3. Team meal per-person limit check

- **Location**: `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/agents.py:189`
- **What it does today**: Extracts the number of attendees from expense notes, divides the total expense amount by attendee count to get `per_person`, then compares it to a hardcoded threshold of 50 (USD). Records a violation if `per_person > 50`.
- **What the change would require**: The hardcoded 50 is USD-specific. If the expense is submitted in EUR, the `per_person` value will be in EUR, but the comparison is to a USD constant. Must convert the hardcoded limit (or the calculated per-person cost) to the expense currency, or convert the expense currency to USD, before comparison.
- **Confidence**: confirmed

### F4. Alcohol reimbursement cap comparison

- **Location**: `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/agents.py:200`
- **What it does today**: Attempts to extract an alcohol amount from the expense notes string and compares it to a hardcoded 30 (USD). Records a violation if `alcohol_amount > 30`.
- **What the change would require**: The hardcoded 30 is USD. If the extracted alcohol amount is in EUR (inferred from the expense currency), the comparison is broken. Must normalize the alcohol amount to match the hardcoded limit's currency, or move the limit into the currency-aware policy data.
- **Confidence**: confirmed

### F5. Auto-approval threshold comparison

- **Location**: `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/agents.py:393`
- **What it does today**: Compares the expense amount to `thresholds["auto_approve_up_to"]`, which comes from APPROVAL_THRESHOLDS (USD values, e.g., 100.00 for Individual Contributor). If amount is within this threshold and no violations exist, the expense is auto-approved.
- **What the change would require**: Currency-aware comparison. Both the incoming expense and the approval threshold are in different potential currencies. Must convert to a common currency before the `<=` comparison. Otherwise, a $50 EUR expense might incorrectly auto-approve against a $100 USD threshold.
- **Confidence**: confirmed

### F6. Receipt-required threshold comparison

- **Location**: `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/tools.py:93`
- **What it does today**: Compares the expense amount to `threshold` (from policy["receipt_required_above"], e.g., 25.00 USD for travel). Sets `required = True` if the amount exceeds the threshold, indicating a receipt is mandatory. If no receipt is attached when required, a violation is recorded back in agents.py line 167-173.
- **What the change would require**: Currency-aware comparison. If expense is in EUR and the threshold is in USD, the comparison `amount > threshold` produces an incorrect boolean. The code that calls this function (PolicyAgent.run at line 164-176) then uses this result to generate violation messages. Must normalize both sides to a common currency before the comparison.
- **Confidence**: confirmed

## What I could not determine

- Whether the system currently has a way to track what currency an expense was submitted in (no currency field in the expense dict in state.py or SAMPLE_EXPENSES in data.py, so it must be added)
- Whether there is a centralized exchange rate system or function available for conversion
- Which currency should serve as the base for all comparisons (inferred to be USD based on all hardcoded policy values, but not stated in code)
- How to handle the extraction and currency interpretation of alcohol_amount from free-text notes at line 199 (the note parsing is fragile and would need a currency marker to disambiguate)

## Files I read

- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/agents.py`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/tools.py`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/data.py`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/state.py`
