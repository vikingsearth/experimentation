# Experiment Plan: LlamaIndex Index Types Comparison

## Goal

Demonstrate how different LlamaIndex index types work by building each one from the same
set of sample documents, querying them with the same questions, and comparing the results
to show when each index type shines.

## Sample Data

Create 4-5 text documents covering different topics with varying levels of detail:

1. **python_overview.txt** -- Overview of Python programming language (general, broad)
2. **machine_learning.txt** -- Machine learning concepts and algorithms (technical, detailed)
3. **climate_change.txt** -- Climate change causes and effects (factual, interconnected)
4. **company_profile.txt** -- Fictional company profile with people and relationships
5. **cooking_recipes.txt** -- A few recipes with specific ingredients and steps (structured)

This variety tests different index strengths: semantic search, summarization, keyword
matching, and relationship extraction.

## Index Types to Demonstrate

1. **VectorStoreIndex** -- Semantic similarity search (the default)
2. **SummaryIndex** -- Read-everything summarization
3. **TreeIndex** -- Hierarchical summary tree
4. **KeywordTableIndex** -- Keyword-based routing

Note: KnowledgeGraphIndex is excluded because it requires significant LLM calls for triplet
extraction and adds complexity without proportional educational value for a quick showcase.

## Test Queries

Design queries that highlight different index strengths:

| Query | Best Index | Why |
|-------|-----------|-----|
| "What is Python used for?" | VectorStore | Semantic similarity finds relevant chunks |
| "Summarize all the documents" | Summary | Reads everything, ideal for global summary |
| "What ingredients do I need for pasta?" | Keyword | Specific keywords match well |
| "Give a high-level overview of all topics covered" | Tree | Hierarchical summary excels |
| "Who is the CEO of TechVista?" | VectorStore/Keyword | Specific fact retrieval |

## Implementation Structure

```
llamaindex-indexers/
  data/                          # Sample documents
    python_overview.txt
    machine_learning.txt
    climate_change.txt
    company_profile.txt
    cooking_recipes.txt
  src/
    01_setup_and_load.py         # Load documents, show node parsing
    02_vector_store_index.py     # Build and query VectorStoreIndex
    03_summary_index.py          # Build and query SummaryIndex
    04_tree_index.py             # Build and query TreeIndex
    05_keyword_table_index.py    # Build and query KeywordTableIndex
    06_compare_all.py            # Run same queries across all indices, compare results
  docs/
    research/                    # Research notes
    planning/                    # This plan
  requirements.txt
  README.md
```

## Approach

- Use **HuggingFace embeddings** (free, local) to avoid requiring an OpenAI API key
  for embeddings
- Use **Ollama** for local LLM calls required for synthesis and tree building
- Default local model is `qwen2.5:3b-instruct`; `llama3.2:3b` is kept for comparison
- Use a repeatable benchmark script to compare local model speed and qualitative output
- Each script is standalone and runnable independently
- The comparison script (`06_compare_all.py`) ties everything together

## Expected Outcomes

- VectorStoreIndex: Best for specific factual queries, fast, good default
- SummaryIndex: Best for "tell me everything" queries, slow but thorough
- TreeIndex: Best for hierarchical/overview queries in principle, but quality is sensitive
  to local model strength and is currently the weakest part of the experiment
- KeywordTableIndex: Best for keyword-specific lookups, cheapest to build

## Current Implementation Status

- The experiment now runs fully offline except for local Ollama and Hugging Face model downloads.
- `MockLLM` and remote OpenAI dependencies have been removed from the actual workflow.
- `SimpleKeywordTableIndex` is used instead of the GPT-backed keyword table variant.
- Tree building is eager so the demo uses a real summary hierarchy.
- `src/07_benchmark_models.py` benchmarks `qwen2.5:3b-instruct` and `llama3.2:3b`
  with a clean Ollama warmup and short qualitative snapshots.
- Latest benchmark run on 2026-03-30 showed `llama3.2:3b` was materially faster,
  while both 3B models still produced weak root-summary output for `TreeIndex`.

## Time Estimate

- A reader should be able to understand the experiment in ~5 minutes by reading the README
  and the comparison script output
- Running `06_compare_all.py` is still short enough for interactive use, but the full
  two-model benchmark takes several minutes because `TreeIndex` build time dominates

## Review Notes

- Plan is simple: 4 index types, 5 documents, 5 queries
- Each script is short and self-contained
- The comparison script provides the "aha moment"
- No external hosted API is required for the current setup
- The main open limitation is TreeIndex summary quality with small local models
