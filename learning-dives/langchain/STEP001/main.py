"""
STEP001 — First LangChain call

Goal: the absolute minimum code to connect to an LLM through LangChain
and receive a response. No chains, no memory, no tools — just a model
and a message.
"""

import os
import httpx
from dotenv import load_dotenv, find_dotenv
from azure.core.credentials import AzureKeyCredential
from langchain_azure_ai.chat_models import AzureAIOpenAIApiChatModel
from langchain_core.messages import HumanMessage

# ── Load environment ──────────────────────────────────────────────────────────
# find_dotenv() walks parent directories until it finds a .env file,
# so this works regardless of from which directory you run the script.
load_dotenv(find_dotenv())

endpoint = os.environ["AZURE_AI_BASE_URL"]
api_key  = os.environ["AZURE_AI_API_KEY"]
model    = os.environ["AZURE_AI_MODEL"]

# AzureAIOpenAIApiChatModel targets the OpenAI-compatible path on Azure AI
# Foundry.  The base URL in the env file is the root domain; the SDK expects
# the full API path including /openai/v1.
openai_endpoint = endpoint.rstrip("/") + "/openai/v1"

# NOTE: verify=False disables TLS certificate verification.
# Only acceptable in a local dev environment behind a corporate proxy that
# performs HTTPS inspection with a self-signed certificate.
# Never set verify=False in production code.
http_client = httpx.Client(verify=False)

# ── Instantiate the LLM ───────────────────────────────────────────────────────
# AzureAIOpenAIApiChatModel wraps Azure AI Foundry's inference API.
# We pass the endpoint and an AzureKeyCredential (the API-key wrapper
# from azure-core) instead of relying on DefaultAzureCredential.
llm = AzureAIOpenAIApiChatModel(
    endpoint=openai_endpoint,
    credential=AzureKeyCredential(api_key),
    model=model,
    http_client=http_client,
)

# ── Build a message and invoke the model ──────────────────────────────────────
# LangChain represents conversation turns as typed Message objects.
# HumanMessage = a message authored by the user / caller.
messages = [HumanMessage(content="Say hello and tell me what you are in one sentence.")]

# .invoke() sends the messages to the LLM and blocks until a response arrives.
# It returns an AIMessage — the model's reply.
response = llm.invoke(messages)

# ── Print the result ──────────────────────────────────────────────────────────
print("Model response:")
print(response.content)
