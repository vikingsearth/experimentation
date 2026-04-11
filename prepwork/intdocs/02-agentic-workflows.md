# Enterprise-Grade Agentic Workflows for Process Automation

> Technical discussion reference — April 2026
> Covers: orchestration patterns, frameworks, enterprise workflows, state management, HITL, error handling

---

## 1. Agent Orchestration Patterns

### 1a. Single Agent (ReAct)

- **Pattern**: LLM reasons → calls tool → observes result → reasons again → repeats until done
- **When**: Simple tasks, 1-5 tools, no branching logic, single domain
- **Limitation**: Context window fills up on complex multi-step tasks

```mermaid
flowchart LR
    U[User] --> R[Reason\nLLM]
    R --> A[Act\nTool Call]
    A --> O[Observe\nResult]
    O --> R
    R --> |Done| RESP[Response]
```

### 1b. Sequential Chain (Pipeline)

- **Pattern**: Agent A output → Agent B input → Agent C input → final output
- **When**: Ordered processing stages where each transforms the previous output
- **Example**: Draft → Review → Edit → Format
- **Advantage**: Simple mental model, easy to debug, predictable execution order

```mermaid
flowchart LR
    IN[Input] --> A1[Agent A\nClassify]
    A1 --> A2[Agent B\nExtract]
    A2 --> A3[Agent C\nValidate]
    A3 --> OUT[Output]
```

### 1c. Parallel Fan-Out / Fan-In

- **Pattern**: Router splits work → N agents execute in parallel → Aggregator merges results
- **When**: Independent subtasks, latency-sensitive, research/analysis tasks
- **Example**: Research question → [search web, search docs, search code] → merge findings

```mermaid
flowchart TD
    IN[Input] --> R{Router}
    R --> A1[Agent 1\nWeb Search]
    R --> A2[Agent 2\nDoc Search]
    R --> A3[Agent 3\nCode Search]
    A1 --> AGG[Aggregator\nMerge + Synthesize]
    A2 --> AGG
    A3 --> AGG
    AGG --> OUT[Output]
```

### 1d. Hierarchical (Manager / Worker)

- **Pattern**: Orchestrator LLM plans and delegates to specialist agents, each with their own tools
- **When**: Complex multi-domain tasks requiring different expertise/toolsets
- **Example**: Project manager agent delegates to research agent, coding agent, testing agent
- **Key design**: Manager sees only summaries, not raw worker output — preserves context

```mermaid
flowchart TD
    U[User] --> MGR[Manager Agent\nPlan + Delegate]
    MGR --> W1[Worker: Researcher\nSearch tools]
    MGR --> W2[Worker: Analyst\nData tools]
    MGR --> W3[Worker: Writer\nFormat tools]
    W1 --> |Summary| MGR
    W2 --> |Summary| MGR
    W3 --> |Summary| MGR
    MGR --> RESP[Final Response]
```

### 1e. Graph-Based (LangGraph StateGraph)

- **Pattern**: Nodes = functions/agents, edges = conditional routing, typed state flows through graph
- **When**: Complex workflows with branching, loops, error recovery, conditional paths
- **Key feature**: Cycles allowed — enables retry loops, human review loops, iterative refinement
- **State**: TypedDict with reducers (e.g. `messages: Annotated[list, add_messages]`)

```mermaid
flowchart TD
    S[Start] --> CL{Classify\nLLM}
    CL -- Invoice --> IE[Extract Invoice\nStructured Output]
    CL -- Contract --> CE[Extract Contract\nStructured Output]
    CL -- Unknown --> HR1[Human\nClassification]
    HR1 --> CL
    IE --> VAL{Validate\nBusiness Rules}
    CE --> VAL
    VAL -- Valid --> ENR[Enrich\nCRM/ERP Lookup]
    VAL -- Invalid --> HR2[Human\nReview]
    HR2 --> VAL
    ENR --> RT[Route to\nDownstream System]
    RT --> AUD[Audit\nLog]
```

### 1f. Event-Driven

- **Pattern**: Message queue triggers agent execution, results published back to queue
- **When**: Async processing, high throughput, decoupled systems, multiple consumers
- **Example**: New email arrives → Kafka topic → agent classifies and routes → publishes result

```mermaid
flowchart LR
    EV[Event\nKafka/SQS] --> TR[Trigger\nConsumer]
    TR --> AG[Agent\nExecution]
    AG --> PUB[Publish\nResult]
    PUB --> Q1[Queue: Notifications]
    PUB --> Q2[Queue: Audit]
    PUB --> Q3[Queue: Analytics]
```

### Pattern Comparison

| Pattern | Complexity | Latency | Fault Tolerance | Observability | Best For |
|---|---|---|---|---|---|
| Single ReAct | Low | Low | Low | Simple (linear trace) | Simple Q&A, tool use |
| Sequential | Low | Medium | Medium | Easy (pipeline trace) | Document processing |
| Parallel Fan-Out | Medium | Low (parallel) | Medium | Moderate (branch trace) | Research, analysis |
| Hierarchical | High | Medium | High | Complex (tree trace) | Multi-domain tasks |
| Graph-Based | High | Variable | High | Complex (graph trace) | Conditional workflows |
| Event-Driven | High | Variable | Highest | Distributed tracing | Async, high throughput |

---

## 2. Framework Comparison

| Framework | Languages | Orchestration Model | State Mgmt | HITL | Streaming | Enterprise Readiness |
|---|---|---|---|---|---|---|
| **LangGraph** | Python, JS/TS | StateGraph (nodes + edges) | Checkpointer | interrupt_before/after | Yes | High (LangSmith, Platform) |
| **CrewAI** | Python | Role-based agents + Process | Built-in memory | Yes (human tool) | Yes | Medium |
| **AutoGen / AG2** | Python | Conversation-based multi-agent | Chat history | Yes (human proxy) | Yes | Medium (research-oriented) |
| **Google ADK** | Python, Java | Agent → Tool → Session → Runner | Session state | Callbacks | Yes | High (Vertex AI deploy) |
| **Semantic Kernel** | C#, Python, Java | Kernel + Plugins + Planner | Kernel memory | Manual | Yes | High (Azure ecosystem) |
| **Temporal + LLM** | Any (polyglot) | Durable workflow engine + LLM activities | Event-sourced | Signal/query | No native | Highest (battle-tested infra) |

### Key Talking Points

- **LangGraph** is the de facto standard for custom agent orchestration. Most flexibility, best tooling (LangSmith traces), largest ecosystem.
- **CrewAI** is higher-level — faster to prototype, less control. Good for "3 agents collaborating on a report" patterns. Less suitable for complex conditional flows.
- **Google ADK** is strong for Google Cloud native. Agent-to-Agent (A2A) protocol for inter-agent communication. Gemini-first but model-agnostic.
- **Semantic Kernel** is the pragmatic choice for .NET/Microsoft shops. Planner handles basic orchestration, Kernel filters for middleware. Deep Azure OpenAI integration.
- **Temporal + LLM** is the nuclear option — durable execution guarantees (retries, timeouts, versioning) that no LLM framework matches. Use when you already have Temporal and need bulletproof reliability. LLM calls become just another Temporal activity.
- **Most enterprises** will use LangGraph for new projects, or Temporal+LLM for regulated industries needing auditable durable workflows.

---

## 3. Enterprise Workflow Patterns

### 3a. Document Processing Pipeline

The most common enterprise agent automation. Replaces manual document intake and routing.

```mermaid
flowchart TD
    IN[Document Intake\nEmail / API / Upload / Scan] --> PRE[Preprocessing\nOCR / Text Extract / Clean]
    PRE --> CL{Classify\nLLM + confidence}
    CL -- "Invoice (>0.9)" --> IE[Invoice Extraction\nLLM + Pydantic schema]
    CL -- "Contract (>0.9)" --> CE[Contract Extraction\nLLM + Pydantic schema]
    CL -- "Support Ticket" --> TE[Ticket Extraction\nLLM + schema]
    CL -- "Low confidence" --> HR1[Human Classification\nQueue]
    HR1 --> CL

    IE --> VAL[Validate\nBusiness Rules Engine]
    CE --> VAL
    TE --> VAL

    VAL -- Pass --> ENR[Enrich\nCRM / ERP Lookup]
    VAL -- Fail --> HR2[Human Review\nWith context]
    HR2 --> |Corrected| VAL

    ENR --> RT{Route\nTo System}
    RT -- Invoice --> AP[Accounts Payable\nSAP / NetSuite]
    RT -- Contract --> CLM[Contract Mgmt\nDocuSign / Ironclad]
    RT -- Ticket --> TSK[Ticketing\nJira / ServiceNow]

    AP --> AUD[Audit Log\nTimestamp + User + Decision]
    CLM --> AUD
    TSK --> AUD
```

**Key design decisions:**
- LLM for classification and extraction, **rules engine for validation** — deterministic checks shouldn't use LLM
- **Structured output** (Pydantic models / JSON schema) for extraction — ensures downstream compatibility
- **Confidence thresholds** determine human routing — tune per document type
- **Idempotency keys** for retry safety — same document shouldn't create duplicate entries

### 3b. Approval Workflows with HITL

- **Interrupt points** before sensitive actions (financial transactions, contract signing, customer communications)
- **Escalation chains**: auto-approve if confidence > threshold, escalate to L1 → L2 → manager if not
- **Timeout handling**: If no response in X hours, re-escalate or auto-reject with notification
- **Audit requirement**: Every approval/rejection logged with approver identity, timestamp, reason

```mermaid
flowchart TD
    ACT[Agent Proposes\nAction] --> CONF{Confidence\n> Threshold?}
    CONF -- Yes --> AUTO[Auto-Execute\nLog decision]
    CONF -- No --> Q[Queue for\nHuman Review]
    Q --> TIMER{Timeout\nExpired?}
    TIMER -- No --> DEC{Human\nDecision}
    TIMER -- Yes --> ESC[Escalate\nNext Tier]
    ESC --> Q
    DEC -- Approve --> EXEC[Execute\nAction]
    DEC -- Modify --> MOD[Apply\nModifications] --> EXEC
    DEC -- Reject --> REJ[Reject\nNotify Agent]
    AUTO --> LOG[Audit\nLog]
    EXEC --> LOG
    REJ --> LOG
```

### 3c. Multi-Step Data Enrichment

- **Entity resolution**: Match records across systems (fuzzy name matching, ID dedup)
- **Parallel enrichment**: Call multiple APIs simultaneously (Clearbit, LinkedIn, D&B, internal CRM)
- **Merge/dedup logic**: Agent resolves conflicts between sources (recency, authority ranking)
- **Caching**: Cache enrichment results with TTL — avoid redundant API calls
- **Pattern**: Fan-out to enrichment APIs → fan-in with conflict resolution → write to master record

### 3d. Incident Response Automation

```mermaid
flowchart TD
    AL[Alert\nPagerDuty / Datadog] --> TR[Triage Agent\nSeverity Assessment]
    TR --> |P1 Critical| RB1[Execute\nRunbook Steps]
    TR --> |P2 High| RB2[Suggest Actions\nAwait Approval]
    TR --> |P3 Low| LOG[Log + Auto-Assign\nTicket]
    RB1 --> CHK{Resolved?}
    CHK -- Yes --> SUM[Generate\nIncident Summary]
    CHK -- No --> ESC[Escalate\nPage On-Call]
    RB2 --> APP{Approved?}
    APP -- Yes --> RB1
    APP -- No --> ESC
    SUM --> JIRA[Create Postmortem\nJira Ticket]
    ESC --> SLACK[Alert\nSlack Channel]
```

**Guardrails**: Never auto-remediate production without approval. Agent can diagnose, suggest, and prepare — but a human executes destructive fixes.

---

## 4. State Management

### Core Concepts

- **State**: Typed dictionary flowing through the graph. Defined via `TypedDict` with annotated reducers.
- **Checkpointing**: Full state snapshot saved after each node execution. Enables resume after failure.
- **Thread**: A conversation/session identifier. All state for one execution lives under one thread ID.
- **Run**: A single invocation within a thread. Multiple runs can share thread state (continuing a conversation).

### Persistence Backends

| Backend | Use Case | Durability | Latency | Scalability |
|---|---|---|---|---|
| `MemorySaver` | Development, testing | None (in-process) | ~0ms | Single process |
| `SqliteSaver` | Local dev, single-user | Disk | ~1ms | Single process |
| `PostgresSaver` | Production | Full (WAL) | ~5ms | Multi-process, replicas |
| `RedisSaver` | High-throughput, caching | Configurable (AOF/RDB) | ~1ms | Clustered |

### State Design Best Practices

- Keep state **typed** (`TypedDict`) — catches errors early, documents the contract
- Use **reducers** for list fields: `messages: Annotated[list, add_messages]` — appends instead of overwrites
- Avoid storing large blobs in state — use references (file paths, URLs, IDs)
- **Partition state by concern**: separate `messages`, `metadata`, `tools_state`, `user_context`
- **Immutability**: Each node returns new state values, reducer merges — never mutate in place

### Checkpointing and Recovery

```mermaid
flowchart LR
    N1[Node 1\nClassify] --> CP1[(Checkpoint\nPostgres)]
    CP1 --> N2[Node 2\nExtract]
    N2 --> CP2[(Checkpoint)]
    CP2 --> N3[Node 3\nValidate]
    N3 --> CP3[(Checkpoint)]

    CP1 -.-> |"Failure → Resume"| N2
    CP2 -.-> |"Failure → Resume"| N3
    CP2 -.-> |"Time-Travel Debug"| LS[LangSmith\nReplay]
```

**Key talking points:**
- **Resume from failure**: If Node 3 crashes, restart from Checkpoint 2 — no re-processing
- **Time-travel debugging**: Load any historical checkpoint in LangSmith, inspect state at that point
- **Versioning**: When you change the graph, old checkpoints may be incompatible — migration strategy needed

---

## 5. Human-in-the-Loop (HITL)

### LangGraph Interrupt Mechanism

- `interrupt_before=["tool_name"]` — Pause execution **before** the tool call, show proposed args to human
- `interrupt_after=["tool_name"]` — Pause execution **after** the tool call, show result to human for review
- Implementation: Graph execution yields at interrupt point, state is checkpointed, resumes when `Command(resume=...)` is called

### HITL Design Patterns

| Pattern | Trigger | Human Action | Use Case |
|---|---|---|---|
| **Approval gate** | Before sensitive tool | Approve / Modify / Reject | Financial transactions, emails |
| **Review gate** | After extraction/generation | Accept / Edit / Regenerate | Document processing, content creation |
| **Confidence threshold** | LLM confidence < threshold | Classify / Verify | Ambiguous inputs, edge cases |
| **Escalation chain** | Timeout or rejection | Route to next tier | Support workflows, incident response |
| **Feedback loop** | After final output | Rate quality, provide correction | Continuous improvement |

### HITL Architecture

```mermaid
flowchart TD
    AG[Agent\nProposes Action] --> INT{Interrupt\nPoint?}
    INT -- No --> EXEC[Execute\nDirectly]
    INT -- Yes --> CHK{Confidence\n> Auto-Approve?}
    CHK -- Yes --> EXEC
    CHK -- No --> QUEUE[Queue for\nHuman Review]
    QUEUE --> UI[Review UI\nShow context + proposed action]
    UI --> DEC{Decision}
    DEC -- Approve --> EXEC
    DEC -- Modify --> EDIT[Edit Args] --> EXEC
    DEC -- Reject --> ALT[Alternative\nPath]
    DEC -- Escalate --> ESC[Next Tier\nReviewer]
    ESC --> UI
    EXEC --> CP[(Checkpoint\nWith Decision)]
    ALT --> CP
```

**Key talking points:**
- HITL is a **spectrum**, not binary. Fully autonomous → confidence-gated → always-human.
- Start with **always-human** for sensitive actions, relax to confidence-gated as trust builds.
- Every human decision becomes **training signal** — log it, use for evaluation, potentially fine-tune.
- **Latency impact**: HITL adds minutes/hours. Design the surrounding workflow to be async — don't block other processing while waiting.

---

## 6. Enterprise Concerns

### RBAC (Role-Based Access Control)

- **Tool-level permissions**: Define which user roles can invoke which tools
  - Admin: all tools including `delete_record`, `execute_sql`
  - Analyst: `read_file`, `search_kb`, `generate_report`
  - Viewer: `search_kb` only
- **Implementation**: User role in `context_schema` (LangGraph config), middleware checks before tool execution
- **Data-level**: Filter tool results by user's data access permissions (row-level security for SQL tools)

### Audit Trails

- Every LLM call: input messages, output message, model, tokens used, latency
- Every tool invocation: tool name, args, result, duration, success/failure
- Every human decision: approver identity, action, timestamp, reason
- Every state transition: from-node, to-node, state diff
- **Format**: Structured JSON logs → SIEM (Splunk, Elastic, Datadog)
- **Retention**: Per compliance framework (SOX: 7 years, GDPR: varies, HIPAA: 6 years)

### Cost Controls

| Control | Implementation | Fallback |
|---|---|---|
| Token budget per request | Count tokens per LLM call, abort if cumulative > limit | Return partial result with warning |
| Daily budget per user/tenant | Aggregate token counts in Redis, check before each call | Queue request, notify user |
| Model tiering | Route simple queries to cheaper model, complex to expensive | Always fallback to cheapest |
| Caching | Semantic cache (embed query, check similarity to cached queries) | Skip cache, accept cost |
| Rate limiting | Leaky bucket per tenant | 429 with retry-after header |

### Compliance & Governance

- **Data residency**: Choose model provider and vector DB region to match compliance requirements (GDPR → EU, CCPA → US)
- **PII handling**: Detect and redact PII before logging, optionally before sending to LLM
- **Model governance**: Track which model version was used for each decision — critical for audits
- **Deterministic fallback**: If LLM fails, exceeds budget, or is unavailable — fall back to rules engine for critical paths

---

## 7. Error Handling

### Retry Strategies

```mermaid
flowchart TD
    CALL[Tool / LLM Call] --> RES{Success?}
    RES -- Yes --> NEXT[Next Node]
    RES -- No --> CLS{Error Type?}
    CLS -- "Transient\n(429, 503, timeout)" --> RETRY{Retry\nCount < Max?}
    RETRY -- Yes --> BACK[Exponential Backoff\n+ Jitter] --> CALL
    RETRY -- No --> FALL[Fallback Path]
    CLS -- "Permanent\n(400, 404, schema)" --> FALL
    CLS -- "Context Overflow" --> SUM[Summarize Context\n+ Retry]
    SUM --> CALL
    FALL --> |Critical| HR[Human\nEscalation]
    FALL --> |Non-critical| PARTIAL[Partial\nResult]
```

### Error Handling Patterns

| Pattern | When | Implementation |
|---|---|---|
| **Exponential backoff** | Transient API failures (429, 503) | `delay = base * 2^attempt + random_jitter` |
| **Circuit breaker** | Tool fails N times in window | Stop calling, route to fallback for cooldown period |
| **Graceful degradation** | Non-critical tool unavailable | Return partial result with confidence warning |
| **Context overflow** | Token limit exceeded | Auto-summarize older messages, retry (deepagents pattern) |
| **Structured output retry** | LLM output doesn't match schema | Append parse error to messages, ask LLM to fix |
| **Human escalation** | All automated paths exhausted | Queue for human with full context + attempted actions |

### LangGraph Error Handling

- **Node-level try/except**: Catch errors in node functions, route to error handling node via conditional edge
- **Checkpoint before risky ops**: If the risky operation fails, resume from pre-operation state
- **Global error handler**: `on_error` callback in graph compilation — catches unhandled exceptions
- **Timeout per node**: Set maximum execution time, abort and route to fallback if exceeded

### Key Talking Points

- **Never silent-fail**: Every error should be logged, surfaced, or escalated — never swallowed
- **Idempotency**: Every tool call should be safe to retry — use idempotency keys for external API calls
- **Partial results > no results**: If 3 of 4 enrichment calls succeed, return what you have with confidence indicator
- **Context overflow is a feature**: Deep agents systems handle this automatically (auto-summarization), not an error — design for it

---

## 8. Putting It Together: Enterprise Agentic Platform Architecture

```mermaid
flowchart TB
    subgraph Ingestion ["Event Sources"]
        EMAIL[Email] 
        API[REST API]
        QUEUE[Message Queue]
        UI[Web UI]
    end

    subgraph Platform ["Agent Platform"]
        GW[API Gateway\nAuth + Rate Limit]
        ROUTER[Agent Router\nClassify + Route]
        
        subgraph Agents ["Agent Pool"]
            A1[Doc Processing\nAgent]
            A2[Customer Support\nAgent]
            A3[Data Enrichment\nAgent]
            A4[Incident Response\nAgent]
        end

        STATE[(State Store\nPostgres + Redis)]
        TOOLS[Tool Registry\nPermissioned]
        HITL_Q[HITL Queue\nApproval UI]
    end

    subgraph Observability ["Observability"]
        TRACE[Tracing\nLangSmith / OTEL]
        METRICS[Metrics\nPrometheus]
        AUDIT[Audit Log\nSIEM]
    end

    subgraph Integration ["Downstream"]
        CRM[CRM\nSalesforce]
        ERP[ERP\nSAP]
        TICKET[Ticketing\nJira]
        NOTIFY[Notifications\nSlack / Email]
    end

    EMAIL & API & QUEUE & UI --> GW
    GW --> ROUTER
    ROUTER --> A1 & A2 & A3 & A4
    A1 & A2 & A3 & A4 --> STATE
    A1 & A2 & A3 & A4 --> TOOLS
    A1 & A2 & A3 & A4 --> HITL_Q
    A1 & A2 & A3 & A4 --> TRACE & METRICS & AUDIT
    A1 & A2 & A3 & A4 --> CRM & ERP & TICKET & NOTIFY
```

---

## Quick Reference: Key Numbers

| Metric | Typical Value |
|---|---|
| ReAct loop iterations (single agent) | 3-10 steps |
| Max recommended tools per agent | 10-15 (beyond this, use subagents) |
| Checkpoint write latency (Postgres) | ~5ms |
| HITL response time (enterprise) | Minutes to hours |
| Context window utilization target | <85% (leave room for tool output) |
| Cost per agent execution (GPT-4o) | $0.01-0.50 depending on complexity |
| Retry max attempts | 3 (transient), 0 (permanent errors) |
| Circuit breaker threshold | 5 failures in 60 seconds |
| Audit log retention | 7 years (SOX), 6 years (HIPAA) |
