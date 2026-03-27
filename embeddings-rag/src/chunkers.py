"""
Four chunking strategies for RAG document indexing.

Each chunker takes a text string and returns a list of Chunk objects.
"""

from dataclasses import dataclass, field
import re
import nltk
import numpy as np

# Download sentence tokenizer data (once)
try:
    nltk.data.find("tokenizers/punkt_tab")
except LookupError:
    nltk.download("punkt_tab", quiet=True)


@dataclass
class Chunk:
    """A piece of text with metadata about its origin."""

    text: str
    source: str = ""
    strategy: str = ""
    index: int = 0
    metadata: dict = field(default_factory=dict)

    def __repr__(self):
        preview = self.text[:60].replace("\n", " ")
        return f"Chunk({self.strategy}#{self.index}, {len(self.text)} chars, '{preview}...')"


# ---------------------------------------------------------------------------
# 1. Fixed-Size Chunking
# ---------------------------------------------------------------------------


def chunk_fixed(text: str, chunk_size: int = 500, overlap: int = 50) -> list[Chunk]:
    """Split text into fixed-size character chunks with overlap."""
    chunks = []
    start = 0
    idx = 0
    while start < len(text):
        end = start + chunk_size
        chunk_text = text[start:end].strip()
        if chunk_text:
            chunks.append(
                Chunk(text=chunk_text, strategy="fixed", index=idx)
            )
            idx += 1
        start = end - overlap
    return chunks


# ---------------------------------------------------------------------------
# 2. Recursive Chunking
# ---------------------------------------------------------------------------


def chunk_recursive(
    text: str, chunk_size: int = 500, overlap: int = 50
) -> list[Chunk]:
    """
    Split hierarchically: paragraphs -> sentences -> characters.
    Mimics LangChain's RecursiveCharacterTextSplitter approach.
    """
    separators = ["\n\n", "\n", ". ", " ", ""]

    def _split(text: str, sep_idx: int) -> list[str]:
        if sep_idx >= len(separators) or len(text) <= chunk_size:
            return [text] if text.strip() else []

        sep = separators[sep_idx]
        if sep:
            parts = text.split(sep)
        else:
            # Last resort: character-level split
            parts = [text[i : i + chunk_size] for i in range(0, len(text), chunk_size)]

        result = []
        current = ""
        for part in parts:
            candidate = current + sep + part if current else part
            if len(candidate) <= chunk_size:
                current = candidate
            else:
                if current:
                    result.append(current)
                # If this single part is too large, split it recursively
                if len(part) > chunk_size:
                    result.extend(_split(part, sep_idx + 1))
                else:
                    current = part
        if current:
            result.append(current)
        return result

    pieces = _split(text, 0)

    # Apply overlap by prepending the tail of the previous chunk
    chunks = []
    for idx, piece in enumerate(pieces):
        chunk_text = piece.strip()
        if not chunk_text:
            continue
        if idx > 0 and overlap > 0:
            prev_tail = pieces[idx - 1][-overlap:]
            chunk_text = prev_tail + " " + chunk_text
        chunks.append(Chunk(text=chunk_text, strategy="recursive", index=idx))
    return chunks


# ---------------------------------------------------------------------------
# 3. Sentence-Based Chunking
# ---------------------------------------------------------------------------


def chunk_sentences(
    text: str, chunk_size: int = 500, overlap_sentences: int = 1
) -> list[Chunk]:
    """Split on sentence boundaries, then group sentences until size limit."""
    sentences = nltk.sent_tokenize(text)
    chunks = []
    current_sentences = []
    current_length = 0
    idx = 0

    for sent in sentences:
        sent = sent.strip()
        if not sent:
            continue

        if current_length + len(sent) > chunk_size and current_sentences:
            chunk_text = " ".join(current_sentences)
            chunks.append(
                Chunk(text=chunk_text, strategy="sentence", index=idx)
            )
            idx += 1
            # Keep last N sentences as overlap
            current_sentences = current_sentences[-overlap_sentences:]
            current_length = sum(len(s) for s in current_sentences)

        current_sentences.append(sent)
        current_length += len(sent)

    # Don't forget the last chunk
    if current_sentences:
        chunk_text = " ".join(current_sentences)
        chunks.append(Chunk(text=chunk_text, strategy="sentence", index=idx))

    return chunks


# ---------------------------------------------------------------------------
# 4. Semantic Chunking
# ---------------------------------------------------------------------------


def chunk_semantic(
    text: str,
    embedding_model=None,
    similarity_threshold: float = 0.5,
    min_chunk_size: int = 100,
    max_chunk_size: int = 1000,
) -> list[Chunk]:
    """
    Split based on semantic similarity between adjacent sentences.
    Where similarity drops below the threshold, insert a break.

    Requires an embedding model (sentence-transformers) to compute
    sentence embeddings. This is the most expensive strategy.
    """
    if embedding_model is None:
        raise ValueError(
            "Semantic chunking requires an embedding model. "
            "Pass a SentenceTransformer instance."
        )

    sentences = nltk.sent_tokenize(text)
    if len(sentences) <= 1:
        return [Chunk(text=text.strip(), strategy="semantic", index=0)]

    # Embed all sentences
    embeddings = embedding_model.encode(sentences, show_progress_bar=False)

    # Compute cosine similarity between adjacent sentences
    similarities = []
    for i in range(len(embeddings) - 1):
        a = embeddings[i]
        b = embeddings[i + 1]
        sim = np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))
        similarities.append(float(sim))

    # Find break points where similarity drops below threshold
    chunks = []
    current_sentences = [sentences[0]]
    idx = 0

    for i, sim in enumerate(similarities):
        current_text = " ".join(current_sentences)
        next_sentence = sentences[i + 1]

        # Break if similarity is low AND we have enough text,
        # OR if we've exceeded max size
        should_break = (
            (sim < similarity_threshold and len(current_text) >= min_chunk_size)
            or len(current_text) + len(next_sentence) > max_chunk_size
        )

        if should_break:
            chunks.append(
                Chunk(text=current_text.strip(), strategy="semantic", index=idx)
            )
            idx += 1
            current_sentences = [next_sentence]
        else:
            current_sentences.append(next_sentence)

    # Last chunk
    if current_sentences:
        chunk_text = " ".join(current_sentences).strip()
        if chunk_text:
            chunks.append(Chunk(text=chunk_text, strategy="semantic", index=idx))

    return chunks


# ---------------------------------------------------------------------------
# Convenience: run all strategies
# ---------------------------------------------------------------------------

STRATEGIES = {
    "fixed": chunk_fixed,
    "recursive": chunk_recursive,
    "sentence": chunk_sentences,
}
# Semantic is separate because it needs an embedding model


def chunk_all(
    text: str, embedding_model=None, chunk_size: int = 500
) -> dict[str, list[Chunk]]:
    """Run all chunking strategies on the same text. Returns {strategy: [chunks]}."""
    results = {}
    for name, fn in STRATEGIES.items():
        results[name] = fn(text, chunk_size=chunk_size)

    if embedding_model is not None:
        results["semantic"] = chunk_semantic(
            text, embedding_model=embedding_model, max_chunk_size=chunk_size * 2
        )

    return results
