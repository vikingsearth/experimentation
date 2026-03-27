"""
Mock data for the expense approval workflow.

In a real system, this data would come from databases, HR systems, and policy documents.
"""

# Employee directory
EMPLOYEES = {
    "EMP-042": {
        "id": "EMP-042",
        "name": "Jane Smith",
        "department": "Engineering",
        "level": "Manager",
        "manager": "EMP-010",
        "monthly_budget": 5000.00,
    },
    "EMP-010": {
        "id": "EMP-010",
        "name": "Robert Chen",
        "department": "Engineering",
        "level": "Director",
        "manager": "EMP-001",
        "monthly_budget": 15000.00,
    },
    "EMP-077": {
        "id": "EMP-077",
        "name": "Alex Johnson",
        "department": "Sales",
        "level": "Individual Contributor",
        "manager": "EMP-055",
        "monthly_budget": 2000.00,
    },
}

# Company expense policies by category
POLICIES = {
    "travel": {
        "max_single_expense": 3000.00,
        "requires_pre_approval_above": 1500.00,
        "receipt_required_above": 25.00,
        "allowed_classes": ["economy", "premium_economy"],
        "rules": [
            "Flights must be booked at least 7 days in advance for domestic travel",
            "Hotel rates must not exceed $250/night for domestic, $350/night for international",
            "Car rentals require manager approval for trips under 3 days",
            "Per diem meals: $75/day domestic, $100/day international",
        ],
    },
    "meals": {
        "max_single_expense": 200.00,
        "requires_pre_approval_above": 150.00,
        "receipt_required_above": 15.00,
        "rules": [
            "Client meals require client name and business purpose",
            "Team meals limited to $50 per person",
            "Alcohol reimbursement capped at $30 per meal",
            "No reimbursement for meals during non-business hours without justification",
        ],
    },
    "equipment": {
        "max_single_expense": 2000.00,
        "requires_pre_approval_above": 500.00,
        "receipt_required_above": 0.00,
        "rules": [
            "Equipment must be from approved vendor list",
            "Personal equipment requires IT approval",
            "Equipment over $1000 must be tagged as company asset",
        ],
    },
    "software": {
        "max_single_expense": 1000.00,
        "requires_pre_approval_above": 200.00,
        "receipt_required_above": 0.00,
        "rules": [
            "Software must be on the approved list or get security review",
            "Annual subscriptions require manager approval",
            "No duplicate licenses -- check existing team subscriptions first",
        ],
    },
    "other": {
        "max_single_expense": 500.00,
        "requires_pre_approval_above": 100.00,
        "receipt_required_above": 10.00,
        "rules": [
            "Must include detailed business justification",
            "Requires manager approval regardless of amount",
        ],
    },
}

# Spending history (mock -- last 30 days)
SPENDING_HISTORY = {
    "EMP-042": {
        "total_30_days": 2800.00,
        "expense_count_30_days": 7,
        "largest_single_expense": 1200.00,
        "categories": {"travel": 1800.00, "meals": 600.00, "software": 400.00},
        "flagged_expenses": 0,
        "rejection_rate_90_days": 0.05,
    },
    "EMP-010": {
        "total_30_days": 8500.00,
        "expense_count_30_days": 12,
        "largest_single_expense": 3500.00,
        "categories": {"travel": 5000.00, "meals": 2000.00, "equipment": 1500.00},
        "flagged_expenses": 2,
        "rejection_rate_90_days": 0.15,
    },
    "EMP-077": {
        "total_30_days": 1200.00,
        "expense_count_30_days": 4,
        "largest_single_expense": 500.00,
        "categories": {"meals": 800.00, "travel": 400.00},
        "flagged_expenses": 0,
        "rejection_rate_90_days": 0.0,
    },
}

# Department budgets
DEPARTMENT_BUDGETS = {
    "Engineering": {
        "monthly_budget": 50000.00,
        "spent_this_month": 44000.00,
        "remaining": 6000.00,
    },
    "Sales": {
        "monthly_budget": 40000.00,
        "spent_this_month": 28000.00,
        "remaining": 12000.00,
    },
}

# Approval thresholds by employee level
APPROVAL_THRESHOLDS = {
    "Individual Contributor": {"auto_approve_up_to": 100.00, "can_approve_up_to": 0.00},
    "Manager": {"auto_approve_up_to": 500.00, "can_approve_up_to": 2000.00},
    "Director": {"auto_approve_up_to": 2000.00, "can_approve_up_to": 10000.00},
    "VP": {"auto_approve_up_to": 5000.00, "can_approve_up_to": 50000.00},
}

# Sample expense submissions for testing
SAMPLE_EXPENSES = [
    {
        "id": "EXP-001",
        "employee_id": "EMP-042",
        "description": "Round-trip flight to NYC for client meeting with Acme Corp",
        "amount": 450.00,
        "date": "2026-03-20",
        "receipt_attached": True,
        "notes": "Booked 14 days in advance, economy class",
    },
    {
        "id": "EXP-002",
        "employee_id": "EMP-077",
        "description": "Team dinner at upscale restaurant -- 8 attendees, celebrating Q1 close",
        "amount": 680.00,
        "date": "2026-03-22",
        "receipt_attached": True,
        "notes": "Includes $120 in alcohol",
    },
    {
        "id": "EXP-003",
        "employee_id": "EMP-042",
        "description": "New MacBook Pro for development work",
        "amount": 3200.00,
        "date": "2026-03-25",
        "receipt_attached": True,
        "notes": "Replacing 5-year-old laptop, IT approved",
    },
    {
        "id": "EXP-004",
        "employee_id": "EMP-010",
        "description": "Flight and hotel for conference in San Francisco",
        "amount": 2800.00,
        "date": "2026-03-26",
        "receipt_attached": True,
        "notes": "Annual engineering leadership summit, booked 21 days in advance",
    },
]
