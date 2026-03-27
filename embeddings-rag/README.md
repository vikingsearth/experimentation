# Embeddings, Chunking Strategies, and Augmented Generation

A hands-on experiment focused on how AI systems ground answers in external knowledge. The current implementation demonstrates chunking strategies, embeddings, a local vector database, dense retrieval, and local lexical or hybrid retrieval over the same chunk sets. The planning docs define the next refactor steps toward a broader benchmark suite covering multiple retrieval and augmentation approaches.

## What This Does Today

Today the project takes two sample documents, splits them using four different chunking strategies, embeds the chunks into vectors, stores them in a local vector database (ChromaDB), and lets you query across all strategies using dense, lexical, or hybrid retrieval to compare retrieval quality.

In other words, the current codebase is now a chunking plus local retrieval experiment with multiple retrieval signals, but it is still narrower than a full comparison of augmentation strategies.

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
python src/query.py --retrieval lexical "What is a list comprehension?"
python src/query.py --retrieval hybrid "What is a list comprehension?"
```

Shows the top results from each strategy. Dense mode uses Chroma similarity search, lexical mode uses local BM25-style scoring, and hybrid mode fuses both signals. Run without arguments for interactive mode.

### 3. Compare strategies

```bash
python src/compare.py
python src/compare.py --retrieval hybrid
```

Runs 8 predefined test questions against all strategies. Produces a comparison table with retrieval scores and keyword relevance for the selected retrieval mode.

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
    planning/            # Experiment and refactor plans
```

## Current Scope vs Planned Scope

Current scope:
- Compare four chunking strategies over one embedding model.
- Use a single local vector database backend: ChromaDB.
- Compare dense, lexical, and hybrid retrieval over the same chunk sets.
- Measure retrieval quality using retrieval-score and keyword heuristics.

Planned refactor scope:
- Compare multiple vector storage backends, not just ChromaDB.
- Add multiple retrieval baselines, not just dense vector search.
- Add a small-corpus no-retrieval baseline aligned with CAG-style evaluation.
- Add a GraphRAG baseline for relational or multi-hop questions.
- Introduce dataset-specific evaluation so graph methods are tested on data that actually rewards graph traversal.

The planning details for that expansion live in [docs/planning/plan.md](docs/planning/plan.md) and [docs/planning/refactor-implementation.md](docs/planning/refactor-implementation.md).

## Key Concepts Demonstrated

1. **Chunking** -- how different splitting strategies affect what gets retrieved
2. **Embeddings** -- converting text to vectors that capture semantic meaning
3. **Vector database** -- storing and searching vectors by similarity
4. **Dense retrieval** -- the document-to-vector-to-nearest-neighbor flow used in many RAG systems

Planned additions expand beyond this into hybrid retrieval, graph-based retrieval, and small-corpus no-retrieval baselines.

## Research Notes

See `docs/research/` for detailed notes on:
- [Chunking strategies](docs/research/chunking-strategies.md)
- [Vector databases](docs/research/vector-databases.md)
- [RAG vs CAG](docs/research/rag-vs-cag.md)
- [Embedding models](docs/research/embedding-models.md)

See `docs/planning/` for the revised benchmark scope and implementation plan:
- [Revised experiment plan](docs/planning/plan.md)
- [Refactor implementation plan](docs/planning/refactor-implementation.md)

## Tech Stack

- **sentence-transformers** (all-MiniLM-L6-v2) -- free, local embedding model
- **ChromaDB** -- embedded vector database, zero infrastructure
- **nltk** -- sentence tokenization
- **numpy** -- vector operations

The current stack is intentionally local-first. The refactor plan preserves that constraint wherever practical so additional baselines can still be run without managed cloud services or API keys.
