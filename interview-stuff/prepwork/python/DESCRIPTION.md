# Python Project Structure — The Familiar Baseline

This is your home turf. This file maps every file and concept in this project
so you have a reference point when comparing against the TypeScript and Java versions.

---

## Directory Walkthrough

```
python/
├── agent.py           ← The entire agent in one file
├── requirements.txt   ← Dependencies (pip install -r requirements.txt)
└── .venv/             ← Virtual environment (gitignored)
```

That's it. No build step, no nested directories, no ceremony. This is the simplest
of the three implementations.

---

## requirements.txt — Dependencies

| Package | What it does | TS equivalent | Java equivalent |
|---------|-------------|---------------|-----------------|
| `langchain-openai` | Azure/OpenAI LLM connector | `@langchain/openai` | `langchain4j-open-ai` |
| `langgraph` | Agent graph framework | `@langchain/langgraph` | `langchain4j` (AiServices) |
| `python-dotenv` | Loads `.env` files | `dotenv` | `dotenv-java` |

---

## agent.py — The Entire Agent

### Structure Overview

The file flows top-to-bottom in five sections:

```
1. SSL workaround      ← Corporate proxy fix (lines 30–58)
2. Config               ← Load .env, set constants (lines 60–73)
3. Tool definition      ← @tool read_file function (lines 75–90)
4. LLM setup            ← AzureChatOpenAI instance (lines 92–102)
5. Agent + main()       ← create_react_agent + streaming loop (lines 104–140)
```

### Key Concepts (mapped to TS and Java)

#### `@tool` decorator — Registers a function as an LLM tool
```python
@tool
def read_file(path: str) -> str:
    """Read the contents of a file in the data/ directory..."""
```
LangChain reads the function name, type hints, and **docstring** to build the
JSON function schema sent to the LLM.

- **TypeScript equivalent:** `tool(fn, { name, description, schema: z.object(...) })`
  — more explicit; uses Zod for the schema instead of docstrings.
- **Java equivalent:** `@Tool("description")` on a method + `@P("description")`
  on each parameter. Same idea, but annotations instead of decorators.

#### `create_react_agent()` — Builds the agent graph
```python
agent = create_react_agent(model=llm, tools=[read_file], prompt=SYSTEM_PROMPT)
```
This creates a LangGraph `StateGraph` with two nodes:
- **agent** — calls the LLM
- **tools** — executes tool calls

The graph loops: agent → tools → agent → … until the LLM produces a final
text response (no more tool calls).

- **TypeScript equivalent:** Identical — `createReactAgent({ llm, tools, prompt })`
- **Java equivalent:** `AiServices.builder(Assistant.class).chatLanguageModel(model).tools(tool).build()`
  — same loop, but hidden behind a proxy object instead of an explicit graph.

#### `agent.stream()` — Streaming execution
```python
for step in agent.stream({"messages": [("user", question)]}):
    for node_name, output in step.items():
        ...
```
Each step yields a dict keyed by the graph node that produced it (`"agent"` or `"tools"`).
This lets you print tool calls as they happen before the final answer arrives.

- **TypeScript equivalent:** `for await (const step of stream) { ... }` — same pattern,
  async iteration instead of sync.
- **Java equivalent:** No streaming in the LangChain4J version. `assistant.chat()`
  blocks and returns the final answer directly. Trade-off: simpler code, less visibility.

### SSL Workaround

```python
httpx.Client = _PatchedClient       # verify=False
httpx.AsyncClient = _PatchedAsync    # verify=False
```

The OpenAI SDK uses `httpx` for HTTP requests. Behind the Netskope corporate proxy,
SSL verification fails because the proxy presents a self-signed certificate.
We monkey-patch both sync and async httpx clients *before* importing openai/langchain.

- **TypeScript equivalent:** `NODE_TLS_REJECT_UNAUTHORIZED=0` environment variable
  — Node.js respects this globally, no code changes needed.
- **Java equivalent:** `SSLContext.setDefault()` with a TrustAll manager in `main()`.
  Only works with OkHttp (OpenAI module), not Netty (Azure module).

### Why `AzureChatOpenAI` (not `ChatOpenAI`)?

`AzureChatOpenAI` from `langchain-openai` knows how to construct Azure-style URLs
(`{endpoint}/openai/deployments/{model}/chat/completions?api-version=...`). It handles
the API version parameter and authentication header automatically.

In TypeScript, we used `ChatOpenAI` with a manual `baseURL` override instead because
the LangChain.js `AzureChatOpenAI` wrapper was routing to the wrong path for Foundry.
In Java, we used `OpenAiChatModel` for the same reason plus the Netty SSL issue.

---

## .venv/ — Virtual Environment

**TypeScript equivalent:** `node_modules/`
**Java equivalent:** `~/.m2/repository/` (Maven's global cache — not per-project)

Created by `python -m venv .venv`. Contains installed packages. Gitignored.

---

## How the Agent Loop Works

```
                 ┌─────────┐
User question →  │  agent  │ → LLM decides to call read_file
                 └────┬────┘
                      │
                 ┌────▼────┐
                 │  tools  │ → reads company-faq.txt or product-docs.txt
                 └────┬────┘
                      │
                 ┌────▼────┐
                 │  agent  │ → LLM gets file contents, writes cited answer
                 └────┬────┘
                      │
              Final answer ← with source citations
```

The streaming loop prints each step as it happens, so you see:
```
[calling tool: read_file({'path': 'product-docs.txt'})]
[tool: read_file] returned 1330 chars

Answer:
CodeLens is TechVista's flagship AI code review assistant...
```

---

## Key Differences from TypeScript/Java Implementations

| Aspect | Python (LangGraph) | TypeScript (LangGraph.js) | Java (LangChain4J) |
|--------|-------------------|--------------------------|-------------------|
| Files | 1 (`agent.py`) | 1 (`agent.ts`) | 2 (`Agent.java` + `FileReadTool.java`) |
| Tool definition | `@tool` + docstring | `tool()` + Zod schema | `@Tool` + `@P` annotations |
| Schema source | Docstring + type hints | Explicit Zod object | Annotation strings |
| Agent loop | Explicit graph, streamable | Explicit graph, streamable | Hidden behind proxy |
| Streaming | `for step in agent.stream()` | `for await (const step of stream)` | Not available |
| SSL workaround | Monkey-patch httpx | Env variable | SSLContext in main() |
| Run command | `python agent.py` | `npx tsx agent.ts` | `mvn compile exec:java` |
| Build step | None | None (tsx) | Required (`mvn compile`) |
