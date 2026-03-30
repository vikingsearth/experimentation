# Diagrams Guide

A section-by-section tour of [`docs/diagrams.md`](../diagrams.md). Each section below explains what the corresponding diagram shows, how to read it, and which code it maps to.

---

## Section 1: Big Picture

**What it shows:** The full data pipeline from raw text files to final comparison output.

**How to read it:**

The ASCII diagram is a top-down flow:

1. **Top:** `data/*.txt` — the 5 sample documents (Python, ML, climate, company, recipes)
2. **Middle fork:** Documents split into two processing paths:
   - **Left:** HuggingFace embeddings (`BAAI/bge-small-en-v1.5`) — used by VectorStore and SummaryIndex (embedding mode)
   - **Right:** Ollama LLM — used by TreeIndex (summary generation) and all query engines (answer synthesis)
3. **Four branches:** The four index types built from the same nodes
4. **Bottom:** Everything converges into the comparison and benchmarking scripts

The Mermaid version adds one detail the ASCII omits: it shows which indices depend on embeddings vs LLM vs both. Notice that `SimpleKeywordTableIndex` connects directly from the document nodes — it needs neither embeddings nor LLM to build.

**Code mapping:**
- The fork into embeddings and LLM happens in `src/06_compare_all.py:44-49` (`build_all_indices()`)
- The convergence at the bottom is `06_compare_all.py` and `07_benchmark_models.py`

---

## Section 2: Script Journey

**What it shows:** The intended execution order of the 7 scripts.

**How to read it:**

This is a linear progression. Each script builds on concepts from the previous one:
- Scripts 01-05 are **standalone demos** — each explores one concept
- Script 06 is the **integration point** — it imports nothing from 01-05 but applies their patterns
- Script 07 is the **measurement layer** — it imports functions from 06 and adds benchmarking

The Mermaid version uses `LR` (left-to-right) layout to emphasize the sequential nature.

**Code mapping:**
- Scripts 01-05: `src/01_setup_and_load.py` through `src/05_keyword_table_index.py`
- Script 06: `src/06_compare_all.py` (the `build_all_indices` and `query_all_indices` functions)
- Script 07: `src/07_benchmark_models.py` (imports from 06 via `importlib.util`)

---

## Section 3: Index Behavior Map

**What it shows:** The build-cost vs query-cost tradeoff for each index type, plus a decision tree for choosing one.

**How to read the table:**

| Column | What it means |
|--------|--------------|
| Build Cost | How expensive it is to create the index. TreeIndex is "high" because the LLM generates summaries at build time (140-185s in benchmarks). KeywordTable is "low" because it uses regex extraction. |
| Query Cost | How expensive each query is. SummaryIndex is "high" because default mode feeds all nodes to the LLM. VectorStore is "low" because it's just a cosine similarity lookup. |
| Best Fit | The query pattern where this index outperforms the others. |

**How to read the decision tree:**

Start at the top ("What kind of question do I have?") and follow the yes/no branches:
1. Need semantic meaning? → VectorStore
2. Need all documents? → Summary
3. Need hierarchical overview? → Tree
4. None of the above → KeywordTable (fast, cheap, exact match)

This is a simplified heuristic. In practice, the answer is often "compose multiple indices" — which is the RouterQueryEngine idea mentioned in `06_compare_all.py:255-261`.

**Code mapping:**
- The build costs are measurable: run `06_compare_all.py` and observe the per-index build times printed at lines 57-75
- The decision tree logic is manually encoded in `query_all_indices()` at `06_compare_all.py:93-111`

---

## Section 4: Compare-All Query Path

**What it shows:** How a single user query flows through `06_compare_all.py` and gets routed to all four indices with different retriever configurations.

**How to read it:**

The query enters at the top and fans out to four parallel retrieval paths. The important detail is the **TreeIndex branching**:
- If the query contains "summarize" or "topics covered" → `retriever_mode="root"` (reads the precomputed root summary)
- Otherwise → `retriever_mode="select_leaf_embedding"` (traverses the tree using embeddings)

All four paths converge back to a single results display showing sources, previews, and timing.

**Code mapping:**
- The fan-out logic: `src/06_compare_all.py:90-131` (`query_all_indices()`)
- The conditional tree routing: `src/06_compare_all.py:99-105`
- The results display: `src/06_compare_all.py:133-165` (`display_comparison()`)

---

## Section 5: Benchmark Workflow

**What it shows:** The `07_benchmark_models.py` execution flow, including the clean-warmup protocol.

**How to read the sequence diagram:**

Four participants interact in order:

1. **Benchmark script → Ollama CLI:** First cleans the environment (`ollama ps` to check, `ollama stop` to clear)
2. **Benchmark script → Ollama CLI:** Warms the target model with a trivial prompt ("Reply with READY")
3. **Benchmark script → Compare-all module:** Builds all indices (reuses `build_all_indices()`)
4. **Benchmark script → Compare-all module:** Runs test queries (reuses `query_all_indices()`)
5. **Benchmark script → Indices directly:** Runs qualitative snapshot queries for manual review

The key insight: steps 1-2 ensure fair measurement. Without them, the first-benchmarked model takes a cold-start penalty and models compete for memory.

**Code mapping:**
- Steps 1-2: `src/07_benchmark_models.py:114-142` (`reset_running_models()`, `warmup_model()`)
- Step 3: `src/07_benchmark_models.py:199-201` (calls `build_all_indices()` imported from 06)
- Step 4: `src/07_benchmark_models.py:206-215` (calls `query_all_indices()` in a loop)
- Step 5: `src/07_benchmark_models.py:145-182` (`capture_qualitative_snapshots()`)

---

## Section 6: Current Findings

**What it shows:** A snapshot of where the experiment stands as of the latest benchmark run.

**How to read it:**

The ASCII block is structured as three categories:
- **Works well:** VectorStore, Summary, KeywordTable, and the benchmarking methodology itself
- **Still weak:** TreeIndex root summary quality with 3B models
- **What that means:** The bottleneck isn't benchmarking or documentation — it's either model capacity or tree strategy

The Mermaid version traces the causal chain: experiment state → TreeIndex is weak → small models are the limiting factor → two possible next moves.

**Important context the diagram doesn't show:** The weakness is partly about corpus fit, not just model size. TreeIndex is designed for large hierarchical corpora where drill-down matters. On 5 small documents, even a strong model wouldn't demonstrate TreeIndex's full value. See [gaps.md](gaps.md) for more on this.

**Code mapping:**
- The benchmark numbers behind these findings come from `07_benchmark_models.py` output
- The qualitative evidence is in the `tree_root_preview` field of the benchmark summary

---

## Section 7: File-Level Mental Model

**What it shows:** The 6 most important files in the project and what role each plays.

**How to read it:**

This is a reference card. If you're trying to understand the experiment, start with:
1. `README.md` — setup and the latest numbers
2. `docs/diagrams.md` — visual orientation (this file you're reading about)
3. `src/06_compare_all.py` — the central comparison logic

If you want to go deeper:
4. `docs/planning/plan.md` — what was planned vs what actually happened
5. `src/04_tree_index.py` — the most complex single-index demo
6. `src/07_benchmark_models.py` — the measurement methodology

The walkthroughs directory you're currently in covers all of these from different angles:
- [journey.md](journey.md) — the timeline
- [learnings.md](learnings.md) — the takeaways
- [code-walkthrough.md](code-walkthrough.md) — the implementation details
- [gaps.md](gaps.md) — what's missing
