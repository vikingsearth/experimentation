"""LLM factory — builds the chat model from application settings.

DECISIONS:
- Factory function, not a global instance. Lets main.py control lifecycle and
  makes it trivial to swap providers (Azure → Ollama → OpenAI direct).
- Uses AzureChatOpenAI from langchain-openai, which correctly builds the
  Azure AI Foundry URL from azure_endpoint + api_version.
- Temperature 0 for deterministic, reproducible answers (important for demos).
"""

from langchain.chat_models import init_chat_model
from langchain_openai import AzureChatOpenAI

from config import Settings


def build_llm(settings: Settings) -> AzureChatOpenAI:
    """Create an LLM instance from the application settings."""
    return AzureChatOpenAI(
        azure_endpoint=settings.azure_base_url,
        api_key=settings.azure_api_key,
        api_version="2024-05-01-preview",
        model=settings.model_name,
        temperature=0,
        max_tokens=1024,
    )
