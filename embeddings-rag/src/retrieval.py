"""Dense, lexical, and hybrid retrieval helpers."""

from collections import Counter, defaultdict
from dataclasses import dataclass, field
import math
import re

import chromadb
import numpy as np
from sentence_transformers import SentenceTransformer

from src.config import TOP_K
from src.corpus import ChunkRecord


TOKEN_PATTERN = re.compile(r"\b\w+\b")


@dataclass
class RetrievedChunk:
    """A normalized retrieval result used by all baselines."""

    id: str
    text: str
    metadata: dict
    score: float
    score_breakdown: dict[str, float] = field(default_factory=dict)


class DenseRetriever:
    """An in-memory dense retriever over chunk records."""

    def __init__(
        self,
        records: list[ChunkRecord],
        model: SentenceTransformer,
    ):
        self.records = records
        self.model = model
        self.embeddings = np.array([])
        if records:
            self.embeddings = np.asarray(
                self.model.encode(
                    [record.text for record in records],
                    show_progress_bar=False,
                ),
                dtype=float,
            )

    def search(
        self,
        question: str,
        top_k: int = TOP_K,
        question_embedding: list[float] | None = None,
    ) -> list[RetrievedChunk]:
        """Return cosine-similarity ranked chunks for a query."""
        if not self.records:
            return []

        if question_embedding is None:
            query_vector = np.asarray(
                self.model.encode([question], show_progress_bar=False)[0],
                dtype=float,
            )
        else:
            query_vector = np.asarray(question_embedding, dtype=float)

        doc_norms = np.linalg.norm(self.embeddings, axis=1)
        query_norm = np.linalg.norm(query_vector)
        similarities = np.zeros(len(self.records), dtype=float)
        nonzero = (doc_norms > 0) & (query_norm > 0)
        similarities[nonzero] = (
            np.dot(self.embeddings[nonzero], query_vector)
            / (doc_norms[nonzero] * query_norm)
        )

        top_indices = np.argsort(similarities)[::-1][:top_k]
        return [
            RetrievedChunk(
                id=self.records[index].id,
                text=self.records[index].text,
                metadata=self.records[index].metadata,
                score=float(similarities[index]),
                score_breakdown={"dense": float(similarities[index])},
            )
            for index in top_indices
        ]


def _tokenize(text: str) -> list[str]:
    return TOKEN_PATTERN.findall(text.lower())


def _normalize_scores(score_map: dict[str, float]) -> dict[str, float]:
    if not score_map:
        return {}

    values = list(score_map.values())
    minimum = min(values)
    maximum = max(values)

    if maximum <= 0:
        return {key: 0.0 for key in score_map}
    if math.isclose(maximum, minimum):
        return {key: 1.0 if value > 0 else 0.0 for key, value in score_map.items()}

    return {
        key: (value - minimum) / (maximum - minimum)
        for key, value in score_map.items()
    }


def query_dense_strategy(
    client: chromadb.ClientAPI,
    strategy: str,
    question_embedding: list[float],
    top_k: int = TOP_K,
) -> list[RetrievedChunk]:
    """Query one Chroma collection and return normalized results."""
    collection_name = f"strategy_{strategy}"
    try:
        collection = client.get_collection(name=collection_name)
    except Exception:
        return []

    results = collection.query(
        query_embeddings=[question_embedding],
        n_results=top_k,
    )

    if not results["ids"][0]:
        return []

    formatted = []
    for idx in range(len(results["ids"][0])):
        distance = float(results["distances"][0][idx])
        similarity = 1 - distance
        formatted.append(
            RetrievedChunk(
                id=results["ids"][0][idx],
                text=results["documents"][0][idx],
                metadata=results["metadatas"][0][idx],
                score=similarity,
                score_breakdown={"dense": similarity},
            )
        )
    return formatted


def build_dense_retrievers(
    catalog: dict[str, list[ChunkRecord]],
    model: SentenceTransformer,
) -> dict[str, DenseRetriever]:
    """Build one in-memory dense retriever per chunking strategy."""
    return {
        strategy: DenseRetriever(records, model)
        for strategy, records in catalog.items()
    }


class LexicalRetriever:
    """A small BM25 retriever over pre-built chunk records."""

    def __init__(self, records: list[ChunkRecord], k1: float = 1.5, b: float = 0.75):
        self.records = records
        self.k1 = k1
        self.b = b
        self.doc_lengths: list[int] = []
        self.avg_doc_length = 0.0
        self.postings: dict[str, list[tuple[int, int]]] = defaultdict(list)
        self.idf: dict[str, float] = {}
        self._build_index()

    def _build_index(self) -> None:
        if not self.records:
            return

        document_frequencies: Counter[str] = Counter()

        for doc_idx, record in enumerate(self.records):
            tokens = _tokenize(record.text)
            self.doc_lengths.append(len(tokens))
            term_counts = Counter(tokens)
            for term, count in term_counts.items():
                self.postings[term].append((doc_idx, count))
            document_frequencies.update(term_counts.keys())

        self.avg_doc_length = sum(self.doc_lengths) / len(self.doc_lengths)
        doc_count = len(self.records)
        self.idf = {
            term: math.log(1 + ((doc_count - freq + 0.5) / (freq + 0.5)))
            for term, freq in document_frequencies.items()
        }

    def search(self, query: str, top_k: int = TOP_K) -> list[RetrievedChunk]:
        """Return BM25-ranked chunks for a query."""
        if not self.records:
            return []

        terms = _tokenize(query)
        if not terms:
            return []

        scores: dict[int, float] = defaultdict(float)
        for term in terms:
            idf = self.idf.get(term)
            if idf is None:
                continue
            for doc_idx, term_frequency in self.postings[term]:
                doc_length = self.doc_lengths[doc_idx]
                denominator = term_frequency + self.k1 * (
                    1 - self.b + self.b * (doc_length / self.avg_doc_length)
                )
                scores[doc_idx] += idf * (
                    (term_frequency * (self.k1 + 1)) / denominator
                )

        ranked = sorted(scores.items(), key=lambda item: item[1], reverse=True)[:top_k]
        return [
            RetrievedChunk(
                id=self.records[doc_idx].id,
                text=self.records[doc_idx].text,
                metadata=self.records[doc_idx].metadata,
                score=score,
                score_breakdown={"lexical": score},
            )
            for doc_idx, score in ranked
        ]


def build_lexical_retrievers(
    catalog: dict[str, list[ChunkRecord]],
) -> dict[str, LexicalRetriever]:
    """Build one lexical retriever per chunking strategy."""
    return {
        strategy: LexicalRetriever(records)
        for strategy, records in catalog.items()
    }


def combine_results(
    dense_results: list[RetrievedChunk],
    lexical_results: list[RetrievedChunk],
    top_k: int = TOP_K,
    dense_weight: float = 0.65,
) -> list[RetrievedChunk]:
    """Fuse dense and lexical results across a shared candidate set."""
    dense_scores = {result.id: result.score for result in dense_results}
    lexical_scores = {result.id: result.score for result in lexical_results}
    dense_normalized = _normalize_scores(dense_scores)
    lexical_normalized = _normalize_scores(lexical_scores)

    merged_results = {result.id: result for result in dense_results}
    for result in lexical_results:
        merged_results.setdefault(result.id, result)

    combined = []
    for result_id, result in merged_results.items():
        dense_score = dense_normalized.get(result_id, 0.0)
        lexical_score = lexical_normalized.get(result_id, 0.0)
        combined_score = (dense_weight * dense_score) + (
            (1 - dense_weight) * lexical_score
        )
        combined.append(
            RetrievedChunk(
                id=result.id,
                text=result.text,
                metadata=result.metadata,
                score=combined_score,
                score_breakdown={
                    "dense": dense_scores.get(result_id, 0.0),
                    "dense_norm": dense_score,
                    "lexical": lexical_scores.get(result_id, 0.0),
                    "lexical_norm": lexical_score,
                    "combined": combined_score,
                },
            )
        )

    combined.sort(key=lambda item: item.score, reverse=True)
    return combined[:top_k]


def query_lexical_strategy(
    retrievers: dict[str, LexicalRetriever],
    strategy: str,
    question: str,
    top_k: int = TOP_K,
) -> list[RetrievedChunk]:
    """Query a strategy-specific lexical retriever."""
    retriever = retrievers.get(strategy)
    if retriever is None:
        return []
    return retriever.search(question, top_k=top_k)


def query_dense_retriever_strategy(
    retrievers: dict[str, DenseRetriever],
    strategy: str,
    question: str,
    top_k: int = TOP_K,
    question_embedding: list[float] | None = None,
) -> list[RetrievedChunk]:
    """Query a strategy-specific in-memory dense retriever."""
    retriever = retrievers.get(strategy)
    if retriever is None:
        return []
    return retriever.search(
        question,
        top_k=top_k,
        question_embedding=question_embedding,
    )


def query_hybrid_retriever_strategy(
    dense_retrievers: dict[str, DenseRetriever],
    lexical_retrievers: dict[str, LexicalRetriever],
    strategy: str,
    question: str,
    top_k: int = TOP_K,
    dense_weight: float = 0.65,
    question_embedding: list[float] | None = None,
) -> list[RetrievedChunk]:
    """Fuse in-memory dense and lexical retrieval for a strategy."""
    candidate_k = max(top_k * 2, top_k)
    dense_results = query_dense_retriever_strategy(
        dense_retrievers,
        strategy,
        question,
        top_k=candidate_k,
        question_embedding=question_embedding,
    )
    lexical_results = query_lexical_strategy(
        lexical_retrievers,
        strategy,
        question,
        top_k=candidate_k,
    )
    return combine_results(
        dense_results,
        lexical_results,
        top_k=top_k,
        dense_weight=dense_weight,
    )


def query_hybrid_strategy(
    client: chromadb.ClientAPI,
    retrievers: dict[str, LexicalRetriever],
    strategy: str,
    question: str,
    question_embedding: list[float],
    top_k: int = TOP_K,
    dense_weight: float = 0.65,
) -> list[RetrievedChunk]:
    """Fuse dense and lexical scores across a shared candidate set."""
    candidate_k = max(top_k * 2, top_k)
    dense_results = query_dense_strategy(
        client,
        strategy,
        question_embedding,
        top_k=candidate_k,
    )
    lexical_results = query_lexical_strategy(
        retrievers,
        strategy,
        question,
        top_k=candidate_k,
    )
    return combine_results(
        dense_results,
        lexical_results,
        top_k=top_k,
        dense_weight=dense_weight,
    )

