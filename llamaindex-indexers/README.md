# LlamaIndex Indexers Experiment

An experiment comparing different LlamaIndex index types to understand how each one works,
when to use it, and how they differ in practice.

## What This Demonstrates

LlamaIndex provides multiple index types for organizing data for LLM-powered retrieval.
This experiment builds **four different index types** from the same set of documents and
queries them with the same questions to show their different behaviors:

| Index Type | How It Works | Best For |
|------------|-------------|----------|
| **VectorStoreIndex** | Embeds nodes, retrieves by cosine similarity | General Q&A, semantic search |
| **SummaryIndex** | Stores nodes in a list, reads all at query time | Summarization, small corpora |
| **TreeIndex** | Builds hierarchical summary tree | Overview-to-detail queries |
| **KeywordTableIndex** | Maps keywords to nodes via regex | Keyword routing, exact terms |

## Project Structure

```
llamaindex-indexers/
  data/                            # 5 sample documents (Python, ML, climate, company, recipes)
  src/
    01_setup_and_load.py           # Load documents, demonstrate node parsing
    02_vector_store_index.py       # Build and query VectorStoreIndex
    03_summary_index.py            # Build and query SummaryIndex
    04_tree_index.py               # Build and query TreeIndex
    05_keyword_table_index.py      # Build and query KeywordTableIndex
    06_compare_all.py              # Compare all indices side-by-side
  docs/
    research/                      # Research notes on LlamaIndex
    planning/                      # Experiment plan
  requirements.txt
```

## Setup

```bash
# Create a virtual environment
python -m venv .venv

# Activate it
# Windows:
.venv\Scripts\activate
# Linux/Mac:
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# If behind a corporate proxy with SSL issues:
pip install pip-system-certs
```

No OpenAI API key is needed -- the experiment uses:
- **HuggingFace BGE-small** for embeddings (free, runs locally)
- **Ollama** for scripts that require an LLM

The default local model is:
- Ollama model: `qwen2.5:3b-instruct`

You can swap models by changing `OLLAMA_MODEL` in `.env`. Two local candidates already
downloaded on this machine are `qwen2.5:3b` / `qwen2.5:3b-instruct` and `llama3.2:3b`.

Optional tuning variables:
- `OLLAMA_BASE_URL=http://127.0.0.1:11434` to target a different Ollama server
- `OLLAMA_CONTEXT_WINDOW=4096` to tune context length
- `OLLAMA_REQUEST_TIMEOUT=180` to allow longer local generations
- `OLLAMA_NUM_PREDICT=256` to cap output length
- `TREE_NUM_CHILDREN=3` to control tree fanout
- `TREE_CHILD_BRANCH_FACTOR=3` to control how many branches tree traversal explores

## Running

Each script is standalone. Run them in order for the best learning experience:

```bash
python src/01_setup_and_load.py       # ~2s  - understand documents and nodes
python src/02_vector_store_index.py   # ~5s  - the default/most common index
python src/03_summary_index.py        # ~5s  - read-everything approach
python src/04_tree_index.py           # ~3s  - hierarchical summaries
python src/05_keyword_table_index.py  # ~3s  - keyword-based lookup
python src/06_compare_all.py          # ~10s - the big comparison
```

The repo also supports a checked-in `.env` file for local defaults. This is especially
useful for Ollama model selection, tree fanout, and timeout settings.

**Start with `06_compare_all.py`** if you just want the key takeaway.

## What to Expect

The comparison script runs 5 queries across all 4 index types and shows:
- Which source documents each index retrieves
- Relevance scores (for vector/embedding-based indices)
- Retrieval speed differences
- Why certain indices are better for certain query types

Key finding: **VectorStoreIndex is the best default choice**, but combining multiple
index types with a RouterQueryEngine gives the best overall results.

## Research Notes

See `docs/research/` for detailed notes on:
- LlamaIndex architecture and core concepts
- Deep dive into each index type's internals
- Comparison with LangChain and Haystack
- Advanced retrieval strategies (hybrid search, reranking, composable indices)
