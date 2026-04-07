# Embedding Models for RAG

## What Are Embeddings?

Embeddings are dense vector representations of text that capture semantic meaning. Similar texts produce vectors that are close together in vector space. They are the foundation of semantic search in RAG.

## Key Models

### Sentence-Transformers (Open Source, Free)

The `sentence-transformers` library provides pre-trained models that run locally.

| Model | Dimensions | Speed | Quality | Size |
|-------|-----------|-------|---------|------|
| all-MiniLM-L6-v2 | 384 | Fast | Good | ~22M params |
| all-mpnet-base-v2 | 768 | Medium | Better | ~110M params |
| BGE-large-en-v1.5 | 1024 | Slower | High | ~335M params |

- **all-MiniLM-L6-v2:** Best speed/quality tradeoff for prototyping. Runs on CPU in seconds.
- **all-mpnet-base-v2:** Most downloaded embedding model on HuggingFace. Good default.
- **BGE-large-en-v1.5:** Higher quality, slower. Good for production.

### OpenAI Embeddings (API, Paid)

| Model | Dimensions | Cost |
|-------|-----------|------|
| text-embedding-3-small | 1536 | $0.02/1M tokens |
| text-embedding-3-large | 3072 | $0.13/1M tokens |

- High quality, especially for general-purpose retrieval
- Requires API calls (latency + cost)
- Not suitable for offline or privacy-sensitive use

### Other Notable Models

- **Voyage AI:** Top-performing commercial embeddings (outcompeting Jina v3 and Cohere v3)
- **Nomic-Embed:** Open-source, strong performance, good starting point
- **NV-Embed-v2:** NVIDIA's model, highest MTEB retrieval score (62.7%)
- **Stella:** Open-source, excellent performance at zero cost

## Choosing an Embedding Model

### Decision Factors

1. **Cost:** Open-source models are free to run; API models charge per token
2. **Privacy:** Local models keep data on-premise; API models send data externally
3. **Quality:** Larger models and API models generally score higher on benchmarks
4. **Speed:** Smaller local models are faster for batch processing
5. **Dimensions:** Higher dimensions capture richer semantics but use more storage

### Practical Guidance

- **Prototyping:** all-MiniLM-L6-v2 (fast, free, good enough)
- **Production (budget):** all-mpnet-base-v2 or BGE-large-en-v1.5
- **Production (quality):** OpenAI text-embedding-3-small or Voyage AI
- **High volume (>1.5M tokens/month):** Local models save significant cost

### Important: Consistency

Once you choose an embedding model, you must use the same model for both indexing and querying. Mixing models produces incompatible vector spaces and breaks retrieval.

## For This Experiment

We use **all-MiniLM-L6-v2** from sentence-transformers because:
1. Free and runs locally (no API key needed)
2. Fast enough for interactive experimentation
3. 384 dimensions keeps storage small
4. Good quality for demonstrating concepts

## Sources

- [BentoML: Best Open-Source Embedding Models 2026](https://www.bentoml.com/blog/a-guide-to-open-source-embedding-models)
- [ArtSmart: Top Embedding Models 2025](https://artsmart.ai/blog/top-embedding-models-in-2025/)
- [Supermemory: Open-Source Embedding Models Benchmarked](https://supermemory.ai/blog/best-open-source-embedding-models-benchmarked-and-ranked/)
- [MarkAICode: Embedding Models Comparison](https://markaicode.com/embedding-models-comparison-openai-sentence-transformers/)
