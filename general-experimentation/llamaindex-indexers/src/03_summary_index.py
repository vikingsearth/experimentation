"""
Step 3: SummaryIndex (formerly ListIndex)

Stores nodes in a flat list and reads through ALL of them at query time.
No embeddings needed at build time -- cheapest to build, most expensive to query.

Key characteristics:
- Build cost: None (no embeddings, no LLM calls)
- Query cost: High (reads every node)
- Best for: Summarization tasks, small document sets, "tell me everything" queries
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
    print("STEP 3: SUMMARY INDEX")
    print("=" * 70)

    from llama_index.core import SimpleDirectoryReader, Settings
    from llama_index.core import SummaryIndex
    from llama_index.embeddings.huggingface import HuggingFaceEmbedding

    Settings.embed_model = HuggingFaceEmbedding(
        model_name="BAAI/bge-small-en-v1.5"
    )
    Settings.chunk_size = 256
    Settings.chunk_overlap = 30

    # ------------------------------------------------------------------
    # Load documents
    # ------------------------------------------------------------------
    print("\nLoading documents...")
    documents = SimpleDirectoryReader(input_dir=str(DATA_DIR)).load_data()
    print(f"Loaded {len(documents)} documents")

    # ------------------------------------------------------------------
    # Build SummaryIndex
    # ------------------------------------------------------------------
    print("\nBuilding SummaryIndex...")
    import time

    start = time.time()
    index = SummaryIndex.from_documents(documents)
    build_time = time.time() - start
    print(f"Index built in {build_time:.2f}s (no embeddings needed!)")

    # ------------------------------------------------------------------
    # Query: Default mode (returns ALL nodes)
    # ------------------------------------------------------------------
    print("\n" + "-" * 70)
    print("DEFAULT MODE: Returns ALL nodes")
    print("-" * 70)

    retriever_all = index.as_retriever(retriever_mode="default")

    query = "What topics are covered in these documents?"
    print(f"\nQuery: {query}")

    start = time.time()
    results = retriever_all.retrieve(query)
    query_time = time.time() - start

    print(f"Retrieved {len(results)} nodes (ALL nodes!) in {query_time:.3f}s")
    sources = set(r.node.metadata.get("file_name", "?") for r in results)
    print(f"From files: {sorted(sources)}")

    # ------------------------------------------------------------------
    # Query: Embedding mode (top-k similar nodes)
    # ------------------------------------------------------------------
    print("\n" + "-" * 70)
    print("EMBEDDING MODE: Returns top-k similar nodes")
    print("-" * 70)

    retriever_emb = index.as_retriever(
        retriever_mode="embedding", similarity_top_k=3
    )

    queries = [
        "What is Python used for?",
        "What ingredients do I need for pasta carbonara?",
        "Who is the CEO of TechVista?",
    ]

    for query in queries:
        print(f"\nQuery: {query}")
        results = retriever_emb.retrieve(query)
        for i, r in enumerate(results):
            source = r.node.metadata.get("file_name", "unknown")
            score = r.score if r.score else 0.0
            preview = r.node.text[:100].replace("\n", " ")
            print(f"  [{i+1}] Score: {score:.4f} | Source: {source}")
            print(f"      {preview}...")

    # ------------------------------------------------------------------
    # Compare: default vs embedding mode
    # ------------------------------------------------------------------
    print("\n" + "-" * 70)
    print("COMPARISON: Default vs Embedding retrieval mode")
    print("-" * 70)

    query = "What are the effects of climate change?"

    # Default: all nodes
    results_all = retriever_all.retrieve(query)
    # Embedding: top 3
    results_emb = retriever_emb.retrieve(query)

    print(f"\nQuery: {query}")
    print(f"  Default mode:   {len(results_all)} nodes (all)")
    print(f"  Embedding mode: {len(results_emb)} nodes (top-3)")
    print()
    print("  Default mode retrieves EVERYTHING -- good for summarization")
    print("  Embedding mode retrieves selectively -- good for specific questions")

    print("\n" + "=" * 70)
    print("SUMMARY INDEX SUMMARY")
    print("=" * 70)
    print("""
How it works:
  1. Documents are chunked into nodes and stored in a flat list
  2. No embeddings generated at build time (zero build cost)
  3. Default query mode: ALL nodes are sent to the LLM for synthesis
  4. Embedding mode: top-k similar nodes retrieved first

Strengths:
  - Zero build cost
  - Considers ALL data (no information loss)
  - Best for summarization and "tell me everything" queries

Weaknesses:
  - Default mode is expensive (many LLM calls to process all nodes)
  - Slow for large document sets
  - Not suitable for large corpora in default mode

Best use case:
  "Summarize all the documents" or "What topics are covered?"
""")

    return index


if __name__ == "__main__":
    index = main()
