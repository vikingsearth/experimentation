# Phase 1 Development Plan

## Scope

Phase 1 is limited to three foundational capabilities:

- CLI shell
- session persistence
- streaming

The goal is not to build a full coding agent yet. The goal is to build the runtime shell
that later features can plug into safely.

## Phase 1 Objectives

By the end of Phase 1, the app should:

- launch from the terminal inside a project directory
- accept a user prompt in an interactive shell
- call the model and stream output incrementally
- save session data locally after each turn
- resume an earlier session with enough context to continue naturally
- expose a clean internal event flow for later tooling and permissions

## Non-Goals

These items should stay out of Phase 1 unless they are needed to unblock the core shell.

- file editing
- bash execution
- permission prompts beyond simple placeholders
- worktrees
- MCP integration
- subagents
- advanced TUI features

## Deliverables

### 1. CLI Entry Point

A TypeScript command that starts the application and enters an interactive session.

Expected behavior:
- starts in the current working directory
- loads or creates a session
- prints a prompt and accepts input
- supports clean exit behavior

### 2. Streaming Response Pipeline

A runtime path that sends a user message to the model and streams tokens or chunks back
to the terminal.

Expected behavior:
- assistant output appears progressively
- errors are surfaced cleanly
- operational events can be displayed separately from assistant text

### 3. Session Store

A local persistence layer that saves and loads session state from disk.

Expected behavior:
- every session has an id
- message history is persisted
- basic metadata such as timestamps and cwd is persisted
- the latest session can be resumed

### 4. Event Model

A minimal internal event model that normalizes the lifecycle of a turn.

Expected behavior:
- one turn can be traced from prompt submission to completion
- the app can persist the event history and optionally render it
- future tool and permission hooks can plug into the same event flow

## Proposed Architecture

### Layer 1. CLI Shell

Responsibilities:
- read user input
- render streaming output
- surface status and errors
- dispatch commands such as exit and resume

Possible concerns:
- prompt handling
- terminal cleanup
- handling Ctrl+C without corrupting session state

### Layer 2. Session Manager

Responsibilities:
- create sessions
- load sessions from disk
- append messages and events
- coordinate resume behavior

Possible storage model:
- one directory per session
- a transcript file for messages/events
- a small metadata file for lookup and summaries

### Layer 3. Agent Runtime

Responsibilities:
- accept user input plus session context
- invoke the model
- stream assistant output events
- later support tool calls without redesigning the shell

### Layer 4. Persistence Adapter

Responsibilities:
- hide filesystem details from the runtime
- support atomic-ish writes where practical
- make future migration to another store possible

## Suggested Data Model

### Session Metadata

Fields to capture:
- session id
- optional session name
- created at
- updated at
- current working directory
- model identifier
- status

### Messages

Fields to capture:
- message id
- role
- content
- created at
- turn id

### Events

Fields to capture:
- event id
- session id
- turn id
- type
- timestamp
- payload

Suggested early event types:
- `session.started`
- `prompt.submitted`
- `model.stream.started`
- `model.stream.chunk`
- `model.stream.completed`
- `turn.completed`
- `turn.failed`

## CLI Shell Plan

### User Experience

Keep the first shell simple.

Recommended commands:
- plain text input sends a prompt to the agent
- `/exit` closes the shell cleanly
- `/resume` resumes the latest session or shows a simple selector later
- `/new` starts a fresh session
- `/help` shows supported commands

Recommended display behavior:
- show a short startup banner
- show current session id or name
- render streamed assistant text without excessive chrome
- render status lines for non-message events

### Implementation Notes

- Start with standard input/output, not a full terminal UI library.
- Keep the rendering logic separate from the runtime logic.
- Treat shell commands as parsed control messages, not as prompts.

## Streaming Plan

### Goals

- make long responses visible immediately
- keep the terminal responsive
- preserve a clean boundary between partial output and committed transcript data

### Strategy

- stream chunks from the model provider
- buffer assistant text while also printing it to the terminal
- only persist the final assistant message after stream completion
- persist stream lifecycle events as they happen

### Edge Cases

- interrupted stream from user cancel
- provider/network failure mid-stream
- empty response
- partial output that should still be visible in logs for debugging

## Session Persistence Plan

### Storage Approach

Use local JSON files for Phase 1.

Suggested layout:

```text
sessions/
  index.json
  <session-id>/
    meta.json
    transcript.jsonl
```

Why this shape:
- simple to inspect manually
- append-friendly transcript format
- easy to migrate later

### Persistence Rules

- create the session before the first turn starts
- append user messages immediately
- append runtime events during processing
- append the finalized assistant message when streaming completes
- update `meta.json` after each turn

### Resume Rules

- latest session resume is enough for Phase 1
- if the transcript is corrupt, fail safely and allow a new session
- load the message history needed for the next model call

## Milestones

### Milestone 1. Bootstrap the Shell

Target outcome:
- app starts
- reads input
- exits cleanly

### Milestone 2. Add Streaming Model Calls

Target outcome:
- user prompt produces streaming assistant output
- runtime can distinguish between stream chunks and final turn completion

### Milestone 3. Persist Sessions

Target outcome:
- sessions are written locally
- restarting the app can reload the latest session

### Milestone 4. Harden the Turn Lifecycle

Target outcome:
- errors do not corrupt session state
- interrupted runs are visible in logs
- event flow is stable enough for Phase 2 extensions

## Risks

### 1. Mixing Rendering With Runtime Logic

Risk:
- streaming code becomes hard to maintain if terminal output is tightly coupled to model events

Mitigation:
- define internal events first, then render from those events

### 2. Fragile Persistence Format

Risk:
- ad hoc JSON blobs become hard to evolve

Mitigation:
- establish stable message/event envelopes early

### 3. Resume Semantics Drift

Risk:
- the data saved to disk is not enough to restore meaningful context

Mitigation:
- design resume around explicit stored messages and session metadata, not in-memory assumptions

### 4. Provider Streaming Differences

Risk:
- model provider APIs may emit chunks in shapes that do not map cleanly to the app

Mitigation:
- normalize provider events into an internal stream event contract

## Definition of Done

Phase 1 is done when all of the following are true:

- a developer can run the CLI from the terminal
- prompts stream live output to the shell
- the session is saved on disk automatically
- the latest session can be resumed in a new process
- failures are recorded without breaking future sessions
- the code structure leaves a clean place to add tools and permissions next

## Next Step After Phase 1

Once these foundations are stable, Phase 2 should add read-only tools first, then
controlled file edits and permission handling. That order keeps the runtime moving toward
a real coding assistant without overloading the first milestone.