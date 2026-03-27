# Relational Dataset: TechVista Operations

This directory contains a small synthetic company operations knowledge base designed for relational retrieval and GraphRAG-style experiments.

Why it exists:
- The top-level tutorial corpus is strong for definitions and explanatory questions.
- It is weak for multi-hop, ownership, dependency, and policy reasoning.
- Graph-based retrieval needs a dataset where relationships are first-class, not incidental.

What is included:
- Team and people ownership notes.
- Service and repository mappings.
- Dependency and event-flow descriptions.
- Policies and controls.
- Incident reports.
- Release and runbook notes.
- A labeled question set in `questions.json`.

Why it is separate:
- The current scripts load only the top-level `.txt` files in `data/`.
- Keeping this corpus under `data/relational/` avoids changing the current dense retrieval benchmark by accident.

Recommended use:
- Multi-hop retrieval evaluation.
- Graph extraction experiments.
- Ownership and dependency tracing.
- Policy and incident root-cause questions.