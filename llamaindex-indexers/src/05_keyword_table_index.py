"""
Step 5: KeywordTableIndex

Maps keywords to nodes using a keyword extraction approach.
Queries are matched by extracting keywords and looking them up in the table.

Key characteristics:
- Build cost: Low (simple variant uses regex, no LLM)
- Query cost: Low (keyword matching)
- Best for: Keyword-specific routing, structured/categorical data
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


def main():
    print("=" * 70)
    print("STEP 5: KEYWORD TABLE INDEX")
    print("=" * 70)

    from llama_index.core import (
        SimpleDirectoryReader,
        Settings,
        SimpleKeywordTableIndex,
    )
    from llama_index.embeddings.huggingface import HuggingFaceEmbedding

    Settings.embed_model = HuggingFaceEmbedding(
        model_name="BAAI/bge-small-en-v1.5"
    )
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
    # Build KeywordTableIndex (Simple variant -- regex-based, no LLM)
    # ------------------------------------------------------------------
    print("\nBuilding SimpleKeywordTableIndex (regex-based)...")
    import time

    start = time.time()
    index = SimpleKeywordTableIndex.from_documents(documents)
    build_time = time.time() - start
    print(f"Index built in {build_time:.2f}s")

    # ------------------------------------------------------------------
    # Inspect the keyword table
    # ------------------------------------------------------------------
    print("\n" + "-" * 70)
    print("KEYWORD TABLE CONTENTS (sample)")
    print("-" * 70)

    # The keyword table maps keywords to node IDs
    keyword_table = index.index_struct.table
    all_keywords = sorted(keyword_table.keys())

    print(f"\nTotal unique keywords: {len(all_keywords)}")
    print(f"\nSample keywords (first 30):")
    for kw in all_keywords[:30]:
        node_count = len(keyword_table[kw])
        print(f"  '{kw}' -> {node_count} node(s)")

    # Show some domain-specific keywords
    print(f"\nDomain-specific keywords found:")
    interesting_keywords = [
        "python", "machine", "learning", "climate", "carbon",
        "techvista", "spaghetti", "neural", "ceo", "ingredients",
        "recipe", "temperature", "algorithm", "funding",
    ]
    for kw in interesting_keywords:
        if kw in keyword_table:
            print(f"  '{kw}' -> {len(keyword_table[kw])} node(s)")
        else:
            print(f"  '{kw}' -> NOT FOUND")

    # ------------------------------------------------------------------
    # Query the index
    # ------------------------------------------------------------------
    print("\n" + "-" * 70)
    print("QUERYING KEYWORD TABLE INDEX")
    print("-" * 70)

    retriever = index.as_retriever(retriever_mode="simple")

    queries = [
        "What is Python used for?",
        "What ingredients do I need for pasta carbonara?",
        "Who is the CEO of TechVista?",
        "What are the effects of climate change?",
        "Tell me about neural networks",
    ]

    for query in queries:
        print(f"\nQuery: {query}")
        print("-" * 50)

        start = time.time()
        try:
            results = retriever.retrieve(query)
            query_time = time.time() - start

            if results:
                for i, r in enumerate(results[:3]):
                    source = r.node.metadata.get("file_name", "unknown")
                    preview = r.node.text[:100].replace("\n", " ")
                    print(f"  [{i+1}] Source: {source}")
                    print(f"      {preview}...")
                print(f"  (Retrieved {len(results)} nodes in {query_time:.3f}s)")
            else:
                print(f"  No results -- keywords not matched!")
        except Exception as e:
            print(f"  Error: {e}")

    # ------------------------------------------------------------------
    # Show how keyword matching works
    # ------------------------------------------------------------------
    print("\n" + "-" * 70)
    print("HOW KEYWORD MATCHING WORKS")
    print("-" * 70)
    print("""
    Build time:
      1. Each node's text is analyzed for keywords
      2. Simple variant: regex extracts words (no LLM needed)
      3. LLM variant: LLM extracts meaningful keywords (more accurate, costly)
      4. A mapping table is built: keyword -> [node_id1, node_id2, ...]

    Query time:
      1. Keywords are extracted from the query
      2. Keywords are looked up in the table
      3. All nodes matching any keyword are returned
      4. Results are passed to the response synthesizer

    Example:
      Query: "What is Python used for?"
      Extracted keywords: ["python", "used"]
      Lookup: "python" -> [node_3, node_7], "used" -> [node_1, node_3, node_12]
      Retrieved: [node_1, node_3, node_7, node_12]
    """)

    print("=" * 70)
    print("KEYWORD TABLE INDEX SUMMARY")
    print("=" * 70)
    print("""
Strengths:
  - Very fast build (regex variant needs no LLM)
  - Fast query (dictionary lookup)
  - Good for keyword-specific routing
  - Complements vector search in hybrid setups

Weaknesses:
  - Misses semantic meaning (synonyms, paraphrases)
  - "Tell me about AI" won't match "artificial intelligence" unless both indexed
  - Keyword extraction quality varies

Best use case:
  Keyword-specific routing, structured data with known terminology
""")

    return index


if __name__ == "__main__":
    index = main()
