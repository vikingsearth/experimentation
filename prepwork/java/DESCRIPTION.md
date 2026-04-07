# Java Project Structure — A Guide for Python/TypeScript Developers

If you've never touched Java, this file explains every directory, file, and concept
in this project, mapped to things you already know from Python and TypeScript.

---

## The Big Picture

In Python, you write `agent.py` and run `python agent.py`. In TypeScript, you write
`agent.ts` and run `npx tsx agent.ts`. In Java, you:

1. Write `.java` source files in a specific directory structure
2. **Compile** them to `.class` bytecode files (`mvn compile`)
3. **Run** the compiled bytecode (`mvn exec:java`)

Maven handles both steps. Think of it as `pip` + `tsc` + a project runner combined.

---

## Directory-by-Directory Walkthrough

```
java/
├── pom.xml                          ← Maven project descriptor (like package.json + tsconfig.json)
├── README.md                        ← How to run it
├── DESCRIPTION.md                   ← This file
├── src/                             ← All source code lives here
│   └── main/
│       └── java/
│           └── com/
│               └── techvista/
│                   ├── Agent.java           ← Entry point (like agent.py / agent.ts)
│                   └── FileReadTool.java    ← The tool the LLM can call
└── target/                          ← Build output (like __pycache__ or dist/)
    ├── classes/                     ← Compiled .class files
    └── ...                          ← Maven metadata, ignore this
```

---

## pom.xml — The Project Descriptor

**Python equivalent:** `requirements.txt` + `pyproject.toml`
**TypeScript equivalent:** `package.json` + `tsconfig.json`

This file tells Maven:

| Section | What it does | Familiar equivalent |
|---------|-------------|-------------------|
| `<groupId>` + `<artifactId>` | Project identity | `"name"` in package.json |
| `<version>` | Version number | `"version"` in package.json |
| `<properties>` | Global settings (Java version, encoding) | `"compilerOptions"` in tsconfig.json |
| `<dependencies>` | Libraries to download | `"dependencies"` in package.json / `requirements.txt` |
| `<build><plugins>` | Build/run plugins | `"scripts"` in package.json |

### Dependencies in this project:

| Dependency | What it is | Python equivalent | TS equivalent |
|-----------|-----------|-------------------|---------------|
| `langchain4j` | Core agent framework | `langchain-core` | `@langchain/core` |
| `langchain4j-open-ai` | OpenAI/Azure model connector | `langchain-openai` | `@langchain/openai` |
| `dotenv-java` | Loads `.env` files | `python-dotenv` | `dotenv` |

### Why no `langchain4j-azure-open-ai`?

We deliberately chose the OpenAI module over the Azure-specific one. The Azure module
uses **Netty** (an async networking library) which bundles its own SSL engine
(**BoringSSL**) that ignores JVM-level SSL settings. Behind a corporate proxy
(Netskope), that means it can't be told to trust the proxy's certificate.

The OpenAI module uses **OkHttp** instead, which respects `SSLContext.setDefault()`.
Since the Azure AI Foundry endpoint is OpenAI-API-compatible anyway, this works
fine — we just point the base URL at Foundry.

---

## src/main/java/com/techvista/ — The Source Code

### Why so many nested directories?

Java requires a directory structure that mirrors the **package name**. The package is
`com.techvista`, so the files live in `com/techvista/`.

The `src/main/java/` prefix is a Maven convention (like how `src/` is conventional in
TypeScript projects or `src/` in Python packages). Maven expects source code here.

**Translation:**

| Java | Python | TypeScript |
|------|--------|------------|
| `src/main/java/com/techvista/Agent.java` | `src/agent.py` | `src/agent.ts` |
| `package com.techvista;` (first line) | being in the `src/` directory | N/A |

### Agent.java — Entry Point

**Python equivalent:** `agent.py`
**TypeScript equivalent:** `agent.ts`

Key Java concepts for Python/TS developers:

#### `public class Agent` — The container
Java requires every file to have exactly one public class, named the same as the file.
Think of it like Python's module system, but stricter.

#### `interface Assistant` — The agent contract
```java
interface Assistant {
    @SystemMessage("...")
    String chat(String userMessage);
}
```
This is like a Python `Protocol` or a TypeScript `interface`. LangChain4J's magic is
that you never implement this yourself — `AiServices.builder()` creates a proxy object
that implements it by calling the LLM. When you call `assistant.chat("question")`,
it actually sends a request to the model.

**Python equivalent:** LangGraph's `create_react_agent()` returns a runnable graph.
**TypeScript equivalent:** LangGraph.js's `createReactAgent()` does the same.

In Java, the pattern is different — you define an interface and the framework creates
the implementation at runtime. This is called the **proxy pattern**.

#### `@SystemMessage` — The system prompt
An annotation (decorator in Python terms) that attaches the system prompt. Annotations
in Java are like Python `@decorators` — metadata attached to a method or class.

#### `public static void main(String[] args)` — The entry point
Every Java program starts here. It's verbose, but this is the equivalent of:
- Python: `if __name__ == "__main__":`
- TypeScript: the top-level code in `agent.ts`

#### SSL Workaround Block
The `TrustManager` / `SSLContext` block at the top of `main()` is the Java equivalent
of the Python `httpx.Client(verify=False)` patch or Node's
`NODE_TLS_REJECT_UNAUTHORIZED=0`. It tells the JVM to accept all SSL certificates.

#### Builder Pattern
```java
OpenAiChatModel.builder()
    .baseUrl(...)
    .apiKey(...)
    .build();
```
Java doesn't have keyword arguments like Python (`OpenAiChatModel(base_url=..., api_key=...)`).
Instead, it uses the **builder pattern**: chain `.property(value)` calls, then `.build()`.
This is extremely common in Java — you'll see it everywhere.

### FileReadTool.java — The LLM Tool

**Python equivalent:** the `@tool` decorated function in `agent.py`
**TypeScript equivalent:** the `tool()` call in `agent.ts`

#### `@Tool("description")` — Registers the method as an LLM tool
LangChain4J reads this annotation and generates the JSON function schema that gets
sent to the LLM in the `tools` array of the chat completion request. The LLM sees
the description and decides when to call it.

#### `@P("description")` — Describes a parameter
Short for "Parameter". LangChain4J uses this to build the JSON schema `properties`
for the tool's parameters.

**Python equivalent:** The `@tool` decorator reads the function docstring and type hints.
**TypeScript equivalent:** The `zod` schema you pass to `tool()`.

#### Path traversal protection
```java
Path target = dataDir.resolve(path).toAbsolutePath().normalize();
if (!target.startsWith(dataDir)) { ... }
```
Same logic in all three languages — resolve the path, then verify it's still inside
the allowed directory. Prevents the LLM from being tricked into reading
`../../etc/passwd`.

---

## target/ — Build Output

**Python equivalent:** `__pycache__/` (compiled `.pyc` files)
**TypeScript equivalent:** `dist/` (compiled `.js` files)

Maven compiles `.java` files into `.class` bytecode files and puts them here.
This directory is gitignored. You never edit anything in it.

---

## How the Agent Loop Works

```
                 ┌─────────┐
User question →  │  Agent  │ → (LLM decides to call readFile)
                 └────┬────┘
                      │
                 ┌────▼────┐
                 │  Tool   │ → reads company-faq.txt or product-docs.txt
                 └────┬────┘
                      │
                 ┌────▼────┐
                 │  Agent  │ → LLM gets file contents, writes cited answer
                 └────┬────┘
                      │
              Final answer ← with source citations
```

LangChain4J's `AiServices` handles this loop internally. You call `assistant.chat()`,
it returns the final string after however many tool calls the LLM needed.

This is less visible than the Python/TS versions where you stream each step.
The trade-off: simpler code, but less visibility into intermediate steps.

---

## Key Differences from Python/TypeScript Implementations

| Aspect | Python (LangGraph) | TypeScript (LangGraph.js) | Java (LangChain4J) |
|--------|-------------------|--------------------------|-------------------|
| Agent pattern | `create_react_agent()` | `createReactAgent()` | `AiServices.builder()` |
| Tool definition | `@tool` decorator | `tool()` function + zod | `@Tool` annotation + `@P` |
| Agent loop | Explicit graph, streamable | Explicit graph, streamable | Hidden behind proxy |
| HTTP client | httpx (patched) | Node fetch | OkHttp |
| SSL workaround | Patch httpx Client/AsyncClient | `NODE_TLS_REJECT_UNAUTHORIZED=0` | `SSLContext.setDefault()` |
| Run command | `python agent.py` | `npx tsx agent.ts` | `mvn compile exec:java` |
| Package manager | pip | npm | Maven |
| Type system | Optional (type hints) | Structural (duck typing) | Nominal (strict) |
