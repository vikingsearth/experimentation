# TypeScript Project Structure — For Python Developers

You know TypeScript already, so this file focuses on the LangChain.js-specific
patterns and highlights where this version differs from the Python and Java agents.

---

## Directory Walkthrough

```
typescript/
├── agent.ts            ← The entire agent in one file
├── package.json        ← Dependencies + scripts (like requirements.txt + pyproject.toml)
├── package-lock.json   ← Exact dependency versions (like pip freeze output)
└── node_modules/       ← Installed packages (like .venv/, gitignored)
```

Same simplicity as the Python version — one source file, no build step needed
(tsx runs `.ts` files directly).

---

## package.json — Dependencies

| Package | What it does | Python equivalent | Java equivalent |
|---------|-------------|-------------------|-----------------|
| `@langchain/openai` | OpenAI/Azure LLM connector | `langchain-openai` | `langchain4j-open-ai` |
| `@langchain/langgraph` | Agent graph framework | `langgraph` | `langchain4j` (AiServices) |
| `@langchain/core` | Core types and utilities | `langchain-core` | `langchain4j` |
| `dotenv` | Loads `.env` files | `python-dotenv` | `dotenv-java` |
| `zod` | Schema validation for tool params | Type hints + docstrings | `@P` annotations |
| `tsx` (dev) | Runs .ts directly, no build step | N/A (Python runs .py directly) | N/A (Java always compiles) |

---

## agent.ts — The Entire Agent

### Structure Overview

The file follows the same five-section structure as the Python version:

```
1. Imports              ← Node builtins + LangChain packages
2. Config               ← Load .env, set constants
3. Tool definition      ← tool() with Zod schema
4. LLM setup            ← ChatOpenAI with custom baseURL
5. Agent + main()       ← createReactAgent + async streaming loop
```

### Key Concepts (mapped to Python and Java)

#### `tool()` function — Registers a function as an LLM tool
```typescript
const readFileTool = tool(
  async ({ path }) => { ... },
  {
    name: "read_file",
    description: "Read the contents of a file...",
    schema: z.object({ path: z.string().describe("...") }),
  }
);
```

Three things define a tool: the function, its name/description, and a Zod schema
for the parameters. The schema is converted to JSON Schema and sent to the LLM.

- **Python equivalent:** `@tool` decorator — reads the docstring and type hints
  to auto-generate the schema. Less explicit, more magic.
- **Java equivalent:** `@Tool("description")` on a method + `@P("description")`
  on parameters. The framework inspects the method signature at runtime.

**Why Zod?** LangChain.js uses Zod because TypeScript's type system is erased at
runtime — there's no way to inspect `{ path: string }` at runtime like Python can
inspect type hints. Zod schemas survive compilation and describe types at runtime.

#### `createReactAgent()` — Builds the agent graph
```typescript
const agent = createReactAgent({ llm, tools: [readFileTool], prompt: SYSTEM_PROMPT });
```

Identical semantics to Python's `create_react_agent()`. Creates a graph with
`agent` and `tools` nodes that loop until the LLM is done.

#### `for await...of` streaming — Async iteration
```typescript
const stream = await agent.stream({ messages: [...] });
for await (const step of stream) { ... }
```

- **Python equivalent:** `for step in agent.stream({...}):` — sync iteration
  (LangGraph Python handles the async internally).
- **Java equivalent:** No streaming. `assistant.chat()` blocks and returns
  the final answer.

### LLM Configuration — Why `ChatOpenAI` (not `AzureChatOpenAI`)?

```typescript
const llm = new ChatOpenAI({
  configuration: {
    baseURL: `${AZURE_BASE_URL}/models`,
    defaultHeaders: { "api-key": AZURE_API_KEY },
  },
  apiKey: AZURE_API_KEY,
  modelName: MODEL_NAME,
  modelKwargs: { max_completion_tokens: 1024 },
});
```

Azure AI Foundry's endpoint uses `/models/chat/completions`, not the standard
Azure OpenAI path `/openai/deployments/{name}/chat/completions`. The LangChain.js
`AzureChatOpenAI` wrapper constructed the wrong URL, so we use `ChatOpenAI` and
override the `baseURL` manually.

- **Python:** `AzureChatOpenAI` worked because langchain-openai's Python version
  handles the Foundry URL pattern correctly.
- **Java:** Same problem — used `OpenAiChatModel` with manual `baseUrl` instead
  of `AzureOpenAiChatModel`.

### `max_completion_tokens` vs `max_tokens`

```typescript
modelKwargs: { max_completion_tokens: 1024 },
```

The gpt-5.4 model rejects the older `max_tokens` parameter and requires
`max_completion_tokens`. Since `ChatOpenAI` doesn't have a dedicated property
for this, we pass it via `modelKwargs` which adds it to the request body.

- **Python:** `AzureChatOpenAI(max_tokens=1024)` — worked because the Python
  wrapper translates `max_tokens` to the correct parameter internally.
- **Java:** `OpenAiChatModel.builder().maxCompletionTokens(1024)` — explicit
  builder method available.

### SSL Workaround

```bash
NODE_TLS_REJECT_UNAUTHORIZED=0 npx tsx agent.ts "..."
```

The simplest of all three. Node.js respects this environment variable globally,
disabling TLS certificate verification for all outgoing HTTPS connections.
No code changes needed.

- **Python:** Must monkey-patch `httpx.Client` and `httpx.AsyncClient` *before*
  importing LangChain/OpenAI. More invasive.
- **Java:** Must set `SSLContext.setDefault()` in code, and it only works with
  OkHttp-based clients (not Netty).

---

## node_modules/ — Installed Packages

**Python equivalent:** `.venv/lib/python3.x/site-packages/`
**Java equivalent:** `~/.m2/repository/` (global cache, not per-project)

Contains all installed npm packages. Gitignored. Recreated by `npm install`.

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

Same graph as Python. The streaming loop prints each step:
```
[calling tool: read_file({"path":"product-docs.txt"})]
[tool: read_file] returned 1330 chars

Answer:
CodeLens is TechVista's flagship AI code review assistant...
```

---

## Key Differences from Python/Java Implementations

| Aspect | Python (LangGraph) | TypeScript (LangGraph.js) | Java (LangChain4J) |
|--------|-------------------|--------------------------|-------------------|
| Files | 1 (`agent.py`) | 1 (`agent.ts`) | 2 (`Agent.java` + `FileReadTool.java`) |
| Tool schema | Docstring + type hints | Zod object (explicit) | `@Tool` + `@P` annotations |
| LLM class | `AzureChatOpenAI` | `ChatOpenAI` (manual baseURL) | `OpenAiChatModel` (manual baseUrl) |
| max tokens | `max_tokens=1024` (auto-translated) | `modelKwargs: { max_completion_tokens }` | `.maxCompletionTokens(1024)` |
| Streaming | `for step in agent.stream()` | `for await (const step of stream)` | Not available |
| SSL workaround | Monkey-patch httpx | Env variable (simplest) | SSLContext in main() |
| Run command | `python agent.py` | `npx tsx agent.ts` | `mvn compile exec:java` |
| Build step | None | None (tsx) | Required (`mvn compile`) |
| Package lock | No (pip has pip.lock optionally) | `package-lock.json` | `pom.xml` (versions in XML) |
