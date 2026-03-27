"""
Step 6: Compare All Index Types

Runs the same queries against all four index types and compares:
- Which documents each index retrieves
- Retrieval speed
- When each index type shines

This is the "aha moment" script that ties the whole experiment together.
"""

import os
import time
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_ROOT / "data"

try:
    from dotenv import load_dotenv

    load_dotenv(PROJECT_ROOT / ".env")
except ImportError:
    pass

from local_llm import build_local_llm


TREE_NUM_CHILDREN = int(os.getenv("TREE_NUM_CHILDREN", "3"))
TREE_CHILD_BRANCH_FACTOR = int(os.getenv("TREE_CHILD_BRANCH_FACTOR", "3"))


def build_all_indices(documents):
    """Build all four index types from the same documents."""
    from llama_index.core import (
        VectorStoreIndex,
        SummaryIndex,
        TreeIndex,
        SimpleKeywordTableIndex,
        Settings,
    )
    from llama_index.embeddings.huggingface import HuggingFaceEmbedding

    Settings.embed_model = HuggingFaceEmbedding(
        model_name="BAAI/bge-small-en-v1.5"
    )
    print("  Loading local GGUF LLM...", end=" ", flush=True)
    Settings.llm = build_local_llm(PROJECT_ROOT)
    print("done")
    Settings.chunk_size = 256
    Settings.chunk_overlap = 30

    indices = {}

    # VectorStoreIndex
    print("  Building VectorStoreIndex...", end=" ", flush=True)
    start = time.time()
    indices["VectorStore"] = VectorStoreIndex.from_documents(documents)
    print(f"({time.time() - start:.2f}s)")

    # SummaryIndex
    print("  Building SummaryIndex...", end=" ", flush=True)
    start = time.time()
    indices["Summary"] = SummaryIndex.from_documents(documents)
    print(f"({time.time() - start:.2f}s)")

    # TreeIndex (eager hierarchy)
    print("  Building TreeIndex (eager)...", end=" ", flush=True)
    start = time.time()
    indices["Tree"] = TreeIndex.from_documents(
        documents,
        build_tree=True,
        num_children=TREE_NUM_CHILDREN,
    )
    print(f"({time.time() - start:.2f}s)")

    # KeywordTableIndex (simple/regex-based)
    print("  Building KeywordTableIndex (simple)...", end=" ", flush=True)
    start = time.time()
    indices["KeywordTable"] = SimpleKeywordTableIndex.from_documents(documents)
    print(f"({time.time() - start:.2f}s)")

    return indices


def query_all_indices(indices, query, top_k=3):
    """Query all indices and return results for comparison."""
    results = {}

    for name, index in indices.items():
        start = time.time()
        try:
            if name == "Summary":
                # Use embedding mode for fair comparison (default returns ALL)
                retriever = index.as_retriever(
                    retriever_mode="embedding", similarity_top_k=top_k
                )
            elif name == "Tree":
                if "summarize" in query.lower() or "topics covered" in query.lower():
                    retriever = index.as_retriever(retriever_mode="root")
                else:
                    retriever = index.as_retriever(
                        retriever_mode="select_leaf_embedding",
                        child_branch_factor=TREE_CHILD_BRANCH_FACTOR,
                    )
            elif name == "VectorStore":
                retriever = index.as_retriever(similarity_top_k=top_k)
            elif name == "KeywordTable":
                retriever = index.as_retriever(retriever_mode="simple")
            else:
                retriever = index.as_retriever()

            retrieved = retriever.retrieve(query)
            query_time = time.time() - start

            results[name] = {
                "nodes": retrieved[:top_k],  # Limit for display
                "total_count": len(retrieved),
                "time": query_time,
                "error": None,
            }
        except Exception as e:
            results[name] = {
                "nodes": [],
                "total_count": 0,
                "time": time.time() - start,
                "error": str(e),
            }

    return results


def display_comparison(query, results, expected_best):
    """Display a formatted comparison of results across all indices."""
    print(f"\n{'=' * 70}")
    print(f"QUERY: {query}")
    print(f"Expected best index: {expected_best}")
    print(f"{'=' * 70}")

    for name, data in results.items():
        marker = " <-- EXPECTED BEST" if name == expected_best else ""
        print(f"\n  [{name}]{marker}")

        if data["error"]:
            print(f"    ERROR: {data['error']}")
            continue

        print(f"    Retrieved: {data['total_count']} nodes in {data['time']:.3f}s")

        if data["nodes"]:
            # Show sources retrieved
            sources = [
                n.node.metadata.get("file_name", "?") for n in data["nodes"]
            ]
            print(f"    Sources: {sources}")

            # Show top result
            top = data["nodes"][0]
            score_str = f"Score: {top.score:.4f}" if top.score else "Score: N/A"
            preview = top.node.text[:100].replace("\n", " ")
            print(f"    Top result: {score_str}")
            print(f"    Preview: {preview}...")
        else:
            print("    No results retrieved")


def main():
    print("=" * 70)
    print("STEP 6: COMPARE ALL INDEX TYPES")
    print("=" * 70)

    from llama_index.core import SimpleDirectoryReader

    # ------------------------------------------------------------------
    # Load documents
    # ------------------------------------------------------------------
    print("\nLoading documents...")
    documents = SimpleDirectoryReader(input_dir=str(DATA_DIR)).load_data()
    print(f"Loaded {len(documents)} documents")

    # ------------------------------------------------------------------
    # Build all indices
    # ------------------------------------------------------------------
    print("\nBuilding all indices from the same documents...")
    indices = build_all_indices(documents)
    print("All indices built!\n")

    # ------------------------------------------------------------------
    # Define test queries with expected best index
    # ------------------------------------------------------------------
    test_queries = [
        {
            "query": "What is Python used for?",
            "expected_best": "VectorStore",
            "reason": "Semantic similarity finds the Python overview chunk easily",
        },
        {
            "query": "What ingredients do I need for spaghetti carbonara?",
            "expected_best": "KeywordTable",
            "reason": "Specific keywords (spaghetti, carbonara, ingredients) match directly",
        },
        {
            "query": "Who is the CEO of TechVista Corporation?",
            "expected_best": "VectorStore",
            "reason": "Specific factual question, vector search finds the relevant chunk",
        },
        {
            "query": "Summarize all topics covered in these documents",
            "expected_best": "Summary",
            "reason": "Summary index reads ALL nodes, perfect for global summarization",
        },
        {
            "query": "What causes greenhouse gas emissions?",
            "expected_best": "VectorStore",
            "reason": "Semantic search understands 'greenhouse gas' relates to climate content",
        },
    ]

    # ------------------------------------------------------------------
    # Run all queries across all indices
    # ------------------------------------------------------------------
    print("-" * 70)
    print("RUNNING COMPARISON QUERIES")
    print("-" * 70)

    for test in test_queries:
        results = query_all_indices(indices, test["query"])
        display_comparison(test["query"], results, test["expected_best"])
        print(f"\n  Reasoning: {test['reason']}")

    # ------------------------------------------------------------------
    # Summary table
    # ------------------------------------------------------------------
    print("\n" + "=" * 70)
    print("FINAL COMPARISON TABLE")
    print("=" * 70)
    print(f"""
    {'Index Type':<20} {'Build Cost':<15} {'Query Cost':<15} {'Best For'}
    {'-'*20} {'-'*15} {'-'*15} {'-'*30}
    {'VectorStore':<20} {'Medium':<15} {'Low':<15} {'Semantic Q&A, factual queries'}
    {'Summary':<20} {'None':<15} {'High':<15} {'Summarization, small corpora'}
    {'Tree':<20} {'High':<15} {'Medium':<15} {'Hierarchical retrieval and summaries'}
    {'KeywordTable':<20} {'Low':<15} {'Low':<15} {'Keyword routing, exact terms'}
    """)

    print("=" * 70)
    print("KEY TAKEAWAYS")
    print("=" * 70)
    print("""
    1. VectorStoreIndex is the best default choice for most use cases.
       It handles semantic similarity well and scales with vector DB backends.

    2. SummaryIndex is ideal when you need to consider ALL data -- like
       summarization. But it's expensive for large document sets.

    3. TreeIndex excels at hierarchical understanding -- from high-level
       overviews to specific details. Cost is paid at build time.

    4. KeywordTableIndex is the fastest to build (regex variant) and works
       well for keyword-specific routing. Combine it with vector search
       for hybrid retrieval.

    5. In practice, composing multiple index types with a RouterQueryEngine
       gives the best results: route keyword queries to KeywordTable,
       semantic queries to VectorStore, and summarization to SummaryIndex.
    """)


if __name__ == "__main__":
    main()
