# Refactor Implementation Plan

## Purpose

This document locks down the intended refactor before code changes begin. The goal is to avoid a loose expansion from a small chunking demo into an unfocused collection of AI retrieval techniques.

The refactor should produce a benchmark suite, not a grab bag of partially implemented ideas.

## Core Decisions

### 1. The project is no longer just a chunking demo

The existing code is a valid dense retrieval baseline, but it does not yet compare augmentation strategies in a serious way. After the refactor, chunking remains important, but it becomes one dimension inside a broader benchmark.

### 2. We will compare all three directions discussed earlier

The project should expand in all of these directions:
- More than one vector backend.
- More than one retrieval style.
- More than one augmentation strategy.

That means the target benchmark includes:
- Dense RAG.
- Hybrid retrieval.
- CAG-style no-retrieval baseline.
- GraphRAG.

### 3. GraphRAG is included, but it must earn its place

GraphRAG will be added as a baseline, not as the default architecture. It should be tested on a relational corpus designed for multi-hop or dependency-heavy questions. It should not be judged solely on the current FAQ and tutorial documents, because those mostly reward plain semantic retrieval.

### 4. Local-first remains a hard constraint

The first implementation should run locally without managed cloud services or mandatory API keys. This affects several choices:
- Prefer embedded or self-hosted vector stores.
- Prefer local lexical retrieval implementations.
- Prefer a local graph representation before adopting a graph database.
- Treat external LLM-dependent graph extraction as optional, not required.

### 5. We will not compare everything against everything

A full cross-product of chunkers, embedding models, vector stores, rerankers, graph methods, and generation strategies would bury the educational value in configuration management.

The first refactor will use a bounded comparison matrix and add depth only where the comparison is meaningful.

## Current Baseline to Preserve

The current implementation should remain the control condition:
- Four chunking strategies.
- `all-MiniLM-L6-v2` embeddings.
- `ChromaDB` storage.
- Dense similarity retrieval.
- Retrieval-centric comparison script.

This matters because future baselines need a stable point of comparison.

## Target Baselines

### 1. Dense RAG

### Purpose

Measure the effect of chunking and storage backend on standard dense retrieval.

### Initial backend set

- `ChromaDB` as the existing control.
- `FAISS` as the low-level local nearest-neighbor baseline.
- `Qdrant` or `pgvector` as the production-leaning comparison.

### Notes

The project should not add five or six vector stores in the first pass. Three is enough to expose the main trade-offs.

### 2. Hybrid Retrieval

### Purpose

Compare dense-only retrieval against dense plus lexical retrieval.

### Initial shape

- Dense retriever plus BM25 fusion.
- Optional reranking left for a later phase.

### Notes

This baseline is likely to matter more than adding a fourth vector database. For technical or structured content, hybrid retrieval often fixes failure modes that dense search alone misses.

### 3. CAG-Style Baseline

### Purpose

Test whether retrieval is worth the overhead for a small, stable corpus.

### Initial implementation options

- Preferred: true persistent KV-cache workflow if the chosen model runtime makes this practical.
- Acceptable first version: no-retrieval context-preload baseline that passes the full small corpus or a compact corpus representation directly to the model.

### Notes

The naming should stay honest. If the implementation is prompt preload without persistent KV cache, the docs and code should say so clearly.

### 4. GraphRAG

### Purpose

Evaluate graph-based retrieval for relational and multi-hop questions.

### Initial implementation shape

- Lightweight graph extraction suitable for a local project.
- Local graph representation using in-memory structures or a serialized graph file.
- Neighborhood or path-based retrieval for relevant entities and relationships.

### Notes

The first version does not need Neo4j or a large graph platform. `networkx` plus a well-designed relational corpus is enough to establish the baseline.

## Dataset Strategy

### Dataset A: Current tutorial corpus

Files:
- `data/python_guide.txt`
- `data/faq.txt`

Best suited for:
- Dense retrieval.
- Chunking comparisons.
- Hybrid retrieval versus dense retrieval.
- Small-corpus no-retrieval evaluation.

Weak for:
- Demonstrating the value of graph traversal.

### Dataset B: New relational corpus

The refactor should add a second dataset that is explicitly relational.

Recommended theme:
- Small synthetic company operations knowledge base.

Suggested entities:
- Teams.
- People.
- Services.
- Repositories.
- Incidents.
- Dependencies.
- Policies.

Suggested question types:
- Ownership questions.
- Dependency questions.
- Root-cause chains.
- Policy exceptions.
- Multi-hop lookups involving two or three linked entities.

This dataset should be compact enough to inspect manually and structured enough that graph retrieval is not decorative.

## Evaluation Plan

The current project mostly measures retrieval similarity and keyword overlap. That is no longer sufficient.

### Retrieval evaluation

For each question, store one or more expected evidence targets:
- relevant chunks for dense and hybrid retrieval.
- relevant nodes or edges for graph retrieval.

Metrics:
- Recall at `k`.
- Precision at `k` where feasible.
- Evidence coverage.

### Answer evaluation

For generated answers, use a light but explicit scoring approach:
- expected answer keywords or facts.
- evidence-backed correctness.
- unsupported claim count where practical.

### Systems evaluation

For each baseline, record:
- indexing time.
- query time.
- storage footprint.
- dependencies required.

### Qualitative evaluation

Record short written observations for:
- failure modes.
- setup complexity.
- interpretability of retrieved evidence.

## Proposed Code Structure

The current single-path scripts should evolve toward reusable components.

```text
src/
  baselines/
    dense_rag.py
    hybrid_retrieval.py
    cag_baseline.py
    graph_rag.py
  backends/
    chroma_store.py
    faiss_store.py
    qdrant_store.py
  retrieval/
    dense.py
    bm25.py
    fusion.py
  graph/
    extract.py
    build.py
    query.py
  evaluation/
    benchmark.py
    metrics.py
    report.py
  datasets/
    loader.py
    labels.py
```

The current files can either be wrapped around the new abstractions or replaced gradually as the new structure lands.

## Command Design

The refactor should move toward commands that reflect baselines and evaluation tasks rather than one-off scripts.

Examples:
- `python src/index.py --baseline dense --backend chroma`
- `python src/query.py --baseline hybrid --question "..."`
- `python src/benchmark.py --dataset tutorial`
- `python src/benchmark.py --dataset relational --baseline graph`

The exact CLI can change, but the principle should stay: users should be able to run the same benchmark flow across different baselines with minimal command changes.

## Sequence of Implementation

1. Preserve the current dense Chroma path as the control baseline.
2. Extract shared dataset loading, chunking, embedding, and reporting utilities.
3. Introduce a storage backend interface.
4. Add `FAISS`.
5. Add `Qdrant` or `pgvector`.
6. Introduce BM25 and hybrid fusion.
7. Add the no-retrieval CAG-style baseline.
8. Add the relational dataset.
9. Add GraphRAG over a lightweight local graph representation.
10. Unify benchmark reporting.

## Explicit Non-Goals for the First Refactor

Do not do these in the initial implementation:
- Fine-tune models.
- Add many embedding models.
- Add multiple rerankers.
- Require GPUs.
- Require cloud services.
- Require a production graph database.

Those are reasonable later expansions, but they should not delay the first usable benchmark suite.

## Success Criteria

The refactor is successful when:
- The project can benchmark dense, hybrid, CAG-style, and graph-based approaches from one shared framework.
- At least one relational dataset exists where GraphRAG has a fair test.
- At least two vector backend comparisons exist beyond Chroma.
- The docs explain where each method is expected to help and where it is likely to be overkill.
- The benchmark output includes both quality and cost trade-offs.

## Final Guardrail

If a proposed addition does not improve one of these dimensions, it should probably wait:
- educational clarity
- methodological fairness
- baseline coverage
- practical usefulness

That is the standard for accepting scope into this refactor.