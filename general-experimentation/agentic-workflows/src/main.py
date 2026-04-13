#!/usr/bin/env python3
"""
Agentic Expense Approval Workflow
==================================

Demonstrates agentic patterns applied to a real business process:
  - Tool Use:       Agents call mock business system APIs
  - ReAct:          Risk agent iterates with Thought -> Action -> Observation
  - Reflection:     Review agent validates the decision
  - Multi-Agent:    Five agents collaborate via shared state
  - State Mgmt:     Central state flows through the pipeline
  - HITL:           Ambiguous cases trigger escalation
  - Guardrails:     Input validation, bounded iterations, scope limits

Run:
    python main.py              # Process all sample expenses
    python main.py --expense 0  # Process only the first sample expense
"""

from __future__ import annotations

import argparse
import sys

from agents import (
    DecisionAgent,
    PolicyAgent,
    ReviewAgent,
    RiskAgent,
    TriageAgent,
)
from data import SAMPLE_EXPENSES
from state import WorkflowState


# ---------------------------------------------------------------------------
# Workflow Orchestrator
# ---------------------------------------------------------------------------

class ExpenseApprovalWorkflow:
    """
    Orchestrates the expense approval pipeline.

    This is a simple sequential orchestrator. In production, you would use
    LangGraph's StateGraph for conditional routing, parallel execution,
    persistent checkpointing, and human-in-the-loop interrupt points.

    The key architectural pattern is the same: agents are composable units
    that read from and write to a shared state.
    """

    def __init__(self) -> None:
        self.agents = [
            TriageAgent(),
            PolicyAgent(),
            RiskAgent(),
            DecisionAgent(),
            ReviewAgent(),
        ]

    def run(self, expense: dict) -> WorkflowState:
        """Run the full approval workflow for an expense."""
        # Initialize state
        state = WorkflowState(expense=expense, status="in_progress")
        state.log("Orchestrator", "workflow_start", f"expense_id={expense.get('id')}")

        print(f"\n{'#' * 60}")
        print(f"  EXPENSE APPROVAL WORKFLOW")
        print(f"  Expense: {expense.get('id')} -- ${expense.get('amount', 0):.2f}")
        print(f"  Description: {expense.get('description', 'N/A')[:55]}...")
        print(f"{'#' * 60}")

        # Run each agent in sequence
        for agent in self.agents:
            state = agent.run(state)

            # Guardrail: stop if there's an error
            if state.status == "error":
                print(f"\n  [!] Workflow halted due to error in {agent.name}")
                break

        # Set final status
        if state.status != "error":
            if state.decision == "escalated":
                state.status = "escalated"
            else:
                state.status = "completed"

        state.log("Orchestrator", "workflow_complete", f"status={state.status}")

        # Print summary
        self._print_summary(state)
        return state

    def _print_summary(self, state: WorkflowState) -> None:
        """Print a clear final summary of the workflow result."""
        print(f"\n{'=' * 60}")
        print(f"  FINAL RESULT")
        print(f"{'=' * 60}")

        # Decision with visual indicator
        decision_display = {
            "approved": "[APPROVED]",
            "approved_with_conditions": "[APPROVED WITH CONDITIONS]",
            "rejected": "[REJECTED]",
            "escalated": "[ESCALATED TO HUMAN]",
        }
        display = decision_display.get(state.decision, f"[{state.decision.upper()}]")
        print(f"  Decision:  {display}")
        print(f"  Risk:      {state.risk_level.upper()} ({state.risk_score}/100)")
        print(f"  Review:    {'PASSED' if state.review_passed else 'FLAGGED'}")
        print(f"  Rationale: {state.decision_rationale}")

        if state.conditions:
            print(f"  Conditions:")
            for cond in state.conditions:
                print(f"    - {cond}")

        if state.review_concerns:
            print(f"  Review Concerns:")
            for concern in state.review_concerns:
                print(f"    - {concern}")

        # HITL demonstration
        if state.decision == "escalated":
            print(f"\n  {'*' * 50}")
            print(f"  * HUMAN-IN-THE-LOOP: This expense requires manual")
            print(f"  * review. In a production system, this would pause")
            print(f"  * the workflow and notify a manager via email/Slack.")
            print(f"  * The workflow state is checkpointed and can resume")
            print(f"  * after human approval.")
            print(f"  {'*' * 50}")

        # Audit trail
        print(f"\n  Audit Trail ({len(state.audit_trail)} entries):")
        for entry in state.audit_trail:
            print(f"    {entry}")

        print()


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Agentic Expense Approval Workflow Demo"
    )
    parser.add_argument(
        "--expense",
        type=int,
        default=None,
        help="Index of a specific sample expense to process (0-based)",
    )
    args = parser.parse_args()

    workflow = ExpenseApprovalWorkflow()

    if args.expense is not None:
        if 0 <= args.expense < len(SAMPLE_EXPENSES):
            expenses = [SAMPLE_EXPENSES[args.expense]]
        else:
            print(f"Error: expense index must be 0-{len(SAMPLE_EXPENSES) - 1}")
            sys.exit(1)
    else:
        expenses = SAMPLE_EXPENSES

    results = []
    for expense in expenses:
        state = workflow.run(expense)
        results.append(state)

    # Final summary table
    if len(results) > 1:
        print(f"\n{'=' * 60}")
        print(f"  BATCH SUMMARY")
        print(f"{'=' * 60}")
        print(f"  {'ID':<10} {'Amount':>10} {'Risk':>8} {'Decision':<25} {'Review'}")
        print(f"  {'-'*10} {'-'*10} {'-'*8} {'-'*25} {'-'*8}")
        for s in results:
            eid = s.expense.get("id", "N/A")
            amt = f"${s.expense.get('amount', 0):.2f}"
            risk = s.risk_level.upper() if s.risk_level else "N/A"
            dec = s.decision.upper() if s.decision else "N/A"
            rev = "PASS" if s.review_passed else "FLAG"
            print(f"  {eid:<10} {amt:>10} {risk:>8} {dec:<25} {rev}")
        print()


if __name__ == "__main__":
    main()
