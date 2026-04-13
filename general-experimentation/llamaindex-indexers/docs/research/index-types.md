# LlamaIndex Index Types: Deep Dive

## Overview

LlamaIndex provides several index types, each with different data structures, build costs,
query strategies, and ideal use cases. Choosing the right index type is critical for
performance, cost, and answer quality.

---

## 1. VectorStoreIndex

**The workhorse of LlamaIndex -- the most commonly used index type.**

### How It Works

- **Build**: Each node is converted to an embedding vector (via an embedding model) and stored
  in a vector store. Embeddings are generated at build time (upfront cost).
- **Data Structure**: A flat collection of (embedding, node) pairs stored in a vector database.
  Default backend is `SimpleVectorStore` (in-memory); can use FAISS, Pinecone, Weaviate,
  Chroma, Qdrant, etc.
- **Query**: The query is embedded, then top-k most similar nodes are retrieved via cosine
  similarity (or other distance metric). Retrieved nodes are passed to the response synthesizer.

### Strengths

- Fast semantic search over large corpora
- Works well for general-purpose Q&A
- Scales with vector database backends
- Simple mental model

### Weaknesses

- Requires embedding model (cost per token at build time)
- May miss keyword-exact matches that semantic search overlooks
- Top-k retrieval can miss relevant context if k is too small

### When to Use

- Default choice for most RAG applications
- When you need semantic similarity search
- When documents are diverse and queries are open-ended

### Code Example

```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader

documents = SimpleDirectoryReader("./data").load_data()
index = VectorStoreIndex.from_documents(documents)
query_engine = index.as_query_engine()
response = query_engine.query("What is the main topic?")
```

---

## 2. SummaryIndex (formerly ListIndex)

**Stores all nodes sequentially and synthesizes over all of them.**

### How It Works

- **Build**: Documents are chunked into nodes and stored in a flat list. No embeddings
  generated at build time (cheapest to build).
- **Data Structure**: An ordered list of nodes.
- **Query (default)**: ALL nodes are loaded and passed to the response synthesizer. The LLM
  reads through every node to synthesize an answer.
- **Query (embedding mode)**: Optionally, retrieve top-k nodes by embedding similarity first,
  then synthesize.

### Strengths

- No build-time cost (no embeddings needed in default mode)
- Guaranteed to consider all data (no information loss)
- Excellent for summarization tasks

### Weaknesses

- Expensive at query time (reads all nodes -> many LLM calls)
- Slow for large document sets
- Not suitable for large corpora

### When to Use

- Summarizing entire document collections
- When you need answers that synthesize across ALL documents
- Small document sets where completeness matters more than speed

### Code Example

```python
from llama_index.core import SummaryIndex, SimpleDirectoryReader

documents = SimpleDirectoryReader("./data").load_data()
index = SummaryIndex.from_documents(documents)
query_engine = index.as_query_engine()  # reads all nodes
# Or with embedding-based retrieval:
query_engine = index.as_query_engine(retriever_mode="embedding")
```

---

## 3. TreeIndex

**Builds a hierarchical tree of summaries for multi-level retrieval.**

### How It Works

- **Build**: Leaf nodes are the document chunks. Parent nodes are LLM-generated summaries of
  their children. The tree is built bottom-up until a root is reached.
  Can be built lazily (`build_tree=False`) to defer summarization to query time.
- **Data Structure**: A tree where leaves are original chunks and internal nodes are summaries.
- **Query**: Traverses from root to leaves. At each level, the LLM selects which child branches
  are most relevant. `child_branch_factor` controls how many children to explore (default=1).

### Strengths

- Efficient for summarization -- root node already contains a high-level summary
- Hierarchical traversal narrows down to relevant leaves
- Embeddings are lazily generated and cached (lower upfront cost than VectorStoreIndex)

### Weaknesses

- Build cost can be high (many LLM calls to generate summaries)
- Tree structure may not suit all data types
- Less intuitive than vector search

### When to Use

- Summarizing large document collections
- When you need hierarchical understanding of data
- When queries range from high-level ("what is this about?") to specific details

### Code Example

```python
from llama_index.core import TreeIndex, SimpleDirectoryReader

documents = SimpleDirectoryReader("./data").load_data()
index = TreeIndex.from_documents(documents)
query_engine = index.as_query_engine()  # traverses tree
```

---

## 4. KeywordTableIndex

**Maps keywords to nodes for keyword-based retrieval.**

### How It Works

- **Build (LLM variant)**: An LLM extracts keywords from each node. Expensive at build time.
- **Build (Simple variant)**: Uses regex-based keyword extraction. No LLM calls -- very cheap.
- **Data Structure**: A mapping (dictionary) from keywords -> set of node references.
- **Query**: Keywords are extracted from the user query, matched against the keyword table,
  and matching nodes are retrieved for synthesis.

### Strengths

- Excellent for keyword-specific routing
- Simple variant has zero LLM build cost
- Good for structured/categorical data where keywords are meaningful

### Weaknesses

- Misses semantic meaning (synonyms, paraphrases)
- Keyword extraction quality varies
- Not suitable for open-ended semantic queries

### When to Use

- When queries contain specific keywords or entities
- Routing queries to specific data sources
- Complementing vector search in hybrid approaches

### Code Example

```python
from llama_index.core import KeywordTableIndex, SimpleDirectoryReader

documents = SimpleDirectoryReader("./data").load_data()
# Simple (regex-based) variant:
index = KeywordTableIndex.from_documents(documents)
query_engine = index.as_query_engine()
```

---

## 5. KnowledgeGraphIndex

**Builds a knowledge graph of (subject, predicate, object) triplets.**

### How It Works

- **Build**: An LLM extracts entity-relationship triplets from each node.
  E.g., "Python was created by Guido van Rossum" -> (Python, created_by, Guido van Rossum)
- **Data Structure**: A graph of entities (nodes) connected by relationships (edges).
  Can use NetworkX (in-memory) or Neo4j/Nebula as backend.
- **Query**: The query is parsed for entities, then the graph is traversed to find related
  triplets. These triplets provide context for the LLM response.

### Strengths

- Captures relationships between entities explicitly
- Great for multi-hop reasoning ("Who founded the company that created X?")
- Naturally handles interconnected data

### Weaknesses

- Expensive to build (many LLM calls for triplet extraction)
- Triplet quality depends on LLM extraction accuracy
- Overkill for simple Q&A tasks

### When to Use

- Data with rich entity relationships
- Multi-hop reasoning queries
- When you need explainable retrieval paths

---

## 6. DocumentSummaryIndex

**Indexes document-level summaries for coarse-grained retrieval.**

### How It Works

- **Build**: An LLM generates a summary for each document. Both the summary and original
  nodes are stored.
- **Data Structure**: Mapping from document summaries to their constituent nodes.
- **Query**: The query is matched against document summaries (via embedding or LLM), then
  the full nodes from matching documents are used for synthesis.

### Strengths

- Better semantic coverage than individual chunk embeddings
- Reduces false negatives from chunking artifacts
- Good balance of precision and recall

### Weaknesses

- Build cost (one LLM call per document for summary)
- Summary quality depends on document structure

---

## Comparison Table

| Index Type | Build Cost | Query Cost | Best For |
|------------|-----------|------------|----------|
| VectorStoreIndex | Medium (embeddings) | Low (top-k) | General Q&A, semantic search |
| SummaryIndex | None | High (reads all) | Summarization, small corpora |
| TreeIndex | High (LLM summaries) | Medium (traversal) | Hierarchical summarization |
| KeywordTableIndex | Low-Medium | Low (keyword match) | Keyword routing, structured data |
| KnowledgeGraphIndex | High (triplet extraction) | Medium (graph traversal) | Relationship queries, multi-hop |
| DocumentSummaryIndex | Medium (summaries) | Medium | Document-level retrieval |
