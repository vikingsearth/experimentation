# Code Walkthrough

A low-level trace through the data pipeline, from raw text files to scored
benchmark results. All file references are relative to `embeddings-rag/`.

---

## Configuration

`src/config.py` centralizes every tuneable parameter. Most are overridable via
environment variables:

```
EMBEDDING_MODEL    = "all-MiniLM-L6-v2"       (line 12)
CHUNK_SIZE         = 500                        (line 13)
TOP_K              = 3                          (line 14)
CAG_OLLAMA_MODEL   = "qwen2.5:3b-instruct"     (line 17)
CAG_OLLAMA_URL     = "http://127.0.0.1:11434"  (line 16)
```

The lists at lines 20-22 define which strategies and baselines exist:

```python
STRATEGIES = ["fixed", "recursive", "sentence", "semantic"]
RETRIEVAL_MODES = ["dense", "lexical", "hybrid"]
RELATIONAL_BASELINES = ["dense", "lexical", "hybrid", "graph", "cag", "all"]
```

---

## 1. Corpus Loading

**`src/corpus.py`**

Two loader functions read `.txt` files from disk into `dict[filename, text]`:

- `load_documents()` (line 37) -- reads from `data/` (tutorial corpus)
- `load_relational_documents()` (line 48) -- reads from `data/relational/`

The `RelationalQuestion` dataclass (line 26) models the labeled benchmark
questions loaded from `data/relational/questions.json` by
`load_relational_questions()` (line 61). Each question carries:

- `expected_answer` -- the ground-truth answer text
- `expected_terms` -- keywords that should appear in a correct answer
- `entities` -- named entities the answer should reference
- `supporting_files` -- which source documents contain the evidence

---

## 2. Chunking

**`src/chunkers.py`**

Each chunker takes a text string and returns `list[Chunk]`. The `Chunk`
dataclass (line 20) carries `text`, `source`, `strategy`, `index`, and
`metadata`.

### Fixed-size (line 39)

```python
def chunk_fixed(text, chunk_size=500, overlap=50):
```

Slides a window of `chunk_size` characters with `overlap` character lookback.
Simple but regularly cuts mid-sentence.

### Recursive (line 61)

```python
def chunk_recursive(text, chunk_size=500, overlap=50):
```

Defines a separator hierarchy: `["\n\n", "\n", ". ", " ", ""]`. The inner
`_split()` function (line 70) tries each separator in order. If a piece
exceeds the size limit after splitting on the current separator, it recurses
to the next one. Overlap is applied by prepending the tail of the previous
chunk (line 108).

### Sentence-based (line 119)

```python
def chunk_sentences(text, chunk_size=500, overlap_sentences=1):
```

Uses `nltk.sent_tokenize` to split on sentence boundaries, then groups
sentences until the character limit. Overlap is in sentences, not characters
(line 141).

### Semantic (line 160)

```python
def chunk_semantic(text, embedding_model=None, similarity_threshold=0.5, ...):
```

Embeds every sentence (line 185), computes cosine similarity between adjacent
pairs (lines 189-193), and inserts a break where similarity drops below the
threshold. This is the most expensive strategy because it requires an embedding
pass during indexing, not just during querying.

### Running all strategies

`chunk_all()` (line 241) runs fixed, recursive, and sentence by default. If an
embedding model is provided, it also runs semantic. Returns
`dict[strategy_name, list[Chunk]]`.

---

## 3. Indexing to ChromaDB

**`src/index.py`**

The `main()` function (line 65) orchestrates the full indexing pipeline:

1. Load the embedding model (line 73)
2. Initialize a persistent ChromaDB client (line 78)
3. Load documents (line 82)
4. For each document, run `chunk_all()` (line 103)
5. For each strategy, create a collection named `strategy_{name}` with cosine
   distance (line 112)
6. Pre-compute embeddings and store them alongside the chunks (line 58-61 in
   `index_chunks()`)

Each chunk is stored with metadata: source filename, strategy name, chunk
index, and character length (lines 47-55).

---

## 4. Dense Retrieval

**`src/retrieval.py:30-87`**

The `DenseRetriever` class builds an in-memory embedding matrix at init time
(lines 42-48). The `search()` method:

1. Embeds the query (line 61-63)
2. Computes cosine similarity: `dot(embeddings, query) / (norms * query_norm)`
   (lines 72-75)
3. Returns top-K results sorted by similarity (line 77)

All results are wrapped in `RetrievedChunk` (line 20), a normalized dataclass
that every retrieval path returns. This is the key abstraction that makes
baselines interchangeable downstream.

There is also a ChromaDB-backed path (`query_dense_strategy`, line 113) used by
the interactive query interface, and an in-memory path used by the benchmark
harness. The ChromaDB path converts Chroma's distance metric to similarity
(`1 - distance`, line 137).

---

## 5. Lexical Retrieval (BM25)

**`src/retrieval.py:161-228`**

`LexicalRetriever` builds a BM25 index at init (line 172). The
`_build_index()` method (line 174):

1. Tokenizes each chunk record with a regex pattern (line 181)
2. Builds posting lists: `term -> [(doc_idx, term_frequency)]` (line 185)
3. Computes IDF: `log(1 + (N - df + 0.5) / (df + 0.5))` (line 191)
4. Tracks per-document lengths for length normalization (line 182, 188)

The `search()` method (line 195) scores candidates using the standard BM25
formula:

```python
score += idf * ((tf * (k1 + 1)) / (tf + k1 * (1 - b + b * (dl / avgdl))))
```

Default parameters: `k1=1.5`, `b=0.75` (line 164).

---

## 6. Hybrid Fusion

**`src/retrieval.py:241-281`**

`combine_results()` fuses dense and lexical results:

1. Collect raw scores from both result sets (lines 248-249)
2. Normalize each independently to [0, 1] via `_normalize_scores()` (lines
   250-251). This function (line 94) maps `[min, max] -> [0, 1]` and handles
   edge cases (all-zero, all-equal)
3. Compute the weighted sum: `0.65 * dense_norm + 0.35 * lexical_norm`
   (lines 261-262)
4. Sort by combined score and return top-K (lines 280-281)

The independent normalization is critical -- without it, raw BM25 scores
(unbounded positive floats) would dominate cosine similarities (bounded to
[-1, 1]).

---

## 7. Graph Retrieval

**`src/graph_rag.py`**

### Graph construction (line 164)

`build_relational_graph()` processes each document:

1. Collect known entities via regex patterns (lines 123-151): `REPO_PATTERN`,
   `POLICY_PATTERN`, `INCIDENT_PATTERN`, `RUNBOOK_PATTERN`, `EVENT_PATTERN`,
   `PERSON_PATTERN`, plus CamelCase names
2. Split documents into paragraph blocks (line 171)
3. For each block, find which known entities appear in it (line 175)
4. Create `GraphFact` nodes -- both block-level and sentence-level -- linked
   to their entities (lines 177-206)
5. Build an alias map (`lowercase -> canonical`) for flexible matching (line
   186)

The result is a `RelationalGraph` (line 59) with:
- `entity_to_fact_ids` -- entity -> set of fact IDs (line 67-70)
- `aliases` -- case-insensitive entity lookup (line 64)
- `fact_index` -- fact ID -> GraphFact (line 66)

### Graph querying (line 211)

`query_graph()` performs multi-hop BFS:

1. Match seed entities from the question text (line 219)
2. For each hop (0 to `max_hops`, default 2), traverse from frontier entities
   to their connected facts (lines 229-262)
3. Score each fact with multiple factors (lines 242-251):
   - **Path bonus**: `2.5 / (hop + 1)` -- closer facts score higher
   - **Token overlap**: `0.35 * overlap` -- question words in the fact
   - **Seed overlap**: `0.8 * count` -- seed entities in the fact
   - **Entity overlap**: `0.25 * count` -- any entity in the question
   - **Kind bonus**: `0.65` for block-level facts (more context)
   - **Size bonus**: `min(entity_count, 8) * 0.08`
   - **Domain bonuses**: extra weight for policy or path/dependency questions
4. Expand the frontier to entities found in the current hop's facts (lines
   256-259)
5. Normalize scores to [0, 1] and return top-K (lines 267-301)

---

## 8. Answer Generation

**`src/cag.py`**

### Shared generator (line 150)

`_generate_answer()` builds a structured prompt (lines 160-199) that requests
JSON with:

- `question_parts` -- decomposed sub-questions
- `supported_facts` -- subject/relation/object triples with source files
- `missing_parts` -- what the context didn't support
- `answer` -- the final answer text
- `cited_files` and `confidence`

The prompt explicitly instructs the model not to collapse multi-part questions
(line 187) and to lower confidence when parts are missing (line 193).

### Ollama communication (lines 201-232)

The generator first tries the Ollama HTTP API with `temperature: 0.0` and
`format: "json"`. If the API is unreachable, it falls back to the Ollama CLI
(line 224-231). On Windows, it checks `LOCALAPPDATA\Programs\Ollama\ollama.exe`
(line 70) as a last resort.

### Robustness layers (lines 234-261)

After receiving a response:

1. Extract JSON, handling model output wrapped in extra text (line 49-58)
2. If `cited_files` is empty, recover citations from `supported_facts`
   (line 242-243)
3. If `answer` is empty, build a fallback from extracted facts (line 238-239,
   function at line 130)
4. Normalize cited filenames through an alias map (line 244)
5. Cap confidence at 0.5 when `missing_parts` is non-empty (line 251-252)

### Two entry points

- `answer_with_evidence()` (line 264) -- takes retrieved chunks, builds an
  evidence pack with scores and source metadata, calls the shared generator
  with label `"retrieved evidence"`
- `answer_with_cag()` (line 284) -- takes the full document set, builds a
  corpus pack ordered by filename, calls the shared generator with label
  `"full corpus context"`

All retrieval-based baselines use the first path. Only the CAG baseline uses
the second. This ensures the only variable between baselines is the evidence
selection, not the generation template.

---

## 9. Benchmark Harness

**`src/benchmark_relational.py`**

### Scoring functions

Two parallel scoring functions measure the same three dimensions against
different inputs:

- `score_retrieval_results()` (line 59) -- measures term coverage, entity
  coverage, and file coverage in the retrieved chunks' text
- `score_answer_response()` (line 87) -- measures the same dimensions in the
  generated answer text and cited files

Both produce a combined score weighted `0.45 * terms + 0.35 * entities +
0.20 * files` (lines 76, 103).

### Baseline orchestration

`run_baseline()` (line 152) loops over questions and dispatches to the
appropriate retrieval path:

- `dense` / `lexical` / `hybrid` -- retrieve chunks, score retrieval, generate
  answer, score answer (lines 180-209)
- `graph` -- query the graph, score retrieval, generate answer (line 214)
- `cag` -- skip retrieval, generate answer from full corpus (lines 210-212)

The CAG baseline is the only one that skips retrieval scoring entirely
(lines 226-233).

### Summary tables

When running all baselines (`--baseline all`), the harness prints two summary
tables (lines 278-307): one for retrieval and one for answer quality. The CAG
row is absent from the retrieval table and present in the answer table.

---

## Notable Patterns

### Unified result format

Every retrieval path returns `list[RetrievedChunk]` (`src/retrieval.py:20-27`).
This single dataclass with `id`, `text`, `metadata`, `score`, and
`score_breakdown` is what makes the baselines pluggable into the same answer
generation and scoring pipeline.

### Score normalization as a first-class concern

`_normalize_scores()` (`src/retrieval.py:94-110`) is used by hybrid fusion but
also by the graph retriever. It maps arbitrary score ranges to [0, 1] and
handles degenerate cases (all zeros, all equal). This prevents any signal from
dominating purely because of scale differences.

### Defensive JSON extraction

`_extract_json_object()` (`src/cag.py:49-58`) first tries a direct parse, then
falls back to extracting the substring between the first `{` and last `}`.
This handles models that wrap their JSON in explanatory text.

### Catalog-based chunk sharing

`build_chunk_catalog()` (`src/corpus.py:81-111`) creates `ChunkRecord` objects
with stable IDs (`{source}_{strategy}_{index}`) that are shared across all
retrieval baselines. This ensures dense, lexical, and hybrid retrievers are
searching over exactly the same chunk set.
