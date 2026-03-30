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
CAG_OLLAMA_URL = os.getenv("CAG_OLLAMA_URL", "http://127.0.0.1:11434/api/generate")
CAG_OLLAMA_MODEL = os.getenv("CAG_OLLAMA_MODEL", os.getenv("OLLAMA_MODEL", "qwen2.5:3b-instruct"))
CAG_REQUEST_TIMEOUT = int(os.getenv("CAG_REQUEST_TIMEOUT", "120"))

STRATEGIES = ["fixed", "recursive", "sentence", "semantic"]
RETRIEVAL_MODES = ["dense", "lexical", "hybrid"]
RELATIONAL_BASELINES = ["dense", "lexical", "hybrid", "graph", "cag", "all"]
