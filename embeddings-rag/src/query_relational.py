"""Query the relational corpus across dense, lexical, hybrid, or graph baselines."""

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
from src.corpus import build_chunk_catalog, load_relational_documents
from src.graph_rag import build_relational_graph, query_graph
from src.retrieval import (
    RetrievedChunk,
    build_dense_retrievers,
    build_lexical_retrievers,
    query_dense_retriever_strategy,
    query_hybrid_retriever_strategy,
    query_lexical_strategy,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("question", nargs="*", help="Question to ask")
    parser.add_argument(
        "--baseline",
        choices=[mode for mode in RELATIONAL_BASELINES if mode != "all"],
        default="graph",
        help="Retrieval baseline to use",
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
        help="Number of evidence items to show",
    )
    parser.add_argument(
        "--evidence-only",
        action="store_true",
        help="Show retrieved evidence only and skip shared answer generation",
    )
    return parser.parse_args()


def print_results(results: list, baseline: str) -> None:
    if baseline == "cag":
        if not results:
            print("  (no result)")
            return
        response = results[0]
        cited_files = ", ".join(response.metadata.get("cited_files", [])) or "none"
        print(
            f"  answer_score={response.score:.4f} | model={response.metadata.get('model')} | cited_files={cited_files}"
        )
        print(f"      {response.text}")
        print()
        return

    if not results:
        print("  (no results)")
        return

    for index, result in enumerate(results, start=1):
        source = result.metadata.get("source", "unknown")
        detail = f"score={result.score:.4f} | source={source}"
        if baseline == "graph":
            seeds = ", ".join(result.metadata.get("seed_entities", [])[:4])
            detail += (
                f" | kind={result.metadata.get('kind', 'unknown')}"
                f" | hops={int(result.metadata.get('hops', 0))}"
                f" | seeds={seeds}"
            )
        print(f"  [{index}] {detail}")
        print(f"      {result.text}")
        print()


def print_answer(response, model_name: str) -> None:
    cited_files = ", ".join(response.cited_files) or "none"
    print("  Answer")
    print("  --------------------------------------------------------------")
    print(
        f"  confidence={response.confidence:.4f} | model={model_name} | cited_files={cited_files}"
    )
    print(f"      {response.answer}")
    print()


def main() -> None:
    args = parse_args()

    if args.question:
        questions = [" ".join(args.question)]
    else:
        print("Interactive relational query mode. Type 'quit' to exit.\n")
        questions = []
        while True:
            question = input("Question: ").strip()
            if question.lower() in {"quit", "exit", "q"}:
                break
            if question:
                questions.append(question)

    documents = load_relational_documents()
    graph = build_relational_graph(documents)

    model = None
    dense_retrievers = None
    lexical_retrievers = None
    if args.baseline in {"dense", "lexical", "hybrid"}:
        print(f"Loading embedding model: {EMBEDDING_MODEL}...")
        model = SentenceTransformer(EMBEDDING_MODEL)
        catalog = build_chunk_catalog(documents, embedding_model=model)
        lexical_retrievers = build_lexical_retrievers(catalog)
        dense_retrievers = build_dense_retrievers(catalog, model)

    for question in questions:
        print(f"\n{'=' * 78}")
        print(f"  QUESTION: {question}")
        print(f"  Baseline: {args.baseline}")
        if args.baseline == "cag":
            print(f"  Model: {CAG_OLLAMA_MODEL}")
        elif args.baseline != "graph":
            print(f"  Chunking strategy: {args.strategy}")
        print(f"{'=' * 78}")

        if args.baseline == "dense":
            query_embedding = model.encode([question], show_progress_bar=False)[0].tolist()
            results = query_dense_retriever_strategy(
                dense_retrievers,
                args.strategy,
                question,
                top_k=args.top_k,
                question_embedding=query_embedding,
            )
        elif args.baseline == "lexical":
            results = query_lexical_strategy(
                lexical_retrievers,
                args.strategy,
                question,
                top_k=args.top_k,
            )
        elif args.baseline == "hybrid":
            query_embedding = model.encode([question], show_progress_bar=False)[0].tolist()
            results = query_hybrid_retriever_strategy(
                dense_retrievers,
                lexical_retrievers,
                args.strategy,
                question,
                top_k=args.top_k,
                question_embedding=query_embedding,
            )
        elif args.baseline == "cag":
            cag_response = answer_with_cag(question, documents)
            results = [
                RetrievedChunk(
                    id="cag_response",
                    text=cag_response.answer,
                    metadata={
                        "model": CAG_OLLAMA_MODEL,
                        "cited_files": cag_response.cited_files,
                        "raw_response": cag_response.raw_response,
                    },
                    score=cag_response.confidence,
                    score_breakdown={"cag": cag_response.confidence},
                )
            ]
        else:
            results = query_graph(graph, question, top_k=args.top_k)

        print_results(results, args.baseline)
        if not args.evidence_only:
            if args.baseline == "cag":
                print_answer(cag_response, CAG_OLLAMA_MODEL)
            else:
                answer = answer_with_evidence(question, results)
                print_answer(answer, CAG_OLLAMA_MODEL)


if __name__ == "__main__":
    main()
