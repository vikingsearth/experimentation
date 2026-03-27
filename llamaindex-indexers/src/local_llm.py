"""Helpers for loading the local GGUF model used by the experiment."""

import os
from functools import lru_cache
from pathlib import Path

DEFAULT_REPO_ID = "tensorblock/llama3.2-1b-Uncensored-GGUF"
DEFAULT_REVISION = "231935b9839df1237fd65a1b106a6c16029174d4"
DEFAULT_FILENAME = "llama3.2-1b-Uncensored-Q8_0.gguf"
DEFAULT_TOKENIZER_REPO = "nztinversive/llama3.2-1b-Uncensored"


def _fallback_chat_template(messages) -> str:
    parts = []
    for message in messages:
        role = message["role"]
        content = message["content"].strip()
        parts.append(
            f"<|start_header_id|>{role}<|end_header_id|>\n\n{content}<|eot_id|>"
        )
    parts.append("<|start_header_id|>assistant<|end_header_id|>\n\n")
    return "".join(parts)


def _apply_prompt_template(tokenizer, messages) -> str:
    if getattr(tokenizer, "chat_template", None):
        return tokenizer.apply_chat_template(
            messages,
            tokenize=False,
            add_generation_prompt=True,
        )
    return _fallback_chat_template(messages)


def _resolve_configured_path(project_root: Path, raw_path: str) -> Path:
    path = Path(raw_path)
    if path.is_absolute():
        return path
    return project_root / path


@lru_cache(maxsize=1)
def build_local_llm(project_root: Path):
    """Download the pinned GGUF file if needed and return a LlamaCPP LLM."""
    try:
        from huggingface_hub import hf_hub_download
        from llama_index.core import set_global_tokenizer
        from llama_index.llms.llama_cpp import LlamaCPP
        from transformers import AutoTokenizer
    except ImportError as exc:
        raise RuntimeError(
            "Install the local LLM dependencies with `pip install -r requirements.txt`."
        ) from exc

    repo_id = os.getenv("LOCAL_LLM_REPO_ID", DEFAULT_REPO_ID)
    revision = os.getenv("LOCAL_LLM_REVISION", DEFAULT_REVISION)
    filename = os.getenv("LOCAL_LLM_FILENAME", DEFAULT_FILENAME)
    tokenizer_repo = os.getenv("LOCAL_LLM_TOKENIZER_REPO", DEFAULT_TOKENIZER_REPO)
    model_dir = Path(
        os.getenv(
            "LOCAL_LLM_DIR",
            str(project_root / "models" / "llama3.2-1b-uncensored-q8_0"),
        )
    )
    model_dir = _resolve_configured_path(project_root, str(model_dir))

    model_path = os.getenv("LOCAL_LLM_MODEL_PATH")
    if model_path:
        resolved_model_path = _resolve_configured_path(project_root, model_path)
    else:
        resolved_model_path = Path(
            hf_hub_download(
                repo_id=repo_id,
                filename=filename,
                revision=revision,
                local_dir=str(model_dir),
            )
        )

    tokenizer = AutoTokenizer.from_pretrained(tokenizer_repo)
    set_global_tokenizer(tokenizer.encode)

    def messages_to_prompt(messages):
        prompt_messages = [
            {"role": message.role.value, "content": message.content or ""}
            for message in messages
        ]
        return _apply_prompt_template(tokenizer, prompt_messages)

    def completion_to_prompt(completion):
        return _apply_prompt_template(
            tokenizer,
            [{"role": "user", "content": completion}],
        )

    n_threads = max((os.cpu_count() or 2) - 1, 1)

    return LlamaCPP(
        model_path=str(resolved_model_path),
        temperature=0.1,
        max_new_tokens=int(os.getenv("LOCAL_LLM_MAX_NEW_TOKENS", "256")),
        context_window=int(os.getenv("LOCAL_LLM_CONTEXT_WINDOW", "4096")),
        generate_kwargs={"top_p": 0.9, "top_k": 40, "repeat_penalty": 1.1},
        model_kwargs={
            "n_threads": n_threads,
            "n_gpu_layers": int(os.getenv("LOCAL_LLM_N_GPU_LAYERS", "0")),
            "verbose": False,
        },
        messages_to_prompt=messages_to_prompt,
        completion_to_prompt=completion_to_prompt,
        verbose=False,
    )