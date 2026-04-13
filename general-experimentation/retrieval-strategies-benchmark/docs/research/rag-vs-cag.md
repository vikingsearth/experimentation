# RAG vs CAG: Augmented Generation Approaches

## The Core Problem

LLMs have a knowledge cutoff and limited context windows. To ground them in specific documents, you need an augmentation strategy. The two main approaches are RAG (Retrieval Augmented Generation) and CAG (Cache Augmented Generation).

## RAG (Retrieval Augmented Generation)

### How It Works

1. **Index:** Chunk documents, embed them, store in a vector database
2. **Retrieve:** When a query arrives, embed the query, search the vector DB for similar chunks
3. **Generate:** Pass retrieved chunks + query to the LLM as context

### Architecture

```
User Query --> Embed Query --> Vector Search --> Top-K Chunks --> LLM --> Response
                                    |
                              Vector Database
                          (pre-indexed documents)
```

### Strengths

- Scales to massive knowledge bases (millions of documents)
- Dynamic -- add/remove documents without retraining
- Only retrieves relevant chunks, keeping context focused
- Well-established ecosystem (LangChain, LlamaIndex, etc.)

### Weaknesses

- Retrieval latency adds to response time
- Retrieval errors propagate -- wrong chunks lead to wrong answers
- Complex pipeline: embeddings + vector DB + reranking + generation
- Chunk boundaries can split important context

## CAG (Cache Augmented Generation)

### How It Works

1. **Preload:** Load entire knowledge base into LLM context (once)
2. **Cache:** Save the KV cache (model's internal state after processing the context)
3. **Query:** For each question, load the cached KV state and generate directly

### Architecture

```
[Offline] Full Document Set --> LLM --> Save KV Cache to disk

[Online]  User Query + Preloaded KV Cache --> LLM --> Response
                                              (no retrieval step)
```

### Strengths

- Very low latency (no retrieval overhead)
- No retrieval errors -- the model sees everything
- Simple architecture (no vector DB, no embedding pipeline)
- Better coherence -- model has full document context

### Weaknesses

- Limited by context window size (even 128K tokens has limits)
- Upfront compute cost to generate the KV cache
- Stale data requires re-caching
- Not practical for very large knowledge bases

### Benchmark Results

On HotPotQA: CAG scored 0.7527 BERTScore vs 0.7398 for dense RAG, while reducing generation time from 94.35s to 2.33s.

## Other Approaches

### Graph RAG

Uses a knowledge graph instead of (or alongside) vector search. Entities and relationships are extracted from documents and stored as a graph. Queries traverse the graph to find relevant context.

- **Best for:** Highly relational data (e.g., org charts, scientific literature networks)
- **Trade-off:** Complex to build and maintain

### Hybrid RAG + CAG

Preload a foundation context (CAG) and use retrieval (RAG) only for edge cases or highly specific queries.

- **Example:** A retail company preloads product details (CAG) for customer support while using RAG to fetch real-time inventory/promotions.

### Long-Context Models (Context Stuffing)

With models supporting 128K-1M tokens, you can sometimes just paste the relevant documents directly into the prompt without any retrieval.

- **Best for:** Small knowledge bases where the entire corpus fits in context
- **Trade-off:** Expensive per-query (processing all tokens every time)

## Decision Framework

| Factor | Choose RAG | Choose CAG |
|--------|-----------|-----------|
| Knowledge base size | Large (>context window) | Small (fits in context) |
| Update frequency | Frequent changes | Stable/infrequent |
| Latency needs | Tolerant | Critical |
| Infrastructure | Can manage pipeline | Want simplicity |
| Accuracy needs | Good enough | Maximum coherence |

## For This Experiment

We implement a RAG pipeline because:
1. It demonstrates the full indexing/embedding/retrieval workflow
2. It works with any knowledge base size
3. It is the most widely used approach in production
4. The concepts (chunking, embedding, vector search) are fundamental to all approaches

## Sources

- [ArXiv: Don't Do RAG (CAG paper)](https://arxiv.org/html/2412.15605v1)
- [PromptHub: RAG vs CAG](https://www.prompthub.us/blog/retrieval-augmented-generation-vs-cache-augmented-generation)
- [ForteGRP: CAG vs RAG Architecture](https://www.fortegrp.com/insights/cag-vs-rag)
- [The Neural Maze: RAG vs CAG Deep Technical Breakdown](https://theneuralmaze.substack.com/p/rag-vs-cag-a-deep-technical-breakdown)
