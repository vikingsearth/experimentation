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
- **Local llama.cpp GGUF model** for scripts that require an LLM

The LLM-backed scripts now use:
- Repo: `tensorblock/llama3.2-1b-Uncensored-GGUF`
- File: `llama3.2-1b-Uncensored-Q8_0.gguf`
- Revision: `231935b9839df1237fd65a1b106a6c16029174d4`

That revision is pinned intentionally because the current `main` branch no longer ships
the `Q8_0` file.

On first run, the scripts download the GGUF into `models/` automatically. If you already
have the file locally, set `LOCAL_LLM_MODEL_PATH` in `.env` and the scripts will use that
path instead.

Optional tuning variables:
- `LOCAL_LLM_N_GPU_LAYERS=0` for CPU-only inference
- `LOCAL_LLM_DIR=...` to change the download directory
- `LOCAL_LLM_CONTEXT_WINDOW=4096` to tune context length
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

The first LLM-backed run will take longer because it downloads about 1.3 GB of GGUF
weights before starting.

The repo also supports a checked-in `.env` file for local defaults. This is especially
useful for the pinned GGUF revision, tree fanout, and CPU/GPU settings.

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
