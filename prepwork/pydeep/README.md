# pydeep — Deep Agent with LangChain deepagents SDK

A Deep Agent built on the `deepagents` SDK, using Azure AI Foundry as the LLM provider.

## Quick start

```bash
# Install dependencies
uv sync

# Run (uses default question if none provided)
uv run python agent.py

# Run with a custom question
uv run python agent.py "What products does TechVista offer?"
```

## What's in here

- `agent.py` — Heavily commented deep agent implementation. Read the comments to learn how each piece works.

## Key concepts

- **Deep Agent** = ReAct loop + built-in planning, filesystem, subagents, and auto-summarization
- **Virtual filesystem** = in-memory scratch space the agent uses for working notes
- **Subagents** = child agents that run in isolation, keeping the parent's context clean
- **write_todos** = built-in planning tool the agent uses to break tasks into steps
