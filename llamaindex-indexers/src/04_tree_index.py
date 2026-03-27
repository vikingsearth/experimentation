"""Step 4: TreeIndex.

Builds a real summary tree and shows how different tree query strategies behave.
"""

import os
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_ROOT / "data"

try:
    from dotenv import load_dotenv

    load_dotenv(PROJECT_ROOT / ".env")
except ImportError:
    pass

from local_llm import build_local_llm


def describe_tree(index):
  root_ids = list(index.index_struct.root_nodes.values())
  all_node_ids = list(index.index_struct.all_nodes.values())

  leaf_count = 0
  summary_count = 0
  for node_id in all_node_ids:
    node = index.docstore.get_node(node_id)
    if index.index_struct.get_children(node):
      summary_count += 1
    else:
      leaf_count += 1

  return {
    "root_count": len(root_ids),
    "total_nodes": len(all_node_ids),
    "leaf_count": leaf_count,
    "summary_count": summary_count,
  }


def main():
    print("=" * 70)
    print("STEP 4: TREE INDEX")
    print("=" * 70)

    from llama_index.core import SimpleDirectoryReader, Settings, TreeIndex
    from llama_index.embeddings.huggingface import HuggingFaceEmbedding

    tree_num_children = int(os.getenv("TREE_NUM_CHILDREN", "3"))
    tree_branch_factor = int(os.getenv("TREE_CHILD_BRANCH_FACTOR", "2"))

    Settings.embed_model = HuggingFaceEmbedding(
        model_name="BAAI/bge-small-en-v1.5"
    )
    print("Loading local GGUF LLM (downloads Q8_0 on first run)...")
    Settings.llm = build_local_llm(PROJECT_ROOT)
    Settings.chunk_size = 256
    Settings.chunk_overlap = 30

    # ------------------------------------------------------------------
    # Load documents
    # ------------------------------------------------------------------
    print("\nLoading documents...")
    documents = SimpleDirectoryReader(input_dir=str(DATA_DIR)).load_data()
    print(f"Loaded {len(documents)} documents")

    # ------------------------------------------------------------------
    # Build TreeIndex eagerly so the demo uses a real summary hierarchy.
    # ------------------------------------------------------------------
    print(
        "\nBuilding eager TreeIndex "
        f"(build_tree=True, num_children={tree_num_children})..."
    )
    import time

    start = time.time()
    index = TreeIndex.from_documents(
        documents,
        build_tree=True,
        num_children=tree_num_children,
    )
    build_time = time.time() - start
    tree_stats = describe_tree(index)
    print(f"Index built in {build_time:.2f}s")
    print(
        "Tree stats: "
        f"{tree_stats['root_count']} root node(s), "
        f"{tree_stats['summary_count']} summary node(s), "
        f"{tree_stats['leaf_count']} leaf node(s)"
    )

    # ------------------------------------------------------------------
    # Query using different tree strategies
    # ------------------------------------------------------------------
    print("\n" + "-" * 70)
    print("TREE INDEX QUERY MODES")
    print("-" * 70)

    broad_query = "Summarize all topics covered in these documents."
    root_nodes = index.as_retriever(retriever_mode="root").retrieve(broad_query)
    print("\n[Mode: root] Inspect precomputed root summaries")
    print(f"  Query: {broad_query}")
    print(f"  Retrieved {len(root_nodes)} root summary node(s)")
    for idx, root_node in enumerate(root_nodes[:2], start=1):
      preview = root_node.node.text[:220].replace("\n", " ")
      print(f"  [{idx}] {preview}...")

    focused_query = "Who is the CEO of TechVista Corporation?"
    narrow_retriever = index.as_retriever(
        retriever_mode="select_leaf_embedding",
      child_branch_factor=1,
    )
    narrow_nodes = narrow_retriever.retrieve(focused_query)
    narrow_sources = [
      node.node.metadata.get("file_name", "?") for node in narrow_nodes
    ]
    print("\n[Mode: select_leaf_embedding, branch_factor=1]")
    print(f"  Query: {focused_query}")
    print(f"  Selected {len(narrow_nodes)} leaf node(s): {narrow_sources}")

    narrow_engine = index.as_query_engine(
        retriever_mode="select_leaf_embedding",
      child_branch_factor=1,
    )
    narrow_response = narrow_engine.query(focused_query)
    print(f"  Answer: {str(narrow_response).strip()[:280]}...")

    wide_query = "What causes greenhouse gas emissions?"
    wide_retriever = index.as_retriever(
      retriever_mode="select_leaf_embedding",
        child_branch_factor=tree_branch_factor,
    )
    wide_nodes = wide_retriever.retrieve(wide_query)
    wide_sources = [node.node.metadata.get("file_name", "?") for node in wide_nodes]
    print(
      f"\n[Mode: select_leaf_embedding, branch_factor={tree_branch_factor}]"
    )
    print(f"  Query: {wide_query}")
    print(f"  Selected {len(wide_nodes)} leaf node(s): {wide_sources}")

    wide_engine = index.as_query_engine(
      retriever_mode="select_leaf_embedding",
      child_branch_factor=tree_branch_factor,
    )
    wide_response = wide_engine.query(wide_query)
    print(f"  Answer: {str(wide_response).strip()[:280]}...")

    # ------------------------------------------------------------------
    # Compare eager and lazy tree builds
    # ------------------------------------------------------------------
    print("\n" + "-" * 70)
    print("BUILD COMPARISON: Eager vs Lazy")
    print("-" * 70)
    start = time.time()
    index_lazy = TreeIndex.from_documents(documents, build_tree=False)
    lazy_time = time.time() - start

    lazy_retriever = index_lazy.as_retriever(retriever_mode="all_leaf")
    lazy_nodes = lazy_retriever.retrieve(broad_query)

    print(f"\n  build_tree=True  (eager): {build_time:.2f}s")
    print(f"  build_tree=False (lazy):  {lazy_time:.2f}s")
    print(
        "  Lazy mode returns all leaves for each query: "
        f"{len(lazy_nodes)} node(s) for the broad summary prompt"
    )

    print("\n" + "=" * 70)
    print("TREE INDEX SUMMARY")
    print("=" * 70)
    print("""
How it works:
  1. Leaf nodes are document chunks
  2. Parent nodes are LLM-generated summaries of their children
  3. Tree is built bottom-up until a root node is reached
  4. Queries can use root summaries, LLM branch selection, or embedding-guided traversal

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

This script defaults to a stronger demo setup:
  - build_tree=True so summaries are created at build time
  - select_leaf_embedding for stable retrieval over the summary hierarchy
  - branch_factor comparison to show precision vs coverage tradeoffs
""")

    return index


if __name__ == "__main__":
    index = main()
