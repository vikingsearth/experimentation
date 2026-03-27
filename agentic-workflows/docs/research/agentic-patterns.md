# Agentic Design Patterns

## What Are Agentic Workflows?

Agentic workflows are structured systems where LLM-powered agents autonomously reason,
make decisions, use tools, and take actions to accomplish complex goals. Unlike simple
prompt-response interactions, agentic workflows involve loops of reasoning, observation,
and adaptation -- making them suitable for automating multi-step business processes.

The global agentic AI market is projected to grow from $28B in 2024 to $127B by 2029
(35% CAGR). Gartner named agentic AI a top technology trend for 2025.

---

## Core Patterns

### 1. ReAct (Reasoning + Acting)

Introduced by Yao et al. (2022), ReAct interleaves reasoning traces with task-specific
actions. The agent follows a **Thought -> Action -> Observation** cycle:

- **Thought**: The agent reasons about what to do next
- **Action**: It executes a tool call or API request
- **Observation**: It processes the result and decides the next step

**Strengths:**
- Transparent decision-making (audit trail of "Thoughts")
- Handles dynamic situations where static plans break down
- Well-suited for regulated industries (finance, healthcare) where explainability matters

**Trade-offs:**
- Each cycle requires a new LLM call, adding latency
- Can struggle with long-horizon goals requiring many steps

### 2. Plan-and-Execute

Separates high-level strategic planning from tactical execution:

1. A **Planner** analyzes the request and breaks it into a DAG of subtasks
2. An **Executor** carries out each subtask, potentially using other patterns (ReAct, Tool Use)
3. The plan can be revised dynamically based on execution results

**Strengths:**
- Handles complex, multi-step workflows with dependencies
- More efficient than pure ReAct for long-horizon tasks
- Plans can be inspected and approved before execution

**Trade-offs:**
- Initial planning step adds overhead for simple tasks
- Plan quality depends heavily on the LLM's understanding of the domain

### 3. Tool Use

Agents interact with external systems -- APIs, databases, code interpreters, search engines.
Tools are the bridge between reasoning and real-world action.

**Key considerations:**
- Use sandboxed environments for code execution
- Implement strict validation for API parameters
- Define clear tool descriptions so the LLM selects the right tool
- Foundation for "action-oriented" agents that don't just talk but actually do

### 4. Reflection

The agent evaluates and improves its own outputs. This can involve:
- Self-critique: asking the same model to review its answer
- Cross-model review: using a different model to evaluate
- Iterative refinement: multiple rounds of generation and critique

**Strengths:**
- Catches errors without human intervention
- Moves toward "System 2" (deliberate, methodical) thinking
- Quality improvements can be significant for complex outputs

**Trade-offs:**
- Multiple LLM calls increase latency and cost
- Diminishing returns after a few iterations

### 5. Multi-Agent Collaboration

Multiple specialized agents work together under an orchestrator:

- **Supervisor pattern**: A coordinator delegates to specialist agents
- **Peer-to-peer**: Agents communicate directly based on need
- **Pipeline**: Agents process work sequentially, each adding value

**Strengths:**
- Modular -- each agent can be developed and tested independently
- Scales well for complex domains (each agent stays focused)
- Mirrors real organizational structures

**Trade-offs:**
- Coordination overhead
- Debugging becomes harder with many interacting agents
- Requires clear responsibility boundaries

---

## Combining Patterns

The most effective agentic solutions combine multiple patterns:

- A **planning** agent breaks down the problem
- **Specialist agents** use **tools** to execute each step
- **Reflection** validates outputs before passing them along
- **ReAct** handles unexpected situations within each step

**Practical advice:** Start with the simplest pattern that works. If the agent
hallucinates, add Reflection. If tasks are too complex for a single loop, add Planning.
If prompts become unmanageable, refactor into Multi-Agent.

---

## Sources

- [ReAct Prompting Guide](https://www.promptingguide.ai/techniques/react)
- [Agentic AI from First Principles: Reflection (Towards Data Science)](https://towardsdatascience.com/agentic-ai-from-first-principles-reflection/)
- [ReAct vs Plan-and-Execute (DEV Community)](https://dev.to/jamesli/react-vs-plan-and-execute-a-practical-comparison-of-llm-agent-patterns-4gh9)
- [5 AI Agent Design Patterns (n1n.ai)](https://explore.n1n.ai/blog/5-ai-agent-design-patterns-master-2026-2026-03-21)
- [Agent Factory: Agentic AI Design Patterns (Microsoft Azure)](https://azure.microsoft.com/en-us/blog/agent-factory-the-new-era-of-agentic-ai-common-use-cases-and-design-patterns/)
- [IBM: What is a ReAct Agent?](https://www.ibm.com/think/topics/react-agent)
