"""
Step 1: Setup and Load Documents

Demonstrates how LlamaIndex loads documents, parses them into nodes,
and shows the fundamental building blocks before indexing.
"""

import os
import sys
from pathlib import Path

# Add project root for imports
PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_ROOT / "data"

# ---------------------------------------------------------------------------
# Optional: load a .env file for OPENAI_API_KEY
# ---------------------------------------------------------------------------
try:
    from dotenv import load_dotenv

    load_dotenv(PROJECT_ROOT / ".env")
except ImportError:
    pass


def main():
    print("=" * 70)
    print("STEP 1: SETUP AND DOCUMENT LOADING")
    print("=" * 70)

    # ------------------------------------------------------------------
    # 1. Load documents with SimpleDirectoryReader
    # ------------------------------------------------------------------
    from llama_index.core import SimpleDirectoryReader

    print(f"\nLoading documents from: {DATA_DIR}")
    reader = SimpleDirectoryReader(input_dir=str(DATA_DIR))
    documents = reader.load_data()

    print(f"Loaded {len(documents)} documents:\n")
    for doc in documents:
        filename = doc.metadata.get("file_name", "unknown")
        preview = doc.text[:80].replace("\n", " ")
        print(f"  - {filename} ({len(doc.text)} chars): {preview}...")

    # ------------------------------------------------------------------
    # 2. Parse documents into nodes using SentenceSplitter
    # ------------------------------------------------------------------
    from llama_index.core.node_parser import SentenceSplitter

    print("\n" + "-" * 70)
    print("PARSING INTO NODES")
    print("-" * 70)

    splitter = SentenceSplitter(chunk_size=256, chunk_overlap=30)
    nodes = splitter.get_nodes_from_documents(documents)

    print(f"\nSentenceSplitter(chunk_size=256, chunk_overlap=30)")
    print(f"Created {len(nodes)} nodes from {len(documents)} documents\n")

    # Show a few sample nodes
    for i, node in enumerate(nodes[:3]):
        source = node.metadata.get("file_name", "unknown")
        print(f"  Node {i} (from {source}):")
        print(f"    Text length: {len(node.text)} chars")
        print(f"    Preview: {node.text[:100].replace(chr(10), ' ')}...")
        print()

    # ------------------------------------------------------------------
    # 3. Show node relationships
    # ------------------------------------------------------------------
    print("-" * 70)
    print("NODE RELATIONSHIPS")
    print("-" * 70)

    sample_node = nodes[1] if len(nodes) > 1 else nodes[0]
    print(f"\nNode 1 relationships:")
    for rel_type, rel_info in sample_node.relationships.items():
        print(f"  {rel_type}: {rel_info.node_id[:40]}...")

    # ------------------------------------------------------------------
    # 4. Demonstrate different chunk sizes
    # ------------------------------------------------------------------
    print("\n" + "-" * 70)
    print("EFFECT OF CHUNK SIZE")
    print("-" * 70)

    for chunk_size in [128, 256, 512, 1024]:
        s = SentenceSplitter(chunk_size=chunk_size, chunk_overlap=20)
        n = s.get_nodes_from_documents(documents)
        print(f"  chunk_size={chunk_size:>5} -> {len(n):>3} nodes")

    print("\nSmaller chunks = more nodes = finer granularity but more retrieval noise")
    print("Larger chunks = fewer nodes = more context per chunk but may miss details")

    print("\n" + "=" * 70)
    print("SETUP COMPLETE - Documents loaded and parsed successfully")
    print("=" * 70)

    return documents, nodes


if __name__ == "__main__":
    documents, nodes = main()
