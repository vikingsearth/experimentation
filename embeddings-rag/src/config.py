"""Shared configuration for the embeddings-rag experiment."""

import os


PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(PROJECT_ROOT, "data")
CHROMA_DIR = os.path.join(PROJECT_ROOT, "chroma_db")
RELATIONAL_DATA_DIR = os.path.join(DATA_DIR, "relational")
RELATIONAL_QUESTIONS_FILE = os.path.join(RELATIONAL_DATA_DIR, "questions.json")

EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "all-MiniLM-L6-v2")
CHUNK_SIZE = int(os.getenv("CHUNK_SIZE", "500"))
TOP_K = int(os.getenv("TOP_K", "3"))
RELATIONAL_DEFAULT_STRATEGY = os.getenv("RELATIONAL_DEFAULT_STRATEGY", "recursive")

STRATEGIES = ["fixed", "recursive", "sentence", "semantic"]
RETRIEVAL_MODES = ["dense", "lexical", "hybrid"]
RELATIONAL_BASELINES = ["dense", "lexical", "hybrid", "graph", "all"]
