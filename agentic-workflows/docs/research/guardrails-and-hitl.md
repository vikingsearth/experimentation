# Guardrails, Error Handling, and Human-in-the-Loop

## Why Guardrails Matter

Agentic systems operate with autonomy. Without guardrails, they can:
- Take irreversible actions based on hallucinated reasoning
- Violate business rules or compliance requirements
- Spiral into infinite loops or wasteful retry cycles
- Leak sensitive data through tool calls or outputs
- Make decisions outside their authorized scope

Enterprises must define governance frameworks that establish agent autonomy levels,
decision boundaries, behavior monitoring, and audit mechanisms.

---

## Guardrail Strategies

### 1. Input Validation
- Validate all inputs before they reach the agent
- Sanitize user inputs to prevent prompt injection
- Enforce schema validation on structured inputs
- Reject requests outside the agent's defined scope

### 2. Output Validation
- Check agent outputs against expected schemas
- Validate that proposed actions are within allowed bounds
- Use a separate "judge" model to evaluate output quality
- Apply business rule checks before executing actions

### 3. Tool Call Safety
- Whitelist allowed tools per agent role
- Validate tool parameters before execution
- Use read-only modes for data retrieval vs. write modes for actions
- Sandbox code execution environments
- Rate-limit tool calls to prevent runaway loops

### 4. Scope Boundaries
- Define what each agent is and is not allowed to do
- Set maximum iteration counts for reasoning loops
- Cap total token usage / cost per workflow execution
- Implement timeout mechanisms for long-running workflows

### 5. Audit and Observability
- Log every agent thought, action, and observation
- Track token usage, latency, and cost per step
- Record the full decision chain for compliance
- Enable replay of workflows for debugging

---

## Error Handling Patterns

### Graceful Degradation
When an agent encounters an error:
1. Retry with exponential backoff for transient failures
2. Try an alternative approach if the first fails
3. Escalate to human if automated recovery fails
4. Never silently swallow errors

### Circuit Breaker
If a tool or service fails repeatedly:
- Stop calling it after N failures
- Route to a fallback path
- Alert operators
- Resume when the service recovers

### State Recovery
Using persistent state (checkpointing):
- Save state after each successful step
- On failure, resume from the last checkpoint
- Avoid re-executing expensive operations
- LangGraph's checkpointing is designed for exactly this

### Bounded Retries
- Set maximum retry counts for each operation
- Use different strategies per error type:
  - Timeout -> retry with longer timeout
  - Rate limit -> retry with backoff
  - Invalid input -> do not retry, escalate
  - Authentication failure -> do not retry, alert

---

## Human-in-the-Loop (HITL) Patterns

### When to Involve Humans

Not all decisions should be fully autonomous. Involve humans when:
- **High stakes**: Financial transactions above a threshold
- **Ambiguity**: Agent confidence is low or the situation is novel
- **Compliance**: Regulations require human approval
- **Learning**: Early deployment where trust has not been established
- **Exceptions**: Edge cases outside the agent's training distribution

### HITL Implementation Approaches

#### 1. Approval Gates
The workflow pauses at defined checkpoints and waits for human approval:
- Agent proposes an action
- Human reviews and approves, modifies, or rejects
- Workflow continues based on human decision
- LangGraph supports this via interrupt nodes in the graph

#### 2. Confidence-Based Escalation
The agent self-assesses its confidence:
- High confidence -> proceed autonomously
- Medium confidence -> proceed but flag for review
- Low confidence -> pause and request human input
- Requires calibrated confidence scoring (which LLMs are not great at natively)

#### 3. Exception Handling
Route to humans only when the automated path fails:
- Agent attempts resolution
- If it cannot resolve, packages the context and escalates
- Human resolves and the agent learns from the resolution

#### 4. Oversight Dashboard
Humans monitor agent activity in real time:
- View current workflow state
- See agent reasoning and proposed actions
- Intervene at any point
- Review and approve batches of decisions

### Framework Support

| Framework | HITL Mechanism |
|-----------|---------------|
| **LangGraph** | Interrupt nodes, persistent state enables async human review |
| **CrewAI** | Human feedback injection at any workflow point |
| **AutoGen** | UserProxyAgent -- human joins the conversation as an agent |

---

## Autonomy Levels

A useful framework for thinking about agent autonomy:

| Level | Description | Human Role |
|-------|-------------|------------|
| **L1: Assistive** | Agent suggests, human decides | Decision maker |
| **L2: Semi-autonomous** | Agent decides routine cases, escalates exceptions | Exception handler |
| **L3: Supervised autonomous** | Agent decides most cases, human reviews samples | Auditor |
| **L4: Fully autonomous** | Agent handles everything, human monitors metrics | Monitor |

Most enterprise deployments in 2025 are at L1-L2. The industry is moving toward L2-L3
for well-defined, lower-risk processes.

---

## Practical Recommendations

1. **Start at L1-L2**: Let the agent suggest actions, have humans approve
2. **Instrument everything**: You cannot govern what you cannot observe
3. **Define decision boundaries explicitly**: What can the agent decide? What must it escalate?
4. **Test adversarially**: Try to break your agent before deploying it
5. **Plan for failure**: Every tool call can fail; every LLM response can be wrong
6. **Build trust incrementally**: Expand autonomy as the system proves reliable

---

## Sources

- [Agentic AI Strategy (Deloitte)](https://www.deloitte.com/us/en/insights/topics/technology-management/tech-trends/2026/agentic-ai-strategy.html)
- [LangGraph Workflows and Agents (LangChain Docs)](https://docs.langchain.com/oss/python/langgraph/workflows-agents)
- [LangGraph State Machines (DEV Community)](https://dev.to/jamesli/langgraph-state-machines-managing-complex-agent-task-flows-in-production-36f4)
- [Agentic AI Explained (Domo)](https://www.domo.com/blog/agentic-ai-explained-definition-benefits-and-use-cases)
