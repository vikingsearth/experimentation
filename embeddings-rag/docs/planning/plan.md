# Experiment Plan: Retrieval and Augmentation Benchmark

## Goal

Evolve the current chunking-focused dense retrieval demo into a broader benchmark that compares multiple augmentation strategies while staying local-first, easy to run, and small enough to teach from.

This means the project should answer more than one question:
- Which chunking strategy works best for dense retrieval on small text corpora?
- How much does the vector store backend matter at this scale?
- When does hybrid retrieval beat dense-only retrieval?
- When is a small-corpus no-retrieval baseline competitive with RAG?
- When does GraphRAG help enough to justify its extra complexity?

## Current State

The existing implementation covers one narrow but useful slice of the space:
- Four chunking strategies.
- One embedding model.
- One vector database backend: ChromaDB.
- Dense, lexical, and hybrid retrieval over the same local corpus.
- Retrieval scoring only, not answer-generation benchmarking.

That remains a valid baseline, but it is no longer the full intended scope of the project.

## Revised Benchmark Scope

The benchmark will be organized around four baseline families:

### 1. Dense RAG

Classic chunking plus embeddings plus vector search.

Questions it answers:
- Which chunker works best?
- Which local vector backend is simplest or fastest?
- How sensitive are results to embedding model and corpus structure?

### 2. Hybrid Retrieval

Combine dense retrieval with lexical retrieval such as BM25, then optionally rerank.

Questions it answers:
- When do exact terms or rare identifiers matter?
- Does hybrid retrieval improve robustness on technical or structured text?

### 3. CAG-Style Small-Corpus Baseline

Use a no-retrieval baseline for corpora that fit into context or can be represented by a cached prompt/context artifact.

Questions it answers:
- For a small and stable corpus, is retrieval overhead worth it?
- How often does a no-retrieval baseline match or exceed dense retrieval?

Note: a true KV-cache implementation is desirable, but the first version may begin with a simpler no-retrieval baseline if model/runtime support makes persistent KV cache management too invasive for the initial refactor.

### 4. GraphRAG

Build a lightweight knowledge graph from entities and relationships, then retrieve subgraphs or graph-neighborhood context for answering relational questions.

Questions it answers:
- Does graph retrieval help on multi-hop or dependency-heavy questions?
- What complexity is introduced relative to dense or hybrid retrieval?

## Datasets

The benchmark will use at least two dataset types.

### A. Tutorial and FAQ Corpus

Current files in `data/` remain useful for:
- Definition lookup.
- Explanatory questions.
- Chunking comparisons.
- Dense versus hybrid retrieval on prose and FAQ formats.

### B. Relational Corpus

A new small synthetic corpus should be added specifically for GraphRAG and multi-hop evaluation.

Desired traits:
- Clear entities such as teams, services, owners, incidents, dependencies, and policies.
- Cross-document relationships that force multi-step reasoning.
- Enough structure that graph retrieval has a fair chance to outperform dense similarity alone.

Without this second corpus, GraphRAG would be present but not meaningfully tested.

## Evaluation Criteria

The refactor should introduce a benchmark harness that evaluates more than retrieval similarity.

### Retrieval Metrics

- Recall at `k` for labeled relevant chunks or nodes.
- Precision at `k` where labels are available.
- Coverage of expected entities, terms, or evidence spans.

### Answer Metrics

- Simple correctness heuristics for deterministic questions.
- Groundedness: whether the answer is supported by retrieved evidence.
- Citation or evidence trace quality where the baseline supports it.

### Performance Metrics

- Index build time.
- Query latency.
- Storage footprint.
- Number of artifacts to manage locally.

### Operational Metrics

- Setup friction.
- Dependency weight.
- Conceptual complexity for someone learning the method.

## Architecture Direction

The project should move from one script path to a baseline-oriented architecture.

```
Dataset
  |
  +--> Dense RAG -----------+
  |
  +--> Hybrid Retrieval ----+--> Unified benchmark harness --> reports
  |
  +--> CAG-style baseline --+
  |
  +--> GraphRAG ------------+
```

The benchmark harness should compare approaches without creating a full combinatorial explosion across every possible model, chunker, and backend.

## Comparison Matrix

The first refactor should keep the matrix intentionally bounded.

Recommended initial matrix:
- Dense RAG with `Chroma`, `FAISS`, and `Qdrant` or `pgvector`.
- Hybrid retrieval with one dense backend plus local BM25.
- CAG-style baseline with no retrieval step.
- GraphRAG with a lightweight local graph representation.

That gives breadth without turning the project into infrastructure work.

## Scope Boundaries

Still out of scope for the first refactor:
- Fine-tuning or training new embedding models.
- Benchmarking every vector database on the market.
- Enterprise-scale corpora.
- Full document parsing pipelines for PDF, HTML, and Office documents.
- Cloud-managed infrastructure as a baseline requirement.

Optional later additions:
- Rerankers.
- More embedding models.
- Long-context answer generation with a local LLM.
- A graph database such as Neo4j after the local graph baseline exists.

## Implementation Phases

1. Lock down docs, scope, datasets, and evaluation criteria.
2. Refactor the code into reusable baseline and backend abstractions.
3. Preserve the current Chroma dense baseline as the control.
4. Add at least two more storage or retrieval backends.
5. Add hybrid retrieval.
6. Add the no-retrieval CAG-style baseline.
7. Add GraphRAG with a relational corpus.
8. Add unified comparison reports.

## What a Developer Should Learn

By the end state, the project should teach:

1. Why chunking still matters even when embeddings are strong.
2. Why vector storage is only one variable in a retrieval system.
3. When keyword signals outperform semantic similarity.
4. Why CAG-style approaches are attractive on small, stable corpora.
5. Why GraphRAG only pays off when the data and question style are relational.
6. How to evaluate augmentation strategies as trade-offs, not ideology.
