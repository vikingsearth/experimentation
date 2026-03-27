"""
Mock tools that agents use to interact with business systems.

In a real system, these would call databases, APIs, and external services.
Here they return realistic mock data to demonstrate the tool-use pattern.

Each tool follows the same contract:
  - Takes typed parameters
  - Returns a dict with the result
  - Raises ValueError for invalid inputs
"""

from __future__ import annotations

from typing import Any

from data import (
    APPROVAL_THRESHOLDS,
    DEPARTMENT_BUDGETS,
    EMPLOYEES,
    POLICIES,
    SPENDING_HISTORY,
)

# ---------------------------------------------------------------------------
# Category keywords for expense classification
# ---------------------------------------------------------------------------
CATEGORY_KEYWORDS = {
    "travel": ["flight", "hotel", "airfare", "train", "car rental", "uber", "lyft", "taxi", "trip"],
    "meals": ["dinner", "lunch", "breakfast", "restaurant", "coffee", "catering", "food", "meal"],
    "equipment": ["laptop", "monitor", "keyboard", "mouse", "macbook", "desk", "chair", "headset"],
    "software": ["license", "subscription", "saas", "software", "tool", "app", "cloud service"],
}


def categorize_expense(description: str) -> dict[str, Any]:
    """
    Classify an expense into a category based on its description.
    Tool: categorize_expense
    """
    description_lower = description.lower()
    scores: dict[str, int] = {}

    for category, keywords in CATEGORY_KEYWORDS.items():
        score = sum(1 for kw in keywords if kw in description_lower)
        if score > 0:
            scores[category] = score

    if scores:
        best = max(scores, key=scores.get)  # type: ignore[arg-type]
        confidence = min(scores[best] / 3.0, 1.0)  # normalize to 0-1
    else:
        best = "other"
        confidence = 0.3

    return {
        "category": best,
        "confidence": round(confidence, 2),
        "all_scores": scores,
    }


def lookup_employee(employee_id: str) -> dict[str, Any]:
    """
    Look up an employee's details from the HR system.
    Tool: lookup_employee
    """
    if employee_id not in EMPLOYEES:
        raise ValueError(f"Employee {employee_id} not found")
    return EMPLOYEES[employee_id].copy()


def get_policy_rules(category: str) -> dict[str, Any]:
    """
    Retrieve the expense policy rules for a given category.
    Tool: get_policy_rules
    """
    if category not in POLICIES:
        return POLICIES["other"].copy()
    return POLICIES[category].copy()


def check_receipt_attached(expense: dict[str, Any]) -> dict[str, Any]:
    """
    Verify whether a receipt is attached and whether one is required.
    Tool: check_receipt_attached
    """
    amount = expense.get("amount", 0)
    category = expense.get("category", "other")
    policy = POLICIES.get(category, POLICIES["other"])
    threshold = policy["receipt_required_above"]
    attached = expense.get("receipt_attached", False)
    required = amount > threshold

    return {
        "receipt_attached": attached,
        "receipt_required": required,
        "threshold": threshold,
        "compliant": not required or attached,
    }


def get_spending_history(employee_id: str) -> dict[str, Any]:
    """
    Retrieve an employee's recent spending history.
    Tool: get_spending_history
    """
    if employee_id not in SPENDING_HISTORY:
        return {
            "total_30_days": 0.0,
            "expense_count_30_days": 0,
            "largest_single_expense": 0.0,
            "categories": {},
            "flagged_expenses": 0,
            "rejection_rate_90_days": 0.0,
        }
    return SPENDING_HISTORY[employee_id].copy()


def calculate_risk_score(factors: dict[str, Any]) -> dict[str, Any]:
    """
    Calculate a risk score (0-100) based on multiple factors.
    Tool: calculate_risk_score

    Factors considered:
    - amount_ratio: expense amount / policy limit (0-1+)
    - violation_count: number of policy violations
    - historical_flags: past flagged expenses
    - rejection_rate: historical rejection rate
    - budget_utilization: department budget usage ratio
    """
    score = 0

    # Amount relative to limit (0-30 points)
    ratio = factors.get("amount_ratio", 0)
    score += min(int(ratio * 30), 40)

    # Policy violations (0-30 points, 15 each)
    violations = factors.get("violation_count", 0)
    score += min(violations * 15, 30)

    # Historical flags (0-15 points)
    flags = factors.get("historical_flags", 0)
    score += min(flags * 10, 15)

    # Rejection rate (0-10 points)
    rej_rate = factors.get("rejection_rate", 0)
    score += int(rej_rate * 100)

    # Budget pressure (0-15 points)
    budget_util = factors.get("budget_utilization", 0)
    if budget_util > 0.8:
        score += int((budget_util - 0.8) * 75)

    return {
        "score": min(score, 100),
        "level": "low" if score < 30 else "medium" if score < 60 else "high",
        "breakdown": {
            "amount_factor": min(int(ratio * 30), 40),
            "violation_factor": min(violations * 15, 30),
            "history_factor": min(flags * 10, 15),
            "rejection_factor": int(rej_rate * 100),
            "budget_factor": int(max(0, (budget_util - 0.8) * 75)),
        },
    }


def get_approval_thresholds(employee_level: str) -> dict[str, Any]:
    """
    Get the approval thresholds for a given employee level.
    Tool: get_approval_thresholds
    """
    if employee_level not in APPROVAL_THRESHOLDS:
        return APPROVAL_THRESHOLDS["Individual Contributor"].copy()
    return APPROVAL_THRESHOLDS[employee_level].copy()


def check_budget_remaining(department: str) -> dict[str, Any]:
    """
    Check how much budget remains for a department this month.
    Tool: check_budget_remaining
    """
    if department not in DEPARTMENT_BUDGETS:
        return {
            "monthly_budget": 0,
            "spent_this_month": 0,
            "remaining": 0,
            "utilization": 0,
        }
    budget = DEPARTMENT_BUDGETS[department].copy()
    budget["utilization"] = round(budget["spent_this_month"] / budget["monthly_budget"], 2)
    return budget
