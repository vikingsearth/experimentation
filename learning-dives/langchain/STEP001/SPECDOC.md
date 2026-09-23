# SPECDOC — STEP001 Specifics

## Goal

Execute the single simplest possible LangChain operation:  
construct a chat model, send it one message, receive and print the reply.

---

## Dependencies

| Package | Version pinning | Purpose |
|---|---|---|
| `langchain` | latest | Core abstractions (BaseMessage, Runnable, etc.) |
| `langchain-azure-ai` | latest | Azure AI Foundry provider integration |
| `azure-core` | latest | `AzureKeyCredential` credential wrapper |
| `python-dotenv` | latest | `.env` file loading |

Install / sync:

```bash
cd learning-dives/langchain/STEP001
uv sync
```

---

## Environment variables

Defined in `learning-dives/.env`.

| Variable | Description | Example |
|---|---|---|
| `AZURE_AI_BASE_URL` | Azure AI Foundry project endpoint | `https://xxx.services.ai.azure.com` |
| `AZURE_AI_API_KEY` | API key for the Foundry project | `48Jx...` |
| `AZURE_AI_MODEL` | Deployment / model name | `gpt-5-4` |

---

## Key imports

```python
from langchain_azure_ai.chat_models import AzureAIOpenAIApiChatModel
from azure.core.credentials import AzureKeyCredential
from langchain_core.messages import HumanMessage
```

- `AzureAIOpenAIApiChatModel` — the Azure AI Foundry chat model class.
  Lives in the `langchain-azure-ai` integration package (not `langchain-openai`).
- `AzureKeyCredential` — wraps a raw API key string into the `azure-core`
  credential protocol. The LangChain integration accepts this directly.
- `HumanMessage` — from `langchain-core`, the base `langchain` package delegates
  to `langchain-core` for all message primitives.

---

## Model instantiation

```python
llm = AzureAIOpenAIApiChatModel(
    endpoint=endpoint,        # full base URL of the Foundry project
    credential=AzureKeyCredential(api_key),
    model=model,              # deployment name as configured in Foundry
)
```

No network call is made here. The client is configured but idle.

---

## Invocation

```python
response = llm.invoke([HumanMessage(content="...")])
print(response.content)       # str — the text of the model's reply
```

`response` is an `AIMessage`. Useful fields:

| Field | Type | Description |
|---|---|---|
| `.content` | `str` | The text reply |
| `.response_metadata` | `dict` | Token counts, stop reason, model ID |
| `.tool_calls` | `list` | Populated only if the model returned tool calls |
| `.id` | `str` | Unique message ID assigned by the provider |

---

## Running the step

```bash
cd learning-dives/langchain/STEP001
uv sync
uv run main.py
```

Expected output (content varies):

```
Model response:
Hello! I'm GPT-5-4, a large language model created by OpenAI and ...
```

---

## What this step does NOT cover

- Streaming responses (`.stream()`)
- System messages / persona
- Multi-turn conversation history
- Prompt templates
- Output parsers
- Error handling / retries

All of those come in later STEPs.
