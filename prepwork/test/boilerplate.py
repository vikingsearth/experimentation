from langchain_openai import AzureChatOpenAI
from langchain.tools import tool
from langchain_core.tools import BaseTool
from deepagents import create_deep_agent


## Load config from .env
from dotenv import dotenv_values
from pathlib import Path
import os

config = dotenv_values()
AZURE_BASE_URL = config.get("AZURE_AI_BASE_URL", None)
AZURE_API_KEY = config.get("AZURE_AI_API_KEY", None)
if not AZURE_BASE_URL or not AZURE_API_KEY:
    raise ValueError("AZURE_AI_BASE_URL and AZURE_AI_API_KEY must be set in .env")

MODEL_NAME = "gpt-5-4"  # resolves to gpt-5.4 on the Foundry endpoint


## Define a simple tool using both approaches
@tool
def run_bash_command(command: str) -> str:
    """Run a bash command and return its output."""
    import subprocess

    # add validation to only allow certain safe commands, e.g. ls, grep, cat
    allowed_commands = ["ls", "grep", "cat", "echo", "head", "tail"]
    if not any(command.startswith(cmd) for cmd in allowed_commands):
        return "Error: command appears unsafe and was blocked."

    # process execution
    try:
        result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
        return result.stdout
    except subprocess.CalledProcessError as e:
        return f"Error: {e.stderr}"


class RunBashTool(BaseTool):
    name: str = "run_bash_command"
    description: str = "Run a bash command and return its output."

    def _call(self, command: str) -> str:
        import subprocess

        # add validation to only allow certain safe commands, e.g. ls, grep, cat
        allowed_commands = ["ls", "grep", "cat", "echo", "head", "tail"]
        if not any(command.startswith(cmd) for cmd in allowed_commands):
            return "Error: command appears unsafe and was blocked."
        
        # process execution
        try:
            result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
            return result.stdout
        except subprocess.CalledProcessError as e:
            return f"Error: {e.stderr}"
        

## Create an LLM instance
llm = AzureChatOpenAI(
    azure_endpoint=AZURE_BASE_URL,
    azure_api_key=AZURE_API_KEY,
    api_version="2024-05-01-preview",
    model=MODEL_NAME,
    temperature=0,
)

## Build a Deep Agent with the LLM and tools
agent_tool_dec = create_deep_agent(
    model=llm,
    tools=[run_bash_command],
    system_prompt="You must use bash commands to answer questions. Focus on ls and grep type commands. Your purpose is to explore and report",
)

agent_tool_class = create_deep_agent(
    model=llm,
    tools=[RunBashTool()],
    system_prompt="You must use bash commands to answer questions. Focus on ls and grep type commands. Your purpose is to explore and report",
)


## Test the first one
print("Testing function-decorated tool:")
result = agent_tool_dec.invoke(
    {"messages": 
        [{
            "role": "user", 
            "content": "List all Python files in the current directory."
        }]
    }
)
print(f"Result:\n{result['messages'][-1].content}")


## Test the second one
print("\nTesting class-based tool:")
result = agent_tool_class.invoke(
    {"messages": 
        [{
            "role": "user", 
            "content": "List all Python files in the current directory."
        }]
    }
)
print(f"Result:\n{result['messages'][-1].content}")