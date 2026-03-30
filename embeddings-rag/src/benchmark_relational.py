"""Benchmark the relational corpus with separate retrieval and answer scores."""

import argparse
import os
import sys

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, PROJECT_ROOT)

import src._ssl_workaround  # noqa: F401, E402

from sentence_transformers import SentenceTransformer

from src.cag import answer_with_cag, answer_with_evidence
from src.config import (
    CAG_OLLAMA_MODEL,
    EMBEDDING_MODEL,
    RELATIONAL_BASELINES,
    RELATIONAL_DEFAULT_STRATEGY,
    TOP_K,
)
from src.corpus import (
    build_chunk_catalog,
    load_relational_documents,
    load_relational_questions,
)
from src.graph_rag import build_relational_graph, query_graph
from src.retrieval import (
    build_dense_retrievers,
    build_lexical_retrievers,
    query_dense_retriever_strategy,
    query_hybrid_retriever_strategy,
    query_lexical_strategy,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--baseline",
        choices=RELATIONAL_BASELINES,
        default="all",
        help="Which relational baseline to benchmark",
    )
    parser.add_argument(
        "--strategy",
        default=RELATIONAL_DEFAULT_STRATEGY,
        help="Chunking strategy for dense, lexical, and hybrid baselines",
    )
    parser.add_argument(
        "--top-k",
        type=int,
        default=TOP_K,
        help="Number of evidence items to score",
    )
    return parser.parse_args()


def score_retrieval_results(results: list, question) -> dict[str, float]:
    all_text = " ".join(result.text for result in results).lower()
    matched_terms = sum(1 for term in question.expected_terms if term.lower() in all_text)
    term_coverage = matched_terms / len(question.expected_terms) if question.expected_terms else 0.0

    matched_entities = sum(1 for entity in question.entities if entity.lower() in all_text)
    entity_coverage = matched_entities / len(question.entities) if question.entities else 0.0

    result_sources = {result.metadata.get("source") for result in results}
    file_coverage = (
        len([source for source in question.supporting_files if source in result_sources])
        / len(question.supporting_files)
        if question.supporting_files
        else 0.0
    )

    avg_score = sum(result.score for result in results) / len(results) if results else 0.0
    combined = (0.45 * term_coverage) + (0.35 * entity_coverage) + (0.20 * file_coverage)

    return {
        "avg_score": avg_score,
        "term_coverage": term_coverage,
        "entity_coverage": entity_coverage,
        "file_coverage": file_coverage,
        "combined": combined,
    }


def score_answer_response(response, question) -> dict[str, float]:
    answer_text = response.answer.lower()
    matched_terms = sum(1 for term in question.expected_terms if term.lower() in answer_text)
    term_coverage = matched_terms / len(question.expected_terms) if question.expected_terms else 0.0

    matched_entities = sum(1 for entity in question.entities if entity.lower() in answer_text)
    entity_coverage = matched_entities / len(question.entities) if question.entities else 0.0

    cited_files = set(response.cited_files)
    file_coverage = (
        len([source for source in question.supporting_files if source in cited_files])
        / len(question.supporting_files)
        if question.supporting_files
        else 0.0
    )

    combined = (0.45 * term_coverage) + (0.35 * entity_coverage) + (0.20 * file_coverage)

    return {
        "avg_score": response.confidence,
        "term_coverage": term_coverage,
        "entity_coverage": entity_coverage,
        "file_coverage": file_coverage,
        "combined": combined,
    }


def empty_score_bucket() -> dict[str, list[float]]:
    return {
        "avg_score": [],
        "term_coverage": [],
        "entity_coverage": [],
        "file_coverage": [],
        "combined": [],
    }


def summarize_scores(score_bucket: dict[str, list[float]]) -> dict[str, float]:
    return {
        key: (sum(values) / len(values) if values else 0.0)
        for key, values in score_bucket.items()
    }


def append_metrics(score_bucket: dict[str, list[float]], metrics: dict[str, float]) -> None:
    for key, value in metrics.items():
        score_bucket[key].append(value)


def print_metric_table(title: str, rows: list[tuple[str, dict[str, float]]], summary: dict[str, float]) -> None:
    print(title)
    print(f"  {'Question':<12s} {'Score':>8s} {'Terms':>10s} {'Entities':>10s} {'Files':>8s} {'Combined':>10s}")
    print(f"  {'-' * 74}")
    for question_id, metrics in rows:
        print(
            f"  {question_id:<12s} {metrics['avg_score']:>8.4f} {metrics['term_coverage']:>10.1%} "
            f"{metrics['entity_coverage']:>10.1%} {metrics['file_coverage']:>8.1%} {metrics['combined']:>10.4f}"
        )
    print(f"  {'-' * 74}")
    print(
        f"  {'average':<12s} {summary['avg_score']:>8.4f} {summary['term_coverage']:>10.1%} "
        f"{summary['entity_coverage']:>10.1%} {summary['file_coverage']:>8.1%} {summary['combined']:>10.4f}"
    )


def run_baseline(
    baseline: str,
    questions,
    strategy: str,
    top_k: int,
    documents,
    graph,
    model,
    dense_retrievers,
    lexical_retrievers,
) -> dict:
    retrieval_scores = empty_score_bucket()
    answer_scores = empty_score_bucket()
    retrieval_rows: list[tuple[str, dict[str, float]]] = []
    answer_rows: list[tuple[str, dict[str, float]]] = []

    print(f"\n{'=' * 88}")
    print(f"  Baseline: {baseline.upper()}")
    if baseline == "cag":
        print(f"  Model: {CAG_OLLAMA_MODEL}")
    elif baseline != "graph":
        print(f"  Chunking strategy: {strategy}")
    print(f"{'=' * 88}")
    for question in questions:
        query_embedding = None
        if baseline in {"dense", "hybrid"}:
            query_embedding = model.encode([question.question], show_progress_bar=False)[0].tolist()

        if baseline == "dense":
            results = query_dense_retriever_strategy(
                dense_retrievers,
                strategy,
                question.question,
                top_k=top_k,
                question_embedding=query_embedding,
            )
            retrieval_metrics = score_retrieval_results(results, question)
            answer_response = answer_with_evidence(question.question, results)
        elif baseline == "lexical":
            results = query_lexical_strategy(
                lexical_retrievers,
                strategy,
                question.question,
                top_k=top_k,
            )
            retrieval_metrics = score_retrieval_results(results, question)
            answer_response = answer_with_evidence(question.question, results)
        elif baseline == "hybrid":
            results = query_hybrid_retriever_strategy(
                dense_retrievers,
                lexical_retrievers,
                strategy,
                question.question,
                top_k=top_k,
                question_embedding=query_embedding,
            )
            retrieval_metrics = score_retrieval_results(results, question)
            answer_response = answer_with_evidence(question.question, results)
        elif baseline == "cag":
            retrieval_metrics = None
            answer_response = answer_with_cag(question.question, documents)
        else:
            results = query_graph(graph, question.question, top_k=top_k)
            retrieval_metrics = score_retrieval_results(results, question)
            answer_response = answer_with_evidence(question.question, results)

        if retrieval_metrics is not None:
            append_metrics(retrieval_scores, retrieval_metrics)
            retrieval_rows.append((question.id, retrieval_metrics))

        answer_metrics = score_answer_response(answer_response, question)
        append_metrics(answer_scores, answer_metrics)
        answer_rows.append((question.id, answer_metrics))

    if baseline != "cag":
        retrieval_summary = summarize_scores(retrieval_scores)
        print_metric_table("  Retrieval Scores", retrieval_rows, retrieval_summary)
    else:
        retrieval_summary = None
        print("  Retrieval Scores")
        print("  --------------------------------------------------------------------------")
        print("  CAG has no retrieval stage, so retrieval metrics are not applicable.")

    answer_summary = summarize_scores(answer_scores)
    print()
    print_metric_table("  Answer Scores", answer_rows, answer_summary)

    return {
        "retrieval": retrieval_summary,
        "answer": answer_summary,
    }


def main() -> None:
    args = parse_args()

    documents = load_relational_documents()
    questions = load_relational_questions()
    graph = build_relational_graph(documents)

    model = None
    dense_retrievers = None
    lexical_retrievers = None

    baselines = [args.baseline] if args.baseline != "all" else ["dense", "lexical", "hybrid", "graph", "cag"]
    if any(baseline in {"dense", "lexical", "hybrid"} for baseline in baselines):
        print(f"Loading embedding model: {EMBEDDING_MODEL}...")
        model = SentenceTransformer(EMBEDDING_MODEL)
        catalog = build_chunk_catalog(documents, embedding_model=model)
        lexical_retrievers = build_lexical_retrievers(catalog)
        dense_retrievers = build_dense_retrievers(catalog, model)

    summaries = {}
    for baseline in baselines:
        summaries[baseline] = run_baseline(
            baseline,
            questions,
            args.strategy,
            args.top_k,
            documents,
            graph,
            model,
            dense_retrievers,
            lexical_retrievers,
        )

    if len(summaries) > 1:
        print(f"\n{'=' * 88}")
        print("  Overall Retrieval Summary")
        print(f"{'=' * 88}")
        print(
            f"  {'Baseline':<12s} {'Terms':>10s} {'Entities':>10s} {'Files':>8s} {'Combined':>10s}"
        )
        print(f"  {'-' * 58}")
        for baseline, metrics in summaries.items():
            retrieval_metrics = metrics["retrieval"]
            if retrieval_metrics is None:
                continue
            print(
                f"  {baseline:<12s} {retrieval_metrics['term_coverage']:>10.1%} {retrieval_metrics['entity_coverage']:>10.1%} "
                f"{retrieval_metrics['file_coverage']:>8.1%} {retrieval_metrics['combined']:>10.4f}"
            )

        print(f"\n{'=' * 88}")
        print("  Overall Answer Summary")
        print(f"{'=' * 88}")
        print(
            f"  {'Baseline':<12s} {'Terms':>10s} {'Entities':>10s} {'Files':>8s} {'Combined':>10s}"
        )
        print(f"  {'-' * 58}")
        for baseline, metrics in summaries.items():
            answer_metrics = metrics["answer"]
            print(
                f"  {baseline:<12s} {answer_metrics['term_coverage']:>10.1%} {answer_metrics['entity_coverage']:>10.1%} "
                f"{answer_metrics['file_coverage']:>8.1%} {answer_metrics['combined']:>10.4f}"
            )


if __name__ == "__main__":
    main()