"""
Agent implementations for the expense approval workflow.

Each agent demonstrates a specific agentic pattern:
  - TriageAgent:    Classification + Tool Use
  - PolicyAgent:    Rule checking + Tool Use
  - RiskAgent:      ReAct pattern (Thought -> Action -> Observation loop)
  - DecisionAgent:  Planning + Decision making
  - ReviewAgent:    Reflection pattern

Agents are intentionally implemented without an LLM dependency. The reasoning
logic is deterministic, but the *structure* -- tool calls, reasoning traces,
state management, and inter-agent communication -- mirrors exactly what you
would build with LLM-powered agents. Swap the if/else logic for LLM calls
and you have a production system.
"""

from __future__ import annotations

from state import WorkflowState
from tools import (
    calculate_risk_score,
    categorize_expense,
    check_budget_remaining,
    check_receipt_attached,
    get_approval_thresholds,
    get_policy_rules,
    get_spending_history,
    lookup_employee,
)

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

INDENT = "  "


def _header(step: int, total: int, name: str) -> None:
    print(f"\n{'=' * 60}")
    print(f"  [{step}/{total}] {name}")
    print(f"{'=' * 60}")


def _thought(msg: str) -> None:
    print(f"{INDENT}Thought: {msg}")


def _action(tool: str, args: str = "") -> None:
    arg_str = f"({args})" if args else "()"
    print(f"{INDENT}Action:  {tool}{arg_str}")


def _observation(msg: str) -> None:
    print(f"{INDENT}Observe: {msg}")


def _result(msg: str) -> None:
    print(f"{INDENT}Result:  {msg}")


# ---------------------------------------------------------------------------
# Agent: Triage
# Pattern: Classification + Tool Use
# ---------------------------------------------------------------------------

class TriageAgent:
    """Categorizes the expense and looks up the submitting employee."""

    name = "Triage Agent"

    def run(self, state: WorkflowState) -> WorkflowState:
        _header(1, 5, self.name)
        state.current_agent = self.name

        # Step 1: Categorize the expense
        _thought("I need to classify this expense into a category.")
        desc = state.expense.get("description", "")
        _action("categorize_expense", f'"{desc[:50]}..."')
        result = categorize_expense(desc)
        state.category = result["category"]
        _observation(
            f"Category = {result['category']} "
            f"(confidence: {result['confidence']:.0%})"
        )
        state.log(self.name, "categorize_expense", f"category={result['category']}")

        # Step 2: Look up the employee
        emp_id = state.expense.get("employee_id", "")
        _thought(f"Now I need to verify the employee ({emp_id}).")
        _action("lookup_employee", f'"{emp_id}"')
        try:
            employee = lookup_employee(emp_id)
            state.employee = employee
            _observation(
                f"{employee['name']}, {employee['department']}, "
                f"{employee['level']} level"
            )
            state.log(self.name, "lookup_employee", f"found: {employee['name']}")
        except ValueError as e:
            _observation(f"ERROR: {e}")
            state.log(self.name, "lookup_employee", f"error: {e}")
            state.status = "error"
            return state

        _result(
            f"Categorized as {state.category.upper()}, "
            f"submitted by {state.employee['name']}"
        )
        return state


# ---------------------------------------------------------------------------
# Agent: Policy Checker
# Pattern: Tool Use + Rule Matching
# ---------------------------------------------------------------------------

class PolicyAgent:
    """Checks the expense against company policy rules."""

    name = "Policy Checker"

    def run(self, state: WorkflowState) -> WorkflowState:
        _header(2, 5, self.name)
        state.current_agent = self.name
        violations = []
        warnings = []

        # Step 1: Get policy rules for this category
        _thought(f"Checking {state.category} policy rules.")
        _action("get_policy_rules", f'"{state.category}"')
        policy = get_policy_rules(state.category)
        _observation(f"Found {len(policy['rules'])} rules, max=${policy['max_single_expense']:.0f}")
        state.log(self.name, "get_policy_rules", f"category={state.category}")

        amount = state.expense.get("amount", 0)
        state.applicable_limit = policy["max_single_expense"]

        # Step 2: Check amount against limit
        _thought(f"Expense is ${amount:.2f}. Limit is ${policy['max_single_expense']:.2f}.")
        if amount > policy["max_single_expense"]:
            msg = (
                f"Amount ${amount:.2f} exceeds {state.category} limit "
                f"of ${policy['max_single_expense']:.2f}"
            )
            violations.append(msg)
            _observation(f"VIOLATION: {msg}")
        else:
            _observation("Amount is within policy limit.")

        # Step 3: Check pre-approval requirement
        if amount > policy["requires_pre_approval_above"]:
            msg = (
                f"Amount ${amount:.2f} exceeds pre-approval threshold "
                f"of ${policy['requires_pre_approval_above']:.2f}"
            )
            warnings.append(msg)
            _thought(f"This requires pre-approval (threshold: ${policy['requires_pre_approval_above']:.2f}).")
            _observation(f"WARNING: {msg}")

        # Step 4: Check receipt
        _thought("Verifying receipt compliance.")
        _action("check_receipt_attached", "expense")
        receipt_result = check_receipt_attached(
            {**state.expense, "category": state.category}
        )
        if not receipt_result["compliant"]:
            msg = (
                f"Receipt required for amounts over ${receipt_result['threshold']:.2f} "
                f"but none attached"
            )
            violations.append(msg)
            _observation(f"VIOLATION: {msg}")
        else:
            _observation("Receipt compliance: OK")
        state.log(self.name, "check_receipt", f"compliant={receipt_result['compliant']}")

        # Step 5: Category-specific checks
        _thought("Running category-specific rule checks.")
        notes = state.expense.get("notes", "").lower()
        if state.category == "meals":
            # Check per-person limit for team meals
            if "team" in state.expense.get("description", "").lower():
                # Try to extract attendee count from notes
                for word in notes.split():
                    if word.isdigit():
                        attendees = int(word)
                        per_person = amount / attendees
                        if per_person > 50:
                            msg = f"Per-person cost ${per_person:.2f} exceeds $50 team meal limit"
                            violations.append(msg)
                            _observation(f"VIOLATION: {msg}")
                        break

            # Check alcohol limit
            if "alcohol" in notes:
                for part in notes.split("$"):
                    try:
                        alcohol_amount = float(part.split()[0])
                        if alcohol_amount > 30:
                            msg = f"Alcohol amount ${alcohol_amount:.2f} exceeds $30 per-meal cap"
                            violations.append(msg)
                            _observation(f"VIOLATION: {msg}")
                        break
                    except (ValueError, IndexError):
                        continue

        state.policy_violations = violations
        state.policy_warnings = warnings

        v_count = len(violations)
        w_count = len(warnings)
        _result(f"{v_count} violation(s), {w_count} warning(s)")
        state.log(
            self.name,
            "policy_check_complete",
            f"violations={v_count}, warnings={w_count}",
        )
        return state


# ---------------------------------------------------------------------------
# Agent: Risk Assessor
# Pattern: ReAct (Thought -> Action -> Observation loop)
# ---------------------------------------------------------------------------

class RiskAgent:
    """
    Assesses the risk level of the expense using the ReAct pattern.

    This agent explicitly demonstrates the Thought -> Action -> Observation
    loop, iterating through multiple data-gathering steps before arriving
    at a risk score.
    """

    name = "Risk Assessor"
    MAX_ITERATIONS = 5  # Guardrail: prevent infinite loops

    def run(self, state: WorkflowState) -> WorkflowState:
        _header(3, 5, self.name)
        state.current_agent = self.name

        factors: dict = {}
        iteration = 0

        # --- ReAct Loop ---
        # Each iteration: Thought -> Action -> Observation

        # Iteration 1: Get spending history
        iteration += 1
        _thought(
            f"[Iteration {iteration}] I need the employee's spending history "
            f"to assess patterns."
        )
        _action("get_spending_history", f'"{state.employee["id"]}"')
        history = get_spending_history(state.employee["id"])
        _observation(
            f"Last 30 days: ${history['total_30_days']:.0f} across "
            f"{history['expense_count_30_days']} expenses, "
            f"{history['flagged_expenses']} flagged"
        )
        factors["historical_flags"] = history["flagged_expenses"]
        factors["rejection_rate"] = history["rejection_rate_90_days"]
        state.log(self.name, "get_spending_history", f"total=${history['total_30_days']}")

        # Iteration 2: Check budget pressure
        iteration += 1
        dept = state.employee.get("department", "Unknown")
        _thought(
            f"[Iteration {iteration}] I should check if the {dept} department "
            f"budget is under pressure."
        )
        _action("check_budget_remaining", f'"{dept}"')
        budget = check_budget_remaining(dept)
        _observation(
            f"Budget: ${budget['remaining']:.0f} remaining of "
            f"${budget['monthly_budget']:.0f} "
            f"({budget['utilization']:.0%} used)"
        )
        factors["budget_utilization"] = budget["utilization"]
        state.log(self.name, "check_budget_remaining", f"utilization={budget['utilization']}")

        # Iteration 3: Calculate amount ratio
        iteration += 1
        amount = state.expense.get("amount", 0)
        limit = state.applicable_limit if state.applicable_limit > 0 else 1
        ratio = amount / limit
        _thought(
            f"[Iteration {iteration}] The expense is ${amount:.2f} against a "
            f"limit of ${limit:.2f} (ratio: {ratio:.2f}). "
            f"I also found {len(state.policy_violations)} policy violations."
        )
        factors["amount_ratio"] = ratio
        factors["violation_count"] = len(state.policy_violations)

        # Iteration 4: Calculate final risk score
        iteration += 1
        _thought(
            f"[Iteration {iteration}] I now have all factors. "
            f"Let me calculate the risk score."
        )
        _action("calculate_risk_score", "factors")
        risk_result = calculate_risk_score(factors)
        _observation(
            f"Risk score: {risk_result['score']}/100 ({risk_result['level']})"
        )
        _observation(f"Breakdown: {risk_result['breakdown']}")

        state.risk_score = risk_result["score"]
        state.risk_level = risk_result["level"]
        state.risk_factors = [
            f"Amount ratio: {ratio:.2f}x of policy limit",
            f"Policy violations: {len(state.policy_violations)}",
            f"Historical flags: {history['flagged_expenses']}",
            f"Budget utilization: {budget['utilization']:.0%}",
        ]

        _result(
            f"Risk level: {state.risk_level.upper()} "
            f"(score: {state.risk_score}/100)"
        )
        state.log(
            self.name,
            "risk_assessment_complete",
            f"score={state.risk_score}, level={state.risk_level}",
        )
        return state


# ---------------------------------------------------------------------------
# Agent: Decision Maker
# Pattern: Planning + Decision Logic
# ---------------------------------------------------------------------------

class DecisionAgent:
    """
    Makes the approval decision based on all gathered information.

    Demonstrates the planning pattern: first outlines the decision criteria,
    then systematically evaluates each one.
    """

    name = "Decision Agent"

    def run(self, state: WorkflowState) -> WorkflowState:
        _header(4, 5, self.name)
        state.current_agent = self.name

        amount = state.expense.get("amount", 0)
        level = state.employee.get("level", "Individual Contributor")

        # Step 1: Plan the decision process
        _thought(
            "I need to make a decision. Let me plan my evaluation:\n"
            f"{INDENT}         1. Check auto-approval thresholds\n"
            f"{INDENT}         2. Evaluate policy violations\n"
            f"{INDENT}         3. Consider risk level\n"
            f"{INDENT}         4. Apply decision rules"
        )

        # Step 2: Check thresholds
        _action("get_approval_thresholds", f'"{level}"')
        thresholds = get_approval_thresholds(level)
        _observation(
            f"Auto-approve up to ${thresholds['auto_approve_up_to']:.0f}, "
            f"can approve up to ${thresholds['can_approve_up_to']:.0f}"
        )
        state.log(self.name, "get_approval_thresholds", f"level={level}")

        # Step 3: Apply decision logic
        violations = state.policy_violations
        risk = state.risk_level
        conditions = []

        _thought("Evaluating all factors together...")

        # Decision tree
        if violations and any("exceeds" in v and "limit" in v for v in violations):
            # Hard violation: over policy limit
            decision = "rejected"
            rationale = (
                f"Expense of ${amount:.2f} has critical policy violation(s): "
                f"{'; '.join(violations)}. Cannot be approved without exception process."
            )
        elif risk == "high":
            # High risk: escalate to human
            decision = "escalated"
            rationale = (
                f"Risk score {state.risk_score}/100 is HIGH. "
                f"Factors: {', '.join(state.risk_factors)}. "
                f"Requires human review before approval."
            )
        elif amount <= thresholds["auto_approve_up_to"] and not violations:
            # Easy case: auto-approve
            decision = "approved"
            rationale = (
                f"Amount ${amount:.2f} is within auto-approval threshold "
                f"(${thresholds['auto_approve_up_to']:.0f}) for {level} level, "
                f"no policy violations, {risk} risk."
            )
        elif violations or state.policy_warnings:
            # Has issues but not critical
            decision = "approved_with_conditions"
            if violations:
                conditions.extend(
                    f"Resolve: {v}" for v in violations
                )
            if state.policy_warnings:
                conditions.extend(
                    f"Note: {w}" for w in state.policy_warnings
                )
            rationale = (
                f"Expense has minor issues that need attention. "
                f"Risk is {risk} ({state.risk_score}/100). "
                f"Approved conditionally pending resolution of: "
                f"{'; '.join(conditions)}"
            )
        else:
            # Standard approval
            decision = "approved"
            rationale = (
                f"Amount ${amount:.2f} is within policy limits, "
                f"no violations, risk is {risk} ({state.risk_score}/100). "
                f"Standard approval."
            )

        state.decision = decision
        state.decision_rationale = rationale
        state.conditions = conditions

        _observation(f"Decision: {decision.upper()}")
        _result(rationale)
        state.log(self.name, "decision", f"{decision}: {rationale[:80]}...")
        return state


# ---------------------------------------------------------------------------
# Agent: Reviewer
# Pattern: Reflection
# ---------------------------------------------------------------------------

class ReviewAgent:
    """
    Validates the decision agent's output using the Reflection pattern.

    This agent acts as a quality gate -- it reviews the decision for
    consistency, completeness, and correctness. In a real system, this
    could be a separate LLM call or even a different model.
    """

    name = "Review Agent"

    def run(self, state: WorkflowState) -> WorkflowState:
        _header(5, 5, f"{self.name} (Reflection)")
        state.current_agent = self.name
        concerns = []

        _thought("Reviewing the decision for consistency and completeness...")

        # Check 1: Decision exists
        if not state.decision:
            concerns.append("No decision was made")
            _observation("CONCERN: No decision was recorded")

        # Check 2: Rationale provided
        if not state.decision_rationale:
            concerns.append("No rationale provided for the decision")
            _observation("CONCERN: Missing rationale")
        else:
            _observation("Rationale provided: OK")

        # Check 3: Consistency -- rejected expenses should have violations or high risk
        if state.decision == "rejected" and not state.policy_violations:
            concerns.append(
                "Expense was rejected but no policy violations were found -- "
                "decision may be inconsistent"
            )
            _observation("CONCERN: Rejection without violations")
        elif state.decision == "rejected":
            _observation("Rejection is consistent with policy violations")

        # Check 4: High-risk expenses should not be auto-approved
        if state.decision == "approved" and state.risk_level == "high":
            concerns.append(
                "High-risk expense was approved without conditions or escalation"
            )
            _observation("CONCERN: High-risk expense auto-approved")
        else:
            _observation("Risk level is consistent with decision")

        # Check 5: Escalated decisions should have clear reasoning
        if state.decision == "escalated" and state.risk_score < 50:
            concerns.append(
                f"Expense escalated but risk score is only {state.risk_score}/100 -- "
                f"may be overly cautious"
            )
            _observation(f"CONCERN: Escalation with moderate risk ({state.risk_score})")

        # Check 6: Conditional approvals should have conditions
        if state.decision == "approved_with_conditions" and not state.conditions:
            concerns.append("Conditional approval but no conditions specified")
            _observation("CONCERN: Missing conditions")
        elif state.decision == "approved_with_conditions":
            _observation(f"Conditions specified: {len(state.conditions)} item(s)")

        # Final assessment
        state.review_concerns = concerns
        state.review_passed = len(concerns) == 0

        if state.review_passed:
            state.review_summary = (
                "Decision is consistent, well-reasoned, and complete. "
                "No concerns found."
            )
            _result("PASSED -- decision is sound")
        else:
            state.review_summary = (
                f"Found {len(concerns)} concern(s): {'; '.join(concerns)}. "
                f"Consider re-evaluating."
            )
            _result(f"FLAGGED -- {len(concerns)} concern(s) found")

        state.log(
            self.name,
            "review_complete",
            f"passed={state.review_passed}, concerns={len(concerns)}",
        )
        return state
