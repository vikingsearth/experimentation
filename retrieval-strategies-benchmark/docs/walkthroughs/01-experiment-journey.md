# The Experiment Journey

How this experiment evolved from a simple chunking demo into a five-baseline
retrieval and augmentation benchmark.

## Phase 1: Chunking Demo

The experiment started with a single question: _which chunking strategy works
best for dense retrieval on small text corpora?_

Four strategies were implemented in `src/chunkers.py`:

| Strategy   | Approach                                           | Commit    |
| ---------- | -------------------------------------------------- | --------- |
| Fixed-size | Split every N characters with overlap              | `298d198` |
| Recursive  | Hierarchical split: paragraphs, sentences, chars   | `298d198` |
| Sentence   | Group complete sentences until a size limit         | `298d198` |
| Semantic   | Embedding similarity between adjacent sentences     | `298d198` |

A tutorial corpus (`data/python_guide.txt`, `data/faq.txt`) and a ChromaDB
indexing pipeline (`src/index.py`) provided the initial testbed. The
`src/compare.py` script benchmarked 8 predefined questions across all four
strategies and ranked them by a combined similarity + keyword-coverage score.

Early result: recursive chunking consistently outperformed the others on this
corpus.

## Phase 2: Retrieval Expansion

Dense similarity alone misses chunks where exact keywords matter (rare
identifiers, policy IDs, team names). Two additional retrieval modes were added
in `src/retrieval.py`:

- **Lexical (BM25)** -- a pure-Python posting-list index with IDF weighting.
  No external dependencies.
- **Hybrid** -- fuses dense and lexical scores with independent normalization
  and a weighted combination (default 65% dense / 35% lexical).

This was the first sign that the experiment needed a corpus that could actually
stress-test keyword-dependent retrieval.

_Key commits: `13e0cf8`, `e74188c`_

## Phase 3: Relational Corpus

A synthetic "TechVista Operations" knowledge base was created under
`data/relational/` -- six documents covering teams, services, dependencies,
policies, incidents, and runbooks. A labeled question set
(`data/relational/questions.json`) provided expected answers, expected terms,
expected entities, and supporting files for each question.

This corpus was kept separate from the tutorial corpus so the original dense
retrieval benchmark remained stable. The relational data was designed to reward
multi-hop reasoning -- questions like "which team owns X and what policy did it
violate?" require connecting facts across multiple documents.

_Key commits: `2890f6d`, `7d13548`_

## Phase 4: GraphRAG

A lightweight GraphRAG baseline was added in `src/graph_rag.py`. Rather than
building a full knowledge graph with an LLM, it uses regex-based entity
extraction (repository IDs, policy IDs, incident IDs, team names, events,
people) to create a bipartite entity-evidence graph. Retrieval works by
matching seed entities from the question, then performing multi-hop BFS
traversal with a multi-factor scoring function.

This was an intentional design choice: the experiment tests whether graph
structure helps retrieval on relational data, without conflating that question
with the quality of LLM-based entity extraction.

_Key commits: `2808638`, `6df021d`_

## Phase 5: CAG Baseline

The experiment added a no-retrieval baseline in `src/cag.py`: Context-Augmented
Generation (CAG-style). Instead of retrieving chunks, it preloads the entire
relational corpus into the prompt and asks the local model to answer directly.

This is honestly labeled as "CAG-style prompt preload" rather than true
KV-cache CAG, which would require a persistent cache runtime like vLLM. The
point is to test whether retrieval overhead is justified when the entire corpus
fits in context.

_Key commits: `353c2c6`, `602c540`_

## Phase 6: Evaluation Refinement

The benchmark harness (`src/benchmark_relational.py`) was restructured to
separate retrieval scoring from answer scoring. All retrieval-based baselines
generate answers through a shared answer generator
(`cag.py:answer_with_evidence`), so the only variable is the evidence
selection, not the generation template.

The answer prompt itself was tightened in the final phase: a structured JSON
schema now asks the model to decompose questions into parts, extract supported
facts with source citations, report missing parts, and only then write the
final answer. This prompt change lifted answer scores across all baselines --
demonstrating that the generation template, not retrieval quality, had been the
bottleneck.

_Key commits: `88c2f95`, `e3fd232`_

## Where the Experiment Stands

The commit history tells a clear story of iterative expansion:

```
8f47a3e  chore: add .gitignore files for all experiments
992c731  docs(embeddings-rag): add research and planning docs
298d198  feat(embeddings-rag): add chunking comparison and RAG pipeline
a5af7a7  docs: add README for each experiment
7597f57  docs(embeddings-rag): clarify current scope in readme
ba44ad0  docs(embeddings-rag): define benchmark refactor plan
13e0cf8  feat(embeddings-rag): add lexical and hybrid retrieval
e74188c  docs(embeddings-rag): document hybrid retrieval modes
2890f6d  feat(embeddings-rag): add relational evaluation corpus
7d13548  docs(embeddings-rag): describe relational dataset
2808638  feat(embeddings-rag): add relational graph benchmark
6df021d  docs(embeddings-rag): document relational graph baseline
353c2c6  feat(embeddings-rag): add relational cag baseline
602c540  docs(embeddings-rag): describe cag baseline
88c2f95  feat(embeddings-rag): split retrieval and answer evaluation
e3fd232  feat(embeddings-rag): tighten shared answer prompt
```

Each phase added one new question to the experiment and one new baseline to
answer it. The planning docs in `docs/planning/` capture the rationale behind
each expansion, and the research docs in `docs/research/` record the background
reading that informed each decision.
