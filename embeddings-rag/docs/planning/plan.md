# Experiment Plan: Embeddings, Chunking, and RAG

## Goal

Build a minimal but complete RAG pipeline that demonstrates document indexing, chunking, embedding, vector storage, and retrieval-augmented generation. Compare chunking strategies side by side on the same document.

## Architecture

```
Sample Documents
      |
      v
  Chunking (4 strategies)
      |
      v
  Embedding (sentence-transformers, all-MiniLM-L6-v2)
      |
      v
  Vector Store (ChromaDB, one collection per strategy)
      |
      v
  Query Pipeline (embed question -> search -> format context -> print results)
      |
      v
  Comparison Report (retrieval quality across strategies)
```

## Components

### 1. Sample Documents (`data/`)

Two sample documents to index:
- A ~2-page article about Python programming (prose, good for testing sentence/paragraph boundaries)
- A structured FAQ document (tests how strategies handle Q&A format)

These are bundled as plain text files so the experiment is self-contained.

### 2. Chunking Module (`src/chunkers.py`)

Implement four chunking strategies in a single file:
- **Fixed-size:** Split every N characters with configurable overlap
- **Recursive:** Split by paragraphs, then sentences, then characters (mimics LangChain's approach)
- **Sentence-based:** Split on sentence boundaries, group until size limit
- **Semantic:** Use embedding similarity between sentences to find natural break points

Each chunker returns a list of `Chunk` objects with text, metadata (source, strategy, index).

### 3. Indexing Script (`src/index.py`)

- Loads documents from `data/`
- Runs each chunking strategy on each document
- Embeds chunks using sentence-transformers
- Stores in ChromaDB (one collection per strategy: `fixed`, `recursive`, `sentence`, `semantic`)
- Prints stats: number of chunks, average chunk size, indexing time

### 4. Query Script (`src/query.py`)

- Accepts a natural language question
- Queries all four ChromaDB collections
- For each strategy: shows top-3 retrieved chunks with similarity scores
- Side-by-side comparison of what each strategy retrieved

### 5. Comparison Script (`src/compare.py`)

- Runs a set of predefined test questions
- For each question and each strategy: measures retrieval relevance
- Produces a summary table comparing strategies
- Highlights which strategy retrieved the most relevant chunks

## Tech Stack

| Component | Tool | Why |
|-----------|------|-----|
| Embeddings | sentence-transformers (all-MiniLM-L6-v2) | Free, fast, local, no API key |
| Vector DB | ChromaDB | Embedded, zero setup, persistent |
| Language | Python 3.10+ | Standard for ML/AI experiments |
| Tokenization | nltk (punkt) | Sentence splitting |

## File Structure

```
embeddings-rag/
  README.md
  requirements.txt
  data/
    python_guide.txt
    faq.txt
  src/
    chunkers.py      # Four chunking strategies
    index.py         # Index documents into ChromaDB
    query.py         # Interactive query across strategies
    compare.py       # Automated comparison
  docs/
    research/        # Research findings
    planning/        # This plan
```

## How to Run

```bash
pip install -r requirements.txt
python src/index.py          # Index sample docs with all strategies
python src/query.py "What is a list comprehension?"  # Query interactively
python src/compare.py        # Run automated comparison
```

## What a Developer Will Learn

1. How different chunking strategies split the same document differently
2. How chunks become vectors and get stored in a vector database
3. How semantic search retrieves relevant context for a question
4. Why chunking strategy choice matters for retrieval quality
5. The complete RAG pipeline from document to answer

## Scope Boundaries

- No LLM generation step (would require an API key). We show the retrieval part clearly.
- No reranking (adds complexity without teaching new concepts).
- No document parsing (PDF, HTML). We use plain text to focus on the core concepts.
- Semantic chunking is included but noted as expensive. The experiment shows the tradeoff.
