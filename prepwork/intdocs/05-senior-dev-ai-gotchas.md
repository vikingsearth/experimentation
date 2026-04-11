# Senior Developer AI Gotchas

> Implementation-level foot-guns for engineers building LLM-powered systems
> April 2026 — the stuff that bites you at the keyboard, not the whiteboard

---

## 1. Prompt Engineering Foot-Guns

### 1a. The Prompt That Works Until It Doesn't

- **Gotcha**: You craft a prompt, test it on 10 examples, ship it. Two weeks later, a user sends a slightly unusual input and the output is catastrophically wrong.
- **Why**: Prompts have invisible decision boundaries. You don't know where they are until you cross them. Unlike code, there are no type errors or compile failures to warn you.
- **What to do**:
  - Build an eval set BEFORE writing the prompt (minimum 30-50 cases covering edge cases)
  - Run the eval after every prompt change — treat it like a test suite
  - Include adversarial cases: empty input, extremely long input, input in wrong language, input that contradicts the system prompt, input with special characters/markdown/code blocks
  - Track the eval score over time — it should only go up

### 1b. Prompt Brittleness

- **Gotcha**: Reordering two paragraphs in the system prompt changes behavior. Adding a single example changes the output format. Changing "You must" to "You should" makes the model ignore the instruction.
- **Why**: LLMs are sensitive to phrasing, ordering, and emphasis in ways that aren't intuitive. What feels like a synonym to you may activate different model behavior.
- **Defensive practices**:
  - Use explicit structure in prompts: numbered rules, XML tags (`<instructions>`, `<context>`, `<output_format>`), clear section headers
  - Put the most important instructions at the beginning AND end (attention is strongest there)
  - Use imperative language: "Always do X" and "Never do Y" instead of "You should try to X"
  - When something works, don't refactor the prompt for "cleanliness" — if it ain't broke, don't rephrase it

### 1c. Few-Shot Example Contamination

- **Gotcha**: Your few-shot examples accidentally teach the model the wrong thing. Example: you provide 3 examples that all happen to be about finance. Model now biases all responses toward financial interpretation.
- **Subtler version**: Your examples all follow the same structure. Model becomes rigid, can't handle inputs that don't match the example pattern.
- **Fix**:
  - Diverse examples: vary domain, length, complexity, edge cases
  - Negative examples: show what the output should NOT look like
  - Test with and without examples — sometimes zero-shot with clear instructions outperforms poorly chosen few-shot

### 1d. System Prompt Length vs. Effectiveness

- **Gotcha**: System prompt grows to 3000 tokens as the team adds more rules, edge cases, and instructions. Model starts ignoring rules that are buried in the middle.
- **The wall**: Empirically, model compliance with instructions drops after ~800-1200 tokens of system prompt. More instructions can mean worse adherence.
- **Fix**:
  - Prioritize: Top 5 rules matter. Everything else is diminishing returns.
  - Separate concerns: Use tool descriptions for tool-specific instructions, not the system prompt
  - Structured output schema does more work than prompt instructions for format compliance
  - If you need complex behavior, use a multi-step chain, not a single mega-prompt

### 1e. The "Be Helpful" vs "Follow Rules" Tension

- **Gotcha**: System prompt says "Only answer questions about our products." User asks a tangentially related question. Model either refuses (bad UX) or answers broadly (violating scope). You can't get the boundary right.
- **Why**: LLMs are trained to be helpful. Scope restrictions fight against this training. The model will try to find a way to help, even if it means bending your rules.
- **What works better than hard boundaries**:
  - Graceful redirects: "I can help with X, Y, Z. For other questions, here's where to go..."
  - Output classifiers: Let the model answer, then classify the output — filter if out of scope
  - Layered approach: Loose prompt constraints + strict output validation

---

## 2. Structured Output Hell

### 2a. JSON Mode Doesn't Mean Valid JSON for Your Schema

- **Gotcha**: You enable JSON mode. Model returns valid JSON. But it has extra fields, missing fields, wrong types, or nested structure that doesn't match your Pydantic model.
- **JSON mode guarantees**: syntactically valid JSON. That's it. Not schema compliance.
- **Fix**:
  - Use structured output / function calling with explicit JSON schema (OpenAI, Anthropic both support this)
  - Always validate with Pydantic / Zod on the output side — never trust the model
  - Include the schema in the prompt AND use the API's schema parameter — belt and suspenders

### 2b. The Enum Hallucination Problem

- **Gotcha**: Schema says `category` must be one of `["billing", "technical", "general"]`. Model returns `"Billing"` (capitalized) or `"tech_support"` (close but wrong) or `"billing/technical"` (trying to be helpful with multi-labels).
- **Fix**:
  - Case-insensitive matching + fuzzy matching as a first pass
  - Structured output with enum types (model API enforces valid values)
  - If using free-text output: post-processing step that maps to nearest valid value
  - Include the exact enum values in the prompt: "Category must be exactly one of: billing, technical, general"

### 2c. Nested Object Depth Failures

- **Gotcha**: Your schema has 4 levels of nesting. Model gets the outer levels right but garbles the inner structure, especially when the inner objects are complex.
- **Why**: Models generate token by token. Deep nesting requires tracking many open brackets and maintaining structural consistency across hundreds of tokens. Error probability compounds with depth.
- **Fix**:
  - Flatten schemas where possible — 2 levels of nesting max is the sweet spot
  - For complex structures: extract in stages (first extract outer, then extract inner per item)
  - Use chain-of-extraction: one LLM call per logical unit, not one mega-extraction

### 2d. Streaming + Structured Output

- **Gotcha**: You're streaming the response for real-time UI. But the output is JSON. You can't parse incomplete JSON. UI shows raw `{"result": "The answer is` until the closing `"}` arrives.
- **Fix**:
  - Partial JSON parsers exist (e.g. `partial-json-parser` in JS, `json-repair` in Python) — but they're fragile
  - Better pattern: Stream a text explanation FIRST, then emit structured data as a separate step
  - Or: Use tool calls for structured data (streamed as complete objects) and text for the conversational part
  - Best: Design the UX around streamed text with structured metadata in the final message

---

## 3. Framework Pitfalls

### 3a. LangChain Abstraction Leaks

- **Gotcha**: LangChain wraps everything in abstractions (Document, Retriever, Chain, Agent). When something goes wrong, you're 6 layers deep in abstraction trying to figure out what HTTP call was actually made.
- **Common pain points**:
  - `Document` objects lose metadata silently during transformations
  - `Retriever` interface hides whether you're doing dense, sparse, or hybrid search
  - Error messages reference internal classes, not your code
  - Upgrading LangChain versions breaks things — the API surface changes frequently
- **Fix**:
  - Use LangGraph directly for agents (lower-level, more control, more stable API)
  - Use LangChain components (embeddings, chat models) but not chains
  - When debugging, add `verbose=True` or use LangSmith tracing to see actual API calls
  - Pin LangChain versions aggressively and test before upgrading

### 3b. LangGraph State Reducer Surprises

- **Gotcha**: You define state with `messages: list[BaseMessage]`. Two nodes both add messages. You expect append. You get overwrite — the last node's messages replace the previous ones.
- **Why**: Default dict merge in LangGraph is overwrite. You need explicit reducers for append behavior.
- **Fix**: Always use `Annotated[list[BaseMessage], add_messages]` for message lists. For any list or accumulating field, define a reducer.
- **Second gotcha**: `add_messages` deduplicates by message ID. If you create messages with the same ID, they get replaced instead of appended. Use unique IDs or let the framework generate them.

### 3c. Async/Sync Mixing Hell

- **Gotcha**: Your tool is sync (calls a REST API with `requests`). Your agent runs async (FastAPI endpoint using `astream`). LangGraph runs the sync tool in a thread pool. But the sync tool uses `threading.local()` for auth context. Auth context is lost in the thread pool.
- **More gotchas in this space**:
  - Sync tool with `time.sleep()` blocks the event loop if not properly wrapped
  - Async tool that calls sync code internally (buried `requests.get()` in a dependency)
  - Database connections that aren't async-safe being used in async context
- **Fix**:
  - Pick a lane: all-sync or all-async. Mixing is where bugs hide.
  - If you must mix: use `asyncio.to_thread()` explicitly, test auth context propagation
  - Use `httpx` (supports both sync and async) instead of `requests` + `aiohttp`

### 3d. The recursion_limit Gotcha

- **Gotcha**: LangGraph default `recursion_limit` is 25. Your agent needs 30 tool calls for a complex task. Graph silently stops at 25 steps, returns incomplete result.
- **Worse**: You set `recursion_limit=9999` to "fix" it. Now a malfunctioning agent can loop 9999 times, consuming $50 of tokens before timing out.
- **Fix**: Set a thoughtful limit based on your workflow's expected maximum steps. Typically 20-50 for most agents. Add a token budget as a secondary backstop.

### 3e. Checkpoint Serialization Gotchas

- **Gotcha**: You add a custom object to your agent's state (e.g. a Pandas DataFrame, a database connection, a file handle). Checkpoint serialization fails because the object isn't JSON-serializable.
- **Fix**:
  - Keep state serializable: primitives, dicts, lists, strings, numbers
  - For complex objects: store a reference (ID, file path, query) in state, reconstruct the object in the node that needs it
  - Never put connections, streams, or open file handles in state
  - Test checkpointing early — switch from MemorySaver to PostgresSaver before building complex state

---

## 4. Testing AI Code

### 4a. Non-Determinism Makes Traditional Testing Impossible

- **Gotcha**: `assert response == "The capital of France is Paris"` passes today, fails tomorrow because the model says "Paris is the capital of France" instead.
- **Why**: Even at temperature 0, LLM outputs vary slightly across calls (batching, infrastructure, model updates).
- **Testing strategies that work**:

  | Strategy | What It Tests | Example |
  | --- | --- | --- |
  | **Schema validation** | Output structure correct | Response is valid JSON matching Pydantic model |
  | **Assertion functions** | Key facts present | `"Paris" in response` and `"France" in response` |
  | **LLM-as-judge** | Semantic correctness | "Does this response correctly answer the question?" → Yes/No |
  | **Embedding similarity** | Response is semantically close to expected | `cosine_sim(embed(response), embed(expected)) > 0.85` |
  | **Classification check** | Output category is correct | Response sentiment is "positive", extracted entity is "Acme Corp" |
  | **Negative assertions** | Known wrong things are absent | `"I don't know" not in response` when answer exists in context |

### 4b. Mocking LLMs in Unit Tests

- **Gotcha**: You mock the LLM to return a fixed response. Your test passes. But the test is now testing your mock, not your system. When the real model returns a slightly different format, production breaks.
- **The right layers to mock**:
  - Mock external APIs (CRM, database) — deterministic, stable interface
  - Mock the LLM for structural/integration tests (does the pipeline wire up correctly?)
  - Do NOT mock the LLM for quality/behavior tests — use real calls with eval assertions
- **Pattern**: Two test suites
  - **Fast suite (mocked LLM)**: Runs in CI on every commit. Tests wiring, error handling, tool execution, state management.
  - **Eval suite (real LLM)**: Runs daily or on-demand. Tests actual output quality against golden dataset. Costs money, takes minutes.

### 4c. Testing Tools in Isolation

- **Gotcha**: Tool works perfectly when called directly. Breaks when called by the agent because the agent passes arguments in a slightly different format than your test.
- **Why**: The model decides what arguments to pass. It might use `"customer_id": "123"` (string) instead of `"customer_id": 123` (integer). Or include extra fields. Or omit optional fields.
- **Fix**:
  - Validate tool input with a schema (Pydantic model for args) — reject bad input clearly
  - Test tools with LLM-generated args, not hand-written args
  - Make tools lenient on input types (accept both string and int for IDs, strip whitespace)
  - Error messages should tell the LLM how to fix the call: "customer_id must be an integer, got string '123'"

### 4d. Integration Test Timing

- **Gotcha**: Integration test calls the real model API. Takes 3 seconds. You have 50 tests. Test suite takes 2.5 minutes. Developer stops running tests.
- **Fix**:
  - Parallelize LLM calls in tests (most providers handle concurrent requests)
  - Cache LLM responses for deterministic test inputs (same prompt → same cached response in test)
  - Separate fast (mocked) and slow (real LLM) test suites — fast runs on every commit, slow runs on PR merge
  - Use the cheapest model that validates your logic for integration tests (Haiku, GPT-4o-mini)

### 4e. Eval Drift

- **Gotcha**: Your eval set was written 6 months ago. The product has evolved. 20% of the "golden" answers are now wrong or outdated. Eval scores are misleading.
- **Fix**:
  - Review and update eval set quarterly
  - Tag eval cases with creation date and domain — retire stale cases
  - Add new eval cases for every production bug ("this should have been caught")
  - Track eval set coverage — are new features/domains represented?

---

## 5. Debugging Non-Deterministic Systems

### 5a. "It Worked Yesterday" Debugging

- **Gotcha**: Exact same input, exact same code, different output today. What changed?
- **Checklist** (in order of likelihood):
  1. Model provider updated the model (check their changelog / status page)
  2. Context is different (previous messages in conversation, retrieved documents changed)
  3. Temperature > 0 (natural variance)
  4. Tool returned different results (external API data changed)
  5. Race condition in parallel tool execution
  6. Caching behavior changed (cache hit vs miss)
- **First debug step**: Compare the full LangSmith traces side-by-side. 90% of the time, the difference is visible in the traces.

### 5b. The "Why Did It Call That Tool?" Mystery

- **Gotcha**: Agent called `search_database` when it should have called `search_knowledge_base`. Output is wrong. Why?
- **Common causes**:
  - Tool descriptions are ambiguous or overlapping
  - Previous messages in context biased the model toward the wrong tool
  - Tool names are too similar (`search_db` vs `search_kb` vs `search_docs`)
  - The model is "pattern matching" on the user's words rather than understanding intent
- **Fix**:
  - Read the full prompt (system + messages + tool descriptions) as the model sees it — often the issue is obvious from this vantage point
  - Improve tool descriptions: add "Use this when..." and "Do NOT use this when..." sections
  - Make tool names clearly distinct and descriptive
  - Add a classification step before tool selection for ambiguous cases

### 5c. Silent Failures in Tool Chains

- **Gotcha**: Tool A returns an error. Model interprets the error message as data. Passes it to Tool B. Tool B processes garbage. Final output looks plausible but is completely wrong.
- **Example**: Search returns "No results found for query." Model extracts "No" as the answer to a yes/no question.
- **Fix**:
  - Tools should return structured error responses, not error messages as content: `{"status": "error", "error": "no_results", "suggestion": "Try broadening your search"}`
  - Middleware that detects tool errors and forces the model to acknowledge and handle them
  - Never let error strings flow into downstream tool inputs without model reasoning in between

### 5d. Context Poisoning

- **Gotcha**: One bad message early in the conversation biases all subsequent model responses. A hallucinated fact from turn 3 gets treated as established truth for the rest of the conversation.
- **Why**: Messages are context. The model doesn't distinguish "things I said" from "verified facts." Its own previous outputs have the same weight as user-provided facts.
- **Fix**:
  - Grounding: Require the model to cite sources for claims. If it can't cite, it shouldn't state.
  - Periodic context refresh: For long conversations, re-retrieve relevant facts instead of relying on conversation history
  - Auto-summarization helps — the summarizer may drop hallucinated details that weren't reinforced

### 5e. The Latency Debugging Nightmare

- **Gotcha**: Agent response takes 12 seconds. Where is the time going? Is it the model? The tool? The vector search? Network? Serialization?
- **Without tracing**: You have no idea. You add `time.time()` around everything, clutter the code, and still miss the async gaps.
- **With tracing (LangSmith / OpenTelemetry)**: Every span is timed. You see:
  - Model call 1: 2.1s (reasoning)
  - Tool: vector_search: 0.3s
  - Tool: reranker: 0.2s
  - Model call 2: 3.4s (generation with context)
  - Tool: crm_lookup: 1.8s (slow API)
  - Model call 3: 2.1s (final response)
  - Total: 9.9s — the CRM lookup is the outlier
- **Lesson**: Add tracing on day 1. Not day 30. The cost is minimal, the value is enormous.

---

## 6. Streaming & Real-Time Gotchas

### 6a. Token-by-Token Streaming Jank

- **Gotcha**: You stream tokens to the UI. First 2 seconds: nothing (model is "thinking" / processing prompt). Then a burst of tokens. Then a pause (tool call). Then more tokens. UX feels broken.
- **Why**: LLMs have a "time to first token" (TTFT) that depends on prompt length. Tool calls interrupt the stream. The model may "think" (output nothing) before responding.
- **Fix**:
  - Show a "thinking" indicator during TTFT and tool execution
  - Emit tool call events to the UI: "Searching knowledge base..." "Reading document..."
  - Buffer a small amount before starting to render (avoid showing 1-2 character bursts)
  - Separate the streaming channel (text) from the metadata channel (tool calls, status)

### 6b. Streaming Error Recovery

- **Gotcha**: Stream is halfway through the response. Model API returns a 500 error. You've already displayed 200 tokens to the user. Now what?
- **Options (all imperfect)**:
  - Show error inline: "...an error occurred. Retrying..." — honest but jarring
  - Retry silently from scratch: User sees the response restart — confusing
  - Retry and resume from last token: Extremely hard to implement, model doesn't support "continue from token 200"
- **Best practice**: Display what you have + error message + "Regenerate" button. Don't try to be clever with transparent retries — users prefer honesty.

### 6c. Backpressure When the Client Is Slow

- **Gotcha**: Model generates tokens at 100 tokens/sec. Client (mobile, slow connection) can only consume at 20 tokens/sec. Buffer grows. Memory grows. Server eventually OOMs or drops the connection.
- **Fix**:
  - Server-side buffer with a max size — if client is too slow, truncate or pause
  - Use WebSocket with flow control or SSE with connection monitoring
  - Set a timeout on the stream — if client hasn't acknowledged in X seconds, close
  - Don't buffer the entire response server-side — stream through, let the client handle its own buffering

---

## 7. Dependency & Environment Gotchas

### 7a. Python Dependency Hell (The LangChain Edition)

- **Gotcha**: `langchain` 0.2 requires `pydantic` v2. Your ORM uses `pydantic` v1. They're incompatible. `langchain-core`, `langchain-community`, `langchain-openai` all have independent version constraints that conflict.
- **Reality**: The LangChain ecosystem has fragmented into 20+ packages with independent versioning. Upgrading one may break another.
- **Fix**:
  - Pin everything: `langchain-core==0.2.38`, not `langchain-core>=0.2`
  - Use `uv` or `poetry` with a lock file — never `pip install` without version pins in production
  - Test upgrades in isolation before applying to the main project
  - Consider using LangGraph directly + `openai` SDK directly, skipping the LangChain abstraction layer where possible — fewer dependencies, more stability

### 7b. API Key Management in Development

- **Gotcha**: API key in `.env` file. Developer commits `.env` to git. Key is now in git history forever. Or: Developer uses their personal API key for testing. Gets rate limited. Blocks the team.
- **What actually happens in practice**:
  - `.env` gets committed at least once (even with `.gitignore`)
  - Developers share API keys over Slack
  - Production key is used in development "just for testing"
  - Key rotation breaks 3 services nobody knew were using it
- **Fix**:
  - `.env.example` in repo (no real values). `.env` in `.gitignore`. Pre-commit hook that rejects files containing API key patterns.
  - Separate API keys per environment (dev, staging, prod). Separate keys per developer.
  - Secret manager (Vault, AWS Secrets Manager, Azure Key Vault) for production — not environment variables.
  - Document which key is used where — a simple table in the README saves hours of debugging.

### 7c. GPU/Compute Surprises for Self-Hosted Models

- **Gotcha**: "We'll just run Llama locally." You need a $10K GPU (A100 80GB for a 70B model). Inference is 10x slower than API. You need to manage CUDA drivers, model loading, memory management, batching, and health checks.
- **Hidden costs of self-hosting**:
  - GPU hardware/rental ($2-5/hour for A100)
  - Engineering time for model serving (vLLM, TGI, Ollama — each with their own quirks)
  - No automatic model updates — you manually download, test, deploy new versions
  - Cold start: Loading a 70B model takes 30-120 seconds
  - No multi-tenancy out of the box — you build your own queue
- **When self-hosting makes sense**: Data sovereignty requirements, very high volume (cheaper than API at scale), need for fine-tuned models, offline/air-gapped environments.
- **When it doesn't**: Anything else. API providers are cheaper, faster, and more reliable until you hit significant scale.

### 7d. The SSL/Proxy Corporate Environment Pain

- **Gotcha**: Every HTTP call fails with SSL certificate verification error. Corporate proxy intercepts TLS. Your `httpx`, `requests`, `openai`, and `langchain` clients all need different SSL configuration.
- **Common "fixes" that create security holes**:
  - `SSL_CERT_FILE=...` environment variable (right approach)
  - `REQUESTS_CA_BUNDLE=...` (works for `requests` only)
  - `verify=False` everywhere (disables all cert verification — DO NOT do this in production)
  - Patching `httpx.Client` at import time to disable verification (the pydeep approach — fine for dev, bad for prod)
- **Proper fix**: Get the corporate CA certificate bundle, configure it at the environment level (`SSL_CERT_FILE`), and ensure all HTTP clients inherit it. Test each client library — they don't all respect the same env vars.

---

## 8. Common Code-Level Anti-Patterns

### 8a. The God Prompt

- **Symptom**: One 4000-token system prompt that handles classification, extraction, formatting, tone, error handling, scope limitation, and personality. Impossible to debug which instruction is causing which behavior.
- **Fix**: Decompose into a pipeline. Classification prompt → Extraction prompt → Formatting prompt. Each is short, testable, single-responsibility.

### 8b. String Concatenation Prompt Building

- **Symptom**: `prompt = f"You are a {role}. " + context + "\n\nAnswer: " + question`. Breaks when `context` contains quotes, braces, or text that looks like prompt instructions.
- **Fix**:
  - Use message objects (`SystemMessage`, `HumanMessage`) — structured, not string-concatenated
  - Use XML tags or delimiters to separate user content from instructions: `<user_input>{input}</user_input>`
  - Never put untrusted input directly adjacent to instructions without clear delimiters

### 8c. Swallowing Tool Errors

- **Symptom**: `try: result = tool(args) except: result = "Error occurred"`. The model gets "Error occurred" as tool output, has no idea what went wrong, hallucinates an answer.
- **Fix**: Return structured errors with actionable information:
  ```python
  except NotFoundException:
      return {"status": "error", "code": "not_found", 
              "message": f"No record found for ID {id}",
              "suggestion": "Verify the ID or try searching by name instead"}
  ```

### 8d. Ignoring Token Counts

- **Symptom**: Building context by concatenating all retrieved chunks, all chat history, and a long system prompt without counting tokens. Works in testing (short conversations). Fails in production (long conversations hit context limit).
- **Fix**:
  - Use `tiktoken` (OpenAI) or model-specific tokenizer to count tokens
  - Budget your context window: system prompt (10%) + retrieved context (40%) + conversation history (40%) + output buffer (10%)
  - Truncate retrieved context to fit the budget — better to send fewer, more relevant chunks than to overflow

### 8e. Synchronous Everything

- **Symptom**: Agent calls 3 independent tools sequentially. Each takes 1 second. Total: 3 seconds. Could have been 1 second with parallel execution.
- **Fix**:
  - LangGraph supports parallel tool execution natively when the model requests multiple tools in one message
  - For custom orchestration: use `asyncio.gather()` for independent tool calls
  - For retrieval: embed query and run BM25 in parallel, then fuse results
  - Measure: parallel tool execution typically saves 30-60% latency on multi-tool turns

### 8f. Logging the Full Prompt in Production

- **Symptom**: DEBUG logging includes the full prompt (system prompt + all messages + all tool descriptions). Each log entry is 10KB. Log volume explodes. Log search becomes unusable. Sensitive data leaks into logs.
- **Fix**:
  - Log structured metadata: model, token counts, tool calls (names + arg keys, not values), latency, thread_id
  - Full prompt/response logging only in trace system (LangSmith) with access controls
  - PII redaction before any logging
  - Log levels: INFO for metadata, DEBUG for full content (never in production)

---

## 9. Production Deployment Gotchas

### 9a. Health Checks for Non-Deterministic Services

- **Gotcha**: Standard health check: `/health` returns 200. But the model is returning gibberish because the API key expired, the model version was deprecated, or the vector DB index is corrupted.
- **Better health checks**:

  | Check | What It Validates | Frequency |
  | --- | --- | --- |
  | `/health` (shallow) | Process is running, memory OK | Every 10s (K8s liveness) |
  | `/ready` (deep) | Can reach model API, vector DB, tool APIs | Every 30s (K8s readiness) |
  | `/quality` (canary) | Model returns sane output for known input | Every 5 min |

- **The canary check**: Send a known question ("What is 2+2?"), verify the answer contains "4". If it doesn't, the model is degraded — pull from load balancer.

### 9b. Graceful Shutdown with In-Flight Agents

- **Gotcha**: Kubernetes sends SIGTERM. Pod shuts down. But there are 5 agent sessions mid-execution. State is lost. Users see errors.
- **Fix**:
  - Handle SIGTERM: stop accepting new requests, wait for in-flight agents to complete (with timeout)
  - Checkpoint state frequently — if the pod dies, agents can resume from last checkpoint on another pod
  - Set `terminationGracePeriodSeconds` high enough for your longest expected agent execution (60-120s typically)
  - Return 503 on `/ready` immediately on SIGTERM — stop receiving new traffic

### 9c. Memory Leaks from Conversation State

- **Gotcha**: Each conversation stores message history in memory. 1000 concurrent conversations * 50KB avg state = 50MB. Normal. 1000 conversations that run for hours without cleanup * 500KB = 500MB. Pod OOMs.
- **Fix**:
  - Externalize state to PostgresSaver/RedisSaver — don't hold it in process memory
  - TTL on conversations — expire inactive sessions after 30 minutes
  - Auto-summarization caps the state size (deepagents pattern)
  - Monitor per-process memory, set memory limits on pods

### 9d. The Cold Start Problem

- **Gotcha**: First request after deployment takes 15 seconds. Why? Loading embedding model into memory, establishing database connection pools, initializing LangGraph, warming caches.
- **Fix**:
  - Readiness probe that only passes after warmup is complete
  - Pre-warm in container startup: load models, establish connections, run a canary inference
  - Keep minimum replica count > 0 (no scale-to-zero for latency-sensitive agents)
  - If using self-hosted embedding models: preload into GPU memory at startup, not on first request

---

## 10. Versioning & Deployment Gotchas

### 10a. What Does "Deploy a Prompt Change" Mean?

- **Gotcha**: Developer changes the system prompt. How does it get to production? Is it hardcoded in the application? Loaded from a config file? Fetched from a database? Each approach has different deployment characteristics.
- **Options and trade-offs**:

  | Approach | Deploy Speed | Safety | Rollback | Audit |
  | --- | --- | --- | --- | --- |
  | Hardcoded in app | Full CI/CD cycle | High (tested) | Git revert + redeploy | Git history |
  | Config file (env var) | Config reload | Medium | Config rollback | Config management |
  | Database / feature flag | Instant | Low (no CI/CD) | Flip flag | Change log |
  | LangSmith Hub / Prompt registry | Instant | Medium (versioned) | Version rollback | Built-in |

- **Recommendation**: Hardcoded in app for early stage (simple, tested). Prompt registry for mature systems (instant rollout, A/B testing, versioning).

### 10b. A/B Testing AI Outputs Is Different

- **Gotcha**: You A/B test a prompt change. Variant B gets 5% higher engagement. Ship it. But engagement came from the model being more agreeable/confident, not more accurate. Quality dropped.
- **Why AI A/B testing is hard**:
  - Engagement metrics don't correlate with accuracy
  - Outputs are non-deterministic — variance between runs may exceed variance between variants
  - Sample sizes need to be larger to account for output variance
- **Fix**:
  - A/B test with quality metrics (accuracy, faithfulness) not just engagement
  - Run the eval suite on both variants — quality regression is a hard veto
  - Longer test periods to account for variance
  - Segment by query type — a prompt that's better for simple queries may be worse for complex ones

### 10c. Canary Deploys for Model Changes

- **Gotcha**: You switch from GPT-4o to Claude Sonnet. Deploy to 100% at once. Prompts that worked with GPT-4o don't work with Claude. Structured output parsing breaks. 100% of users are affected.
- **Fix**: Treat model changes like code changes — canary deploy:
  1. 5% of traffic to new model, 95% to old
  2. Monitor quality metrics, error rates, latency, cost
  3. If metrics are green after 24 hours: 25% → 50% → 100%
  4. If metrics degrade at any stage: roll back to 0%, investigate
  - This requires a model router / feature flag, not hardcoded model names

---

## Quick Reference: The "Did I Forget?" Checklist Before Shipping

```
[ ] Eval suite with 30+ cases, running in CI
[ ] Structured output validated with Pydantic/Zod (not just JSON mode)
[ ] Error handling: tool errors are structured, not string messages
[ ] Token counting: context budget enforced, not just hoped for
[ ] Tracing: LangSmith or OTEL spans on every node and tool call
[ ] Health checks: shallow (liveness), deep (readiness), canary (quality)
[ ] Graceful shutdown: SIGTERM handler, in-flight completion, checkpoint
[ ] State externalized: PostgresSaver or equivalent (not in-memory)
[ ] API keys: not in code, not in .env committed to git, rotatable
[ ] Rate limits: handled with retry + backoff, not just crash
[ ] Streaming: error recovery, backpressure, UI loading states
[ ] Prompt: version-controlled, tested against eval, not string-concatenated
[ ] Model version: pinned explicitly, not "latest"
[ ] Dependencies: locked, not floating
[ ] Logging: structured metadata, PII redacted, full content only in traces
```
