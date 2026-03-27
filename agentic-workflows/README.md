# Agentic Workflows: Expense Approval Demo

A hands-on experiment exploring **agentic workflows for business logic automation**. Five cooperating agents process expense reports through classification, policy checking, risk assessment, decision making, and reflective review.

## What This Demonstrates

| Agentic Pattern | Where It Appears |
|-----------------|-----------------|
| **Tool Use** | Every agent calls mock business-system APIs (employee lookup, policy retrieval, budget checks) |
| **ReAct** | Risk Assessor iterates through a Thought -> Action -> Observation loop across 4 data-gathering steps |
| **Reflection** | Review Agent validates the Decision Agent's output for consistency and completeness |
| **Multi-Agent** | Five agents collaborate via shared state in a pipeline |
| **State Management** | A central `WorkflowState` dataclass flows through the entire pipeline with full audit trail |
| **Human-in-the-Loop** | Ambiguous high-risk cases trigger escalation instead of automated decisions |
| **Guardrails** | Input validation, bounded iterations, scope-limited decisions |

## Quick Start

```bash
# No dependencies required -- Python 3.9+ standard library only
cd agentic-workflows/src

python main.py              # Process all 4 sample expenses
python main.py --expense 0  # Process only one (index 0-3)
```

## Sample Expenses

| ID | Description | Amount | Expected Outcome |
|----|-------------|--------|-----------------|
| EXP-001 | Flight to NYC for client meeting | $450 | Approved (low risk, within limits) |
| EXP-002 | Team dinner, 8 attendees, alcohol | $680 | Rejected (over meal limit + alcohol cap) |
| EXP-003 | MacBook Pro for development | $3,200 | Rejected (exceeds equipment limit) |
| EXP-004 | Conference travel (high-spend employee) | $2,800 | Escalated to human (high risk score) |

## Project Structure

```
agentic-workflows/
  src/
    main.py        # Entry point and workflow orchestrator
    agents.py      # 5 agent implementations (Triage, Policy, Risk, Decision, Review)
    tools.py       # Mock business-system APIs
    state.py       # WorkflowState dataclass with audit trail
    data.py        # Mock data: employees, policies, budgets, sample expenses
  docs/
    research/      # Research on agentic patterns, frameworks, guardrails
    planning/      # Implementation plan
  requirements.txt # No external deps needed
```

## Key Design Decisions

- **No LLM dependency**: Agents use deterministic logic to simulate reasoning. The architecture (tool calls, reasoning traces, state flow, inter-agent communication) mirrors exactly what you would build with real LLMs. Swap the if/else logic for LLM calls and you have a production system.
- **No external framework**: The orchestrator is ~50 lines of Python, making the patterns visible rather than hidden behind framework abstractions. In production, use LangGraph or similar.
- **Full audit trail**: Every agent action is logged with timestamps, enabling debugging and compliance review.

## Research Notes

The `docs/research/` folder contains detailed write-ups on:
- [Agentic Patterns](docs/research/agentic-patterns.md) -- ReAct, Reflection, Tool Use, Planning, Multi-Agent
- [Frameworks Overview](docs/research/frameworks-overview.md) -- LangGraph vs CrewAI vs AutoGen comparison
- [Business Logic Modeling](docs/research/business-logic-modeling.md) -- How to map business processes to agent workflows
- [Guardrails and HITL](docs/research/guardrails-and-hitl.md) -- Safety, error handling, human-in-the-loop patterns
