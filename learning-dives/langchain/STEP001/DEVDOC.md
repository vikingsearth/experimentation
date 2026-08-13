# DEVDOC — Patterns, Standards & Principles

## Project layout convention

Each STEP is a **self-contained Python project**. It carries its own
`pyproject.toml` (dependencies, metadata) and can be run with a fresh
`uv` virtual environment. Nothing leaks between steps.

---

## Dependency management — `uv`

We use `uv` throughout. Core commands:

```bash
# Create a venv and install declared dependencies
uv sync

# Run the script inside the managed venv without activating it
uv run main.py

# Add a new dependency and update pyproject.toml
uv add some-package
```

`uv` is preferred over plain `pip` + `venv` because it is significantly
faster and keeps `pyproject.toml` as the single source of truth.

---

## Secret management — never hardcode

**Rule:** credentials never appear in source code.

All secrets live in `learning-dives/.env`. Steps load them with
`python-dotenv`:

```python
from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv())
```

`find_dotenv()` searches parent directories, so the path is never
hardcoded and the script works regardless of the working directory.

Access secrets via `os.environ["KEY"]` (not `os.getenv`). Using `[]`
raises `KeyError` immediately if a variable is missing, making
misconfiguration visible at startup rather than as a runtime mystery.

---

## LangChain interface pattern — "Runnable"

Every core LangChain component (`ChatModel`, `Prompt`, `OutputParser`,
`Retriever`, `Tool`, …) implements the **Runnable** interface.
That interface provides a consistent set of invocation methods:

| Method | Behaviour |
|---|---|
| `.invoke(input)` | Synchronous call, returns one output |
| `.ainvoke(input)` | Async equivalent |
| `.stream(input)` | Synchronous streaming (yields chunks) |
| `.astream(input)` | Async streaming |
| `.batch(inputs)` | Run many calls in parallel |

In STEP001 we only use `.invoke()` — the simplest synchronous path.
All other methods exist on the same object and will appear in later STEPs.

---

## LangChain message model

Treat messages as **immutable value objects**. Always build a fresh list;
never mutate an existing message. This is the mental model the entire
framework is built around.

```python
# Good
messages = [SystemMessage("You are helpful."), HumanMessage("Hi")]

# Bad — mutating content in place
messages[0].content += " extra"
```

---

## `BaseChatModel` vs. `BaseLLM`

There are two model base classes in LangChain:

- `BaseLLM` — legacy text‑in / text‑out interface (a string goes in,
  a string comes out). Avoid for new work.
- `BaseChatModel` — modern chat interface (messages in, AIMessage out).
  All current provider integrations implement this.

Always use `BaseChatModel` implementations (prefixed `Chat*` or named
`*ChatModel`).

---

## Principle: thin glue code

LangChain steps should be **glue**, not logic. Keep business logic out
of the LangChain layer. The model call is infrastructure; treat it that way.
