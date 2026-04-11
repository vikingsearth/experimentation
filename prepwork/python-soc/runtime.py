"""Agent runtime — wraps the Deep Agent harness.

DECISIONS:
- Uses LangChain's Deep Agents SDK (deepagents) which provides:
  - Built-in planning via write_todos tool
  - Virtual filesystem for context management
  - Subagent spawning for context isolation
  - Auto-summarization of long conversations
- The runtime is the only file that knows about the agent framework. If you
  swap Deep Agents for raw LangGraph or CrewAI, only this file changes.
- build_agent() is a factory: takes LLM + tools + prompt, returns a runnable.
- run() handles streaming and output formatting.
"""

from langchain_core.language_models import BaseChatModel
from langchain_core.tools import BaseTool
from deepagents import create_deep_agent


def build_agent(
    llm: BaseChatModel,
    tools: list[BaseTool],
    system_prompt: str,
):
    """Build a Deep Agent with the given LLM, tools, and system prompt.

    Returns a compiled LangGraph StateGraph that can be invoked or streamed.
    """
    return create_deep_agent(
        model=llm,
        tools=tools,
        system_prompt=system_prompt,
    )


def run(agent, question: str) -> str:
    """Run the agent on a question, streaming steps to stdout.

    Returns the final answer text.
    """
    print(f"\n{'─' * 60}")
    print(f"Question: {question}")
    print(f"{'─' * 60}\n")

    result = agent.invoke(
        {"messages": [{"role": "user", "content": question}]}
    )

    # The final message contains the answer
    answer = result["messages"][-1].content
    print(f"\nAnswer:\n{answer}")
    print(f"\n{'─' * 60}")

    return answer
