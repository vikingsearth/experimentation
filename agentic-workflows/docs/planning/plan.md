# Implementation Plan: Expense Approval Workflow

## Concept

An **expense approval workflow** automated by cooperating agents. An employee submits
an expense report; agents classify it, check policy compliance, assess risk, make an
approval decision, and produce a final report -- all with clear reasoning traces.

This is a realistic business process that demonstrates multiple agentic patterns
without requiring external APIs or LLM calls. We simulate the "intelligence" with
rule-based mock agents so the demo runs instantly with zero dependencies beyond
Python's standard library.

---

## Why This Workflow?

- Universally understood business process
- Has clear decision points, branching, and escalation
- Naturally involves multiple "roles" (classifier, policy checker, approver)
- Demonstrates real patterns: tool use, reflection, state management, HITL

---

## Architecture

```
[Expense Submitted]
       |
       v
 +-----------+     +----------------+
 | Triage    | --> | Policy Checker | --> checks rules against company policy
 | Agent     |     +----------------+
 +-----------+            |
       |                  v
       |          +----------------+
       |          | Risk Assessor  | --> scores risk based on amount, category, history
       |          +----------------+
       |                  |
       |                  v
       |          +----------------+
       |          | Decision Agent | --> approve / reject / escalate
       |          +----------------+
       |                  |
       |                  v
       |          +----------------+
       |          | Review Agent   | --> reflection: validates the decision
       |          +----------------+
       |                  |
       |                  v
       |          [Final Decision + Report]
```

---

## Agents and Their Roles

### 1. Triage Agent
- **Pattern**: Classification + Tool Use
- **Job**: Categorize the expense (travel, meals, equipment, software, other)
- **Tools**: `categorize_expense()`, `lookup_employee()`
- **Output**: Category, employee details, initial metadata

### 2. Policy Checker Agent
- **Pattern**: Tool Use + ReAct
- **Job**: Check the expense against company policy rules
- **Tools**: `get_policy_rules()`, `check_receipt_attached()`
- **Output**: List of policy violations (if any), applicable limits

### 3. Risk Assessor Agent
- **Pattern**: ReAct (Thought -> Action -> Observation)
- **Job**: Score the risk of the expense (0-100)
- **Tools**: `get_spending_history()`, `calculate_risk_score()`
- **Output**: Risk score, risk factors, explanation

### 4. Decision Agent
- **Pattern**: Planning + Tool Use
- **Job**: Make the final decision based on all gathered information
- **Tools**: `get_approval_thresholds()`, `check_budget_remaining()`
- **Logic**:
  - Low risk + no violations -> Auto-approve
  - Medium risk or minor violations -> Approve with conditions
  - High risk or major violations -> Reject
  - Ambiguous cases -> Escalate to human (HITL)
- **Output**: Decision + detailed rationale

### 5. Review Agent
- **Pattern**: Reflection
- **Job**: Validate the decision agent's reasoning
- **Checks**: Is the decision consistent with the evidence? Were all policy rules considered?
- **Output**: Validation result, any concerns flagged

---

## State Management

A single `WorkflowState` dictionary flows through all agents:

```python
{
    "expense": { ... },           # Original submission
    "employee": { ... },          # Looked up employee info
    "category": "travel",         # Triage result
    "policy_check": { ... },      # Policy violations
    "risk_assessment": { ... },   # Risk score and factors
    "decision": { ... },          # Approval decision
    "review": { ... },            # Reflection result
    "audit_trail": [ ... ],       # Every agent action logged
    "status": "approved"          # Final status
}
```

---

## Mock Tools (No External Dependencies)

All tools are Python functions that return realistic mock data:
- `lookup_employee(id)` -> returns employee record from a dict
- `get_policy_rules(category)` -> returns rules for that expense category
- `get_spending_history(employee_id)` -> returns mock spending data
- `calculate_risk_score(factors)` -> deterministic scoring formula
- `get_approval_thresholds()` -> returns approval limits by role
- `check_budget_remaining(department)` -> returns budget info

---

## Patterns Demonstrated

| Pattern | Where |
|---------|-------|
| **Tool Use** | Every agent uses mock tools to gather information |
| **ReAct** | Risk Assessor follows Thought -> Action -> Observation loop |
| **Reflection** | Review Agent validates the Decision Agent's output |
| **Multi-Agent** | Five agents collaborate via shared state |
| **State Management** | Central state dict flows through the pipeline |
| **Human-in-the-Loop** | Ambiguous cases trigger escalation prompt |
| **Guardrails** | Max iterations, input validation, bounded decisions |

---

## Output

The program prints a clear, step-by-step trace of each agent's reasoning:

```
=== EXPENSE APPROVAL WORKFLOW ===

[1/5] TRIAGE AGENT
  Thought: Analyzing expense submission...
  Action: categorize_expense("Flight to NYC for client meeting")
  Observation: Category = travel
  Action: lookup_employee("EMP-042")
  Observation: Jane Smith, Engineering, Manager level
  Result: Categorized as TRAVEL, employee verified

[2/5] POLICY CHECKER
  Thought: Checking travel policy rules...
  Action: get_policy_rules("travel")
  ...

[FINAL DECISION]
  Status: APPROVED
  Rationale: Travel expense within policy limits, low risk score (22/100)...
```

---

## File Structure

```
agentic-workflows/
  src/
    main.py              # Entry point, runs the workflow
    agents.py            # All agent implementations
    tools.py             # Mock tools/APIs
    state.py             # WorkflowState definition
    data.py              # Mock data (employees, policies, etc.)
  requirements.txt       # Just Python 3.10+ (no external deps)
  README.md
  docs/
    research/            # Research files
    planning/
      plan.md            # This file
```

---

## Technical Decisions

- **No LLM dependency**: Mock agents use deterministic logic to simulate reasoning.
  This means the demo runs instantly, needs no API keys, and the output is reproducible.
  The patterns and architecture are identical to what you would build with real LLMs --
  swap the mock logic for LLM calls and you have a production system.

- **No external framework**: We implement the workflow orchestrator ourselves (~50 lines)
  to make the patterns visible. In production, you would use LangGraph or similar.

- **Python 3.10+ only**: Uses match/case for clean pattern matching. No pip installs.

- **Rich console output**: Uses only built-in print with clear formatting to show the
  agent reasoning trace.
