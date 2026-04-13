"""
Workflow state definition.

The state is the single source of truth that flows through all agents.
Each agent reads from and writes to it, building up a complete picture
of the expense review.
"""

from __future__ import annotations

import copy
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any


@dataclass
class AuditEntry:
    """A single entry in the audit trail."""

    timestamp: str
    agent: str
    action: str
    detail: str

    def __str__(self) -> str:
        return f"[{self.timestamp}] {self.agent}: {self.action} -- {self.detail}"


@dataclass
class WorkflowState:
    """
    Central state object for the expense approval workflow.

    This is the shared memory that all agents read from and write to.
    In a production system with LangGraph, this would be a TypedDict
    with reducer functions. Here we use a simple dataclass.
    """

    # Input
    expense: dict[str, Any] = field(default_factory=dict)

    # Triage results
    employee: dict[str, Any] = field(default_factory=dict)
    category: str = ""

    # Policy check results
    policy_violations: list[str] = field(default_factory=list)
    policy_warnings: list[str] = field(default_factory=list)
    applicable_limit: float = 0.0

    # Risk assessment results
    risk_score: int = 0  # 0-100
    risk_factors: list[str] = field(default_factory=list)
    risk_level: str = ""  # low, medium, high

    # Decision
    decision: str = ""  # approved, approved_with_conditions, rejected, escalated
    decision_rationale: str = ""
    conditions: list[str] = field(default_factory=list)

    # Review (reflection)
    review_passed: bool = False
    review_concerns: list[str] = field(default_factory=list)
    review_summary: str = ""

    # Workflow metadata
    status: str = "pending"  # pending, in_progress, completed, escalated
    audit_trail: list[AuditEntry] = field(default_factory=list)
    current_agent: str = ""

    def log(self, agent: str, action: str, detail: str) -> None:
        """Add an entry to the audit trail."""
        entry = AuditEntry(
            timestamp=datetime.now().strftime("%H:%M:%S.%f")[:-3],
            agent=agent,
            action=action,
            detail=detail,
        )
        self.audit_trail.append(entry)

    def snapshot(self) -> dict[str, Any]:
        """Return a serializable snapshot of the current state."""
        return {
            "expense_id": self.expense.get("id", "N/A"),
            "category": self.category,
            "amount": self.expense.get("amount", 0),
            "risk_score": self.risk_score,
            "risk_level": self.risk_level,
            "violations": len(self.policy_violations),
            "decision": self.decision,
            "review_passed": self.review_passed,
            "status": self.status,
        }

    def clone(self) -> WorkflowState:
        """Deep copy the state (useful for checkpointing)."""
        return copy.deepcopy(self)
