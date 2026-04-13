"""
Deep Agent — built with the `deepagents` SDK (LangChain ecosystem)
==================================================================

WHAT'S DIFFERENT FROM YOUR REACT AGENT?
---------------------------------------
In prepwork/python/agent.py you built a ReAct agent with `create_react_agent`.
That gives you:  LLM ↔ tool call loop.  That's it.

`create_deep_agent` wraps that same loop but ALSO gives the LLM:

  1. PLANNING      — a built-in `write_todos` tool so the agent breaks tasks
                     into steps before diving in.
  2. FILESYSTEM    — built-in ls, read_file, write_file, edit_file, glob, grep
                     tools backed by a virtual filesystem (in-memory by default).
  3. SUBAGENTS     — a `task` tool to spawn child agents that work in isolation,
                     keeping the parent's context clean.
  4. AUTO-SUMMARY  — when context hits ~85% of the model's window, older messages
                     get summarized automatically so the agent can keep working.
  5. OFFLOADING    — large tool outputs get written to the filesystem and replaced
                     with a reference, preventing context overflow.

Think of it as: your ReAct agent is a bare engine; a Deep Agent is the full car
with steering, brakes, and navigation built in.

ARCHITECTURE DECISION: WHY `deepagents` INSTEAD OF RAW LANGGRAPH?
------------------------------------------------------------------
You *could* build all this yourself in LangGraph (define the graph, add planning
nodes, wire up summarization, etc). But `deepagents` packages proven patterns so
you get production-grade context management out of the box. It's the same
relationship as Express.js to raw Node HTTP — a harness over the primitives.
"""

import os
import ssl
import sys
import warnings
from pathlib import Path

# ── SSL workaround (corporate proxy with self-signed cert) ─────────────────
# Same fix as your existing agent.py — must run BEFORE any HTTP imports.
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
from langchain_openai import AzureChatOpenAI  # noqa: E402
from deepagents import create_deep_agent  # noqa: E402

# ── Config ──────────────────────────────────────────────────────────────────
# Load the shared .env from prepwork root (same as your other agents)
load_dotenv(Path(__file__).resolve().parent.parent / ".env")

AZURE_BASE_URL = os.environ["AZURE_AI_BASE_URL"]
AZURE_API_KEY = os.environ["AZURE_AI_API_KEY"]
MODEL_NAME = "gpt-5-4"
DATA_DIR = Path(__file__).resolve().parent.parent / "data"


# ── LLM Setup ──────────────────────────────────────────────────────────────
#
# KEY CONCEPT: Model initialization
# ----------------------------------
# Deep Agents accept either:
#   a) A string like "anthropic:claude-sonnet-4-6" — uses LangChain's
#      init_chat_model to auto-configure.
#   b) A pre-built BaseChatModel instance — for custom setups like Azure.
#
# Since you're on Azure AI Foundry (OpenAI-compatible endpoint), we build
# the model ourselves, same as in your existing agent.py.

llm = AzureChatOpenAI(
    azure_endpoint=AZURE_BASE_URL,
    api_key=AZURE_API_KEY,
    api_version="2024-05-01-preview",
    model=MODEL_NAME,
    temperature=0,
    max_tokens=16000,  # higher than your ReAct agent — deep agents do more work
)


# ── System Prompt ───────────────────────────────────────────────────────────
#
# KEY CONCEPT: System prompt layering
# ------------------------------------
# In a Deep Agent, YOUR system prompt gets PREPENDED to the built-in harness
# prompt. The harness prompt teaches the model how to use planning, filesystem,
# and subagent tools. You only need to define the agent's ROLE and DOMAIN.
#
# Compare this to your ReAct agent where you had to explain the tools manually.
# Here the harness handles that — you just say "who you are and what you do."

SYSTEM_PROMPT = """You are a research assistant for TechVista Inc.

Your job is to help users find information from internal knowledge base files
and synthesize clear, cited answers.

GUIDELINES:
1. Plan before acting — use write_todos to break down multi-part questions.
2. Read files from the knowledge base to ground your answers.
3. Always cite your sources (filename + relevant passage).
4. If the answer isn't in the files, say so honestly.
5. For complex questions, delegate subtasks to subagents.
"""


# ── Custom Tools ────────────────────────────────────────────────────────────
#
# KEY CONCEPT: Custom tools + built-in tools
# -------------------------------------------
# Deep Agents come with filesystem tools (read_file, write_file, etc.) that
# operate on a VIRTUAL filesystem (in-memory by default).
#
# But you can ALSO add your own tools. These sit alongside the built-in ones.
# Here we add a knowledge_base_search tool that reads from your REAL local
# data/ directory — the same files your ReAct agent uses.
#
# WHY BOTH? The virtual filesystem is for the agent's scratch work (notes,
# drafts, intermediate results). Your custom tool accesses the real world.

from langchain_core.tools import tool


@tool
def knowledge_base_read(filename: str) -> str:
    """Read a file from the TechVista knowledge base.

    Use this to look up company information from internal documents.
    Available files: company-faq.txt, product-docs.txt

    Args:
        filename: Name of the file, e.g. "company-faq.txt"
    """
    target = (DATA_DIR / filename).resolve()
    # Security: prevent path traversal outside data/
    if not str(target).startswith(str(DATA_DIR.resolve())):
        return "Error: access denied — path outside knowledge base."
    if not target.is_file():
        return f"Error: file not found — {filename}"
    return target.read_text(encoding="utf-8")


@tool
def knowledge_base_list() -> str:
    """List all available files in the TechVista knowledge base.

    Call this first to see what files are available before reading them.
    """
    if not DATA_DIR.is_dir():
        return "Error: knowledge base directory not found."
    files = [f.name for f in DATA_DIR.iterdir() if f.is_file()]
    return "\n".join(files) if files else "No files found."


# ── Subagent Configuration ──────────────────────────────────────────────────
#
# KEY CONCEPT: Subagents for context isolation
# ---------------------------------------------
# When the main agent does heavy work (reading lots of files, searching),
# its context window fills up fast. Subagents solve this:
#
#   Main agent → spawns subagent via `task` tool
#   Subagent runs with FRESH context → does the heavy lifting
#   Subagent returns a SHORT summary → main agent's context stays clean
#
# Think of it like: instead of reading 10 files yourself and filling your
# brain, you send an intern to read them and come back with bullet points.
#
# Each subagent config is a dict with:
#   - name: how the main agent refers to it
#   - description: when to use it (the LLM reads this to decide)
#   - system_prompt: role/instructions for the subagent
#   - tools: what the subagent can use (can differ from parent!)

researcher_subagent = {
    "name": "researcher",
    "description": (
        "Conducts deep research across knowledge base files. "
        "Use when the user asks a complex question that requires "
        "reading and cross-referencing multiple files."
    ),
    "system_prompt": (
        "You are a research specialist. Read the available knowledge base "
        "files thoroughly, cross-reference information, and return a concise "
        "summary (under 500 words) with specific citations.\n\n"
        "IMPORTANT: Return only the synthesized findings, not raw file contents."
    ),
    "tools": [knowledge_base_read, knowledge_base_list],
}


# ── Create the Deep Agent ──────────────────────────────────────────────────
#
# KEY CONCEPT: What create_deep_agent returns
# --------------------------------------------
# This returns a compiled LangGraph StateGraph — the same type as your
# create_react_agent, but with middleware layers that add the harness
# capabilities (planning, filesystem, summarization, subagents).
#
# Under the hood it's:
#   your tools + built-in tools → LLM → tool execution → LLM → ...
#   with middleware intercepting to manage context at each step.

agent = create_deep_agent(
    model=llm,
    tools=[knowledge_base_read, knowledge_base_list],
    system_prompt=SYSTEM_PROMPT,
    subagents=[researcher_subagent],
)


# ── Run ─────────────────────────────────────────────────────────────────────
#
# KEY CONCEPT: invoke vs stream
# ------------------------------
# .invoke() — runs to completion, returns final state. Simple but opaque.
# .stream() — yields each step (tool calls, responses, subagent work).
#             Better for understanding what the agent is doing.
#
# We use stream() here so you can watch the agent plan, use tools, and think.

def main():
    question = (
        " ".join(sys.argv[1:])
        if len(sys.argv) > 1
        else "What products does TechVista offer and what are their pricing tiers?"
    )

    print(f"\n{'═' * 60}")
    print(f"  Deep Agent — TechVista Research Assistant")
    print(f"{'═' * 60}")
    print(f"\n  Question: {question}\n")
    print(f"{'─' * 60}")

    # Stream the agent — default mode yields dict keyed by node name.
    # Deep agents wrap messages in Overwrite objects (a LangGraph detail
    # for state management), so we need to unwrap them.
    for step in agent.stream(
        {"messages": [{"role": "user", "content": question}]},
    ):
        for node_name, output in step.items():
            if output is None:
                continue
            # Extract messages — may be a list or an Overwrite wrapper
            raw = output.get("messages", []) if isinstance(output, dict) else []
            if not isinstance(raw, list):
                # Overwrite objects have a .data attribute with the actual list
                raw = getattr(raw, "data", [raw]) if hasattr(raw, "data") else [raw]

            for msg in raw:
                # Tool calls — the agent deciding to use a tool
                if hasattr(msg, "tool_calls") and msg.tool_calls:
                    for tc in msg.tool_calls:
                        print(f"\n  [{node_name} calling: {tc['name']}]")
                        if tc.get("args"):
                            args_preview = str(tc["args"])[:100]
                            print(f"    args: {args_preview}")

                # Tool results — what came back (ToolMessage has a truthy .name)
                elif getattr(msg, "name", None):
                    print(f"  [{msg.name} returned {len(str(msg.content))} chars]")

                # Agent's text response (AIMessage with text, no tool calls)
                elif getattr(msg, "content", None):
                    print(f"\n  Answer:\n")
                    print(f"  {msg.content}")

    print(f"\n{'═' * 60}\n")


if __name__ == "__main__":
    main()
