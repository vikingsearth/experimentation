"""Document and chunk catalog helpers for retrieval experiments."""

from dataclasses import dataclass
import json
import os

from src.chunkers import chunk_all
from src.config import (
    CHUNK_SIZE,
    DATA_DIR,
    RELATIONAL_DATA_DIR,
    RELATIONAL_QUESTIONS_FILE,
)


@dataclass(frozen=True)
class ChunkRecord:
    """A chunk plus stable metadata shared across retrieval baselines."""

    id: str
    text: str
    metadata: dict


@dataclass(frozen=True)
class RelationalQuestion:
    """A labeled question for the relational benchmark."""

    id: str
    question: str
    expected_answer: str
    expected_terms: list[str]
    entities: list[str]
    supporting_files: list[str]


def load_documents(data_dir: str = DATA_DIR) -> dict[str, str]:
    """Load all .txt files from the data directory."""
    documents = {}
    for filename in sorted(os.listdir(data_dir)):
        if filename.endswith(".txt"):
            filepath = os.path.join(data_dir, filename)
            with open(filepath, "r", encoding="utf-8") as handle:
                documents[filename] = handle.read()
    return documents


def load_relational_documents(
    data_dir: str = RELATIONAL_DATA_DIR,
) -> dict[str, str]:
    """Load the relational corpus documents, excluding the dataset README."""
    documents = {}
    for filename in sorted(os.listdir(data_dir)):
        if filename.endswith(".txt"):
            filepath = os.path.join(data_dir, filename)
            with open(filepath, "r", encoding="utf-8") as handle:
                documents[filename] = handle.read()
    return documents


def load_relational_questions(
    question_file: str = RELATIONAL_QUESTIONS_FILE,
) -> list[RelationalQuestion]:
    """Load labeled questions for the relational benchmark."""
    with open(question_file, "r", encoding="utf-8") as handle:
        payload = json.load(handle)

    return [
        RelationalQuestion(
            id=item["id"],
            question=item["question"],
            expected_answer=item["expected_answer"],
            expected_terms=item["expected_terms"],
            entities=item["entities"],
            supporting_files=item["supporting_files"],
        )
        for item in payload
    ]


def build_chunk_catalog(
    documents: dict[str, str],
    embedding_model,
    chunk_size: int = CHUNK_SIZE,
) -> dict[str, list[ChunkRecord]]:
    """Build stable chunk records for every strategy across every document."""
    catalog: dict[str, list[ChunkRecord]] = {}

    for source, text in documents.items():
        strategy_chunks = chunk_all(
            text,
            embedding_model=embedding_model,
            chunk_size=chunk_size,
        )
        for strategy, chunks in strategy_chunks.items():
            records = catalog.setdefault(strategy, [])
            for chunk in chunks:
                records.append(
                    ChunkRecord(
                        id=f"{source}_{chunk.strategy}_{chunk.index}",
                        text=chunk.text,
                        metadata={
                            "source": source,
                            "strategy": chunk.strategy,
                            "chunk_index": chunk.index,
                            "char_length": len(chunk.text),
                        },
                    )
                )

    return catalog
