"""
Compare chunking strategies by running predefined test questions.

Usage:
    python src/compare.py

Runs a set of test questions against all four chunking strategies and
produces a comparison table showing which strategies retrieve the most
relevant chunks for each question.
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


def query_and_score(
    client: chromadb.ClientAPI,
    strategy: str,
    question_embedding: list[float],
    keywords: list[str],
    top_k: int = 3,
) -> dict:
    """Query a strategy and compute relevance scores."""
    collection_name = f"strategy_{strategy}"
    try:
        collection = client.get_collection(name=collection_name)
    except Exception:
        return {"avg_similarity": 0, "keyword_score": 0, "top_text": ""}

    results = collection.query(
        query_embeddings=[question_embedding], n_results=top_k
    )

    if not results["ids"][0]:
        return {"avg_similarity": 0, "keyword_score": 0, "top_text": ""}

    # Similarity scores (1 - distance for cosine)
    similarities = [1 - d for d in results["distances"][0]]
    avg_similarity = sum(similarities) / len(similarities)

    # Keyword relevance (how many expected keywords appear in retrieved chunks)
    all_text = " ".join(results["documents"][0])
    keyword_score = score_relevance(all_text, keywords)

    return {
        "avg_similarity": avg_similarity,
        "keyword_score": keyword_score,
        "top_text": results["documents"][0][0][:100],
    }


def main():
    if not os.path.exists(CHROMA_DIR):
        print("Error: ChromaDB not found. Run 'python src/index.py' first.")
        sys.exit(1)

    print(f"Loading embedding model: {EMBEDDING_MODEL}...")
    model = SentenceTransformer(EMBEDDING_MODEL)
    client = chromadb.PersistentClient(path=CHROMA_DIR)

    print("=" * 80)
    print("  Chunking Strategy Comparison")
    print("=" * 80)

    # Collect scores
    all_scores = {s: {"similarity": [], "keyword": []} for s in STRATEGIES}

    for tq in TEST_QUESTIONS:
        question = tq["question"]
        keywords = tq["keywords"]

        # Embed question once
        question_embedding = model.encode(
            [question], show_progress_bar=False
        )[0].tolist()

        print(f"\n  Q: {question}")
        print(f"  {'-' * 72}")
        print(
            f"  {'Strategy':<12s} {'Avg Similarity':>16s} {'Keyword Score':>15s}  "
            f"{'Top Chunk Preview'}"
        )
        print(f"  {'-' * 72}")

        for strategy in STRATEGIES:
            result = query_and_score(
                client, strategy, question_embedding, keywords
            )
            all_scores[strategy]["similarity"].append(result["avg_similarity"])
            all_scores[strategy]["keyword"].append(result["keyword_score"])

            preview = result["top_text"].replace("\n", " ")[:40]
            print(
                f"  {strategy:<12s} {result['avg_similarity']:>16.4f} "
                f"{result['keyword_score']:>15.1%}  "
                f"{preview}..."
            )

    # Overall summary
    print(f"\n{'=' * 80}")
    print("  Overall Results (averaged across all questions)")
    print(f"{'=' * 80}")
    print(
        f"\n  {'Strategy':<12s} {'Avg Similarity':>16s} {'Avg Keyword Score':>19s} "
        f"{'Combined Score':>16s}"
    )
    print(f"  {'-' * 65}")

    best_strategy = None
    best_combined = -1

    for strategy in STRATEGIES:
        sims = all_scores[strategy]["similarity"]
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
    print("  - Fixed-size chunking may split mid-sentence, losing context")
    print("  - Recursive chunking preserves paragraph boundaries when possible")
    print("  - Sentence-based chunking never splits a sentence")
    print(
        "  - Semantic chunking groups related content but is more expensive to index"
    )
    print(
        "  - The 'best' strategy depends on your document type and query patterns"
    )
    print()


if __name__ == "__main__":
    main()
