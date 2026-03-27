"""
Step 4: TreeIndex

Builds a hierarchical tree of summaries. Leaf nodes are document chunks,
parent nodes are LLM-generated summaries. Traverses from root to leaves
during queries.

Key characteristics:
- Build cost: High (LLM calls to generate summaries at each level)
- Query cost: Medium (traverses tree, fewer LLM calls than SummaryIndex)
- Best for: Hierarchical summarization, overview-to-detail queries

NOTE: TreeIndex requires an LLM at build time to generate summaries.
      This script demonstrates building with build_tree=False (lazy mode)
      which defers summarization to query time.
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
    print("STEP 4: TREE INDEX")
    print("=" * 70)

    from llama_index.core import SimpleDirectoryReader, Settings, TreeIndex
    from llama_index.core.llms import MockLLM
    from llama_index.embeddings.huggingface import HuggingFaceEmbedding

    Settings.embed_model = HuggingFaceEmbedding(
        model_name="BAAI/bge-small-en-v1.5"
    )
    # TreeIndex requires an LLM. Use MockLLM for offline demo;
    # replace with OpenAI() if you have an API key.
    Settings.llm = MockLLM()
    Settings.chunk_size = 256
    Settings.chunk_overlap = 30

    # ------------------------------------------------------------------
    # Load documents
    # ------------------------------------------------------------------
    print("\nLoading documents...")
    documents = SimpleDirectoryReader(input_dir=str(DATA_DIR)).load_data()
    print(f"Loaded {len(documents)} documents")

    # ------------------------------------------------------------------
    # Build TreeIndex (lazy mode -- no LLM calls at build time)
    # ------------------------------------------------------------------
    print("\nBuilding TreeIndex (build_tree=False for lazy/deferred mode)...")
    import time

    start = time.time()
    index = TreeIndex.from_documents(documents, build_tree=False)
    build_time = time.time() - start
    print(f"Index built in {build_time:.2f}s (no tree built yet -- deferred)")

    # ------------------------------------------------------------------
    # Retrieve using different modes
    # ------------------------------------------------------------------
    print("\n" + "-" * 70)
    print("TREE INDEX RETRIEVAL MODES")
    print("-" * 70)

    # Mode 1: all_leaf -- returns all leaf nodes (similar to SummaryIndex default)
    print("\n[Mode: all_leaf] Returns all leaf nodes")
    retriever_leaf = index.as_retriever(retriever_mode="all_leaf")
    query = "What topics are covered?"
    results = retriever_leaf.retrieve(query)
    print(f"  Query: {query}")
    print(f"  Retrieved {len(results)} leaf nodes")
    sources = set(r.node.metadata.get("file_name", "?") for r in results)
    print(f"  From files: {sorted(sources)}")

    # ------------------------------------------------------------------
    # Show tree structure concept
    # ------------------------------------------------------------------
    print("\n" + "-" * 70)
    print("TREE INDEX STRUCTURE (CONCEPTUAL)")
    print("-" * 70)
    print("""
    When build_tree=True, the TreeIndex creates a hierarchy:

                    [Root Summary]
                   /       |       \\
          [Summary A]  [Summary B]  [Summary C]
          /    \\        /    \\        /    \\
       [Leaf] [Leaf] [Leaf] [Leaf] [Leaf] [Leaf]

    Leaf nodes = original document chunks
    Parent nodes = LLM-generated summaries of children
    Root node = summary of everything

    Query traversal (mode="select_leaf"):
      1. Start at root
      2. LLM selects most relevant child branch
      3. Repeat until reaching leaf nodes
      4. Return selected leaf nodes

    child_branch_factor controls how many children to explore:
      - child_branch_factor=1: follow single best path (fast, may miss)
      - child_branch_factor=2: explore top-2 branches (slower, more thorough)
    """)

    # ------------------------------------------------------------------
    # Compare build with and without tree
    # ------------------------------------------------------------------
    print("-" * 70)
    print("BUILD COMPARISON: Lazy vs Eager")
    print("-" * 70)

    # Lazy build (no tree)
    start = time.time()
    index_lazy = TreeIndex.from_documents(documents, build_tree=False)
    lazy_time = time.time() - start

    print(f"\n  build_tree=False (lazy):  {lazy_time:.2f}s  -- No LLM calls")
    print(f"  build_tree=True  (eager): Requires LLM -- generates summaries at each level")
    print(f"                            Typically 5-30s depending on document size and LLM")

    print("\n" + "=" * 70)
    print("TREE INDEX SUMMARY")
    print("=" * 70)
    print("""
How it works:
  1. Leaf nodes are document chunks
  2. Parent nodes are LLM-generated summaries of their children
  3. Tree is built bottom-up until a root node is reached
  4. Queries traverse from root to relevant leaves

Strengths:
  - Root node already contains a global summary
  - Hierarchical traversal efficiently narrows to relevant content
  - Good for queries ranging from high-level to specific

Weaknesses:
  - Expensive to build (many LLM calls for summaries)
  - Tree structure may not suit all data types
  - Less intuitive than vector search

Best use case:
  "Give me a high-level overview" or "Summarize then drill into details"

Key parameter: child_branch_factor
  - Controls how many child branches to explore at each level
  - Default=1 (fast but may miss relevant branches)
  - Higher values = more thorough but more expensive
""")

    return index


if __name__ == "__main__":
    index = main()
