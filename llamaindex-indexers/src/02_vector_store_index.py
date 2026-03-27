"""
Step 2: VectorStoreIndex

The most common index type. Embeds all nodes into vectors and retrieves
the top-k most similar nodes for any given query.

Key characteristics:
- Build cost: Medium (embedding generation for all nodes)
- Query cost: Low (fast vector similarity search)
- Best for: General Q&A, semantic search, factual questions
"""

import os
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_ROOT / "data"

try:
    from dotenv import load_dotenv

    load_dotenv(PROJECT_ROOT / ".env")
except ImportError:
    pass


def main():
    print("=" * 70)
    print("STEP 2: VECTOR STORE INDEX")
    print("=" * 70)

    from llama_index.core import SimpleDirectoryReader, VectorStoreIndex, Settings
    from llama_index.core.node_parser import SentenceSplitter

    # ------------------------------------------------------------------
    # Configure: use HuggingFace embeddings (free, local)
    # ------------------------------------------------------------------
    from llama_index.embeddings.huggingface import HuggingFaceEmbedding

    Settings.embed_model = HuggingFaceEmbedding(
        model_name="BAAI/bge-small-en-v1.5"
    )

    # Use a small chunk size for this demo
    Settings.chunk_size = 256
    Settings.chunk_overlap = 30

    # ------------------------------------------------------------------
    # Load documents
    # ------------------------------------------------------------------
    print("\nLoading documents...")
    documents = SimpleDirectoryReader(input_dir=str(DATA_DIR)).load_data()
    print(f"Loaded {len(documents)} documents")

    # ------------------------------------------------------------------
    # Build VectorStoreIndex
    # ------------------------------------------------------------------
    print("\nBuilding VectorStoreIndex (generating embeddings)...")
    import time

    start = time.time()
    index = VectorStoreIndex.from_documents(documents)
    build_time = time.time() - start
    print(f"Index built in {build_time:.2f}s")

    # ------------------------------------------------------------------
    # Query the index
    # ------------------------------------------------------------------
    print("\n" + "-" * 70)
    print("QUERYING VECTORSTOREINDEX")
    print("-" * 70)

    # Create a retriever (no LLM needed -- just retrieves nodes)
    retriever = index.as_retriever(similarity_top_k=3)

    queries = [
        "What is Python used for?",
        "What ingredients do I need for pasta carbonara?",
        "Who is the CEO of TechVista?",
        "What are the effects of climate change?",
    ]

    for query in queries:
        print(f"\nQuery: {query}")
        print("-" * 50)

        start = time.time()
        results = retriever.retrieve(query)
        query_time = time.time() - start

        for i, node_with_score in enumerate(results):
            source = node_with_score.node.metadata.get("file_name", "unknown")
            score = node_with_score.score
            text_preview = node_with_score.node.text[:120].replace("\n", " ")
            print(f"  [{i+1}] Score: {score:.4f} | Source: {source}")
            print(f"      {text_preview}...")

        print(f"  (Retrieved in {query_time:.3f}s)")

    # ------------------------------------------------------------------
    # Demonstrate similarity_top_k effect
    # ------------------------------------------------------------------
    print("\n" + "-" * 70)
    print("EFFECT OF similarity_top_k")
    print("-" * 70)

    query = "What is machine learning?"
    for k in [1, 3, 5]:
        retriever = index.as_retriever(similarity_top_k=k)
        results = retriever.retrieve(query)
        sources = [r.node.metadata.get("file_name", "?") for r in results]
        scores = [f"{r.score:.4f}" for r in results]
        print(f"\n  top_k={k}: {len(results)} results")
        print(f"    Sources: {sources}")
        print(f"    Scores:  {scores}")

    print("\n" + "=" * 70)
    print("VECTORSTOREINDEX SUMMARY")
    print("=" * 70)
    print("""
How it works:
  1. Each document chunk is converted to an embedding vector
  2. Vectors are stored in a vector store (default: in-memory)
  3. Queries are embedded and compared via cosine similarity
  4. Top-k most similar chunks are returned

Strengths:
  - Fast semantic search over large corpora
  - Good default choice for most RAG applications
  - Works well for factual, specific questions

Weaknesses:
  - May miss keyword-exact matches
  - Top-k can miss relevant context if k is too small
  - Requires embedding model (though local ones like bge-small are free)
""")

    return index


if __name__ == "__main__":
    index = main()
