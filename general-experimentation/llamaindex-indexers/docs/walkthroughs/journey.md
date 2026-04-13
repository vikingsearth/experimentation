# The Experiment Journey

How this experiment evolved from an idea to a working index-type comparison framework.

## The starting question

> If LlamaIndex offers multiple index types, when should you use each one?

Most RAG tutorials default to VectorStoreIndex and never look back. This experiment set out to build all four practical index types from the same documents, run the same queries against each, and show the tradeoffs in a way you can see and measure.

## Timeline

### Phase 1 — Research and planning (2026-03-27)

The first commits laid groundwork before writing any indexing code:

- **Research docs** (`docs/research/`) covering LlamaIndex architecture, all six index types, retrieval strategies, and how LlamaIndex compares to LangChain and Haystack.
- **Planning doc** (`docs/planning/plan.md`) defining the experiment scope: 4 index types, 5 diverse documents, 5 standardized test queries, and clear expected outcomes per index.

Key scoping decision: **KnowledgeGraphIndex was excluded**. It requires heavy LLM extraction and adds complexity without proportional educational value for a quick comparison.

### Phase 2 — Core scripts (2026-03-27)

Six scripts built in sequence, each one layering on the previous:

| Script | What it established |
|--------|-------------------|
| `01_setup_and_load.py` | Document loading, chunking, node relationships |
| `02_vector_store_index.py` | Embedding-based semantic search |
| `03_summary_index.py` | Exhaustive vs selective retrieval modes |
| `04_tree_index.py` | Hierarchical summaries with multiple traversal modes |
| `05_keyword_table_index.py` | Regex-based keyword routing |
| `06_compare_all.py` | Side-by-side comparison of all four |

The design choice to use `SimpleKeywordTableIndex` (regex extraction) instead of the LLM-powered `KeywordTableIndex` was deliberate — it keeps build cost near zero and isolates the keyword-routing concept from LLM quality concerns.

### Phase 3 — Local LLM pivot (2026-03-27 to 2026-03-30)

The experiment initially used a local GGUF model file. This worked but had friction:
- Model files are large and not easily swapped
- No standard CLI for model management
- Hard to compare multiple models

**The pivot to Ollama** solved all three. Ollama provides a CLI for pulling, running, and stopping models, and its HTTP API integrates cleanly with LlamaIndex via `llama-index-llms-ollama`. The `ollama_llm.py` helper centralizes configuration through environment variables.

### Phase 4 — Benchmarking (2026-03-30)

With Ollama making model-switching trivial, `07_benchmark_models.py` was added to answer: *does the choice of 3B model matter?*

The benchmark methodology was designed for reproducibility:
1. Stop all loaded Ollama models (clean slate)
2. Warm the target model with a trivial prompt (eliminate cold-start variance)
3. Build all indices and time the tree build specifically
4. Run 5 test queries, track retrieval times and source-hit accuracy
5. Capture qualitative snapshots (actual LLM output) for manual review

Result: `llama3.2:3b` builds trees ~27% faster than `qwen2.5:3b-instruct`, but both produce the same source-hit score (18/25) and similarly weak TreeIndex root summaries.

### Phase 5 — Documentation (2026-03-30)

The final phase added visual documentation:
- `docs/diagrams.md` with ASCII and Mermaid diagrams covering the architecture, script flow, index behavior, benchmark workflow, and findings
- README updates with the latest benchmark table and experiment recommendations

## Key decisions and why

| Decision | Alternative considered | Why this way |
|----------|----------------------|--------------|
| Ollama over GGUF | Direct GGUF loading via llama-cpp-python | Ollama gives CLI model management, easy swapping, HTTP API |
| SimpleKeywordTableIndex | LLM-powered KeywordTableIndex | Zero LLM cost at build time, isolates keyword concept |
| Eager TreeIndex (`build_tree=True`) | Lazy tree (build on query) | Shows the real summary hierarchy; lazy mode is just a flat fallback |
| BGE-small embeddings | OpenAI embeddings | Free, local, no API key — keeps the experiment fully offline |
| 5 diverse documents | Larger corpus | Small enough to inspect every node, diverse enough to stress each index |

## Where we are now

The experiment is functionally complete as a comparison framework. All four index types are built, queried, compared, and benchmarked. The documentation captures the architecture and findings.

The open question is whether to extend the experiment (RouterQueryEngine, larger corpus, stronger models) or wrap it up. See [gaps.md](gaps.md) for specifics.
