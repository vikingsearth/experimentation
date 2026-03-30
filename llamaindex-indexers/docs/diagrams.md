# LlamaIndex Indexers Diagrams

This file gives a visual map of the experiment so you can reason about it without
jumping between all the scripts.

## 1. Big Picture

ASCII overview:

```text
data/*.txt
   |
   v
SimpleDirectoryReader
   |
   v
Document chunks / nodes
   |
   +------------------------------+
   |                              |
   v                              v
HuggingFace embeddings       Ollama local LLM
(BAAI/bge-small-en-v1.5)     (qwen2.5:3b-instruct or llama3.2:3b)
   |                              |
   +--------------+---------------+
                  |
                  v
        +------------------------+
        | Four index experiments |
        +------------------------+
          |       |       |      |
          v       v       v      v
      Vector   Summary   Tree  Keyword
       Store     List    Hier.  Table
          \       |       |      /
           \      |       |     /
            +-----+-------+----+
                  |
                  v
        Side-by-side query comparison
             and model benchmarking
```

Mermaid overview:

```mermaid
flowchart TD
    A[data/*.txt] --> B[SimpleDirectoryReader]
    B --> C[Document chunks and nodes]
    C --> D[HuggingFace embeddings\nBAAI/bge-small-en-v1.5]
    C --> E[Ollama local LLM\nqwen2.5:3b-instruct or llama3.2:3b]
    D --> F[VectorStoreIndex]
    D --> G[SummaryIndex embedding mode]
    D --> H[TreeIndex retrieval guidance]
    C --> I[SimpleKeywordTableIndex]
    E --> G
    E --> H
    F --> J[06_compare_all.py]
    G --> J
    H --> J
    I --> J
    J --> K[Result comparison]
    J --> L[07_benchmark_models.py]
```

## 2. Script Journey

ASCII walkthrough:

```text
01_setup_and_load.py
  -> show documents and chunking

02_vector_store_index.py
  -> semantic retrieval baseline

03_summary_index.py
  -> read-many / summarize-all behavior

04_tree_index.py
  -> hierarchical summaries and traversal

05_keyword_table_index.py
  -> simple keyword routing via regex-style extraction

06_compare_all.py
  -> same questions across all four indices

07_benchmark_models.py
  -> same workflow across multiple Ollama models
```

Mermaid script flow:

```mermaid
flowchart LR
    S1[01 setup and load] --> S2[02 vector store]
    S2 --> S3[03 summary]
    S3 --> S4[04 tree]
    S4 --> S5[05 keyword table]
    S5 --> S6[06 compare all]
    S6 --> S7[07 benchmark models]
```

## 3. Index Behavior Map

ASCII comparison:

```text
+-------------------+------------+------------+-------------------------------+
| Index             | Build Cost | Query Cost | Best Fit                      |
+-------------------+------------+------------+-------------------------------+
| VectorStoreIndex  | medium     | low        | semantic Q&A, factual lookup  |
| SummaryIndex      | low        | high       | summarize everything          |
| TreeIndex         | high       | medium     | hierarchy, overview to detail |
| KeywordTableIndex | low        | low        | exact terms, routing          |
+-------------------+------------+------------+-------------------------------+
```

Mermaid decision map:

```mermaid
flowchart TD
    Q[What kind of question do I have?] --> Q1{Need semantic meaning?}
    Q1 -->|Yes| V[VectorStoreIndex]
    Q1 -->|No| Q2{Need all documents considered?}
    Q2 -->|Yes| S[SummaryIndex]
    Q2 -->|No| Q3{Need hierarchical overview?}
    Q3 -->|Yes| T[TreeIndex]
    Q3 -->|No| K[KeywordTableIndex]
```

## 4. Compare-All Query Path

ASCII query lifecycle:

```text
User query
   |
   v
06_compare_all.py
   |
   +--> VectorStoreIndex.as_retriever(similarity_top_k=3)
   |
   +--> SummaryIndex.as_retriever(retriever_mode="embedding")
   |
   +--> TreeIndex.as_retriever(...)
   |      |- root mode for broad summarization queries
   |      `- select_leaf_embedding for focused queries
   |
   `--> SimpleKeywordTableIndex.as_retriever(retriever_mode="simple")
           |
           v
     Retrieved nodes + timing + source files
           |
           v
     Printed side-by-side comparison
```

Mermaid query flow:

```mermaid
flowchart TD
    Q[User query] --> C[06_compare_all.py]
    C --> V[VectorStore retriever]
    C --> S[Summary retriever embedding mode]
    C --> T[Tree retriever]
    C --> K[Simple keyword retriever]
    T --> T1[root mode for broad summary queries]
    T --> T2[select_leaf_embedding for focused queries]
    V --> R[Collected results]
    S --> R
    T1 --> R
    T2 --> R
    K --> R
    R --> O[Display sources, previews, timing]
```

## 5. Benchmark Workflow

ASCII benchmark path:

```text
07_benchmark_models.py
   |
   +--> ollama ps / ollama stop
   |      clean loaded models
   |
   +--> ollama run MODEL "READY"
   |      warm target model
   |
   +--> build_all_indices(documents)
   |
   +--> run fixed query set
   |      record timing and source hits
   |
   `--> run qualitative snapshots
          |- summary answer
          |- tree answer
          |- vector fact answer
          `- tree fact answer
```

Mermaid sequence diagram:

```mermaid
sequenceDiagram
    participant B as 07_benchmark_models.py
    participant O as Ollama CLI
    participant C as 06_compare_all.py
    participant I as Indices

    B->>O: ollama ps
    B->>O: ollama stop <running models>
    B->>O: ollama run MODEL "READY"
    B->>C: build_all_indices(documents)
    C->>I: Build VectorStore, Summary, Tree, Keyword
    B->>C: query_all_indices(test queries)
    C->>I: Retrieve nodes and timings
    B->>I: Run qualitative snapshot queries
    I-->>B: Answers and source hits
```

## 6. Current Findings

ASCII summary of where the experiment stands now:

```text
What works well:
  - VectorStoreIndex is the strongest default.
  - SummaryIndex behaves predictably.
  - KeywordTableIndex is cheap and useful for exact-term routing.
  - Benchmarking is now repeatable across local models.

What is still weak:
  - TreeIndex root summaries are poor with the current 3B local models.
  - Switching between qwen2.5:3b-instruct and llama3.2:3b changes speed more
    than it changes the core TreeIndex quality problem.

What that means:
  - The next meaningful improvement is not more documentation or more small-model
    comparison. It is either:
      1. a stronger local model, or
      2. a different TreeIndex strategy / prompt / retrieval setup.
```

Mermaid findings map:

```mermaid
flowchart TD
    A[Current experiment state] --> B[VectorStoreIndex is strong]
    A --> C[SummaryIndex is understandable and stable]
    A --> D[KeywordTableIndex is fast and cheap]
    A --> E[TreeIndex quality is weak]
    E --> F[Small local models are the limiting factor]
    F --> G[Try a stronger local model]
    F --> H[Or change tree strategy and prompting]
```

## 7. File-Level Mental Model

```text
README.md
  human-oriented setup, usage, and latest benchmark takeaway

docs/planning/plan.md
  what the experiment set out to show and what changed in practice

docs/diagrams.md
  visual orientation for the whole experiment

src/04_tree_index.py
  deepest TreeIndex-specific demo and current weak point

src/06_compare_all.py
  central comparison harness for the four index types

src/07_benchmark_models.py
  repeatable local-model comparison harness
```