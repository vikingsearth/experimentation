"""
Query the indexed documents across all chunking strategies.

Usage:
    python src/query.py "What is a list comprehension?"
    python src/query.py  # (interactive mode)

Shows side-by-side results from each strategy with similarity scores.
"""

import os
import sys

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, PROJECT_ROOT)

import src._ssl_workaround  # noqa: F401, E402

import chromadb
from sentence_transformers import SentenceTransformer

CHROMA_DIR = os.path.join(PROJECT_ROOT, "chroma_db")
EMBEDDING_MODEL = "all-MiniLM-L6-v2"
STRATEGIES = ["fixed", "recursive", "sentence", "semantic"]
TOP_K = 3


def query_strategy(
    client: chromadb.ClientAPI,
    strategy: str,
    question_embedding: list[float],
    top_k: int = TOP_K,
) -> list[dict]:
    """Query a single strategy's collection and return results."""
    collection_name = f"strategy_{strategy}"
    try:
        collection = client.get_collection(name=collection_name)
    except Exception:
        return []

    results = collection.query(
        query_embeddings=[question_embedding], n_results=top_k
    )

    formatted = []
    for i in range(len(results["ids"][0])):
        formatted.append(
            {
                "id": results["ids"][0][i],
                "text": results["documents"][0][i],
                "distance": results["distances"][0][i],
                "metadata": results["metadatas"][0][i],
            }
        )
    return formatted


def print_results(strategy: str, results: list[dict]) -> None:
    """Pretty-print results for a strategy."""
    print(f"\n  Strategy: {strategy.upper()}")
    print(f"  {'-' * 60}")

    if not results:
        print("  (no results -- collection may not exist. Run index.py first.)")
        return

    for i, r in enumerate(results):
        # ChromaDB returns distances; lower = more similar for cosine
        similarity = 1 - r["distance"]  # Convert distance to similarity
        source = r["metadata"].get("source", "unknown")
        chars = r["metadata"].get("char_length", len(r["text"]))
        preview = r["text"][:200].replace("\n", " ")

        print(
            f"  [{i + 1}] similarity={similarity:.4f} | source={source} | {chars} chars"
        )
        print(f"      {preview}...")
        print()


def main():
    # Check if ChromaDB exists
    if not os.path.exists(CHROMA_DIR):
        print("Error: ChromaDB not found. Run 'python src/index.py' first.")
        sys.exit(1)

    print(f"Loading embedding model: {EMBEDDING_MODEL}...")
    model = SentenceTransformer(EMBEDDING_MODEL)
    client = chromadb.PersistentClient(path=CHROMA_DIR)

    # Get question from args or interactive mode
    if len(sys.argv) > 1:
        questions = [" ".join(sys.argv[1:])]
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
        print(f"{'=' * 70}")

        # Embed the question once, reuse across strategies
        question_embedding = model.encode([question], show_progress_bar=False)[
            0
        ].tolist()

        for strategy in STRATEGIES:
            results = query_strategy(client, strategy, question_embedding)
            print_results(strategy, results)

        print()


if __name__ == "__main__":
    main()
