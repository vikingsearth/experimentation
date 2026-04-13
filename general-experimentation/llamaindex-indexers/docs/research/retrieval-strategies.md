# Retrieval Strategies in LlamaIndex

## Basic Retrieval Modes

Each index type supports one or more retrieval modes:

### VectorStoreIndex Retrieval
- **Default**: Embed query, find top-k similar nodes by cosine similarity
- **With metadata filters**: Filter nodes by metadata before similarity search
- **MMR (Maximal Marginal Relevance)**: Balance relevance with diversity in results

### SummaryIndex Retrieval
- **Default**: Return ALL nodes (no filtering)
- **Embedding mode**: Embed query, return top-k similar nodes
- **LLM mode**: Use LLM to determine which nodes are relevant

### TreeIndex Retrieval
- **Select**: LLM selects relevant child at each level (default)
- **All leaf**: Return all leaf nodes
- **Root**: Return only root summary nodes

### KeywordTableIndex Retrieval
- **Default**: Extract keywords from query, match against keyword table
- **Simple**: Regex-based keyword extraction (no LLM)
- **Rake**: Use RAKE algorithm for keyword extraction

## Advanced Retrieval Strategies

### 1. Hybrid Search
Combine keyword (BM25) and vector (semantic) search:
```python
from llama_index.core.retrievers import QueryFusionRetriever

retriever = QueryFusionRetriever(
    retrievers=[vector_retriever, bm25_retriever],
    similarity_top_k=5,
    num_queries=1,  # disable query generation
    mode="reciprocal_rerank",
)
```

### 2. Reranking
Apply a cross-encoder to re-order top-k candidates after initial retrieval:
```python
from llama_index.postprocessor.cohere_rerank import CohereRerank

reranker = CohereRerank(top_n=3)
query_engine = index.as_query_engine(
    similarity_top_k=10,
    node_postprocessors=[reranker],
)
```

### 3. Query Transformations
- **HyDE (Hypothetical Document Embeddings)**: Generate a hypothetical answer, embed it,
  use that embedding for retrieval
- **Sub-question decomposition**: Break complex queries into simpler sub-queries, retrieve
  for each, then combine
- **Step-back prompting**: Generate a more general query to retrieve broader context

### 4. Sentence Window Retrieval
Store small sentence-level chunks for precise matching, but return a larger window of
surrounding context to the LLM:
```python
from llama_index.core.node_parser import SentenceWindowNodeParser

node_parser = SentenceWindowNodeParser.from_defaults(
    window_size=3,  # 3 sentences on each side
)
```

### 5. Auto-Merging Retrieval
If enough leaf chunks from the same parent are retrieved, automatically merge them into
the parent chunk for more complete context.

## Composable Indices and Routing

### ComposableGraph
Build indices on top of other indices:
```python
from llama_index.core.composability import ComposableGraph

graph = ComposableGraph.from_indices(
    TreeIndex,
    [index1, index2, index3],
    index_summaries=["Summary of index 1", "Summary of index 2", "Summary of index 3"],
)
query_engine = graph.as_query_engine()
```

### RouterQueryEngine
Route queries to the most appropriate index automatically:
```python
from llama_index.core.query_engine import RouterQueryEngine
from llama_index.core.selectors import LLMSingleSelector

query_engine = RouterQueryEngine(
    selector=LLMSingleSelector.from_defaults(),
    query_engine_tools=[
        QueryEngineTool.from_defaults(query_engine=vector_qe, description="..."),
        QueryEngineTool.from_defaults(query_engine=summary_qe, description="..."),
    ],
)
```

### Agentic Composite Retrieval (2025+)
LlamaIndex now supports agentic retrieval patterns:
- Top layer: LLM-based classification routes to relevant sub-indices
- Sub-index layer: Auto-selects retrieval method (chunk, files_via_metadata, files_via_content)
- Uses `CompositeRetrievalMode.ROUTED` for automatic routing

## Best Practices

1. **Start with VectorStoreIndex** -- it works well for most use cases
2. **Tune chunk_size and chunk_overlap** -- these have outsized effect on accuracy
3. **Add reranking** once basic retrieval is working
4. **Use hybrid search** when you need both keyword precision and semantic recall
5. **Compose indices** when you have heterogeneous document types
6. **Route queries** when different data sources need different retrieval strategies
