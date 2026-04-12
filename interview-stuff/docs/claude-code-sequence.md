# Claude Code Style Sequence

This note captures a practical mental model for a Claude Code style agent stack.

## Layer Model

- REPL: the interactive terminal experience.
- CLI app: the host process for the agent system.
- Harness: the orchestration layer inside the CLI.
- Runtime: the execution engine for a specific agent run.
- Model and tools: the components used by the runtime while executing.

The key distinction is that the harness configures and drives the runtime. The runtime then executes the live request using the selected model, tools, graph, state, and limits.

## Sequence

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant REPL as REPL / Terminal UI
    participant CLI as CLI App
    participant Harness as Harness / Orchestrator
    participant Runtime as Runtime / Graph Executor
    participant Model as Model
    participant Tools as Tooling Layer

    User->>REPL: Enter prompt
    REPL->>CLI: Submit request
    CLI->>Harness: Create agent request
    Harness->>Harness: Resolve policy and configuration
    Note over Harness: Select model profile, tool access, graph,<br/>memory, middleware, limits, permissions
    Harness->>Runtime: Start configured run

    loop Agent execution
        Runtime->>Model: Ask for next step
        alt Model returns tool call
            Model-->>Runtime: Tool call request
            Runtime->>Tools: Execute allowed tool
            Tools-->>Runtime: Tool result
            Runtime->>Harness: Emit step events and state updates
            Harness-->>REPL: Stream progress
        else Model returns answer
            Model-->>Runtime: Final response
        end
    end

    Runtime-->>Harness: Final state and output
    Harness-->>CLI: Final response payload
    CLI-->>REPL: Render final answer
    REPL-->>User: Show result
```

## Practical Interpretation

For the wording you were using earlier, this is the most accurate version:

- The REPL wraps the CLI experience.
- The CLI hosts the harness.
- The harness prepares and configures a run.
- The runtime executes that run.
- The selected model, tools, graph, and limits are usually runtime configuration for that run, not the runtime itself.

## Short Version

Think of it this way:

- REPL: user interface
- CLI: application shell
- Harness: agent control layer
- Runtime: execution engine
- Model and tools: resources used during execution

So when a user sends a request, the harness composes the run and the runtime carries it out.