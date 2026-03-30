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

You can swap models by changing `OLLAMA_MODEL` in `.env`. The two local candidates used
for comparison are `qwen2.5:3b-instruct` and `llama3.2:3b`.

Current recommendation:
- Keep `qwen2.5:3b-instruct` as the default if you want the safer instruction-tuned baseline.
- Keep `llama3.2:3b` available when you care more about build/query speed.
- The included `src/07_benchmark_models.py` script measures speed, source-hit counts,
  and prints short qualitative snapshots for manual review.

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

If you want to compare local Ollama models directly, run:

```bash
python src/07_benchmark_models.py
```

That benchmark now does two extra things by default:
- Stops any already-loaded Ollama models, then warms the target model before timing.
- Prints short qualitative snapshots so you can compare summary phrasing, not just speed.

You can also pass explicit model names:

```bash
python src/07_benchmark_models.py --models qwen2.5:3b-instruct llama3.2:3b
```

If you want a faster, less controlled run, you can disable either extra step:

```bash
python src/07_benchmark_models.py --skip-clean-warmup --skip-qualitative
```

Latest checked run on 2026-03-30 using clean warmup:

| Model | Tree build | Avg Tree query | Source-hit total | Qualitative note |
|-------|------------|----------------|------------------|------------------|
| `qwen2.5:3b-instruct` | `185.59s` | `0.375s` | `18` | More conservative baseline, but still weak on root-summary quality |
| `llama3.2:3b` | `141.49s` | `0.366s` | `18` | Clearly faster, but root-summary output is still weak on this corpus |

Current conclusion from that run:
- `llama3.2:3b` is the better speed pick.
- `qwen2.5:3b-instruct` remains the safer default because it is instruction-tuned.
- Neither 3B model is producing a genuinely strong `TreeIndex` root summary here, so the
  next real improvement would come from a better local model or a different tree strategy,
  not from more benchmark churn between these two.

## What to Expect

The comparison script runs 5 queries across all 4 index types and shows:
- Which source documents each index retrieves
- Relevance scores (for vector/embedding-based indices)
- Retrieval speed differences
- Why certain indices are better for certain query types

Key finding: **VectorStoreIndex is the best default choice**, but combining multiple
index types with a RouterQueryEngine gives the best overall results.

Operational finding: there is a real tradeoff between the two local Ollama models.
`llama3.2:3b` is currently faster in the automated benchmark. `qwen2.5:3b-instruct`
is still the safer default for a tiny local instruct model, but neither model is giving
strong `TreeIndex` root summaries on this dataset.

## Research Notes

For a visual walkthrough, see `docs/diagrams.md`.

See `docs/research/` for detailed notes on:
- LlamaIndex architecture and core concepts
- Deep dive into each index type's internals
- Comparison with LangChain and Haystack
- Advanced retrieval strategies (hybrid search, reranking, composable indices)

See `docs/planning/plan.md` for the implementation plan and current status notes.
