# Python Agent — LangGraph + Azure AI Foundry

A minimal AI agent that takes a user question, reads local knowledge base files via a tool call, and returns a grounded answer with citations.

## Prerequisites

- Python 3.10+
- Azure AI Foundry API key in `../prepwork/.env`

## Setup

```bash
cd prepwork/python
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Run

```bash
source .venv/bin/activate
python agent.py "What is CodeLens and how much does it cost?"
```

## How It Works

1. Loads config from `../.env` (Azure AI Foundry URL + API key)
2. Builds an `AzureChatOpenAI` LLM pointed at the Foundry endpoint
3. Defines a `read_file` tool that reads files from `../data/`
4. LangGraph's `create_react_agent` builds a ReAct agent graph:
   - User asks a question
   - LLM decides to call `read_file("company-faq.txt")` or `read_file("product-docs.txt")`
   - Tool returns file contents
   - LLM synthesizes a cited answer
5. Streams each step so you can see tool calls as they happen

## Data Files

Located in `../data/` (shared across Python, TypeScript, and Java implementations):

| File | Contents |
|------|----------|
| `company-faq.txt` | TechVista company background, leadership, policies |
| `product-docs.txt` | CodeLens product docs, features, pricing, API |
