# Enterprise AI Architectural Gotchas

> Senior architect perspective — April 2026
> Hard-won lessons on bringing AI into enterprise systems at every layer
> Not a best-practices guide — a "what will bite you" guide

---

## 1. Organizational & Strategic Gotchas

### 1a. The "AI Everywhere" Trap

- **Gotcha**: Leadership mandates AI in every product/process. Teams bolt LLMs onto problems that don't need them.
- **Reality**: LLMs are expensive, non-deterministic, and slow compared to traditional code. A regex, a rules engine, or a SQL query is often the right tool.
- **Architect's job**: Establish a decision framework — "Use AI when the problem is ambiguous, unstructured, or requires natural language understanding. Use traditional code when the problem is well-defined and deterministic."
- **Red flag**: If someone can write the business rules on a whiteboard in 30 minutes, an LLM is overkill.

### 1b. POC-to-Production Gap

- **Gotcha**: The POC works beautifully in a demo. It takes 6-12 months to get it into production.
- **Why**: POCs skip auth, multi-tenancy, error handling, observability, compliance, data governance, cost management, and edge cases. The "last 20%" is 80% of the work.
- **Architect's checklist before greenlighting a POC for production**:
  - What happens when the model returns garbage? (fallback path)
  - What happens when the model is down for 2 hours? (degraded mode)
  - What happens when a user sends adversarial input? (guardrails)
  - What does the audit log look like? (compliance)
  - What does the cost model look like at 100x current usage? (economics)
  - Who owns the model relationship and API key rotation? (operations)

### 1c. Vendor Lock-In Creep

- **Gotcha**: You start with OpenAI for everything. 18 months later, you have 40 services hardcoded to `gpt-4o`, prompt-tuned to its quirks, relying on its specific JSON mode behavior.
- **Mitigation**:
  - Abstract the LLM behind an interface (model gateway / LLM router)
  - Keep prompts model-agnostic where possible (avoid model-specific XML tags, system prompt tricks)
  - Test critical paths against 2+ providers quarterly
  - Store model version in every audit log — you need to know what made each decision
- **Counter-argument**: Some lock-in is acceptable if the provider is significantly better for your use case. The goal is informed lock-in, not accidental lock-in.

### 1d. The Shared Services vs. Embedded Teams Debate

- **Gotcha**: Central AI platform team builds shared infrastructure, but product teams wait months for features. OR product teams build independently, and you get 15 incompatible agent frameworks.
- **What works**: Platform team owns the harness, middleware, model gateway, and observability. Product teams own the agents, tools, and prompts. Clear interface boundary.
- **Anti-pattern**: Platform team tries to own the prompts or agent logic — they don't have domain context. Product teams try to build their own model gateway — they'll skip cost controls and observability.

---

## 2. Model & Provider Gotchas

### 2a. Model Regression After Updates

- **Gotcha**: Provider updates the model. Your carefully tuned prompts break. Your structured output parsing fails. Your evaluation scores drop 15%.
- **This happens regularly**: OpenAI, Anthropic, and Google all update models with new versions. Behavior changes are undocumented and sometimes subtle.
- **Mitigation**:
  - Pin model versions explicitly (`gpt-4o-2024-08-06`, not `gpt-4o`)
  - Run evaluation suites before adopting new model versions
  - Keep a rollback plan — be able to switch back to previous version within minutes
  - Monitor output quality metrics continuously, not just at deployment

### 2b. Rate Limits Are Your Real Scaling Ceiling

- **Gotcha**: Your infrastructure scales beautifully. Kubernetes auto-scales pods. Then you hit the model provider's rate limit and everything queues.
- **Numbers that matter**:
  - OpenAI Tier 5: ~10K RPM for GPT-4o (tokens per minute varies)
  - Anthropic: Varies by tier and model
  - Azure OpenAI: PTU (provisioned throughput) is predictable but expensive
- **Mitigation**:
  - Multi-provider failover (primary → secondary → tertiary)
  - Request queuing with priority levels (customer-facing > internal > batch)
  - Model tiering: route simple queries to cheaper/faster models
  - Caching: semantic cache for repeated/similar queries — saves 20-40% of calls in many workloads
  - Batch API for non-real-time workloads (50% cheaper, higher throughput)

### 2c. The Temperature Trap

- **Gotcha**: Developer sets `temperature=0` thinking it makes output deterministic. It doesn't — it makes it *mostly* deterministic. Same prompt, same model, different day: different output.
- **Why**: Floating point rounding, model serving infrastructure, batching behavior, and model updates all introduce variance.
- **Implication**: Never build business logic that assumes identical prompts produce identical outputs. Always validate output structure, never assume content stability.

### 2d. Context Window != Usable Context

- **Gotcha**: "The model supports 128K tokens!" So you stuff 120K tokens of context and expect great results.
- **Reality**: LLM performance degrades significantly on long context. The "lost in the middle" problem — models attend to the beginning and end, miss the middle.
- **Rule of thumb**: Use <50% of context window for best quality. Use RAG to select the most relevant context rather than dumping everything in.
- **Exception**: Some tasks (summarization, code analysis) genuinely benefit from full context. Test and measure, don't assume.

### 2e. Multi-Modal Is Not Free

- **Gotcha**: "We'll just send images/PDFs to the vision model." Vision tokens are 2-5x more expensive than text tokens, and vision API latency is 2-3x higher.
- **Cost example**: A 10-page PDF as images ≈ 10K-30K tokens per page = 100K-300K vision tokens = $1-5 per document with GPT-4o.
- **Mitigation**: OCR/text extraction first, fall back to vision only for complex layouts (tables, charts, handwriting). ColPali for retrieval, text for generation.

---

## 3. Data & RAG Gotchas

### 3a. Garbage In, Garbage Out (But Harder to Detect)

- **Gotcha**: Traditional systems fail visibly on bad data (parse errors, constraint violations). LLMs fail silently — they generate plausible-sounding answers from garbage context.
- **Implication**: Data quality is MORE critical for AI systems, not less. A hallucinated answer that looks correct is worse than an error message.
- **Architect's response**:
  - Invest in data quality pipelines BEFORE building the AI layer
  - Implement citation/grounding — every AI-generated claim must reference a source chunk
  - Build evaluation that checks answer accuracy against known ground truth, not just fluency

### 3b. Chunking Is a Data Modeling Problem

- **Gotcha**: Teams treat chunking as a text processing step. They use LangChain's default recursive splitter on everything and wonder why retrieval is poor.
- **Reality**: Chunking is a data modeling decision as important as schema design. How you chunk determines what questions your system can answer.
- **Examples of chunking gone wrong**:
  - Fixed-size chunks split a table across two chunks — neither chunk contains the full table
  - A policy document is chunked by paragraph — each chunk lacks the section header context
  - Code files are chunked mid-function — retrieved chunks are syntactically incomplete
- **Fix**: Match chunking strategy to document type and query patterns. Multiple chunk representations (parent-child, contextual) are often necessary.

### 3c. Embedding Drift

- **Gotcha**: You re-embed your corpus with a new embedding model. Old embeddings and new embeddings aren't compatible — you need to re-embed everything.
- **Scale problem**: 10M documents * 512 tokens avg * $0.02/1M tokens = $100 to re-embed. Sounds cheap. But the pipeline takes 8 hours, and you need to do it with zero downtime.
- **Mitigation**:
  - Blue/green vector store deployments — build new index alongside old, swap when ready
  - Store raw text alongside embeddings — enables re-embedding without re-crawling
  - Factor re-embedding cost into your embedding model selection decision

### 3d. The Freshness Problem

- **Gotcha**: Your RAG system answers based on documents indexed 3 weeks ago. The policy was updated yesterday. The agent confidently gives outdated information.
- **Mitigation**:
  - Real-time or near-real-time sync for critical document sources
  - Timestamp metadata on every chunk — use in retrieval scoring (boost recent)
  - Staleness indicators in agent responses ("Based on documents last updated on...")
  - Webhook/CDC triggers for high-priority document changes

### 3e. RAG Evaluation Is Unsolved (But You Must Do It)

- **Gotcha**: "How good is our RAG system?" "Uh... users seem happy?"
- **What to measure**:

  | Metric | What It Measures | How to Compute |
  | --- | --- | --- |
  | Retrieval precision@k | Are retrieved chunks relevant? | Human labels or LLM-as-judge on retrieved chunks |
  | Retrieval recall | Did we find all relevant chunks? | Requires known-relevant set (expensive to build) |
  | Answer faithfulness | Is the answer supported by retrieved context? | LLM-as-judge: check each claim against sources |
  | Answer correctness | Is the answer actually right? | Compare against ground-truth QA pairs |
  | Answer relevance | Does the answer address the question? | LLM-as-judge or human eval |

- **Frameworks**: RAGAS, DeepEval, LangSmith evaluators
- **Key insight**: Automated evaluation with LLM-as-judge is imperfect but 10x better than no evaluation. Run it in CI/CD. Human eval quarterly for calibration.

---

## 4. Agent Architecture Gotchas

### 4a. Agent Autonomy Spectrum (Get This Wrong and You're in Trouble)

- **Gotcha**: Team builds a fully autonomous agent for a sensitive workflow. Agent makes a bad decision. No human ever saw it. Customer is affected.
- **The spectrum**:

  | Level | Description | Use When |
  | --- | --- | --- |
  | **Copilot** | Suggests, human executes | High-stakes, regulated, early trust-building |
  | **Supervised** | Executes with approval gates | Medium-stakes, established patterns, audit needed |
  | **Autonomous** | Executes independently, logs for review | Low-stakes, well-understood, high volume |

- **Rule**: Start every new agent at Copilot level. Promote to Supervised after 2-4 weeks of logged performance. Promote to Autonomous only when error rate is demonstrably below human error rate.
- **Never skip the ladder**: The cost of a bad autonomous decision (legal exposure, customer trust, compliance violation) dwarfs the cost of human review.

### 4b. Tool Explosion

- **Gotcha**: Agent has 30 tools. LLM struggles to select the right one. Latency increases because the tool descriptions consume 20% of context. Tool selection accuracy drops below 80%.
- **Empirical observation**: Most models perform well with 5-10 tools, degrade noticeably above 15, and fail frequently above 25.
- **Mitigation**:
  - Subagents: Group related tools under specialist subagents (finance tools → finance subagent)
  - Progressive disclosure: Load tools contextually based on conversation stage (deepagents SkillsMiddleware pattern)
  - Tool routing: Lightweight classifier selects relevant tool subset before the main LLM sees them
  - Better tool descriptions: Clear, concise, with examples. The model reads these on every call.

### 4c. The Infinite Loop Problem

- **Gotcha**: Agent gets confused, calls the same tool repeatedly with slightly different parameters, never converging on an answer. Token costs spiral.
- **Causes**: Ambiguous tool descriptions, model not understanding when to stop, error responses that don't help the model course-correct.
- **Mitigation**:
  - `recursion_limit` on LangGraph (deepagents uses 9999, but production should be much lower — 20-50)
  - Token budget per run (hard cutoff)
  - Duplicate tool call detection (middleware that detects and breaks loops)
  - Clear tool error messages that suggest alternatives ("No results found. Try broadening your search terms or using a different tool.")

### 4d. Subagent Overhead

- **Gotcha**: You decompose everything into subagents for clean architecture. Each subagent spawns its own LLM call. A simple question that should take 1 LLM call now takes 5 (router → planner → 2 subagents → aggregator).
- **Rule**: Use subagents when the context savings justify the extra LLM calls. If the subagent's work would consume <5K tokens in the parent context, just do it in the parent.
- **Cost math**: Subagent = 1 extra LLM round-trip (~$0.01-0.05 with GPT-4o). Context overflow recovery = summarization LLM call (~$0.02-0.10) + degraded quality. Pick your trade-off.

### 4e. State Schema Evolution

- **Gotcha**: You add a new field to your agent's state schema. Existing checkpoints don't have this field. Agent crashes on resume.
- **This is database migration for agents**: Same problem as adding a NOT NULL column to a table with existing rows.
- **Mitigation**:
  - Always add new state fields with defaults
  - Version your state schema
  - Write migration logic for checkpoint stores
  - Consider TTL on checkpoints — old conversations expire naturally

---

## 5. Security Gotchas

### 5a. Prompt Injection Is SQL Injection for LLMs

- **Gotcha**: User input reaches the LLM without sanitization. Attacker crafts input that overrides system prompt instructions. Agent executes unauthorized tool calls.
- **Why it's hard**: Unlike SQL injection (where parameterized queries solve it), there's no equivalent "parameterized prompt" that fully prevents injection. The LLM processes all text in the same attention mechanism.
- **Defense in depth** (no single layer is sufficient):

  | Layer | Method | What It Catches |
  | --- | --- | --- |
  | **Input classification** | Lightweight model flags suspicious inputs | Known injection patterns |
  | **Instruction hierarchy** | System prompt establishes authority boundaries | Naive "ignore previous instructions" |
  | **Tool permissions** | RBAC limits what tools are available | Even if injection succeeds, damage is bounded |
  | **Output validation** | Check outputs against expected schema/patterns | Exfiltration via output channel |
  | **Canary tokens** | Embed unique tokens in system prompt, alert if leaked | System prompt extraction attempts |
  | **Human review** | HITL on sensitive actions | Everything else |

- **Key insight**: Assume injection WILL occasionally succeed. Design the blast radius to be small (tool permissions, data access controls, HITL on destructive actions).

### 5b. Data Leakage via Context

- **Gotcha**: Agent retrieves sensitive data (PII, financial, health) into context as part of RAG. That data is now in the model provider's logs, your observability traces, and potentially in the model's training data.
- **Mitigation**:
  - PII detection/redaction BEFORE data enters LLM context
  - Data classification on documents at indexing time — tag sensitivity level
  - Restrict which documents are retrievable based on user's data access level
  - Use enterprise model agreements that guarantee no training on your data (Azure OpenAI, Anthropic API)
  - Encrypt audit logs containing context, restrict access

### 5c. Tool Call as Attack Surface

- **Gotcha**: Agent has a `run_sql` tool. Attacker via prompt injection gets the agent to run `DROP TABLE users`. Or `SELECT * FROM credentials`.
- **Mitigation**:
  - Read-only database credentials for query tools (not read-write)
  - Query allowlisting: only permit SELECT on specific tables
  - Row-level security: query results filtered by user's permissions
  - Rate limiting on tool calls
  - HITL approval for any write/delete operations
  - **Never give an agent a shell command tool with unrestricted access in production**

### 5d. Supply Chain Risk in AI Dependencies

- **Gotcha**: Your agent framework depends on 200+ Python packages. A compromised package gets write access to your model API key, agent state, and tool credentials.
- **This is standard supply chain risk, amplified**: AI agents often have broader permissions than traditional services (tool access, API keys for multiple services, customer data in context).
- **Mitigation**:
  - Pin all dependency versions, audit updates
  - Minimize dependency tree — prefer fewer, well-known packages
  - Secret management (Vault, AWS Secrets Manager) — not environment variables
  - Network segmentation — agent runtime can only reach services it needs

---

## 6. Operations & Cost Gotchas

### 6a. Cost Escalation Is Non-Linear

- **Gotcha**: POC costs $50/month. Production costs $50,000/month. Nobody planned for this.
- **Why non-linear**:
  - More users = more concurrent agents = more LLM calls
  - Agents that loop or use subagents multiply calls per request
  - Context auto-summarization adds LLM calls (summarization is itself an LLM call)
  - Evaluation and monitoring add LLM calls (LLM-as-judge)
  - Re-embedding on model updates costs proportional to corpus size

- **Cost model template**:

  | Component | Cost Driver | Estimate Per Request |
  | --- | --- | --- |
  | Input tokens | Prompt + context | ~1K-10K tokens |
  | Output tokens | Response + tool calls | ~500-2K tokens |
  | Agent loops | Avg tool calls per request * per-call cost | 3-10 calls |
  | Subagent calls | Per subagent * per-call cost | 0-3 calls |
  | Summarization | ~1 per 10 turns of conversation | Amortized |
  | Embedding (query) | 1 embedding call per retrieval | ~$0.00001 |
  | Reranking | 1 reranker call per retrieval | ~$0.002 |
  | **Total per request** | | **$0.01-0.50** |

- **At scale**: 100K requests/day * $0.10 avg = $10K/day = $300K/month. This surprises people.

### 6b. Latency Budget Reality

- **Gotcha**: Stakeholder expects "chatbot-like" 1-2 second responses. Agent needs 3 tool calls, 1 retrieval, 1 reranker, and 2 LLM calls. Actual latency: 8-15 seconds.
- **Typical latency breakdown**:

  | Step | Latency |
  | --- | --- |
  | LLM call (reasoning) | 1-5s (depends on output length) |
  | LLM call (tool selection) | 0.5-2s |
  | Vector search | 50-200ms |
  | Reranking | 100-300ms |
  | Tool execution (API call) | 200ms-2s |
  | Per agent loop iteration | 2-7s |
  | Total (3 iterations) | 6-21s |

- **Mitigation**:
  - Streaming: Show partial results as they arrive (dramatically improves perceived latency)
  - Parallel tool calls: If model requests multiple tools, execute simultaneously
  - Model tiering: Use faster model for routing/classification, capable model for generation
  - Caching: Semantic cache for repeated queries eliminates LLM call entirely
  - Pre-computation: For known query patterns, pre-generate and cache answers

### 6c. Observability Is Not Optional — It's Day 1

- **Gotcha**: Team builds the agent, ships it, then tries to add observability. Now they can't debug why the agent gave a wrong answer to a customer 3 days ago.
- **What you need from day 1**:
  - Full trace of every agent execution (LangSmith or OpenTelemetry)
  - Token usage per request, per user, per tenant
  - Cost attribution per request
  - Tool success/failure rates
  - Latency percentiles (P50, P95, P99) per step
  - Error rates by type (model error, tool error, context overflow, timeout)
- **The question you must be able to answer**: "Why did the agent say X to customer Y on date Z?" If you can't, you're not production-ready.

### 6d. The Monitoring Blind Spot: Quality Degradation

- **Gotcha**: Uptime is 99.9%. Latency is within SLA. Error rate is <1%. But answer quality has silently dropped 20% because the model was updated, the knowledge base drifted, or prompt performance degraded on a new category of questions.
- **Mitigation**:
  - Automated quality evaluation on a sample of production traffic (LLM-as-judge, run async)
  - User feedback signals (thumbs up/down, explicit corrections)
  - Drift detection: Compare output distribution over time (embedding similarity of outputs, topic classification)
  - Regression test suite: Golden QA pairs re-evaluated weekly against production

---

## 7. Compliance & Governance Gotchas

### 7a. "The AI Made That Decision" Is Not an Acceptable Audit Response

- **Gotcha**: Regulator asks why a loan was denied, a claim was rejected, or a customer was flagged. "The AI decided" is not acceptable under GDPR Article 22 (right to explanation), ECOA, or FCRA.
- **Requirement**: For any consequential decision, you must be able to produce:
  - What data the model received (input context)
  - What the model said (output)
  - What tools were called and what they returned
  - What human (if any) reviewed and approved
  - What model version was used
  - Timestamp of every step
- **Architect's response**: Audit logging middleware is non-negotiable. Implement it before the first production deployment, not after the first audit.

### 7b. Data Residency Surprises

- **Gotcha**: Your EU customer data goes to a US-based model API. GDPR violation.
- **Layers where data travels**:
  - Model API: Where does the provider process your data? (Region-specific endpoints exist)
  - Vector database: Where are embeddings stored?
  - Observability: Where do traces/logs with context land?
  - Cache: Where are cached responses stored?
- **Mitigation**: Map every service in the AI pipeline to a region. Use Azure OpenAI (region-specific), EU vector DB instances, and region-locked observability.

### 7c. Model Output as Legal Liability

- **Gotcha**: Agent gives medical advice, financial guidance, or legal interpretation. User acts on it. Outcome is bad.
- **Mitigation**:
  - Explicit disclaimers in agent output for regulated domains
  - Domain-specific guardrails (medical: "consult a doctor", financial: "not financial advice")
  - HITL mandatory for advice that could create liability
  - Terms of service covering AI-generated content limitations
  - Insurance consideration for AI-generated advice in professional services

### 7d. Intellectual Property in Prompts and Fine-Tunes

- **Gotcha**: Your competitive advantage is encoded in your system prompts, few-shot examples, and fine-tuning data. Model provider potentially has access to all of it.
- **Risk varies by provider**:
  - API providers (OpenAI API, Anthropic API, Azure OpenAI): Typically contractual guarantee of no training on your data
  - Consumer products (ChatGPT free tier): May use your data for training
  - Open-source self-hosted: Full control, no third-party access
- **Mitigation**: Enterprise agreements with explicit data handling terms. For highest-sensitivity: self-hosted open-source models (but significant ops cost).

---

## 8. Integration Gotchas

### 8a. The "Just Add an API Call" Fallacy

- **Gotcha**: "We'll just have the agent call the CRM API." Six months later: OAuth token refresh failures at 3am, API rate limiting during peak hours, schema changes breaking the tool, and timeout handling that doesn't work.
- **Every tool integration needs**:
  - Auth: Token refresh, key rotation, credential scoping
  - Error handling: Timeouts, retries, circuit breakers, clear error messages for the LLM
  - Rate limiting: Per-tool, per-tenant, respecting external API limits
  - Schema evolution: Handle API changes gracefully (version pinning, adapter layer)
  - Monitoring: Per-tool success rate, latency, error categorization
- **Anti-pattern**: Giving the agent raw HTTP access. Always wrap external APIs in purpose-built tools with proper error handling and permission boundaries.

### 8b. Async Integration Mismatch

- **Gotcha**: User expects real-time response. Agent calls a tool that triggers an async process (Jira ticket creation, approval workflow, email send). The async process takes hours. Agent says "Done!" but nothing has actually happened yet.
- **Mitigation**:
  - Distinguish between "initiated" and "completed" in tool responses and agent output
  - For long-running processes: return a status/tracking ID, offer to check later
  - Webhook-based completion notification → agent resumes conversation when async process finishes
  - Set clear expectations in agent responses ("I've submitted the request. You'll receive a confirmation within 2 hours.")

### 8c. Legacy System Integration Tax

- **Gotcha**: Enterprise has 15-year-old ERP with SOAP APIs, mainframe batch processing, and FTP file exchanges. "Just connect the AI agent" becomes a 6-month integration project.
- **Reality**: AI doesn't magically solve integration complexity. It adds a new consumer to existing integration problems.
- **Patterns that work**:
  - MCP server wrapping legacy APIs (standardized interface for the agent)
  - Event bridge: Legacy system publishes events, agent consumes asynchronously
  - Screen scraping as last resort (fragile but sometimes the only option)
  - API gateway / facade layer that modernizes the interface before the agent sees it

---

## 9. Team & Process Gotchas

### 9a. The Prompt Engineering Skills Gap

- **Gotcha**: Senior engineers are great at writing code. They write terrible prompts. Prompt engineering is a different skill — closer to technical writing than to programming.
- **Symptoms**: Overly complex system prompts, inconsistent output quality, no evaluation framework, prompt changes deployed without testing.
- **Mitigation**:
  - Treat prompts as code: version control, review process, test suites
  - Evaluation-driven development: Write evaluation cases BEFORE changing the prompt
  - Prompt libraries: Shared, tested templates for common patterns (classification, extraction, summarization)
  - Training: Most engineers need 2-4 weeks of hands-on prompt engineering to become effective

### 9b. The Evaluation Gap

- **Gotcha**: Team ships an AI feature with no way to measure if it's working well. "Users aren't complaining" is not a quality metric.
- **Minimum viable evaluation**:
  - 50-100 golden QA pairs for your domain (human-verified correct answers)
  - Automated evaluation running in CI (block merges that regress quality)
  - Production sampling: Evaluate 1-5% of live traffic with LLM-as-judge
  - User feedback loop: Simple thumbs up/down, feed into evaluation dashboard
- **Key insight**: Without evaluation, you can't iterate. Every prompt change, every model upgrade, every knowledge base update is a guess.

### 9c. The "Just Use the Latest Model" Reflex

- **Gotcha**: New model drops. Team immediately switches. Prompts break. Costs change. Latency characteristics differ. Nobody tested.
- **Process**:
  1. New model available → run full evaluation suite
  2. Compare: quality, latency, cost, edge case behavior
  3. If better: staged rollout (10% → 50% → 100%) with monitoring
  4. If worse on any critical metric: don't switch, document why
  - This is canary deployment for models — same discipline as code deploys.

---

## 10. Decision Framework: The AI Architecture Review Checklist

Before approving any AI system for production, an architect should verify:

| Category | Question | Red Flag If Missing |
| --- | --- | --- |
| **Necessity** | Does this problem require AI, or is a deterministic solution viable? | Building complexity for its own sake |
| **Fallback** | What happens when the model fails, hallucinates, or is unavailable? | No degraded mode |
| **Cost** | What's the projected cost at 10x and 100x current scale? | No cost model |
| **Latency** | What's the latency budget and is it achievable with the current design? | No latency measurement |
| **Security** | How are prompt injection, data leakage, and tool abuse prevented? | No guardrails layer |
| **Compliance** | Can we explain every AI decision to a regulator? | No audit logging |
| **Evaluation** | How do we know the system is working correctly? | No quality metrics |
| **Observability** | Can we debug why the agent did X on date Y? | No tracing |
| **Data quality** | How fresh and accurate is the knowledge base? | No sync pipeline |
| **Autonomy level** | What decisions can the agent make without human approval? | No HITL on destructive actions |
| **Vendor** | What's the model switching cost? | Single-provider, no abstraction |
| **Operations** | Who gets paged when it breaks? Who rotates API keys? | No runbook |

---

## Quick Reference: Top 10 Gotchas by Blast Radius

| # | Gotcha | Blast Radius | Detection Difficulty |
| --- | --- | --- | --- |
| 1 | No audit logging in regulated domain | Legal / compliance catastrophe | Easy to detect, hard to fix retroactively |
| 2 | Prompt injection → unauthorized tool call | Data breach, financial loss | Hard — requires adversarial testing |
| 3 | Cost escalation at scale | Budget blowout | Easy — but often ignored until too late |
| 4 | Model regression after provider update | Silent quality degradation | Medium — requires automated evaluation |
| 5 | PII/sensitive data in model context | Compliance violation, data breach | Medium — requires data classification |
| 6 | Fully autonomous agent on sensitive workflow | Customer impact, legal exposure | Easy — but organizational pressure to automate |
| 7 | No fallback when model is unavailable | Service outage | Easy — but teams skip it for MVP |
| 8 | RAG over stale/incorrect data | Wrong answers at scale | Hard — requires freshness monitoring |
| 9 | Vendor lock-in across 40+ services | Migration cost, negotiation leverage loss | Easy to detect, expensive to fix |
| 10 | No evaluation framework | Can't improve, can't verify, can't audit | Easy — but requires discipline to build |
