# TypeScript Agent — LangGraph.js + Azure AI Foundry

A minimal AI agent that takes a user question, reads local knowledge base files via a tool call, and returns a grounded answer with citations.

## Prerequisites

- Node.js 18+
- Azure AI Foundry API key in `../prepwork/.env`

## Setup

```bash
cd prepwork/typescript
npm install
```

## Run

```bash
NODE_TLS_REJECT_UNAUTHORIZED=0 npx tsx agent.ts "What is CodeLens and how much does it cost?"
```

The `NODE_TLS_REJECT_UNAUTHORIZED=0` is needed behind the corporate proxy (Netskope). Remove it on a clean network.

## How It Works

1. Loads config from `../.env` (Azure AI Foundry URL + API key)
2. Builds a `ChatOpenAI` LLM with a custom `baseURL` pointing at the Foundry endpoint
3. Defines a `read_file` tool that reads files from `../data/`
4. LangGraph.js's `createReactAgent` builds a ReAct agent graph:
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
