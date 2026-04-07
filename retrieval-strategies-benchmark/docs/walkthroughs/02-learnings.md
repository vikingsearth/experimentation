# What You Can Learn From This Experiment

Each takeaway below is grounded in the benchmark results and code. Where
possible, the numbers come from the most recent relational benchmark run.

---

## 1. Chunking Strategy Matters More Than You Think

Fixed-size chunking is the simplest approach, but it regularly cuts mid-sentence
and mid-paragraph. Recursive chunking (`src/chunkers.py:61-111`) preserves
document structure by splitting hierarchically -- paragraphs first, then
sentences, then characters as a last resort -- and consistently outperforms
fixed-size on the tutorial corpus.

The lesson isn't "always use recursive." It's that how you split your documents
determines what the retriever can find. If a fact spans two chunks, no amount
of retrieval sophistication will recover it from a single chunk.

## 2. Keyword Signals Complement Embeddings

Dense retrieval encodes meaning into vectors, but it can miss exact matches on
rare identifiers like `repo-customer-api` or `POL-002`. The BM25 lexical
retriever (`src/retrieval.py:161-228`) catches these because it operates on
exact token matches with IDF weighting.

Hybrid retrieval (`src/retrieval.py:241-281`) fuses both signals with
independent score normalization. On the relational benchmark, hybrid retrieval
achieved the highest retrieval score (`0.9244`) compared to lexical (`0.8858`),
dense (`0.8788`), and graph (`0.8013`).

The normalization step is important: without it, one signal can dominate the
other simply because its raw scores are larger.

## 3. Better Retrieval Does Not Mean Proportionally Better Answers

This is the most counter-intuitive result. Retrieval-side scores spread widely:

| Baseline | Retrieval Score |
| -------- | --------------- |
| Hybrid   | 0.9244          |
| Lexical  | 0.8858          |
| Dense    | 0.8788          |
| Graph    | 0.8013          |

But answer-side scores compress into a narrow band:

| Baseline | Answer Score |
| -------- | ------------ |
| Hybrid   | 0.5893       |
| CAG      | 0.5889       |
| Lexical  | 0.5876       |
| Dense    | 0.5747       |
| Graph    | 0.5492       |

The gap between the best and worst retriever is ~12 points on the retrieval
side but only ~4 points on the answer side. This means the generation model is
the bottleneck once evidence quality passes a threshold. Improving retrieval
has diminishing returns if the answer generator can't fully exploit the
evidence.

## 4. CAG Is Competitive on Small, Stable Corpora

The CAG baseline (`src/cag.py:284-300`) skips retrieval entirely and preloads
the full corpus into the prompt. On the relational benchmark it scored `0.5889`
-- essentially tied with hybrid at `0.5893`.

This makes sense: the relational corpus is ~42K characters across 6 documents,
which fits comfortably in a single model context. When the corpus is small
enough to fit, retrieval adds latency and information loss (selecting top-K
chunks means throwing away context) without improving the answer.

The tradeoff: CAG doesn't scale. As the corpus grows, it will exceed the
context window, and even within limits, longer contexts degrade model attention.
But for small, stable knowledge bases -- internal docs, policy sets, team
wikis -- CAG is a serious option.

## 5. GraphRAG Only Pays Off When Data Is Relational

The graph baseline (`src/graph_rag.py:211-302`) scored lowest on retrieval
(`0.8013`) and answer quality (`0.5492`). This doesn't mean GraphRAG is bad --
it means the overhead of graph construction and traversal only pays off when
questions genuinely require multi-hop reasoning across relationships.

On simple fact-lookup questions ("What service does team X own?"), dense or
hybrid retrieval finds the answer directly. The graph's advantage appears on
questions like "What is the downstream impact path from service A?" where
entity-to-entity traversal surfaces evidence that a similarity search would
rank lower.

The lesson: match the retrieval method to the question type. GraphRAG is a
tool for relationship-heavy queries, not a universal upgrade.

## 6. The Generation Template Can Be the Real Bottleneck

Before prompt tightening, answer scores were substantially lower:

| Baseline | Before | After  | Lift   |
| -------- | ------ | ------ | ------ |
| Dense    | 0.5165 | 0.5747 | +0.058 |
| Lexical  | 0.3661 | 0.5876 | +0.222 |
| Hybrid   | 0.4366 | 0.5893 | +0.153 |
| Graph    | 0.4025 | 0.5492 | +0.147 |
| CAG      | 0.4623 | 0.5889 | +0.127 |

The structured JSON schema (`src/cag.py:160-199`) asks the model to decompose
questions into parts, extract supported facts, and report missing parts before
writing the final answer. This single change lifted every baseline without
touching the retrieval layer.

The biggest lift was lexical (+0.222), suggesting the model was previously
collapsing multi-part questions into partial answers -- the structured
decomposition forced it to address each part explicitly.

## 7. Local-First Constraints Force Clarity

The entire experiment runs locally without cloud services or API keys (except
a local Ollama instance for answer generation). This constraint has a
secondary benefit: it forces the experiment to isolate the variables that
actually matter.

When you can't throw a bigger model or a managed vector database at the
problem, you have to understand _why_ one approach outperforms another. That
understanding transfers to production systems in a way that benchmark numbers
from a managed service do not.

---

## Summary

If you take one thing from this experiment: the pipeline is a chain, and the
weakest link determines the output quality. Improving chunking, retrieval,
or generation in isolation yields diminishing returns once the other stages
become the bottleneck. The most effective optimization is identifying which
stage is currently limiting and focusing there.
