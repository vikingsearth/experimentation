## Summary

The current expense approval workflow uses bare `float` values for monetary amounts, which are implicitly assumed to be in US dollars. To add multi-currency support, we'll need to modify how amounts are handled in several key areas where scores are derived, totals are accumulated, or budgets are consumed. The main changes will involve tracking currency information alongside amounts and ensuring proper currency conversion when performing arithmetic operations or comparisons.

## Findings

### F1. Risk score calculation with mixed currencies

- **Location**: `src/tools.py:120-165`
- **What it does today**: The `calculate_risk_score` function computes a risk score based on various factors, including the amount ratio (expense amount divided by policy limit). It assumes all amounts are in the same currency (USD).
- **What the change would require**: Modify the function to handle currency conversion when calculating ratios and scores. This would involve:
  - Tracking currency information for each factor
  - Converting amounts to a common base currency (USD) before performing calculations
  - Ensuring that the score calculation accounts for currency differences
- **Confidence**: confirmed

### F2. Spending history with mixed currencies

- **Location**: `src/tools.py:103-117`
- **What it does today**: The `get_spending_history` function returns historical spending data for an employee, with all amounts in USD.
- **What the change would require**: Update the function to track spending history by currency. This would involve:
  - Modifying the data structure to store amounts by currency
  - Implementing currency conversion when aggregating totals across different currencies
  - Ensuring that historical comparisons (e.g., largest single expense) are currency-aware
- **Confidence**: confirmed

### F3. Budget checking with mixed currencies

- **Location**: `src/tools.py:178-192`
- **What it does today**: The `check_budget_remaining` function returns budget information for a department, with all amounts in USD.
- **What the change would require**: Modify the function to handle department budgets in multiple currencies. This would involve:
  - Tracking budget allocations by currency
  - Implementing currency conversion when calculating remaining budget
  - Ensuring that budget utilization percentages are calculated correctly for mixed currencies
- **Confidence**: confirmed

### F4. Amount ratio calculation in RiskAgent

- **Location**: `src/agents.py:285-287`
- **What it does today**: The RiskAgent calculates the amount ratio by dividing the expense amount by the policy limit, assuming both are in USD.
- **What the change would require**: Update the calculation to handle currency conversion if the expense amount and policy limit are in different currencies. This would involve:
  - Retrieving currency information for both the expense and the policy limit
  - Converting one of the amounts to match the other's currency before performing the division
- **Confidence**: confirmed

### F5. Budget utilization observation in RiskAgent

- **Location**: `src/agents.py:276-279`
- **What it does today**: The RiskAgent observes budget utilization as a percentage, assuming all amounts are in USD.
- **What the change would require**: Modify the observation to account for currency differences. This would involve:
  - Ensuring that the budget remaining and monthly budget are in the same currency
  - Converting amounts if necessary before calculating the utilization percentage
- **Confidence**: confirmed

## What I could not determine

- None

## Files I read

- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/agents.py`
- `/Users/wikus.bergh/dev/experimentation/general-experimentation/agentic-workflows/src/tools.py`
