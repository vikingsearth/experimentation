"""Benchmark local Ollama models against the index comparison workflow."""

import argparse
import importlib.util
import os
import shutil
import subprocess
import time
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_ROOT / "data"

try:
    from dotenv import load_dotenv

    load_dotenv(PROJECT_ROOT / ".env")
except ImportError:
    pass

from ollama_llm import DEFAULT_OLLAMA_MODEL, build_local_llm


COMPARE_ALL_PATH = Path(__file__).resolve().parent / "06_compare_all.py"
COMPARE_ALL_SPEC = importlib.util.spec_from_file_location(
    "compare_all_module", COMPARE_ALL_PATH
)
COMPARE_ALL_MODULE = importlib.util.module_from_spec(COMPARE_ALL_SPEC)
assert COMPARE_ALL_SPEC is not None and COMPARE_ALL_SPEC.loader is not None
COMPARE_ALL_SPEC.loader.exec_module(COMPARE_ALL_MODULE)

build_all_indices = COMPARE_ALL_MODULE.build_all_indices
query_all_indices = COMPARE_ALL_MODULE.query_all_indices


TEST_QUERIES = [
    {
        "query": "What is Python used for?",
        "expected_sources": {"python_overview.txt"},
    },
    {
        "query": "What ingredients do I need for spaghetti carbonara?",
        "expected_sources": {"cooking_recipes.txt"},
    },
    {
        "query": "Who is the CEO of TechVista Corporation?",
        "expected_sources": {"company_profile.txt"},
    },
    {
        "query": "Summarize all topics covered in these documents",
        "expected_sources": {"python_overview.txt", "company_profile.txt"},
    },
    {
        "query": "What causes greenhouse gas emissions?",
        "expected_sources": {"climate_change.txt"},
    },
]

INDEX_ORDER = ["VectorStore", "Summary", "Tree", "KeywordTable"]
SUMMARY_REVIEW_QUERY = "Summarize all topics covered in these documents in 2-3 sentences."
FACT_REVIEW_QUERY = "Who is the CEO of TechVista Corporation and what does the company do?"
WARMUP_PROMPT = "Reply with the single word READY."


def clip_text(text: str, limit: int = 280) -> str:
    normalized = " ".join(text.split())
    if len(normalized) <= limit:
        return normalized
    return normalized[: limit - 3].rstrip() + "..."


def resolve_ollama_bin() -> Path:
    configured = os.getenv("OLLAMA_BIN")
    if configured:
        return Path(configured)

    discovered = shutil.which("ollama")
    if discovered:
        return Path(discovered)

    windows_default = Path.home() / "AppData/Local/Programs/Ollama/ollama.exe"
    if windows_default.exists():
        return windows_default

    raise RuntimeError(
        "Could not find the Ollama CLI. Set OLLAMA_BIN or add ollama to PATH."
    )


def run_ollama_command(args, check: bool = True):
    completed = subprocess.run(
        [str(resolve_ollama_bin()), *args],
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if check and completed.returncode != 0:
        stderr = completed.stderr.strip() or completed.stdout.strip()
        raise RuntimeError(f"Ollama command failed: {' '.join(args)}\n{stderr}")
    return completed


def list_running_models():
    completed = run_ollama_command(["ps"])
    models = []
    for line in completed.stdout.splitlines():
        stripped = line.strip()
        if not stripped or stripped.upper().startswith("NAME"):
            continue
        models.append(stripped.split()[0])
    return models


def reset_running_models(candidate_models):
    running_models = set(candidate_models)
    running_models.update(list_running_models())

    stopped = []
    for model_name in sorted(running_models):
        completed = run_ollama_command(["stop", model_name], check=False)
        if completed.returncode == 0:
            stopped.append(model_name)
    return stopped


def warmup_model(model_name: str):
    keep_alive = os.getenv("OLLAMA_KEEP_ALIVE", "10m")
    start = time.time()
    completed = run_ollama_command(
        [
            "run",
            model_name,
            WARMUP_PROMPT,
            "--keepalive",
            keep_alive,
            "--hidethinking",
        ]
    )
    return {
        "time": time.time() - start,
        "preview": clip_text(completed.stdout.strip(), limit=80),
    }


def capture_qualitative_snapshots(indices, model_name: str):
    from llama_index.core import Settings

    llm = build_local_llm(model_name)
    Settings.llm = llm

    root_nodes = indices["Tree"].as_retriever(retriever_mode="root").retrieve(
        SUMMARY_REVIEW_QUERY
    )
    root_preview = "No root summary retrieved"
    if root_nodes:
        root_preview = clip_text(root_nodes[0].node.text, limit=220)

    summary_engine = indices["Summary"].as_query_engine(
        response_mode="tree_summarize",
        llm=llm,
    )
    tree_summary_engine = indices["Tree"].as_query_engine(
        retriever_mode="root",
        llm=llm,
    )
    vector_fact_engine = indices["VectorStore"].as_query_engine(
        similarity_top_k=3,
        llm=llm,
    )
    tree_fact_engine = indices["Tree"].as_query_engine(
        retriever_mode="select_leaf_embedding",
        child_branch_factor=int(os.getenv("TREE_CHILD_BRANCH_FACTOR", "3")),
        llm=llm,
    )

    return {
        "tree_root_preview": root_preview,
        "summary_answer": clip_text(str(summary_engine.query(SUMMARY_REVIEW_QUERY))),
        "tree_answer": clip_text(str(tree_summary_engine.query(SUMMARY_REVIEW_QUERY))),
        "vector_fact_answer": clip_text(str(vector_fact_engine.query(FACT_REVIEW_QUERY))),
        "tree_fact_answer": clip_text(str(tree_fact_engine.query(FACT_REVIEW_QUERY))),
    }


def benchmark_model(model_name: str, benchmark_models, clean_warmup: bool = True, include_qualitative: bool = True):
    from llama_index.core import SimpleDirectoryReader

    os.environ["OLLAMA_MODEL"] = model_name
    build_local_llm.cache_clear()

    warmup = None
    if clean_warmup:
        stopped_models = reset_running_models(benchmark_models)
        warmup = warmup_model(model_name)
        warmup["stopped_models"] = stopped_models

    documents = SimpleDirectoryReader(input_dir=str(DATA_DIR)).load_data()

    start = time.time()
    indices = build_all_indices(documents)
    build_time = time.time() - start

    query_times = {name: [] for name in INDEX_ORDER}
    source_hits = {name: 0 for name in INDEX_ORDER}

    for test in TEST_QUERIES:
        results = query_all_indices(indices, test["query"])
        for index_name in INDEX_ORDER:
            data = results[index_name]
            query_times[index_name].append(data["time"])
            sources = {
                node.node.metadata.get("file_name", "?") for node in data["nodes"]
            }
            if sources & test["expected_sources"]:
                source_hits[index_name] += 1

    qualitative = None
    if include_qualitative:
        qualitative = capture_qualitative_snapshots(indices, model_name)

    return {
        "model": model_name,
        "warmup": warmup,
        "build_time": build_time,
        "avg_query_times": {
            name: sum(times) / len(times) for name, times in query_times.items()
        },
        "source_hits": source_hits,
        "qualitative": qualitative,
    }


def print_summary(summary):
    print("\n" + "=" * 70)
    print(f"MODEL: {summary['model']}")
    print("=" * 70)
    if summary["warmup"]:
        stopped = summary["warmup"].get("stopped_models") or []
        stopped_display = ", ".join(stopped) if stopped else "none"
        print(f"Clean warmup: {summary['warmup']['time']:.2f}s | stopped: {stopped_display}")
        print(f"Warmup reply: {summary['warmup']['preview']}")
    print(f"Tree-inclusive build time: {summary['build_time']:.2f}s")
    print("\nAverage query time by index:")
    for index_name in INDEX_ORDER:
        avg_time = summary["avg_query_times"][index_name]
        print(f"  {index_name:<12} {avg_time:.3f}s")
    print("\nSource-hit count across benchmark queries:")
    for index_name in INDEX_ORDER:
        hit_count = summary["source_hits"][index_name]
        print(f"  {index_name:<12} {hit_count}/{len(TEST_QUERIES)}")
    if summary["qualitative"]:
        print("\nQualitative snapshots:")
        print(f"  Tree root preview:   {summary['qualitative']['tree_root_preview']}")
        print(f"  Summary answer:     {summary['qualitative']['summary_answer']}")
        print(f"  Tree answer:        {summary['qualitative']['tree_answer']}")
        print(f"  Vector fact answer: {summary['qualitative']['vector_fact_answer']}")
        print(f"  Tree fact answer:   {summary['qualitative']['tree_fact_answer']}")


def main():
    parser = argparse.ArgumentParser(
        description="Benchmark multiple Ollama models for the LlamaIndex experiment."
    )
    parser.add_argument(
        "--models",
        nargs="+",
        default=[DEFAULT_OLLAMA_MODEL, "llama3.2:3b"],
        help="Ollama model names to benchmark sequentially.",
    )
    parser.add_argument(
        "--skip-clean-warmup",
        action="store_true",
        help="Skip stopping loaded Ollama models and warming the target model before timing.",
    )
    parser.add_argument(
        "--skip-qualitative",
        action="store_true",
        help="Skip the manual-review snapshots after the timing run.",
    )
    args = parser.parse_args()

    summaries = []
    for model_name in args.models:
        print(f"\nRunning benchmark for {model_name}...")
        summaries.append(
            benchmark_model(
                model_name,
                benchmark_models=args.models,
                clean_warmup=not args.skip_clean_warmup,
                include_qualitative=not args.skip_qualitative,
            )
        )

    for summary in summaries:
        print_summary(summary)

    fastest_build = min(summaries, key=lambda item: item["build_time"])
    best_tree = min(summaries, key=lambda item: item["avg_query_times"]["Tree"])
    best_source_hits = max(
        summaries,
        key=lambda item: sum(item["source_hits"].values()),
    )

    print("\n" + "=" * 70)
    print("PERFORMANCE SUMMARY")
    print("=" * 70)
    print(
        f"Fastest build: {fastest_build['model']} "
        f"({fastest_build['build_time']:.2f}s)"
    )
    print(
        f"Fastest Tree query average: {best_tree['model']} "
        f"({best_tree['avg_query_times']['Tree']:.3f}s)"
    )
    print(
        f"Best aggregate source-hit score: {best_source_hits['model']} "
        f"({sum(best_source_hits['source_hits'].values())})"
    )
    if args.skip_qualitative:
        print("Manual output review is still needed for summary phrasing quality.")
    else:
        print("Use the qualitative snapshots above to compare summary phrasing and factual grounding.")


if __name__ == "__main__":
    main()