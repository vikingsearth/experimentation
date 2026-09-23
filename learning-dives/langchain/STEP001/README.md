# STEP001 — Under the Hood

## What this step does

Sends one message to an LLM through LangChain and prints the reply. That's it.  
No chains, no memory, no agents — just the raw, fundamental interaction.

---

## What LangChain actually is

LangChain is a **composition framework**. Its job is to give you consistent,
reusable abstractions over the messy reality of LLM providers, APIs, and output
formats so you can wire them together in predictable ways.

At the very bottom of that abstraction stack sits the **chat model**.

---

## The chat model abstraction

Every LLM in LangChain implements the `BaseChatModel` interface. At its core,
that interface is a single method:

```
invoke(messages) → AIMessage
```

That one method hides:

1. **HTTP transport** — building the JSON body, setting auth headers, sending
   the request to the provider's REST endpoint and waiting for the response.
2. **Schema normalisation** — mapping the provider's response format back into
   LangChain's own `AIMessage` type so your code doesn't care which provider
   you're talking to.
3. **Retry / back‑off** — transient error handling (rate limits, timeouts).

When you call `llm.invoke(messages)`, the execution path looks like this:

```
your code
  │
  └── BaseChatModel.invoke()
        │
        └── AzureAIOpenAIApiChatModel._generate()   ← provider‑specific
              │
              └── azure-ai-inference ChatCompletionsClient.complete()
                    │
                    └── HTTPS POST → Azure AI Foundry endpoint
                          │
                          └── JSON response → AIMessage
```

---

## Messages

LangChain uses a typed message system to represent conversation turns:

| Class | Role | When to use |
|---|---|---|
| `SystemMessage` | `system` | Instructions / persona for the model |
| `HumanMessage` | `user` | Input from the caller |
| `AIMessage` | `assistant` | The model's reply |
| `ToolMessage` | `tool` | Result returned from a tool call |

In STEP001 we send a single `HumanMessage` — the simplest possible conversation.

---

## What `AzureAIOpenAIApiChatModel` wraps

`langchain-azure-ai` wraps Microsoft's `azure-ai-inference` SDK.  
That SDK targets the **Azure AI Foundry** inference endpoint — a unified API
that can serve many different model families (OpenAI GPT-n, Mistral, Phi,
DeepSeek, Cohere, etc.) through one consistent URL shape.

The authentication abstraction is provided by `azure-core`:

- `AzureKeyCredential` — wraps an API key string and injects it as the
  `api-key` header on every request.
- `DefaultAzureCredential` — chains through several identity sources
  (env, managed identity, VS Code, CLI…) for keyless/passwordless auth.

In STEP001 we use `AzureKeyCredential` because the env file already contains
a raw API key.

---

## The `find_dotenv()` trick

`find_dotenv()` (from `python-dotenv`) walks up the directory tree from the
current working directory until it finds a `.env` file.  
This means you can run `python main.py` from *any* directory within the project
and it will always locate `learning-dives/.env` without hardcoding a path.

---

## What happens at runtime (line by line)

1. `load_dotenv(find_dotenv())` — reads `learning-dives/.env` into
   `os.environ`.
2. The three `os.environ[]` reads pull out the endpoint URL, API key, and
   model name. Raising `KeyError` if any are missing is **intentional** —
   failing loudly at startup > failing mysteriously later.
3. `AzureAIOpenAIApiChatModel(...)` — creates the client. No network call
   happens here; this is just configuration.
4. `[HumanMessage(...)]` — creates a list of one message. LangChain always
   works with lists of messages, even for a single turn, because the underlying
   API is always a conversation.
5. `llm.invoke(messages)` — the only network call. Blocks until the model
   replies.
6. `response.content` — the raw string text of the model's reply. `AIMessage`
   also carries `.response_metadata` (token counts, stop reason, model name)
   and `.tool_calls` (empty here) if you need them later.
