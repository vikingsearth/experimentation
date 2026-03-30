"""CAG-style no-retrieval baseline over the relational corpus."""

from dataclasses import dataclass
import json
import os
import shutil
import subprocess
from urllib import error, request

from src.config import CAG_OLLAMA_MODEL, CAG_OLLAMA_URL, CAG_REQUEST_TIMEOUT


@dataclass(frozen=True)
class CAGResponse:
    """A model answer produced from a preloaded corpus context."""

    answer: str
    cited_files: list[str]
    confidence: float
    raw_response: str


def build_corpus_pack(documents: dict[str, str]) -> str:
    """Build a stable no-retrieval context pack from the relational corpus."""
    sections = []
    for filename, text in sorted(documents.items()):
        sections.append(f"## {filename}\n{text.strip()}")
    return "\n\n".join(sections)


def _extract_json_object(payload: str) -> dict:
    payload = payload.strip()
    try:
        return json.loads(payload)
    except json.JSONDecodeError:
        start = payload.find("{")
        end = payload.rfind("}")
        if start == -1 or end == -1 or end <= start:
            raise
        return json.loads(payload[start : end + 1])


def _resolve_ollama_executable() -> str | None:
    executable = shutil.which("ollama")
    if executable:
        return executable

    local_app_data = os.getenv("LOCALAPPDATA")
    if not local_app_data:
        return None

    candidate = os.path.join(local_app_data, "Programs", "Ollama", "ollama.exe")
    if os.path.exists(candidate):
        return candidate
    return None


def _run_ollama_cli(prompt: str, model: str, timeout_seconds: int) -> str:
    executable = _resolve_ollama_executable()
    if not executable:
        raise RuntimeError(
            "Could not find the Ollama CLI and the Ollama HTTP API request failed."
        )

    completed = subprocess.run(
        [executable, "run", model, prompt],
        capture_output=True,
        text=True,
        encoding="utf-8",
        timeout=timeout_seconds,
        check=True,
    )
    return completed.stdout


def answer_with_cag(
    question: str,
    documents: dict[str, str],
    model: str = CAG_OLLAMA_MODEL,
    api_url: str = CAG_OLLAMA_URL,
    timeout_seconds: int = CAG_REQUEST_TIMEOUT,
) -> CAGResponse:
    """Generate an answer using the full corpus as preloaded context."""
    corpus_pack = build_corpus_pack(documents)
    prompt = f"""
You are answering questions from a small, fixed knowledge base that has already been fully loaded into context.
Do not retrieve external information and do not invent missing facts.
Use only the corpus below.

Return JSON only with this exact schema:
{{
  "answer": "short factual answer",
  "cited_files": ["filename.txt"],
  "confidence": 0.0
}}

Rules:
- Keep the answer concise but complete.
- If the question asks for multiple items, include all of them, not just the first one.
- Preserve exact service names, repository names, policy IDs, incident IDs, and team names from the corpus.
- Cite all filenames that directly support the answer, not just one of them.
- Prefer a one- or two-sentence answer that includes the full dependency or ownership chain when the question is relational.
- If the corpus does not support the answer, say so explicitly and use an empty file list.
- Confidence must be a number between 0 and 1, and it should be lower when the answer may be incomplete.

Corpus:
{corpus_pack}

Question: {question}
""".strip()

    payload = json.dumps(
        {
            "model": model,
            "prompt": prompt,
            "stream": False,
            "format": "json",
            "options": {"temperature": 0.1},
        }
    ).encode("utf-8")

    http_request = request.Request(
        api_url,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    try:
        with request.urlopen(http_request, timeout=timeout_seconds) as response:
            raw = response.read().decode("utf-8")
        outer = json.loads(raw)
        inner = _extract_json_object(outer.get("response", ""))
    except (error.URLError, error.HTTPError, json.JSONDecodeError, RuntimeError):
        try:
            cli_output = _run_ollama_cli(prompt, model, timeout_seconds)
        except (subprocess.SubprocessError, OSError) as exc:
            raise RuntimeError(
                "Could not reach the local Ollama API or CLI. Ensure Ollama is installed, "
                f"running, and that the model '{model}' is available."
            ) from exc
        inner = _extract_json_object(cli_output)
        outer = {"response": cli_output}

    answer = str(inner.get("answer", "")).strip()
    cited_files = inner.get("cited_files", []) or []
    if not isinstance(cited_files, list):
        cited_files = []
    cited_files = [str(item).strip() for item in cited_files if str(item).strip()]

    try:
        confidence = float(inner.get("confidence", 0.0))
    except (TypeError, ValueError):
        confidence = 0.0

    confidence = max(0.0, min(confidence, 1.0))

    return CAGResponse(
        answer=answer,
        cited_files=cited_files,
        confidence=confidence,
        raw_response=outer.get("response", ""),
    )