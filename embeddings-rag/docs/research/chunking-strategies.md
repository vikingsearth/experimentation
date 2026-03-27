# Chunking Strategies for RAG

## Why Chunking Matters

Chunking is how you break documents into pieces before embedding them. It directly shapes retrieval quality: chunks that are too large dilute the semantic signal; chunks that are too small lose context. Chunking is not just preprocessing -- it is a design decision that shapes the entire RAG pipeline.

## Strategy Overview

### 1. Fixed-Size Chunking

Split text into equal-length pieces by character count, word count, or token count.

- **Pros:** Simple, fast, predictable chunk sizes
- **Cons:** Cuts mid-sentence or mid-paragraph, destroying semantic coherence
- **Use when:** You need a quick baseline or uniform chunk sizes for benchmarking

Example: split every 500 characters with 50-character overlap.

### 2. Recursive Chunking

Split hierarchically: first by paragraphs, then sentences, then characters, until chunks fit within a size limit. This is the default in LangChain's `RecursiveCharacterTextSplitter`.

- **Pros:** Preserves natural document structure (paragraphs, sentences) as much as possible
- **Cons:** Slightly more complex than fixed-size; chunk sizes vary
- **Use when:** General-purpose RAG (this is the recommended default)
- **Recommended config:** 400-512 tokens with 10-20% overlap

### 3. Sentence-Based Chunking

Split on sentence boundaries, then group sentences until a size limit is reached.

- **Pros:** Never cuts mid-sentence; cheap to compute
- **Cons:** May split related sentences across chunks
- **Use when:** Prose-heavy documents where sentence integrity matters

A January 2026 analysis found sentence chunking matched semantic chunking in quality up to ~5,000 tokens at a fraction of the computational cost.

### 4. Semantic Chunking

Uses embeddings to detect meaning shifts. Each sentence is embedded, and similarity between adjacent sentences determines where to split.

- **Pros:** Highest retrieval recall (91-92% vs 85-90% for recursive)
- **Cons:** Expensive -- requires embedding every sentence during indexing
- **Use when:** High-value domains where the 2-3% recall improvement justifies the cost

### 5. Context-Aware / Document-Specific Chunking

Adapts to document structure: split by headers in markdown/HTML, by function definitions in code, by sections in PDFs.

- **Pros:** Highest relevance for structured documents
- **Cons:** Requires per-format logic
- **Use when:** You know your document types and can write custom splitters

## Overlap

Overlap repeats tokens from the end of one chunk at the start of the next, preserving context at boundaries.

- **Recommended:** 10-20% of chunk size (e.g., 50-100 tokens for a 500-token chunk)
- **Too little overlap:** Context loss at boundaries
- **Too much overlap:** Redundant storage and retrieval of duplicate content

## Chunk Size Guidelines

| Use Case | Recommended Size | Notes |
|----------|-----------------|-------|
| General RAG | 200-500 tokens | Balance of context and specificity |
| Q&A over docs | 300-400 tokens | Tighter chunks for precise answers |
| Summarization | 500-1000 tokens | Larger chunks preserve more context |
| Code | Variable | Split by function/class boundaries |

## Practical Recommendation

Start with recursive chunking at 400 tokens with 10% overlap. Measure retrieval quality. Only move to semantic chunking if you need the marginal improvement and can afford the indexing cost.

## Sources

- [Weaviate: Chunking Strategies for RAG](https://weaviate.io/blog/chunking-strategies-for-rag)
- [Stack Overflow: Breaking Up is Hard to Do](https://stackoverflow.blog/2024/12/27/breaking-up-is-hard-to-do-chunking-in-rag-applications/)
- [Firecrawl: Best Chunking Strategies for RAG 2026](https://www.firecrawl.dev/blog/best-chunking-strategies-rag)
- [Agenta: Ultimate Guide to RAG Chunking Strategies](https://agenta.ai/blog/the-ultimate-guide-for-chunking-strategies)
