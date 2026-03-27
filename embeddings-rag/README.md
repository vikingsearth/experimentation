# Embeddings, Chunking Strategies, and RAG

A hands-on experiment demonstrating how document indexing works for AI/LLM context: chunking strategies, vector embeddings, vector databases, and retrieval-augmented generation (RAG).

## What This Does

Takes two sample documents, splits them using four different chunking strategies, embeds the chunks into vectors, stores them in a local vector database (ChromaDB), and lets you query across all strategies to compare retrieval quality.

### Chunking Strategies Compared

| Strategy | How It Works |
|----------|-------------|
| **Fixed-size** | Split every N characters with overlap. Simple but cuts mid-sentence. |
| **Recursive** | Split by paragraphs, then sentences, then characters. Preserves structure. |
| **Sentence-based** | Group sentences up to a size limit. Never splits a sentence. |
| **Semantic** | Use embedding similarity to detect meaning shifts. Most expensive. |

## Prerequisites

- Python 3.10+
- ~2 GB disk space (for the embedding model on first run)
- Internet connection (first run only, to download the model)

## Setup

```bash
cd embeddings-rag
python -m venv .venv

# Windows
.venv\Scripts\activate

# macOS/Linux
source .venv/bin/activate

pip install -r requirements.txt
```

## How to Run

### 1. Index documents

```bash
python src/index.py
```

Loads sample docs from `data/`, chunks them with all four strategies, embeds them, and stores in ChromaDB. Prints chunk count and size stats per strategy.

### 2. Query interactively

```bash
python src/query.py "What is a list comprehension?"
```

Shows the top-3 most similar chunks from each strategy with similarity scores. Run without arguments for interactive mode.

### 3. Compare strategies

```bash
python src/compare.py
```

Runs 8 predefined test questions against all strategies. Produces a comparison table with similarity scores and keyword relevance.

## What to Expect

The comparison shows that **recursive chunking** typically performs best overall because it preserves paragraph boundaries while keeping chunks within a size limit. Semantic chunking produces the most focused chunks but creates many small pieces. Fixed-size chunking is the simplest but splits mid-sentence.

Example output (abbreviated):

```
  Strategy       Avg Similarity   Avg Keyword Score   Combined Score
  -----------------------------------------------------------------
  fixed                  0.4915              100.0%           0.6949
  recursive              0.6232               96.9%           0.7614
  sentence               0.5554               96.9%           0.7207
  semantic               0.5324               93.8%           0.6944

  Best performing strategy: RECURSIVE
```

## Project Structure

```
embeddings-rag/
  README.md              # This file
  requirements.txt       # Python dependencies
  data/                  # Sample documents to index
    python_guide.txt     # Python programming guide (~7.5K chars)
    faq.txt              # ML FAQ document (~7K chars)
  src/
    _ssl_workaround.py   # SSL fix for corporate proxies (delete if not needed)
    chunkers.py          # Four chunking strategy implementations
    index.py             # Index documents into ChromaDB
    query.py             # Query the index interactively
    compare.py           # Automated strategy comparison
  docs/
    research/            # Research notes on the underlying concepts
    planning/            # Experiment plan
```

## Key Concepts Demonstrated

1. **Chunking** -- how different splitting strategies affect what gets retrieved
2. **Embeddings** -- converting text to vectors that capture semantic meaning
3. **Vector database** -- storing and searching vectors by similarity
4. **RAG pipeline** -- the full flow from document to retrieval result

## Research Notes

See `docs/research/` for detailed notes on:
- [Chunking strategies](docs/research/chunking-strategies.md)
- [Vector databases](docs/research/vector-databases.md)
- [RAG vs CAG](docs/research/rag-vs-cag.md)
- [Embedding models](docs/research/embedding-models.md)

## Tech Stack

- **sentence-transformers** (all-MiniLM-L6-v2) -- free, local embedding model
- **ChromaDB** -- embedded vector database, zero infrastructure
- **nltk** -- sentence tokenization
- **numpy** -- vector operations
