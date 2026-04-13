"""Entry point — thin CLI that wires all components together.

DECISIONS:
- main.py is pure wiring: load config → build LLM → collect tools → build agent → run.
- No business logic lives here. Each component is independently testable.
- config.py is imported first because it sets SSL env vars before any HTTP
  client is created (the Netskope CA cert path).
"""

import sys

# Config must be imported first — it sets SSL_CERT_FILE / REQUESTS_CA_BUNDLE
# before any HTTP libraries are loaded.
from config import load_settings
from llm import build_llm
from tools.read_file import create_read_file_tool
from prompts.system import SYSTEM_PROMPT
from runtime import build_agent, run


def main():
    # 1. Load validated settings from .env
    settings = load_settings()

    # 2. Build the LLM from settings
    llm = build_llm(settings)

    # 3. Collect tools (add new tools here as you create them)
    tools = [
        create_read_file_tool(settings.data_dir),
    ]

    # 4. Build the agent harness
    agent = build_agent(llm, tools, SYSTEM_PROMPT)

    # 5. Run with the user's question (or default)
    question = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else "Who founded TechVista and when?"
    run(agent, question)


if __name__ == "__main__":
    main()
