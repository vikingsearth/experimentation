# Gaps in the Current Experiment

What this experiment doesn't cover yet, and which gaps are worth closing.

---

## 1. TreeIndex quality is a corpus-fit problem, not just a model problem

The benchmark shows both 3B models produce weak root summaries. The previous agent's recommendation was to try a stronger model (7B+) or tune the tree prompts.

That diagnosis is half right. The deeper issue is **corpus fit**: TreeIndex is designed for large, hierarchically structured corpora where you need drill-down from overview to detail. Our corpus is 5 small documents totaling ~1,500 words. At this scale:

- The root summary is trying to compress content that's already short
- The tree hierarchy has only 2-3 levels — not enough depth for hierarchical traversal to add value over flat retrieval
- `select_leaf_embedding` with `child_branch_factor=3` often explores most of the tree anyway

**Where to see this:**
- `src/04_tree_index.py:85-92` — `describe_tree()` shows the tree is shallow (1-2 roots, ~13 summary nodes, ~40 leaves)
- `src/07_benchmark_models.py:151-156` — the `tree_root_preview` qualitative snapshot shows the weak summary

**What would actually help:** Test TreeIndex on a corpus that matches its architecture — e.g., a technical manual with chapters, sections, and subsections (hundreds of pages). That would make the hierarchical traversal meaningful and give the summary hierarchy real work to do.

---

## 2. RouterQueryEngine is described but never implemented

`src/06_compare_all.py:255-261` recommends composing indices with a RouterQueryEngine:

> In practice, composing multiple index types with a RouterQueryEngine gives the best results: route keyword queries to KeywordTable, semantic queries to VectorStore, and summarization to SummaryIndex.

This is the natural conclusion of the experiment — you've shown each index wins on different queries, now let the system pick automatically. But the code stops at manual routing (`06_compare_all.py:99-105` switches TreeIndex mode based on string matching in the query).

**What implementation would look like:**
- Build a `RouterQueryEngine` with query engine tools for each index type
- Let the LLM decide which index to route to based on the query
- Compare the router's choices against the `expected_best` labels in the test queries
- Measure whether the router picks the right index and whether routing overhead is worth it

This is the highest-value gap to close because it turns the experiment from "here are your options" into "here's how to use them together."

---

## 3. Benchmarks measure retrieval, not answer quality

The benchmark (`src/07_benchmark_models.py`) tracks two quantitative metrics:
- **Query time** — how fast each retriever returns nodes
- **Source-hit accuracy** — whether the correct source documents appear in the results (`07_benchmark_models.py:211-215`)

Both measure the **retrieval** step. Neither measures the **answer** step: given the retrieved nodes, does the LLM produce a correct, coherent response?

The qualitative snapshots (`07_benchmark_models.py:145-182`) capture actual LLM output for manual review, but there's no automated evaluation. You have to read the `summary_answer`, `tree_answer`, `vector_fact_answer`, and `tree_fact_answer` fields yourself and judge.

**What would close the gap:**
- Define expected answers (or at least expected answer components) for the test queries
- Use an LLM-as-judge pattern or simple substring checks to score answer quality
- Track answer quality alongside retrieval metrics in the benchmark output

---

## 4. Single corpus, no scaling signal

All scripts use the same 5 documents (~12KB total). This tells you how each index *behaves* but not how it *scales*.

Questions the current corpus can't answer:
- At what document count does SummaryIndex's "read all nodes" strategy become impractical?
- How does VectorStoreIndex query time grow with corpus size?
- Does TreeIndex's hierarchical advantage emerge at 50, 500, or 5,000 documents?
- Does KeywordTable's keyword collision rate degrade retrieval precision at scale?

**Where the limitation shows:**
- `src/06_compare_all.py:178-179` — loads all documents from a single small directory
- `src/01_setup_and_load.py:36-39` — the entire corpus fits in a handful of chunks

**What would help:** A scaling experiment that indexes progressively larger document sets (10, 100, 1000 documents) and tracks build time, query time, and retrieval accuracy at each level.

---

## 5. No hybrid retrieval

The research docs cover hybrid retrieval strategies in detail:
- `docs/research/retrieval-strategies.md` discusses combining BM25 with vector search, reranking, query transformations, and sentence-window retrieval

None of these are implemented in code. The experiment stays at single-index retrieval per query (with the manual routing in `06_compare_all.py`).

The most immediately useful hybrid pattern would be **vector + keyword** — using KeywordTableIndex as a fast filter and VectorStoreIndex for semantic ranking within the filtered set. This is a common production pattern and would demonstrate composition at a lower level than RouterQueryEngine.

---

## 6. KnowledgeGraphIndex excluded

`docs/planning/plan.md` explicitly excluded KnowledgeGraphIndex:

> KnowledgeGraphIndex is excluded due to complexity and high LLM cost for a quick comparison.

This was the right call for scope, but it leaves a gap in the index-type coverage. KnowledgeGraphIndex is the only type that extracts and queries entity relationships (e.g., "Who reports to the CEO?" → traverse the graph). The `company_profile.txt` document was specifically designed with relationships that would benefit from graph-based retrieval.

**Worth adding if:** You want complete coverage of LlamaIndex's index types. Not worth it if the experiment's purpose is already served by the four current types.

---

## Priority ranking

If you're deciding what to work on next:

| Gap | Value | Effort | Recommendation |
|-----|-------|--------|---------------|
| RouterQueryEngine | High | Medium | Best next step — it's the natural conclusion |
| Answer quality metrics | Medium | Low | Adds rigor to existing benchmarks |
| Larger corpus for TreeIndex | Medium | Medium | Only if TreeIndex quality is a focus |
| Hybrid retrieval | Medium | Medium | Good for production-readiness |
| Scaling experiment | Low | High | Nice to have, not essential for learning |
| KnowledgeGraphIndex | Low | High | Only for completeness |

The experiment has already answered its core question. Closing gap #1 (RouterQueryEngine) would be the most impactful addition. The rest depends on whether you want to deepen the experiment or move on.
