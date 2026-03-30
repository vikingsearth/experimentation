"""Helpers for loading the Ollama-backed LLM used by the experiment."""

import os
from functools import lru_cache
from typing import Optional


DEFAULT_OLLAMA_MODEL = "qwen2.5:3b-instruct"
DEFAULT_OLLAMA_BASE_URL = "http://127.0.0.1:11434"


@lru_cache(maxsize=8)
def build_local_llm(model_name: Optional[str] = None):
    """Return the configured Ollama LLM client."""
    try:
        from llama_index.llms.ollama import Ollama
    except ImportError as exc:
        raise RuntimeError(
            "Install the Ollama dependencies with `pip install -r requirements.txt`."
        ) from exc

    model = model_name or os.getenv("OLLAMA_MODEL", DEFAULT_OLLAMA_MODEL)
    base_url = os.getenv("OLLAMA_BASE_URL", DEFAULT_OLLAMA_BASE_URL)
    request_timeout = float(os.getenv("OLLAMA_REQUEST_TIMEOUT", "180"))
    context_window = int(os.getenv("OLLAMA_CONTEXT_WINDOW", "4096"))
    temperature = float(os.getenv("OLLAMA_TEMPERATURE", "0.1"))
    keep_alive = os.getenv("OLLAMA_KEEP_ALIVE", "10m")
    num_predict = int(os.getenv("OLLAMA_NUM_PREDICT", "256"))

    return Ollama(
        model=model,
        base_url=base_url,
        temperature=temperature,
        context_window=context_window,
        request_timeout=request_timeout,
        keep_alive=keep_alive,
        additional_kwargs={"num_predict": num_predict},
    )