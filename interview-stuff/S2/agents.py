import os
from datetime import datetime, timezone
from pathlib import Path

from dotenv import load_dotenv

# Load .env from parent dir (interview-stuff/.env) for local dev.
# In Docker, env vars are passed at runtime instead.
load_dotenv(Path(__file__).parent.parent / ".env")

# Remap Azure AI vars to Anthropic — same pattern as S1
os.environ.setdefault("ANTHROPIC_BASE_URL", os.environ.get("AZURE_AI_BASE_URL", ""))
os.environ.setdefault("ANTHROPIC_API_KEY", os.environ.get("AZURE_AI_API_KEY", ""))

from deepagents import create_deep_agent  # noqa: E402
from langgraph.checkpoint.memory import MemorySaver  # noqa: E402

_checkpointer = MemorySaver()


def get_current_time() -> str:
    """Get the current UTC time."""
    return datetime.now(timezone.utc).isoformat()


_agent = create_deep_agent(
    model=os.getenv("MODEL", "anthropic:claude-haiku-4-5"),
    tools=[get_current_time],
    checkpointer=_checkpointer,
)


def run(prompt: str, session_id: str) -> str:
    config = {"configurable": {"thread_id": session_id}}
    result = _agent.invoke(
        {"messages": [{"role": "user", "content": prompt}]},
        config=config,
    )
    return result["messages"][-1].content
