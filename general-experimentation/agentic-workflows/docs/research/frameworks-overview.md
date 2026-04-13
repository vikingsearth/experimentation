# Agentic Workflow Frameworks Overview

## Landscape Summary

Three frameworks dominate the agentic workflow space in 2025-2026: **LangGraph**,
**CrewAI**, and **AutoGen/AG2**. Each takes a fundamentally different approach to
orchestrating AI agents.

---

## LangGraph

**Philosophy:** Graph-based workflow design. Agent interactions are nodes in a directed
graph with explicit state management.

**Key features:**
- StateGraph with TypedDict-based state schemas
- Conditional edges for branching logic
- Persistent checkpointing (resume workflows, survive crashes)
- Reducer-driven state updates prevent data loss
- Human-in-the-loop via interrupt points in the graph
- MIT-licensed, open source

**Architecture:**
- Nodes = units of work (functions, tools, models)
- Edges = workflow paths between nodes
- State = persistent data passed between nodes, updated through reducers

**Best for:**
- Complex branching business logic
- Workflows needing persistent state and checkpointing
- Production deployments requiring observability
- Single-agent + tools scenarios (simpler than multi-agent frameworks)

**Trade-offs:**
- Steep learning curve (graph theory, state machines)
- Boilerplate can feel heavy for simple workflows
- Teams need solid understanding of distributed systems concepts

---

## CrewAI

**Philosophy:** Role-based model. Agents act like employees with specific
responsibilities, organized into Crews.

**Key features:**
- Two-layer architecture: Crews (dynamic collaboration) + Flows (deterministic orchestration)
- YAML-driven configuration for agent roles and tasks
- Built-in observability and enterprise features
- CrewAI Studio GUI for visual workflow design
- Paid control plane available for enterprise

**Best for:**
- Content production pipelines
- Report generation systems
- Quality assurance workflows
- Teams wanting structured, role-based abstractions

**Trade-offs:**
- YAML config can become unwieldy for complex customizations
- Less flexible than LangGraph for arbitrary control flow
- Enterprise features behind paid tier

---

## AutoGen / AG2

**Philosophy:** Everything is an asynchronous conversation among specialized agents.

**Key features:**
- Agents pass messages back and forth (chat-like interaction)
- UserProxyAgent for human-in-the-loop
- Async-first design reduces blocking
- AutoGen Studio GUI for prototyping
- Born from Microsoft Research

**Important note on the fork:**
- **AG2** is the community-driven continuation of AutoGen 0.2 (original creators who left MS)
- **Microsoft AutoGen 0.4** is a complete rewrite heading toward Semantic Kernel integration
- The two are diverging -- choose based on your ecosystem

**Best for:**
- Conversational workflows and customer-facing apps
- Rapid prototyping
- Human-in-the-loop scenarios via natural language
- Research and experimentation

**Trade-offs:**
- No managed deployment platform (DIY production setup)
- Less battle-tested in production than LangGraph/CrewAI
- Fork confusion between AG2 and MS AutoGen 0.4

---

## Other Notable Frameworks

| Framework | Description |
|-----------|-------------|
| **Claude Agent SDK** | Anthropic's SDK for building agents with Claude models |
| **OpenAI Agents SDK** | OpenAI's toolkit for building agents with GPT models |
| **Strands Agents** | AWS-backed, focuses on tool orchestration |
| **PydanticAI** | Type-safe agent framework leveraging Pydantic models |
| **LlamaIndex Workflows** | Agent workflows focused on data/RAG pipelines |

---

## Decision Matrix

| Need | Best Fit |
|------|----------|
| Complex branching workflows | **LangGraph** |
| Role-based agent teams | **CrewAI** |
| Conversational multi-agent | **AutoGen** |
| Enterprise production | **LangGraph** or **CrewAI** |
| Rapid prototyping | **AutoGen** or **CrewAI** |
| Human-in-the-loop | All three (LangGraph and CrewAI strongest) |
| Open protocol support (MCP, A2A) | **LangGraph** leading |

---

## Sources

- [CrewAI vs LangGraph vs AutoGen (DataCamp)](https://www.datacamp.com/tutorial/crewai-vs-langgraph-vs-autogen)
- [Top AI Agent Frameworks 2025 (Codecademy)](https://www.codecademy.com/article/top-ai-agent-frameworks-in-2025)
- [Comparing Open-Source AI Agent Frameworks (Langfuse)](https://langfuse.com/blog/2025-03-19-ai-agent-comparison)
- [AI Agent Frameworks Comparison (Turing)](https://www.turing.com/resources/ai-agent-frameworks)
- [LangGraph Official (LangChain)](https://www.langchain.com/langgraph)
- [Best AI Agent Frameworks 2025 (Maxim)](https://www.getmaxim.ai/articles/top-5-ai-agent-frameworks-in-2025-a-practical-guide-for-ai-builders/)
