# Gaps and Next Steps

An honest assessment of what the experiment doesn't yet cover, with references
to the code and planning docs that define the gap.

---

## 1. Vector Backend Comparison

**The gap:** The original plan (`docs/planning/plan.md`) asks "How much does
the vector store backend matter at this scale?" -- but only ChromaDB is
implemented. The backend is hardcoded in `src/config.py:8`:

```python
CHROMA_DIR = os.path.join(PROJECT_ROOT, "chroma_db")
```

And every indexing and querying path assumes ChromaDB:
- `src/index.py:78` creates a `PersistentClient`
- `src/retrieval.py:113-147` queries Chroma collections directly

The research doc (`docs/research/vector-databases.md`) compares ChromaDB,
FAISS, Qdrant, and Pinecone, but none of the alternatives are wired in.

**Why this matters less than it sounds:** At the current corpus size (~42K
characters, a few hundred chunks), backend differences are negligible. The
research docs themselves note that ChromaDB is appropriate up to ~10M vectors.
The interesting backend comparison would require a corpus large enough for
indexing strategy, quantization, and approximate nearest-neighbor tradeoffs
to become visible.

**Next step:** Adding FAISS as a second backend would answer the question at
this scale. But a more impactful move would be testing with a larger corpus
first, then comparing backends where the difference is measurable.

---

## 2. Corpus Size and Messiness

**The gap:** The relational corpus (`data/relational/`) is synthetic, clean,
and small -- six well-structured documents totaling ~42K characters. Every
method can find something useful because the data is designed to be findable.

In real-world use, documents are messy: inconsistent formatting, duplicated
information, ambiguous entity references, missing context. The current
benchmark may overstate how well these methods generalize.

**Evidence from the results:** The compressed answer-score range (0.55-0.59
across all baselines) partly reflects this. When the corpus is clean enough,
even the weakest retriever surfaces adequate evidence.

**Next step:** Test with a larger or messier corpus -- for example, a real
internal wiki export or a scraped documentation site -- where method tradeoffs
become sharper. This would stress-test:
- Whether hybrid retrieval's advantage holds on noisy text
- Whether GraphRAG's entity extraction degrades on inconsistent naming
- Whether CAG remains competitive as corpus size exceeds the context window

---

## 3. Code Organization

**The gap:** The refactor plan (`docs/planning/refactor-implementation.md`)
describes a modular structure with `baseline/` and `backend/` directories. The
current layout is a flat `src/` folder:

```
src/
  config.py
  corpus.py
  chunkers.py
  retrieval.py      # dense, lexical, hybrid all in one file
  graph_rag.py
  cag.py            # CAG baseline + shared answer generation
  index.py
  query.py
  compare.py
  query_relational.py
  benchmark_relational.py
```

Adding a new baseline currently requires:
1. Writing the retrieval logic (new file or extending `retrieval.py`)
2. Adding a dispatch branch in `benchmark_relational.py:run_baseline()` (line
   152, already at 5 branches across lines 180-216)
3. Updating `RELATIONAL_BASELINES` in `src/config.py:22`
4. Potentially adding a new query script

There's no shared interface or registration mechanism -- each baseline is wired
in by hand.

**Why this is secondary:** The current layout works. Five baselines fit
comfortably in the existing structure. The organizational debt would become
painful at 8-10 baselines or if multiple people were contributing
simultaneously.

**Next step:** Extract a `BaselineRunner` protocol (or simple ABC) that each
baseline implements, and let the benchmark harness discover baselines by
registration rather than by if/elif chains.

---

## 4. Single Embedding Model

**The gap:** Only `all-MiniLM-L6-v2` is used (`src/config.py:12`). The
research doc (`docs/research/embedding-models.md`) lists several alternatives:

| Model               | Dimensions | Notes                          |
| ------------------- | ---------- | ------------------------------ |
| all-MiniLM-L6-v2    | 384        | Current choice, fast, small    |
| all-mpnet-base-v2   | 768        | Most downloaded on HuggingFace |
| BGE-large-en-v1.5   | 1024       | Higher quality, slower         |

The embedding model is configurable via `EMBEDDING_MODEL` env var, so swapping
it is trivial. But the experiment doesn't include any comparison of how model
choice affects retrieval or answer quality.

**Next step:** Run the benchmark with 2-3 models and add an embedding-model
column to the results. The infrastructure already supports it -- just set the
env var and re-index.

---

## 5. True KV-Cache CAG

**The gap:** The CAG baseline (`src/cag.py:284-300`) uses prompt preload: it
concatenates the entire corpus into the prompt and sends it to Ollama on every
query. This means:

- Each query re-processes the full corpus (no caching across queries)
- Latency scales with corpus size on every call
- There is no persistent state between queries

True KV-cache CAG would use a runtime like vLLM to cache the corpus encoding
once, then answer subsequent queries from the cached state with dramatically
lower latency.

The code is honest about this: the docstring says "full corpus as preloaded
context" (line 291), and the planning docs describe it as "CAG-style prompt
preload."

**Why this is acceptable:** The experiment's goal is to test whether retrieval
is worth the overhead on small corpora. Prompt preload answers that question.
True KV-cache CAG would improve latency but not answer quality, so it doesn't
change the benchmark conclusions.

**Next step:** If latency comparisons become part of the benchmark, a vLLM or
llama.cpp server with prefix caching would make the CAG baseline more
representative of production use.
