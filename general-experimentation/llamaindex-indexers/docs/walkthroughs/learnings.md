# What You Can Learn From This Experiment

If you're new to LlamaIndex or RAG in general, this experiment demonstrates several concepts that are hard to absorb from documentation alone. Here's what to pay attention to.

## 1. There is no single best index type

The central insight of `src/06_compare_all.py` is that each index type wins on different queries:

| Query | Winner | Why |
|-------|--------|-----|
| "What is Python used for?" | VectorStore | Semantic similarity maps the question to the Python overview chunk |
| "What ingredients for spaghetti carbonara?" | KeywordTable | Exact keyword match ("spaghetti", "carbonara") routes directly |
| "Who is the CEO of TechVista?" | VectorStore | Factual lookup via embedding similarity |
| "Summarize all topics" | Summary | Only Summary considers every document |
| "What causes greenhouse gas emissions?" | VectorStore | Semantic understanding of "greenhouse gas" → climate content |

VectorStore wins 3 out of 5 — it really is the best default. But it can't summarize everything (Summary's job) and it's slower than keyword lookup when exact terms suffice.

The practical takeaway: **compose multiple indices with a RouterQueryEngine**. Route keyword-heavy queries to KeywordTable, semantic queries to VectorStore, and summarization to Summary. This is described in `06_compare_all.py` lines 249-266 but not yet implemented in code.

## 2. You can run RAG entirely offline

This experiment uses zero commercial APIs:

- **Embeddings:** HuggingFace `BAAI/bge-small-en-v1.5` — free, runs locally, ~130MB download
- **LLM:** Ollama with `qwen2.5:3b-instruct` or `llama3.2:3b` — free, runs locally
- **Configuration:** All in `.env`, no API keys

The tradeoff is quality. A 3B parameter model produces adequate retrieval but weak summaries compared to GPT-4 or Claude. The experiment makes this tradeoff visible rather than hiding it.

## 3. Chunking parameters matter more than you'd expect

`src/01_setup_and_load.py` tests four chunk sizes on the same documents:

| Chunk size | Effect |
|-----------|--------|
| 128 tokens | More nodes, finer granularity, but splits mid-thought |
| 256 tokens | The experiment default — balanced |
| 512 tokens | Fewer nodes, more context per chunk |
| 1024 tokens | Some documents become a single node — no retrieval selectivity |

The `chunk_overlap=30` setting preserves context across boundaries. Without overlap, a sentence split across two chunks loses its meaning in both.

This is the kind of thing that's easy to set once and forget, but the wrong chunk size can make or break retrieval quality.

## 4. TreeIndex is powerful in theory, limited by model capacity

TreeIndex builds a bottom-up summary hierarchy: leaf nodes are document chunks, parent nodes are LLM-generated summaries, and the root is a summary of summaries.

In principle, this gives you:
- Instant high-level overviews (just read the root)
- Efficient drill-down (traverse the tree to the relevant leaf)
- Multiple query strategies (root, select_leaf, select_leaf_embedding)

In practice with 3B models, the root summary is weak. The LLM doesn't have enough capacity to produce a coherent summary-of-summaries. Both `qwen2.5:3b-instruct` and `llama3.2:3b` produce the same source-hit score (18/25) and similarly poor root summaries.

This is visible in `src/07_benchmark_models.py`'s qualitative snapshots — the `tree_root_preview` field shows what the model actually generated.

## 5. Build cost vs query cost is a real tradeoff

Each index pays its cost at a different time:

| Index | Build cost | Query cost | When to choose |
|-------|-----------|------------|----------------|
| VectorStore | Medium (compute embeddings) | Low (vector similarity) | Default choice |
| Summary | None | High (reads all nodes) | Small corpus, need completeness |
| Tree | High (LLM generates summaries) | Medium (tree traversal) | Hierarchical data with strong LLM |
| KeywordTable (Simple) | Low (regex extraction) | Low (keyword lookup) | Exact-term routing |

TreeIndex took 141-185 seconds to build in benchmarks. VectorStore and KeywordTable built in under 5 seconds. If your corpus changes frequently, build cost dominates.

## 6. Benchmarking local models requires methodology

Naive benchmarking (just time it) gives misleading results because:
- **Cold start:** The first query after loading a model is much slower
- **Model caching:** Ollama keeps models in memory; a "fast" model might just be the one that was already loaded
- **Variance:** Small models on CPU have significant run-to-run variance

`src/07_benchmark_models.py` addresses this with:
1. `reset_running_models()` — stops all loaded models before each benchmark
2. `warmup_model()` — runs a trivial prompt to load the model into memory
3. Separate timing for build vs query phases
4. Source-hit accuracy (not just speed) as a metric
5. Qualitative snapshots for manual review of output quality

## 7. Retriever modes change everything

The same index can behave completely differently depending on the retriever mode. TreeIndex is the clearest example (`src/04_tree_index.py`):

- `retriever_mode="root"` — returns the precomputed root summary (instant, broad)
- `retriever_mode="select_leaf_embedding"` with `child_branch_factor=1` — narrow path to one leaf (fast, precise)
- `retriever_mode="select_leaf_embedding"` with `child_branch_factor=3` — explores multiple branches (thorough, slower)

SummaryIndex also has two modes (`src/03_summary_index.py`):
- `retriever_mode="default"` — returns every node (exhaustive)
- `retriever_mode="embedding"` — uses embeddings to select top-k (selective)

Understanding retriever modes is what separates "I used LlamaIndex" from "I used the right retrieval strategy."

## Summary

The experiment teaches you to think about index selection as a design decision, not a default. Each index type exists because it solves a specific retrieval pattern better than the others. The real skill is matching your query patterns to the right index — or composing multiple indices to cover all patterns.
