# LlamaIndex Overview

## What is LlamaIndex?

LlamaIndex (formerly GPT Index) is a data framework for building LLM-powered applications over
custom data. It is the leading open-source toolkit for Retrieval-Augmented Generation (RAG),
providing tools to ingest, structure, index, and query data for use with large language models.

**GitHub:** [run-llama/llama_index](https://github.com/run-llama/llama_index)

## Core Architecture

LlamaIndex's architecture follows a pipeline model:

```
Documents --> Node Parsing --> Indexing --> Querying --> Response Synthesis
```

### 1. Data Connectors (Loaders)

- **SimpleDirectoryReader**: Built-in loader for local files (txt, pdf, docx, csv, etc.)
- **LlamaParse**: Managed API for advanced PDF parsing
- **LlamaHub**: Community-contributed loaders for databases, APIs, web pages, Notion, Slack, etc.
- Supports remote filesystems via fsspec (S3, Azure Blob, Google Drive, SFTP)

### 2. Documents and Nodes

- **Document**: The fundamental data unit -- contains text content plus metadata (filename, URL, etc.)
- **Node**: A chunk of a Document. Nodes maintain relationships (parent, child, next, previous)
- Metadata from documents propagates to nodes and is included in embeddings and LLM calls

### 3. Node Parsers / Text Splitters

Split documents into nodes using various strategies:

| Parser | Description |
|--------|-------------|
| SentenceSplitter | Splits on sentence boundaries (most common) |
| TokenTextSplitter | Splits by token count |
| HTMLNodeParser | Splits HTML by tags |
| JSONNodeParser | Splits JSON structures |
| MarkdownNodeParser | Splits by markdown headers |
| SimpleFileNodeParser | Auto-selects parser based on file type |

Configuration example:
```python
from llama_index.core.node_parser import SentenceSplitter
splitter = SentenceSplitter(chunk_size=1024, chunk_overlap=20)
```

### 4. Indices

The core of LlamaIndex -- data structures that organize nodes for efficient retrieval.
See `index-types.md` for detailed coverage.

### 5. Query Engines

Transform a natural language query into a retrieval + synthesis pipeline:
- **RetrieverQueryEngine**: Standard retrieve-then-synthesize
- **RouterQueryEngine**: Routes queries to appropriate sub-engines
- **SubQuestionQueryEngine**: Decomposes complex queries into sub-questions
- **CitationQueryEngine**: Includes source citations in responses

### 6. Response Synthesizers

Combine retrieved nodes into a final answer:
- **Refine**: Iteratively refine answer with each node
- **CompactAndRefine**: Compact nodes into fewer LLM calls, then refine
- **TreeSummarize**: Build a summary tree bottom-up
- **SimpleSummarize**: Single LLM call with all nodes

## Installation (Modern, 2025+)

```bash
# Core package
pip install llama-index-core

# LLM provider
pip install llama-index-llms-openai

# Embedding provider
pip install llama-index-embeddings-openai
# or for local/free embeddings:
pip install llama-index-embeddings-huggingface

# Convenience meta-package (installs common integrations)
pip install llama-index
```

## Global Settings

```python
from llama_index.core import Settings

Settings.llm = OpenAI(model="gpt-4o-mini")
Settings.embed_model = HuggingFaceEmbedding(model_name="BAAI/bge-small-en-v1.5")
Settings.chunk_size = 1024
Settings.chunk_overlap = 20
```

## Key Design Philosophy

1. **RAG-first**: Built specifically for retrieval-augmented generation
2. **Code-first**: Favors explicit Python code over YAML/config-driven pipelines
3. **Composable**: Indices can be composed, routed, and layered
4. **Provider-agnostic**: Pluggable LLMs, embeddings, and vector stores
