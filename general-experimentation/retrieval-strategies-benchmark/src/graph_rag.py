"""Lightweight GraphRAG baseline over the relational corpus."""

from collections import defaultdict
from dataclasses import dataclass
import math
import re

from src.retrieval import RetrievedChunk


TOKEN_PATTERN = re.compile(r"\b[a-z0-9_.-]+\b", flags=re.IGNORECASE)
CAMEL_PATTERN = re.compile(r"\b[A-Z][A-Za-z0-9]+(?:[A-Z][A-Za-z0-9]+)*\b")
REPO_PATTERN = re.compile(r"\brepo-[a-z0-9-]+\b")
POLICY_PATTERN = re.compile(r"\bPOL-\d+\b")
INCIDENT_PATTERN = re.compile(r"\bINC-[0-9-]+\b")
RUNBOOK_PATTERN = re.compile(r"\bRB-[A-Z]+-\d+\b")
EVENT_PATTERN = re.compile(r"\b[a-z]+\.[a-z_]+\b")
PERSON_PATTERN = re.compile(r"\b[A-Z][a-z]+ [A-Z][a-z]+\b")

STOP_TITLES = {
    "TechVista Operations Knowledge Base",
    "Services and Repositories",
    "Dependencies and Flows",
    "Policies and Controls",
    "Incident Reports",
    "Changes and Runbooks",
    "People and Teams",
}

STOP_ENTITIES = {
    "The",
    "Any",
    "When",
    "If",
    "During",
    "Change",
    "Policy",
    "Dependency",
    "Incident",
    "Reports",
    "Services",
    "Repositories",
    "Changes",
    "Runbooks",
}


@dataclass(frozen=True)
class GraphFact:
    """A sentence-sized evidence unit connected to entity nodes."""

    id: str
    source: str
    text: str
    kind: str
    entities: tuple[str, ...]


class RelationalGraph:
    """A bipartite entity-evidence graph for lightweight GraphRAG."""

    def __init__(self, facts: list[GraphFact], aliases: dict[str, str]):
        self.facts = facts
        self.aliases = aliases
        self.entities = sorted(set(aliases.values()))
        self.fact_index = {fact.id: fact for fact in facts}
        self.entity_to_fact_ids: dict[str, set[str]] = defaultdict(set)
        for fact in facts:
            for entity in fact.entities:
                self.entity_to_fact_ids[entity].add(fact.id)

    def match_entities(self, question: str, max_entities: int = 6) -> list[str]:
        """Match known entities directly from the question text."""
        question_lower = question.lower()
        matched = []
        for alias, canonical in sorted(
            self.aliases.items(),
            key=lambda item: (-len(item[0]), item[0]),
        ):
            if alias and alias in question_lower and canonical not in matched:
                matched.append(canonical)
            if len(matched) >= max_entities:
                break

        if matched:
            return matched

        query_tokens = set(_tokenize(question))
        scored = []
        for entity in self.entities:
            entity_tokens = set(_tokenize(entity))
            overlap = len(query_tokens & entity_tokens)
            if overlap:
                scored.append((overlap, entity))
        scored.sort(reverse=True)
        return [entity for _, entity in scored[:max_entities]]


def _tokenize(text: str) -> list[str]:
    return TOKEN_PATTERN.findall(text.lower())


def _split_sentences(block: str) -> list[str]:
    normalized = re.sub(r"\s+", " ", block.strip())
    if not normalized:
        return []
    return [
        sentence.strip()
        for sentence in re.split(r"(?<=[.!?])\s+", normalized)
        if sentence.strip()
    ]


def _clean_entity(entity: str) -> str | None:
    candidate = entity.strip(" .,:;()")
    if not candidate or candidate in STOP_TITLES or candidate in STOP_ENTITIES:
        return None
    if candidate.isupper() and len(candidate) <= 4 and "-" not in candidate:
        return None
    return candidate


def _collect_known_entities(documents: dict[str, str]) -> set[str]:
    entities = set()

    for text in documents.values():
        entities.update(REPO_PATTERN.findall(text))
        entities.update(POLICY_PATTERN.findall(text))
        entities.update(INCIDENT_PATTERN.findall(text))
        entities.update(RUNBOOK_PATTERN.findall(text))
        entities.update(EVENT_PATTERN.findall(text))
        entities.update(PERSON_PATTERN.findall(text))

        entities.update(
            re.findall(
                r"\b(?:the )?([A-Z][A-Za-z]+(?: [A-Z][A-Za-z]+)+ team)\b",
                text,
            )
        )

        for match in CAMEL_PATTERN.findall(text):
            cleaned = _clean_entity(match)
            if cleaned:
                entities.add(cleaned)

    normalized = set()
    for entity in entities:
        cleaned = _clean_entity(entity)
        if cleaned:
            normalized.add(cleaned)
    return normalized


def _find_entities(text: str, known_entities: set[str]) -> tuple[str, ...]:
    text_lower = text.lower()
    matched = []
    for entity in sorted(known_entities, key=lambda value: (-len(value), value)):
        alias = entity.lower()
        if alias in text_lower and entity not in matched:
            matched.append(entity)
    return tuple(matched)


def build_relational_graph(documents: dict[str, str]) -> RelationalGraph:
    """Build a bipartite entity-evidence graph from relational documents."""
    facts: list[GraphFact] = []
    aliases: dict[str, str] = {}
    known_entities = _collect_known_entities(documents)

    for source, text in documents.items():
        blocks = [block.strip() for block in text.split("\n\n") if block.strip()]
        for block_index, block in enumerate(blocks):
            if "Knowledge Base:" in block and len(block.splitlines()) == 1:
                continue
            block_entities = _find_entities(block, known_entities)
            if block_entities:
                block_fact = GraphFact(
                    id=f"{source}::block::{block_index}",
                    source=source,
                    text=re.sub(r"\s+", " ", block),
                    kind="block",
                    entities=block_entities,
                )
                facts.append(block_fact)
                for entity in block_entities:
                    aliases[entity.lower()] = entity
                    if entity.endswith(" team"):
                        aliases[entity[: -len(" team")].lower()] = entity

            for sentence_index, sentence in enumerate(_split_sentences(block)):
                sentence_entities = _find_entities(sentence, known_entities)
                if not sentence_entities:
                    continue

                fact = GraphFact(
                    id=f"{source}::fact::{block_index}::{sentence_index}",
                    source=source,
                    text=sentence,
                    kind="sentence",
                    entities=sentence_entities,
                )
                facts.append(fact)
                for entity in sentence_entities:
                    aliases[entity.lower()] = entity
                    if entity.endswith(" team"):
                        aliases[entity[: -len(" team")].lower()] = entity

    return RelationalGraph(facts=facts, aliases=aliases)


def query_graph(
    graph: RelationalGraph,
    question: str,
    top_k: int = 5,
    max_hops: int = 2,
) -> list[RetrievedChunk]:
    """Retrieve graph-connected evidence for a question."""
    query_tokens = set(_tokenize(question))
    seed_entities = graph.match_entities(question)

    if not seed_entities:
        return []

    candidate_scores: dict[str, float] = defaultdict(float)
    best_hops: dict[str, int] = {}
    frontier = set(seed_entities)
    visited_entities = set(seed_entities)

    for hop in range(max_hops + 1):
        next_frontier: set[str] = set()
        for entity in frontier:
            for fact_id in graph.entity_to_fact_ids.get(entity, set()):
                fact = graph.fact_index[fact_id]
                fact_tokens = set(_tokenize(fact.text))
                token_overlap = len(query_tokens & fact_tokens)
                seed_overlap = sum(1 for seed in seed_entities if seed in fact.entities)
                entity_overlap = sum(1 for item in fact.entities if item.lower() in question.lower())
                kind_bonus = 0.65 if fact.kind == "block" else 0.0
                size_bonus = min(len(fact.entities), 8) * 0.08
                policy_bonus = 0.6 if "policy" in question.lower() and any(entity.startswith("POL-") for entity in fact.entities) else 0.0
                path_bonus = 0.5 if any(word in question.lower() for word in ["path", "downstream", "after"]) and any(word in fact.text.lower() for word in ["path", "depends on", "consumes", "publishes"]) else 0.0
                score = (
                    (2.5 / (hop + 1))
                    + (0.35 * token_overlap)
                    + (0.8 * seed_overlap)
                    + (0.25 * entity_overlap)
                    + kind_bonus
                    + size_bonus
                    + policy_bonus
                    + path_bonus
                )
                if score > candidate_scores[fact_id]:
                    candidate_scores[fact_id] = score
                    best_hops[fact_id] = hop

                for related_entity in fact.entities:
                    if related_entity not in visited_entities:
                        visited_entities.add(related_entity)
                        next_frontier.add(related_entity)
        frontier = next_frontier
        if not frontier:
            break

    if not candidate_scores:
        return []

    values = list(candidate_scores.values())
    max_score = max(values)
    min_score = min(values)
    normalized = {}
    for fact_id, score in candidate_scores.items():
        if math.isclose(max_score, min_score):
            normalized[fact_id] = 1.0
        else:
            normalized[fact_id] = (score - min_score) / (max_score - min_score)

    ranked_fact_ids = sorted(
        candidate_scores,
        key=lambda fact_id: (candidate_scores[fact_id], -best_hops.get(fact_id, 0)),
        reverse=True,
    )[:top_k]

    return [
        RetrievedChunk(
            id=fact_id,
            text=graph.fact_index[fact_id].text,
            metadata={
                "source": graph.fact_index[fact_id].source,
                "kind": graph.fact_index[fact_id].kind,
                "entities": list(graph.fact_index[fact_id].entities),
                "hops": best_hops.get(fact_id, 0),
                "seed_entities": seed_entities,
            },
            score=normalized[fact_id],
            score_breakdown={
                "graph": candidate_scores[fact_id],
                "graph_norm": normalized[fact_id],
                "hops": float(best_hops.get(fact_id, 0)),
            },
        )
        for fact_id in ranked_fact_ids
    ]
