"""Shared configuration for the embeddings-rag experiment."""

import os


PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(PROJECT_ROOT, "data")
CHROMA_DIR = os.path.join(PROJECT_ROOT, "chroma_db")

EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "all-MiniLM-L6-v2")
CHUNK_SIZE = int(os.getenv("CHUNK_SIZE", "500"))
TOP_K = int(os.getenv("TOP_K", "3"))

STRATEGIES = ["fixed", "recursive", "sentence", "semantic"]
RETRIEVAL_MODES = ["dense", "lexical", "hybrid"]
