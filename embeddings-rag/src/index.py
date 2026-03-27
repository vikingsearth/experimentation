"""
Index sample documents into ChromaDB using multiple chunking strategies.

Usage:
    python src/index.py

This will:
1. Load documents from data/
2. Chunk each document with 4 strategies (fixed, recursive, sentence, semantic)
3. Embed chunks using sentence-transformers
4. Store in ChromaDB (one collection per strategy)
5. Print statistics
"""

import os
import sys
import time

# Add project root to path
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, PROJECT_ROOT)

# SSL workaround for corporate environments (remove if not needed)
import src._ssl_workaround  # noqa: F401, E402

import chromadb
from sentence_transformers import SentenceTransformer

from src.chunkers import chunk_all, Chunk

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

DATA_DIR = os.path.join(PROJECT_ROOT, "data")
CHROMA_DIR = os.path.join(PROJECT_ROOT, "chroma_db")
EMBEDDING_MODEL = "all-MiniLM-L6-v2"
CHUNK_SIZE = 500


def load_documents(data_dir: str) -> dict[str, str]:
    """Load all .txt files from the data directory."""
    docs = {}
    for filename in sorted(os.listdir(data_dir)):
        if filename.endswith(".txt"):
            filepath = os.path.join(data_dir, filename)
            with open(filepath, "r", encoding="utf-8") as f:
                docs[filename] = f.read()
    return docs


def index_chunks(
    collection: chromadb.Collection,
    chunks: list[Chunk],
    source: str,
    model: SentenceTransformer,
) -> None:
    """Embed chunks and add them to a ChromaDB collection."""
    if not chunks:
        return

    ids = [f"{source}_{chunk.strategy}_{chunk.index}" for chunk in chunks]
    documents = [chunk.text for chunk in chunks]
    metadatas = [
        {
            "source": source,
            "strategy": chunk.strategy,
            "chunk_index": chunk.index,
            "char_length": len(chunk.text),
        }
        for chunk in chunks
    ]

    # Pre-compute embeddings with sentence-transformers
    embeddings = model.encode(documents, show_progress_bar=False).tolist()

    collection.add(
        ids=ids, documents=documents, metadatas=metadatas, embeddings=embeddings
    )


def main():
    print("=" * 70)
    print("  Document Indexing with Multiple Chunking Strategies")
    print("=" * 70)

    # Load embedding model
    print(f"\nLoading embedding model: {EMBEDDING_MODEL}...")
    t0 = time.time()
    model = SentenceTransformer(EMBEDDING_MODEL)
    print(f"  Model loaded in {time.time() - t0:.1f}s")

    # Initialize ChromaDB
    print(f"\nInitializing ChromaDB at: {CHROMA_DIR}")
    client = chromadb.PersistentClient(path=CHROMA_DIR)

    # Load documents
    print(f"\nLoading documents from: {DATA_DIR}")
    documents = load_documents(DATA_DIR)
    for name, text in documents.items():
        print(f"  {name}: {len(text)} characters")

    # Clean up existing collections before re-indexing
    for strategy_name in ["fixed", "recursive", "sentence", "semantic"]:
        collection_name = f"strategy_{strategy_name}"
        try:
            client.delete_collection(collection_name)
        except Exception:
            pass

    # Process each document with all strategies
    strategy_stats = {}

    for doc_name, doc_text in documents.items():
        print(f"\n{'-' * 50}")
        print(f"Processing: {doc_name}")
        print(f"{'-' * 50}")

        t0 = time.time()
        all_chunks = chunk_all(
            doc_text, embedding_model=model, chunk_size=CHUNK_SIZE
        )
        chunk_time = time.time() - t0
        print(f"  Chunking completed in {chunk_time:.2f}s")

        for strategy_name, chunks in all_chunks.items():
            # Get or create collection for this strategy
            collection_name = f"strategy_{strategy_name}"
            collection = client.get_or_create_collection(
                name=collection_name,
                metadata={"hnsw:space": "cosine"},
            )

            # Index chunks (with pre-computed embeddings)
            t0 = time.time()
            index_chunks(collection, chunks, source=doc_name, model=model)
            index_time = time.time() - t0

            # Collect stats
            char_lengths = [len(c.text) for c in chunks]
            stats = {
                "num_chunks": len(chunks),
                "avg_chars": sum(char_lengths) / len(char_lengths) if char_lengths else 0,
                "min_chars": min(char_lengths) if char_lengths else 0,
                "max_chars": max(char_lengths) if char_lengths else 0,
                "index_time": index_time,
            }

            if strategy_name not in strategy_stats:
                strategy_stats[strategy_name] = {}
            strategy_stats[strategy_name][doc_name] = stats

            print(
                f"  {strategy_name:12s}: {stats['num_chunks']:3d} chunks | "
                f"avg {stats['avg_chars']:.0f} chars | "
                f"range [{stats['min_chars']}-{stats['max_chars']}] | "
                f"indexed in {stats['index_time']:.3f}s"
            )

    # Summary
    print(f"\n{'=' * 70}")
    print("  Summary: Chunks per Strategy (across all documents)")
    print(f"{'=' * 70}")
    print(f"\n  {'Strategy':<12s} {'Total Chunks':>14s} {'Avg Size (chars)':>18s}")
    print(f"  {'-' * 46}")
    for strategy_name, doc_stats in sorted(strategy_stats.items()):
        total_chunks = sum(s["num_chunks"] for s in doc_stats.values())
        all_avgs = [s["avg_chars"] for s in doc_stats.values()]
        overall_avg = sum(all_avgs) / len(all_avgs) if all_avgs else 0
        print(f"  {strategy_name:<12s} {total_chunks:>14d} {overall_avg:>18.0f}")

    print(f"\nChromaDB collections stored at: {CHROMA_DIR}")
    print("Run 'python src/query.py <question>' to query the index.")
    print("Run 'python src/compare.py' to compare strategies.\n")


if __name__ == "__main__":
    main()
