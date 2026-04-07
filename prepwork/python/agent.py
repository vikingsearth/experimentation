# Python agent — LangGraph + Azure AI Foundry
# -------------------------------------------
# Minimal AI agent: takes a user question, uses a file-read tool
# to ground its answer in local data files, and returns a cited response.
#
# DECISIONS & REASONING (for walkthrough / interview explainability):
#
# 1. Framework: LangGraph (not raw LangChain or plain OpenAI SDK)
#    - LangGraph gives explicit control over the agent loop (tool call → observe → respond).
#    - It's the recommended way to build agents in the LangChain ecosystem as of 2025+.
#    - The graph is inspectable: you can print nodes/edges and explain every state transition.
#
# 2. LLM provider: Azure AI Foundry via the OpenAI-compatible endpoint.
#    - The Foundry endpoint follows the OpenAI chat completions spec, so we use
#      langchain_openai.AzureChatOpenAI (or the OpenAI wrapper pointed at Azure).
#    - Config comes from ../. env so all three language projects share one secret file.
#
# 3. Tool: read_file — reads a file from the local data/ directory.
#    - The task says "file read" is a valid tool choice.
#    - We restrict reads to the data/ directory to prevent path traversal (security).
#    - The tool returns the full file content so the LLM can cite specific lines.
#
# 4. Grounding & citations: The system prompt instructs the model to quote
#    the source file name and relevant passage when answering.
#
# 5. Agent loop: LangGraph's prebuilt ReAct agent handles the tool-call loop:
#    User question → LLM decides to call read_file → tool returns content →
#    LLM synthesizes a cited answer.  If no tool is needed it answers directly.

import os
import ssl
import warnings
import sys
from pathlib import Path

# ── SSL workaround (corporate proxy with self-signed cert) ─────────────────
# Must run BEFORE any httpx/openai imports.  Remove if not behind a proxy.
warnings.filterwarnings("ignore", message=".*SSL.*")
warnings.filterwarnings("ignore", message=".*Unverified HTTPS.*")
ssl._create_default_https_context = ssl._create_unverified_context
os.environ["CURL_CA_BUNDLE"] = ""

import httpx  # noqa: E402

_OrigClient = httpx.Client
_OrigAsync = httpx.AsyncClient

class _PatchedClient(_OrigClient):
    def __init__(self, *a, **kw):
        kw["verify"] = False
        super().__init__(*a, **kw)

class _PatchedAsync(_OrigAsync):
    def __init__(self, *a, **kw):
        kw["verify"] = False
        super().__init__(*a, **kw)

httpx.Client = _PatchedClient
httpx.AsyncClient = _PatchedAsync
# ── end SSL workaround ─────────────────────────────────────────────────────

from dotenv import load_dotenv  # noqa: E402
from langchain_core.tools import tool  # noqa: E402
from langchain_openai import AzureChatOpenAI  # noqa: E402
from langgraph.prebuilt import create_react_agent  # noqa: E402

# ── Config ──────────────────────────────────────────────────────────────────

# Load shared .env from the prepwork root (one level up from python/)
load_dotenv(Path(__file__).resolve().parent.parent / ".env")

AZURE_BASE_URL = os.environ["AZURE_AI_BASE_URL"]
AZURE_API_KEY = os.environ["AZURE_AI_API_KEY"]
MODEL_NAME = "gpt-5-4"  # resolves to gpt-5.4 on the Foundry endpoint
DATA_DIR = Path(__file__).resolve().parent.parent / "data"

# ── Tool definition ─────────────────────────────────────────────────────────

@tool
def read_file(path: str) -> str:
    """Read the contents of a file in the data/ directory.

    Use this tool to look up information from local knowledge base files.
    Available files: company-faq.txt, product-docs.txt

    Args:
        path: Filename inside the data/ directory, e.g. "company-faq.txt"
    """
    # Security: resolve and verify the file stays within DATA_DIR
    target = (DATA_DIR / path).resolve()
    if not str(target).startswith(str(DATA_DIR.resolve())):
        return "Error: access denied — path outside data directory."
    if not target.is_file():
        return f"Error: file not found — {path}"
    return target.read_text(encoding="utf-8")


# ── LLM setup ──────────────────────────────────────────────────────────────

# Azure AI Foundry exposes an OpenAI-compatible chat/completions endpoint.
# We point AzureChatOpenAI at it.  The api_version and azure_endpoint together
# build the URL: {base}/models/chat/completions?api-version=...
llm = AzureChatOpenAI(
    azure_endpoint=AZURE_BASE_URL,
    api_key=AZURE_API_KEY,
    api_version="2024-05-01-preview",
    model=MODEL_NAME,
    temperature=0,
    max_tokens=1024,
)

# ── System prompt ───────────────────────────────────────────────────────────

SYSTEM_PROMPT = """You are a helpful assistant for TechVista Inc.

You have access to a read_file tool that can read files in the local data/ directory.
Available files:
- company-faq.txt  (company background, leadership, policies)
- product-docs.txt (CodeLens product documentation, pricing, API)

RULES:
1. ALWAYS use the read_file tool to look up information before answering.
   Do not rely on prior knowledge — ground every answer in the file contents.
2. After reading, cite your source: mention the filename and quote the relevant passage.
3. If the files don't contain the answer, say so honestly.
4. Keep answers concise and factual.
"""

# ── Agent graph ─────────────────────────────────────────────────────────────

# create_react_agent wires up: LLM → tool calls → tool execution → LLM → …
# It returns a compiled LangGraph StateGraph that we can invoke or stream.
agent = create_react_agent(
    model=llm,
    tools=[read_file],
    prompt=SYSTEM_PROMPT,
)

# ── Main ────────────────────────────────────────────────────────────────────

def main():
    question = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else "Who founded TechVista and when?"
    print(f"\n{'─'*60}")
    print(f"Question: {question}")
    print(f"{'─'*60}\n")

    # Stream the agent's execution so we can see each step
    for step in agent.stream({"messages": [("user", question)]}):
        # Each step is a dict keyed by the graph node that produced it
        for node_name, output in step.items():
            if node_name == "tools":
                for msg in output.get("messages", []):
                    print(f"[tool: {msg.name}] returned {len(msg.content)} chars")
            elif node_name == "agent":
                for msg in output.get("messages", []):
                    if msg.content:
                        print(f"\nAnswer:\n{msg.content}")
                    if hasattr(msg, "tool_calls") and msg.tool_calls:
                        for tc in msg.tool_calls:
                            print(f"[calling tool: {tc['name']}({tc['args']})]")

    print(f"\n{'─'*60}")


if __name__ == "__main__":
    main()
