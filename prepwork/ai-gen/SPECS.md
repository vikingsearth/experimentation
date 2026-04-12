**WHAT?**

- REPL over a CLI of an agent harness using an Azure Foundry proxy for model access

**STACK**

- Runtime: Node.JS
- Language: TypeScript
- Framework: LangChain.js + LangGraph.js

**DESIGN**

- HARNESS:
  - Operational shell around core model loop
  - Allows for the injection of tools, utilities, and custom logic
  - Can be seen as the "operating system" for the agent, managing resources and orchestrating interactions
  - Can (after each step of the runtime) run middleware functions that inspect and modify the agent's state, tool calls, and LLM interactions
  - POLICIES AND CAPABILITIES
- RUNTIME:
  - execution machinery for the agent graph
  - handles the actual calls to the LLM and tools, manages state, etc.
  - EXECUTOR AND CONTROL PLANE
