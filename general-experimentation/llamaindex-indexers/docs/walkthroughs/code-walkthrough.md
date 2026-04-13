# Code Walkthrough

A script-by-script tour of the implementation, highlighting the key patterns and non-obvious choices.

---

## `ollama_llm.py` — The LLM factory

This helper centralizes Ollama configuration so every script gets the same LLM instance.

```python
@lru_cache(maxsize=8)
def build_local_llm(model_name=None):
    ...
    return Ollama(
        model=model_name,
        base_url=os.getenv("OLLAMA_BASE_URL", "http://127.0.0.1:11434"),
        request_timeout=float(os.getenv("OLLAMA_REQUEST_TIMEOUT", "180")),
        ...
    )
```

**What to notice:**
- `@lru_cache` means repeated calls with the same model name return the cached client. This avoids re-establishing connections. The benchmark script explicitly calls `build_local_llm.cache_clear()` when switching models (`07_benchmark_models.py:189`).
- Every parameter reads from an environment variable with a sensible default. You can tune the experiment entirely through `.env` without touching code.
- `OLLAMA_TEMPERATURE=0.1` keeps outputs deterministic. Higher values would make benchmark comparisons unreliable.

---

## `01_setup_and_load.py` — Document loading and node parsing

Establishes the data pipeline that every subsequent script reuses.

```python
splitter = SentenceSplitter(chunk_size=256, chunk_overlap=30)
nodes = splitter.get_nodes_from_documents(documents)
```

**What to notice:**
- `chunk_size=256` with `chunk_overlap=30` is the canonical config used across all scripts. This produces ~40-50 nodes from 5 documents.
- The script tests multiple chunk sizes (128, 256, 512, 1024) to show how granularity affects node count. At 1024 tokens, some documents become a single node — meaning there's nothing to select between during retrieval.
- Node relationship inspection (lines 59-78) shows that LlamaIndex preserves `PREVIOUS`/`NEXT` relationships between chunks from the same document. This metadata powers advanced retrieval strategies like sentence-window retrieval.

---

## `02_vector_store_index.py` — Semantic similarity search

The most common index type and the experiment's baseline.

```python
Settings.embed_model = HuggingFaceEmbedding(model_name="BAAI/bge-small-en-v1.5")
index = VectorStoreIndex.from_documents(documents)
retriever = index.as_retriever(similarity_top_k=3)
```

**What to notice:**
- No LLM is needed for VectorStoreIndex — only embeddings. Build and query are pure vector math.
- `similarity_top_k` controls the precision/recall tradeoff. The script tests k=1, 3, and 5 to show how broadening the window pulls in more (sometimes irrelevant) documents.
- Similarity scores are printed alongside results. A score close to 1.0 means strong semantic match; scores below 0.7 are often noise.

---

## `03_summary_index.py` — Two retrieval philosophies in one index

SummaryIndex stores nodes in a flat list. The interesting part is the two retrieval modes.

```python
retriever_all = index.as_retriever(retriever_mode="default")       # returns ALL nodes
retriever_emb = index.as_retriever(retriever_mode="embedding",     # returns top-k
                                    similarity_top_k=3)
```

**What to notice:**
- Default mode returns every node on every query. This is what makes SummaryIndex ideal for "summarize everything" — the response synthesizer sees all content. But it's expensive: the LLM processes all nodes.
- Embedding mode makes SummaryIndex behave like VectorStoreIndex at query time (but without pre-building an embedding index). This mode exists for the comparison in `06_compare_all.py`, where fair side-by-side comparison requires all indices to return top-k results.
- Build cost is zero — no embeddings, no LLM calls. The cost is deferred entirely to query time.

---

## `04_tree_index.py` — The most complex index type

TreeIndex is the only index that generates content during build. The `describe_tree()` helper (lines 22-40) inspects the resulting structure.

```python
index = TreeIndex.from_documents(
    documents,
    build_tree=True,
    num_children=tree_num_children,   # from TREE_NUM_CHILDREN env var
)
```

**What to notice:**
- `build_tree=True` triggers eager construction. The LLM generates summary nodes bottom-up: groups of `num_children` leaf nodes get summarized, then groups of summaries get summarized, until a root is reached. This is where the 140-185 second build time comes from.
- Three retrieval modes are demonstrated:
  1. `retriever_mode="root"` (line 102) — instant, just returns the precomputed root summary
  2. `select_leaf_embedding` with `child_branch_factor=1` (lines 111-114) — walks down one branch
  3. `select_leaf_embedding` with `child_branch_factor=2` (lines 131-134) — explores multiple branches
- The eager vs lazy comparison (lines 150-168) shows that `build_tree=False` is essentially instant but returns all leaves (no hierarchy to navigate). Lazy mode loses TreeIndex's main advantage.
- `describe_tree()` counts root, summary, and leaf nodes. With `num_children=3` and ~40 leaf nodes, you get roughly 13 summary nodes and 4-5 intermediate summaries, converging to 1-2 roots.

---

## `05_keyword_table_index.py` — Regex-based routing

Uses `SimpleKeywordTableIndex` — the regex variant that avoids LLM calls entirely.

```python
index = SimpleKeywordTableIndex.from_documents(documents)
keyword_table = index.index_struct.table    # direct introspection
```

**What to notice:**
- The keyword table is a plain dictionary mapping keywords to node IDs. The script inspects it directly (lines 55-72) to show exactly which keywords were extracted from each chunk.
- Retrieval is a set intersection: query keywords are extracted, matched against the table, and matching nodes are returned. No semantic understanding — "AI" won't match "artificial intelligence" unless both strings appear in the same chunk.
- The script tests specific keywords (lines 74-92) to show hits and misses. This makes the limitation concrete.
- Build cost is negligible (regex runs in milliseconds). This makes KeywordTable viable as a fast routing layer in front of a more expensive index.

---

## `06_compare_all.py` — The integration point

This is the central script. `build_all_indices()` and `query_all_indices()` are the two functions that `07_benchmark_models.py` imports and reuses.

### The retriever decision tree (lines 93-111)

```python
if name == "Summary":
    retriever = index.as_retriever(retriever_mode="embedding", similarity_top_k=top_k)
elif name == "Tree":
    if "summarize" in query.lower() or "topics covered" in query.lower():
        retriever = index.as_retriever(retriever_mode="root")
    else:
        retriever = index.as_retriever(
            retriever_mode="select_leaf_embedding",
            child_branch_factor=TREE_CHILD_BRANCH_FACTOR,
        )
```

**What to notice:**
- SummaryIndex is forced into embedding mode for fair comparison. Without this, it would return all nodes and always "win" on completeness.
- TreeIndex switches strategy based on query content: summarization queries go to the root, factual queries traverse the tree. This is a manual version of what RouterQueryEngine would do automatically.
- The query-content detection (`"summarize" in query.lower()`) is intentionally simple — it's a demo, not production routing logic.

### The test queries (lines 191-217)

Each query has an `expected_best` field and a `reason`. This isn't just for display — it documents the experiment's hypothesis. When the actual results don't match expectations (e.g., KeywordTable misses on a keyword query because the exact terms weren't indexed), that's a finding worth noting.

---

## `07_benchmark_models.py` — Rigorous model comparison

The most complex script. Several patterns worth understanding.

### Dynamic module import (lines 24-33)

```python
COMPARE_ALL_SPEC = importlib.util.spec_from_file_location(
    "compare_all_module", COMPARE_ALL_PATH
)
COMPARE_ALL_MODULE = importlib.util.module_from_spec(COMPARE_ALL_SPEC)
COMPARE_ALL_SPEC.loader.exec_module(COMPARE_ALL_MODULE)
build_all_indices = COMPARE_ALL_MODULE.build_all_indices
```

**Why not just `import`?** The scripts aren't in a package (no `__init__.py`). This approach loads `06_compare_all.py` as a module by file path, then extracts the two functions needed. It keeps the benchmark DRY without restructuring the project.

### Clean warmup protocol (lines 114-142)

```python
def reset_running_models(candidate_models):
    running_models = set(candidate_models)
    running_models.update(list_running_models())
    for model_name in sorted(running_models):
        run_ollama_command(["stop", model_name], check=False)

def warmup_model(model_name):
    run_ollama_command(["run", model_name, WARMUP_PROMPT, "--keepalive", keep_alive])
```

This two-step process ensures:
1. No other model is loaded (would compete for GPU/CPU memory)
2. The target model is fully loaded before timing starts

Without this, the first model benchmarked would appear slower (cold start) and models would compete for resources.

### Source-hit accuracy (lines 206-215)

```python
sources = {node.node.metadata.get("file_name", "?") for node in data["nodes"]}
if sources & test["expected_sources"]:
    source_hits[index_name] += 1
```

This checks whether the retrieved nodes include the expected source document — a set intersection. It measures retrieval correctness, not just speed. A fast retriever that returns the wrong documents is worse than a slow one that finds the right ones.

### Qualitative snapshots (lines 145-182)

The benchmark captures actual LLM output for five specific scenarios:
- Tree root summary preview
- Summary index answer to a summarization query
- Tree index answer to the same summarization query
- Vector store answer to a factual query
- Tree index answer to the same factual query

These are printed for manual review. Automated metrics (timing, source-hits) can't tell you whether a summary is coherent — you need to read it.

---

## Cross-cutting patterns

### Global Settings

Every script configures LlamaIndex the same way:

```python
Settings.embed_model = HuggingFaceEmbedding(model_name="BAAI/bge-small-en-v1.5")
Settings.llm = build_local_llm()
Settings.chunk_size = 256
Settings.chunk_overlap = 30
```

This is the modern LlamaIndex pattern (post-2024). Earlier versions passed these as constructor arguments. The global `Settings` object simplifies configuration but means you need to set it before building any index.

### Retriever → Query Engine pattern

Two-step querying appears throughout:

```python
retriever = index.as_retriever(...)       # just fetches nodes
engine = index.as_query_engine(...)       # fetches nodes + synthesizes answer via LLM
```

Scripts 01-06 mostly use retrievers (to show what was fetched). Script 07 uses query engines for qualitative snapshots (to show what the LLM produces).

### Timing everything

Every build and query is wrapped in `time.time()`. This isn't just for benchmarking — it makes the build-cost vs query-cost tradeoff tangible. When you see TreeIndex build takes 180 seconds and VectorStore takes 2 seconds, the tradeoff stops being theoretical.
