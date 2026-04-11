---
paths:
  - "src/mcp-registry/**/*.ts"
---

# MCP Server Development Standards

Standards S01–S18 from ADR-0002. Reference implementation: `src/mcp-registry/clickhouse-mcp/`. SDK: `@modelcontextprotocol/sdk@^1.26.0`.

## SDK & Protocol (S01–S03)

- **Use the low-level `Server` class** from `@modelcontextprotocol/sdk/server/index.js` — not `McpServer`
  - `McpServer` hides protocol details; only acceptable for throwaway prototypes < 50 LOC
- **One `StreamableHTTPServerTransport` per session** — never reuse transports across sessions
  - Use `randomUUID()` for session IDs
  - Required options: `enableJsonResponse: true`, `enableDnsRebindingProtection: true`
- **Register handlers explicitly** with `server.setRequestHandler(ListToolsRequestSchema, ...)` and `server.setRequestHandler(CallToolRequestSchema, ...)`

```typescript
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";

const server = new Server(
  { name: "my-mcp-server", version: "1.0.0" },
  { capabilities: { tools: { listChanged: true } } }
);
```

## Project Structure (S04–S06)

- **Separate entry point from app factory**:
  - `server.ts` — process lifecycle: config loading, `app.listen()`, signal handlers, cleanup intervals
  - `create-app.ts` — Express app factory returning `{ app, sessions }` — enables testing without side effects
- **Canonical file structure** (all MCP servers must have):

```
src/
  __tests__/           — Vitest tests
  config.ts            — Zod-validated config + loadConfig() + getVersion()
  create-app.ts        — Express app factory → { app, sessions }
  <name>-mcp.ts        — MCP Server: tool registration + request handlers
  <name>-manager.ts    — Domain logic (DB queries, API calls, caching)
  server.ts            — Entry point (process lifecycle)
  tracing.ts           — TSLog logger factory + OTel setup
  types.ts             — MCPSession, AppConfig, domain types
```

- **ESM with `.js` extensions** — all imports must include `.js` even though source is `.ts`:

```typescript
import { ClickHouseManager } from "./clickhouse-manager.js";
import type { AppConfig } from "./types.js";
```

## Configuration & Logging (S07–S09)

- **Zod config at startup** — define schema with defaults, parse env vars through it. Exit on validation failure, never fall through with `undefined`
  - Use `import "dotenv/config"` at top of `config.ts`
  - Include standard server config: `bindPort`, `bindHost` (default `0.0.0.0`), `maxSessions`, `sessionTimeoutMs`, `sessionCleanupIntervalMs`, `gracefulShutdownTimeoutMs`
- **TSLog with sub-loggers** — create root logger in `tracing.ts`, export named sub-loggers (`serverLogger`, `mcpLogger`, `managerLogger`)
  - **Never `console.log`** for operational logging
- **OTel first import** — if using OpenTelemetry, `import './tracing.js'` must be the first line in `server.ts`

## Session Management (S10–S13)

- **Flat `MCPSession` type** in `Map<string, MCPSession>`:

```typescript
interface MCPSession {
  sessionId: string;
  createdAt: Date;
  lastAccessedAt: Date;
  activeRequests: number;
  transport: StreamableHTTPServerTransport;
  mcpInstance: MyMCP;
}
```

- **Track active requests** — increment before `transport.handleRequest()`, decrement in `finally`. Prevents cleanup from destroying in-flight sessions:

```typescript
session.activeRequests++;
try {
  await session.transport.handleRequest(req, res, req.body);
} finally {
  session.activeRequests = Math.max(0, session.activeRequests - 1);
  session.lastAccessedAt = new Date();
}
```

- **Periodic cleanup with guard** — `setInterval` that expires sessions past `sessionTimeoutMs` only when `activeRequests === 0`. Use `cleanupInProgress` boolean to prevent overlapping cycles. Call `.unref()` on the interval
- **Max session limit** — reject new sessions with HTTP 503 when `sessions.size >= config.server.maxSessions`

## Tool Implementation (S14–S16)

- **One manager class per domain** — MCP tool handlers delegate to the manager, never contain business logic directly. Keeps protocol concerns separate from domain logic
- **Return `isError: true` for app errors** — never throw from tool handlers (SDK converts unhandled exceptions to opaque errors):

```typescript
// ✅ Application error as tool result
return {
  content: [{ type: "text", text: `Query failed: ${error.message}` }],
  isError: true,
};

// ❌ Never throw from handlers
throw new Error(`Query failed: ${error.message}`);
```

- **Zod validation on tool inputs** — validate at the start of each `tools/call` handler. Return `isError: true` with Zod error for invalid inputs

## Error Handling (S17–S18)

- **Three-tier error strategy**:

| Level | Error Type | Handling |
|-------|-----------|----------|
| Protocol | Invalid JSON-RPC, unknown method, bad session ID | Let SDK handle (standard JSON-RPC error codes) |
| Application | Tool failure, upstream timeout, validation error | Return `CallToolResult` with `isError: true` |
| Infrastructure | Express middleware errors, uncaught exceptions | Catch in `handleMCPRequest`, return HTTP 500 |

- **Never expose stack traces to clients** — error responses contain message only; stack traces go to server logs only
