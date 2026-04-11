# Planned Features

## Purpose

`typescript-soc` is planned as a TypeScript-based terminal coding assistant for team use.
The product goal is to provide a Claude Code CLI-style experience around a team-safe,
observable, extensible agent shell that can read code, plan work, call tools, and keep
session state over time.

This document captures the high-level feature set for the first versions of the app.
It is intentionally product-focused rather than implementation-heavy.

## Product Principles

- CLI-first experience with clear streaming feedback.
- Team-safe defaults with explicit permissions and auditable actions.
- Session continuity so work can be resumed instead of restarted.
- Extensible tool model that can later support local tools and MCP-based integrations.
- Predictable architecture that is easy to debug and evolve.

## Core Features

### 1. Interactive CLI Shell

The app should provide an interactive shell where a user can ask for help, inspect a
codebase, and run multi-step agent workflows from the terminal.

Description:
- Starts in the current project directory.
- Accepts freeform prompts and shell-like commands.
- Displays a clear prompt, session name, and current mode.
- Supports both interactive usage and future headless automation.

Why it matters:
- This is the primary user surface.
- It creates the foundation for planning, tool use, and session management.

### 2. Streaming Agent Output

The app should stream model and tool activity as it happens instead of waiting for a
single final response.

Description:
- Streams assistant text incrementally.
- Shows tool-call intent, tool execution, and tool results in a readable format.
- Separates final answer content from operational status messages.
- Makes long-running turns feel observable and interruptible.

Why it matters:
- Streaming is one of the main traits that makes a coding CLI feel alive and usable.
- It helps users trust what the agent is doing.

### 3. Session Persistence and Resume

The app should persist sessions to disk so users can continue prior work without losing
context.

Description:
- Saves messages, metadata, and tool events locally.
- Allows a user to resume the most recent session or select an older one.
- Preserves enough state to continue the conversation coherently.
- Supports friendly session naming for future discoverability.

Why it matters:
- Teams do not want to restart context gathering every time they reopen the tool.
- Persistent sessions make the CLI feel like a working environment, not a disposable chat.

### 4. Tool-Oriented Agent Runtime

The app should expose capabilities to the model through tools instead of relying on raw
prompting alone.

Description:
- Starts with a small built-in tool set such as file reads, code search, and safe command
  execution.
- Uses explicit schemas for tool input and output.
- Emits structured events before and after tool use.
- Keeps the tool model simple enough to evolve into a richer broker later.

Why it matters:
- Tool use is the bridge between conversation and useful work.
- It also creates the control points needed for permissions and observability.

### 5. Session Event Log and Observability

The app should capture a structured history of what happened during a turn.

Description:
- Records prompts, assistant messages, tool calls, tool results, errors, and timestamps.
- Provides enough detail for debugging and later replay-style features.
- Supports future export to JSON or tracing systems.

Why it matters:
- A team app needs explainability and auditability.
- This also reduces debugging effort when agent behavior is unexpected.

### 6. Permission and Safety Layer

The app should mediate sensitive actions rather than letting the agent act without review.

Description:
- Defines which tools are always allowed, which require confirmation, and which are denied.
- Starts with simple policy rules and room for later expansion.
- Applies permission checks before tool execution.
- Returns clear user-facing reasons when an action is blocked.

Why it matters:
- Team adoption depends on predictable safety behavior.
- This is a prerequisite for shell commands, file edits, and external integrations.

### 7. Project Context Awareness

The app should operate relative to the active repository or working directory.

Description:
- Anchors file reads and searches to a project root.
- Surfaces project-relevant metadata such as the current path or session scope.
- Leaves room for later git-aware features like diff summaries and PR support.

Why it matters:
- Coding agents need a strong sense of where they are operating.
- Project scoping prevents ambiguous or unsafe behavior.

### 8. Multiple Operating Modes

The app should eventually support different modes of operation depending on user intent.

Description:
- Default mode for normal assistance.
- Plan mode for analysis-first behavior with no mutations.
- Headless mode for automation and scripting.
- Future auto/accept-edits style modes once permissions and policies are mature.

Why it matters:
- Different tasks need different safety and UX defaults.
- Mode boundaries make the app easier to trust and reason about.

### 9. Configurable Instructions and Team Defaults

The app should support shared behavioral guidance without hardcoding everything into the
runtime.

Description:
- Supports project-level instructions later on.
- Leaves room for user-level preferences and local overrides.
- Encourages standard team behavior without blocking local experimentation.

Why it matters:
- Teams need consistency.
- The app will be easier to adopt if repo-specific expectations can be configured.

### 10. Extensibility for MCP and External Integrations

The app should be designed so external tools and integrations can be added without
rewriting the runtime.

Description:
- Keeps tool registration modular.
- Plans for local tools, remote tools, and MCP-backed servers.
- Supports future auth and configuration by scope.

Why it matters:
- Internal adoption grows when the tool can connect to GitHub, issue trackers,
  observability systems, and internal APIs.

## Future Feature Areas

These are not Phase 1 priorities but should shape architecture decisions now.

### File Editing and Patch Application

Allow the assistant to propose and eventually apply file changes with confirmation,
diff previews, and rollback-aware behavior.

### Bash / Command Execution

Add controlled terminal command execution with logging, timeouts, and permission rules.

### Search and Code Navigation

Add richer repository navigation, symbol lookup, and semantic search capabilities.

### Subagents and Parallel Work

Support specialized workers for research, code review, or verification tasks.

### Worktree Isolation

Allow isolated parallel work on separate branches or worktrees.

### MCP Server Management

Allow project-scoped and user-scoped external tool connections.

### Automation and Headless Runs

Support `-p` style prompt execution, JSON output, and CI-friendly runs.

## Suggested Release Shape

### Phase 1

Focus on the minimum useful shell:
- interactive CLI shell
- session persistence
- streaming assistant output
- basic event logging
- simple read-only tool use

### Phase 2

Add controlled action capability:
- file editing
- command execution
- permission prompts
- better repo navigation

### Phase 3

Add team-scale features:
- config scopes
- external tools and MCP
- subagents
- automation and workflow integration

## Success Criteria

The first useful version of the app should let a developer:

- open a CLI in a repo
- ask a question and see streamed output
- have the agent read project files through tools
- close the CLI and resume the same session later
- understand what happened during the turn from saved session data

If those behaviors feel solid, the app will have a credible foundation for the more
advanced Claude Code-style capabilities.