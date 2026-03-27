"""Query the indexed documents across all chunking strategies."""

import argparse
import os
import sys

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

sys.path.insert(0, PROJECT_ROOT)

from src.config import (
    CHROMA_DIR,
    EMBEDDING_MODEL,
    RETRIEVAL_MODES,
    STRATEGIES,
    TOP_K,
)
from src.corpus import build_chunk_catalog, load_documents
from src.retrieval import (
    build_lexical_retrievers,
    query_dense_strategy,
    query_hybrid_strategy,
    query_lexical_strategy,
)

import src._ssl_workaround  # noqa: F401, E402

import chromadb
from sentence_transformers import SentenceTransformer


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("question", nargs="*", help="Question to ask")
    parser.add_argument(
        "--retrieval",
        choices=RETRIEVAL_MODES,
        default="dense",
        help="Retrieval mode to use across strategies",
    )
    parser.add_argument(
        "--top-k",
        type=int,
        default=TOP_K,
        help="Number of results to show per strategy",
    )
    return parser.parse_args()


def print_results(strategy: str, results: list, retrieval_mode: str) -> None:
    """Pretty-print results for a strategy."""
    print(f"\n  Strategy: {strategy.upper()}")
    print(f"  {'-' * 60}")

    if not results:
        print("  (no results for this strategy.)")
        return

    for i, result in enumerate(results):
        source = result.metadata.get("source", "unknown")
        chars = result.metadata.get("char_length", len(result.text))
        preview = result.text[:200].replace("\n", " ")

        if retrieval_mode == "hybrid":
            print(
                f"  [{i + 1}] score={result.score:.4f} "
                f"| dense={result.score_breakdown.get('dense', 0.0):.4f} "
                f"| lexical={result.score_breakdown.get('lexical', 0.0):.4f} "
                f"| source={source} | {chars} chars"
            )
        else:
            print(
                f"  [{i + 1}] score={result.score:.4f} | source={source} | {chars} chars"
            )
        print(f"      {preview}...")
        print()


def main():
    args = parse_args()

    # Check if ChromaDB exists
    if not os.path.exists(CHROMA_DIR):
        print("Error: ChromaDB not found. Run 'python src/index.py' first.")
        sys.exit(1)

    print(f"Loading embedding model: {EMBEDDING_MODEL}...")
    model = SentenceTransformer(EMBEDDING_MODEL)
    client = chromadb.PersistentClient(path=CHROMA_DIR)
    lexical_retrievers = None

    if args.retrieval in {"lexical", "hybrid"}:
        print("Building lexical chunk catalog for BM25 retrieval...")
        documents = load_documents()
        catalog = build_chunk_catalog(documents, embedding_model=model)
        lexical_retrievers = build_lexical_retrievers(catalog)

    # Get question from args or interactive mode
    if args.question:
        questions = [" ".join(args.question)]
    else:
        print("Interactive query mode. Type 'quit' to exit.\n")
        questions = []
        while True:
            q = input("Question: ").strip()
            if q.lower() in ("quit", "exit", "q"):
                break
            if q:
                questions.append(q)

    for question in questions:
        print(f"\n{'=' * 70}")
        print(f"  QUERY: {question}")
        print(f"  Retrieval mode: {args.retrieval}")
        print(f"{'=' * 70}")

        # Embed the question once, reuse across strategies
        question_embedding = None
        if args.retrieval in {"dense", "hybrid"}:
            question_embedding = model.encode([question], show_progress_bar=False)[
                0
            ].tolist()

        for strategy in STRATEGIES:
            if args.retrieval == "dense":
                results = query_dense_strategy(
                    client,
                    strategy,
                    question_embedding,
                    top_k=args.top_k,
                )
            elif args.retrieval == "lexical":
                results = query_lexical_strategy(
                    lexical_retrievers,
                    strategy,
                    question,
                    top_k=args.top_k,
                )
            else:
                results = query_hybrid_strategy(
                    client,
                    lexical_retrievers,
                    strategy,
                    question,
                    question_embedding,
                    top_k=args.top_k,
                )
            print_results(strategy, results, args.retrieval)

        print()


if __name__ == "__main__":
    main()
