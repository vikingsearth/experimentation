# ADR Examples

Reference examples from this repository showing simple and complex ADR structures.

## Simple ADRs (single file, no supplementary)

### ADR-0005: Core User Flow Representation

- **File**: `docs/adrs/adr-0005-core-flow-representation.md`
- **Status**: Proposed
- **Complexity**: Simple — single decision (Playwright + POM for E2E tests), 3 options, no supplementary material
- **Good example of**: Clear context, well-structured pros/cons, concise decision rationale

### ADR-0006: Adopt Canonical Cross-SDK Message Contract

- **File**: `docs/adrs/adr-0006-agent-message-sdk.md`
- **Status**: Accepted
- **Complexity**: Simple — single decision (shared message contract), focused scope
- **Good example of**: Strong problem statement with concrete examples, explaining *why* the current approach fails

## Complex ADRs (with supplementary material)

### ADR-0003: AI Tooling Configuration Strategy

- **File**: `docs/adrs/adr-0003-ai-tooling-configuration-strategy.md`
- **Supplementary**: `docs/adrs/adr-0003-supplementary/`
  - `ai-directory-migration.md` — migration plan for `.ai/` directory structure
  - `cross-tool-mapping.md` — detailed mapping between Claude and Copilot constructs
- **Status**: Proposed
- **Complexity**: Complex — cross-cutting decision affecting multiple tools and directory structures, requires a mental model table and detailed construct mappings
- **Good example of**: Using supplementary directory for detailed technical mappings that would bloat the main ADR

### ADR-0007: Adopt LiteLLM Proxy as Unified AI Gateway

- **File**: `docs/adrs/adr-0007-litellm-proxy-ai-gateway.md`
- **Supplementary**: `docs/adrs/adr-0007-supplementary/`
  - `technical-design.md` — detailed technical design for the LiteLLM proxy integration
- **Status**: Accepted — Phase 1
- **Complexity**: Complex — involves infrastructure, multiple AI models, wire protocol considerations, and phased rollout
- **Good example of**: Phased status ("Accepted — Phase 1"), technical constraints driving decisions (Claude Agent SDK wire format), supplementary technical design

## When to Use Supplementary Material

Use a `docs/adrs/adr-NNNN-supplementary/` directory when the ADR involves:

- **Detailed technical mappings** (like ADR-0003's cross-tool mapping table)
- **Technical design documents** (like ADR-0007's implementation design)
- **Migration plans** with step-by-step instructions
- **Benchmarks or performance data** that would exceed 2 pages inline
- **Diagrams** that need their own files (architecture diagrams, sequence diagrams)

The main ADR should remain 1-2 pages and **link to** supplementary material rather than including it inline.
