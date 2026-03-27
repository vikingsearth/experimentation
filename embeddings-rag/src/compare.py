"""Compare chunking strategies across different retrieval modes."""

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

# Test questions with keywords that should appear in relevant chunks
TEST_QUESTIONS = [
    {
        "question": "What is a list comprehension in Python?",
        "keywords": ["list comprehension", "concise", "expression", "iterable"],
    },
    {
        "question": "How do decorators work?",
        "keywords": ["decorator", "@", "function", "modify"],
    },
    {
        "question": "What is overfitting and how to prevent it?",
        "keywords": ["overfitting", "regularization", "dropout", "training"],
    },
    {
        "question": "Explain the transformer architecture",
        "keywords": ["transformer", "attention", "self-attention", "parallel"],
    },
    {
        "question": "What is a vector database?",
        "keywords": ["vector database", "similarity", "embeddings", "search"],
    },
    {
        "question": "How does RAG work?",
        "keywords": ["retrieval", "augmented", "generation", "knowledge"],
    },
    {
        "question": "What are generators in Python?",
        "keywords": ["generator", "yield", "iterator", "memory"],
    },
    {
        "question": "What is gradient descent?",
        "keywords": ["gradient", "descent", "optimization", "loss"],
    },
]


def score_relevance(text: str, keywords: list[str]) -> float:
    """
    Simple keyword-based relevance scoring.
    Returns the fraction of keywords found in the text (case-insensitive).
    """
    text_lower = text.lower()
    found = sum(1 for kw in keywords if kw.lower() in text_lower)
    return found / len(keywords) if keywords else 0.0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--retrieval",
        choices=RETRIEVAL_MODES,
        default="dense",
        help="Retrieval mode to benchmark",
    )
    parser.add_argument(
        "--top-k",
        type=int,
        default=3,
        help="Number of results to score for each strategy",
    )
    return parser.parse_args()


def query_and_score(results: list, keywords: list[str]) -> dict:
    """Compute evaluation metrics from retrieved results."""
    if not results:
        return {"avg_score": 0, "keyword_score": 0, "top_text": ""}

    avg_score = sum(result.score for result in results) / len(results)
    all_text = " ".join(result.text for result in results)
    keyword_score = score_relevance(all_text, keywords)

    return {
        "avg_score": avg_score,
        "keyword_score": keyword_score,
        "top_text": results[0].text[:100],
    }


def main():
    args = parse_args()

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

    print("=" * 80)
    print(f"  Chunking Strategy Comparison ({args.retrieval.upper()} retrieval)")
    print("=" * 80)

    # Collect scores
    all_scores = {s: {"score": [], "keyword": []} for s in STRATEGIES}

    for tq in TEST_QUESTIONS:
        question = tq["question"]
        keywords = tq["keywords"]

        question_embedding = None
        if args.retrieval in {"dense", "hybrid"}:
            question_embedding = model.encode(
                [question], show_progress_bar=False
            )[0].tolist()

        print(f"\n  Q: {question}")
        print(f"  {'-' * 72}")
        print(
            f"  {'Strategy':<12s} {'Avg Score':>16s} {'Keyword Score':>15s}  "
            f"{'Top Chunk Preview'}"
        )
        print(f"  {'-' * 72}")

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

            result = query_and_score(results, keywords)
            all_scores[strategy]["score"].append(result["avg_score"])
            all_scores[strategy]["keyword"].append(result["keyword_score"])

            preview = result["top_text"].replace("\n", " ")[:40]
            print(
                f"  {strategy:<12s} {result['avg_score']:>16.4f} "
                f"{result['keyword_score']:>15.1%}  "
                f"{preview}..."
            )

    # Overall summary
    print(f"\n{'=' * 80}")
    print("  Overall Results (averaged across all questions)")
    print(f"{'=' * 80}")
    print(
        f"\n  {'Strategy':<12s} {'Avg Score':>16s} {'Avg Keyword Score':>19s} "
        f"{'Combined Score':>16s}"
    )
    print(f"  {'-' * 65}")

    best_strategy = None
    best_combined = -1

    for strategy in STRATEGIES:
        sims = all_scores[strategy]["score"]
        keys = all_scores[strategy]["keyword"]
        avg_sim = sum(sims) / len(sims) if sims else 0
        avg_key = sum(keys) / len(keys) if keys else 0
        # Combined: weighted average (similarity matters more than keyword match)
        combined = 0.6 * avg_sim + 0.4 * avg_key

        if combined > best_combined:
            best_combined = combined
            best_strategy = strategy

        print(
            f"  {strategy:<12s} {avg_sim:>16.4f} {avg_key:>19.1%} {combined:>16.4f}"
        )

    print(f"\n  Best performing strategy: {best_strategy.upper()}")
    print()

    # Observations
    print("  Observations:")
    print("  - Dense retrieval rewards semantic similarity across paraphrases")
    print("  - Lexical retrieval rewards exact keyword overlap and rare terms")
    print("  - Hybrid retrieval can recover chunks missed by either signal alone")
    print("  - Recursive and sentence chunking usually preserve context more cleanly")
    print("  - The best strategy still depends on your documents and question style")
    print()


if __name__ == "__main__":
    main()
