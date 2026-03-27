# Vector Databases for RAG

## What is a Vector Database?

A vector database stores high-dimensional vectors (embeddings) and supports fast similarity search. In a RAG pipeline, it is the retrieval layer: you query it with an embedded question and get back the most semantically similar document chunks.

## Key Options

### ChromaDB

- **Type:** Open-source embedded vector database
- **Best for:** Prototyping, learning, MVPs (up to ~10M vectors)
- **Key traits:**
  - Runs in-process (no separate server needed)
  - Python-native API -- feels like working with a dict
  - 2025 Rust rewrite: 4x faster writes and queries
  - Supports persistent storage to disk
  - Built-in embedding function support
- **Limitations:** Not designed for 50M+ vector production workloads

### FAISS (Meta)

- **Type:** Low-level similarity search library (C++ with Python bindings)
- **Best for:** Research, maximum performance, GPU-accelerated search
- **Key traits:**
  - Pure search library -- no persistence, no API, no metadata management
  - GPU acceleration: 5-10x faster than CPU
  - Scales to billions of vectors (with manual management)
  - Multiple index types (flat, IVF, HNSW, PQ)
- **Limitations:** You build everything around it yourself

### Pinecone

- **Type:** Fully managed cloud vector database
- **Best for:** Enterprise production, serverless scaling
- **Key traits:**
  - Zero infrastructure management
  - Separates storage from compute
  - Handles billions of vectors
  - Built-in filtering and metadata
- **Limitations:** Cloud-only, pay-per-use cost

### Other Notable Options

- **Weaviate:** Open-source, GraphQL API, hybrid search (vector + keyword)
- **Qdrant:** Open-source, Rust-based, strong filtering, good for production
- **Milvus:** Open-source, designed for massive scale, GPU support

## Quick Comparison

| Feature | ChromaDB | FAISS | Pinecone |
|---------|----------|-------|----------|
| Type | Open-source DB | Library | Managed cloud |
| Setup | `pip install` | `pip install` | API key |
| Persistence | Built-in | DIY | Managed |
| Scale | ~10M vectors | Billions | Billions |
| Cost | Free | Free | Pay-per-use |
| GPU | No | Yes | N/A |
| Metadata | Yes | No | Yes |
| REST API | Yes | No | Yes |

## Choosing for This Experiment

We use **ChromaDB** because:
1. Zero infrastructure -- runs embedded in Python
2. Free and open-source
3. Built-in embedding function support
4. Persistent storage for comparing across runs
5. Perfect for learning and prototyping

## Sources

- [Medium: Vector Databases for RAG](https://medium.com/@priyaskulkarni/vector-databases-for-rag-faiss-vs-chroma-vs-pinecone-6797bd98277d)
- [LiquidMetal AI: Vector Database Comparison 2025](https://liquidmetal.ai/casesAndBlogs/vector-comparison/)
- [Firecrawl: Best Vector Databases 2025](https://www.firecrawl.dev/blog/best-vector-databases)
