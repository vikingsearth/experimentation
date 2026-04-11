---
description: Effect-TS coding standards for all Effect-TS services (agent-proxy-svc, evt-svc, ctx-svc, aurora-ai) including tests
paths:
  - "src/agent-proxy-svc/**/*.ts"
  - "src/evt-svc/**/*.ts"
  - "src/ctx-svc/**/*.ts"
  - "src/aurora-ai/**/*.ts"
---

# Effect-TS Standards Rules

**Auto-applies to**: All TypeScript files in Effect-TS services (evt-svc, ctx-svc, aurora-ai) including tests

**Reference**: See `.claude/skills/apply-effect-ts-standards/references/effect-ts.standards.md` for complete 1963-line standards guide

## Priority Focus Areas (Current Sprint)

### 1. HTTP Client Migration (CRITICAL)

❌ **NEVER** use axios, fetch, or node-fetch directly
✅ **ALWAYS** use `@effect/platform/HttpClient`

**Migration Pattern:**

```typescript
// ❌ BAD (current pattern in ctx-svc-client.service.ts)
import axios from 'axios';

const httpClient = axios.create({
  baseURL: url,
  timeout: 30000,
  headers: { 'Content-Type': 'application/json' }
});

const result = yield* Effect.tryPromise({
  try: async () => {
    const response = await httpClient.request({ method, url, data });
    return response.data;
  },
  catch: (error) => new PersistenceError({ /* ... */ })
});

// ✅ GOOD (required pattern)
import * as Http from "@effect/platform/HttpClient";

const result = yield* Http.request(method)(url).pipe(
  Http.client.setHeaders({ 'Content-Type': 'application/json' }),
  Http.client.execute,
  Effect.flatMap(response => response.json),
  Effect.retry(retryPolicy),
  Effect.timeout("30 seconds"),
  Effect.mapError(error => new PersistenceError({ /* ... */ }))
);
```

**Files Needing Migration:**
- `src/evt-svc/src/services/ctx-svc-client.service.ts` (lines 5, 71-77)
- `src/evt-svc/src/services/agent-proxy-svc-client.service.ts`
- `src/evt-svc/src/services/cc-svc-client.service.ts`

---

### 2. Error Handling Specificity (HIGH PRIORITY)

❌ **AVOID** `catchAll` for handling multiple specific error types
✅ **PREFER** `catchTag` or `catchTags` for type-safe error handling
⚠️ **ONLY** use `catchAll` when genuinely handling any/unknown errors

**Refactoring Pattern:**

```typescript
// ❌ BAD (event-handler.service.ts lines 84-90)
const workflow = yield* workflowConfig.getWorkflow(event.eventType).pipe(
  Effect.catchAll(() =>
    Effect.gen(function* () {
      yield* Effect.logWarning(`No workflow found for ${event.eventType}`);
      return null;
    })
  )
);

// ✅ GOOD - Specific error handling
const workflow = yield* workflowConfig.getWorkflow(event.eventType).pipe(
  Effect.catchTag("WorkflowNotFoundError", (e) =>
    Effect.gen(function* () {
      yield* Effect.logWarning(`No workflow for ${e.eventType}`);
      return null;
    })
  )
);

// ✅ ALSO GOOD - Multiple specific errors
const result = yield* operation.pipe(
  Effect.catchTags({
    WorkflowNotFoundError: (e) => handleNotFound(e),
    WorkflowConfigError: (e) => handleConfigError(e),
    ValidationError: (e) => handleValidation(e)
  })
);
```

**Files Needing Update:**
- `src/evt-svc/src/services/event-handler.service.ts` (lines 84-90, 302)

---

### 3. Schema Validation Expansion (HIGH PRIORITY)

✅ **ALL** HTTP endpoint responses MUST use `Schema.decode`
✅ **ALL** external data (pub/sub, APIs, databases) MUST be validated
✅ **DEFINE** Schema before implementation (schema-first design)

**Pattern:**

```typescript
// ✅ Already doing this for events (good!)
import { Schema } from '@effect/schema';

const PlayerEventSchema = Schema.Struct({
  eventType: Schema.String,
  playerId: Schema.String,
  // ...
});

const parseEvent = Schema.decodeUnknownEither(PlayerEventSchema);

// ✅ Extend to ALL HTTP responses
const PlayerContextResponseSchema = Schema.Struct({
  context: Schema.Union(
    Schema.Record(Schema.String, Schema.Unknown),
    Schema.Null
  ),
  embeddings: Schema.Array(EmbeddingSchema)
});

const getContext = (playerId: string) =>
  Http.get(`${baseUrl}/context/${playerId}`).pipe(
    Http.client.execute,
    Effect.flatMap(r => r.json),
    Effect.flatMap(Schema.decode(PlayerContextResponseSchema)),
    Effect.mapError(e => /* map parse errors to domain errors */)
  );
```

**Missing Validations:**
- HTTP responses from ctx-svc, agent-proxy-svc, cc-svc
- ClickHouse query results in query-orchestrator

---

## Core Principles

### Effects are Lazy Blueprints

**Remember**: An Effect is a description, not an execution. Nothing happens until you call a runtime function.

```typescript
// ✅ GOOD: Understanding laziness
const program = Effect.gen(function* () {
  yield* Effect.log("This only runs when executed");
  return 42;
});

// Execute explicitly
await Effect.runPromise(program);

// ❌ BAD: Expecting effects to run on definition
const result = Effect.log("This doesn't run yet");
// Nothing happens until you call runPromise/runSync/runFork
```

---

### Business Logic Patterns

- **Multi-step workflows** → Use `Effect.gen`
- **Simple transformations** → Use `.pipe()`
- **Avoid** long `.pipe(Effect.flatMap(...))` chains (use Effect.gen instead)

```typescript
// ✅ GOOD: Effect.gen for clear sequential logic
const processEvent = (event: PlayerEvent) =>
  Effect.gen(function* () {
    const validated = yield* validateEvent(event);
    const enriched = yield* enrichWithClickHouse(validated);
    const processed = yield* applyMappings(enriched);
    return yield* persistToCtxSvc(processed);
  });

// ❌ BAD: Deep nesting with flatMap
const processEvent = (event: PlayerEvent) =>
  validateEvent(event).pipe(
    Effect.flatMap(validated =>
      enrichWithClickHouse(validated).pipe(
        Effect.flatMap(enriched =>
          applyMappings(enriched).pipe(
            Effect.flatMap(processed =>
              persistToCtxSvc(processed)
            )
          )
        )
      )
    )
  );
```

---

### Tagged Errors (Already Excellent in This Codebase!)

✅ **ALL** custom errors MUST extend `Data.TaggedError`
✅ **INCLUDE** rich context: entity IDs, operation, cause
✅ **USE** error unions for common patterns

**Example from `src/evt-svc/src/errors.ts` (follow this pattern):**

```typescript
import { Data } from 'effect';

export class PersistenceError extends Data.TaggedError('PersistenceError')<{
  readonly playerId: string;
  readonly operation: 'save' | 'load' | 'delete' | 'config' | 'http-invoke';
  readonly storeType: 'relational' | 'vector' | 'dapr' | 'http';
  readonly cause: unknown;
}> {}

export class PlayerContextNotFoundError extends Data.TaggedError('PlayerContextNotFoundError')<{
  readonly playerId: string;
}> {}

// Error unions for common patterns
export type PlayerContextError =
  | PlayerContextNotFoundError
  | ContextUpdateError
  | PlayerActorError;
```

**Anti-pattern:**

```typescript
// ❌ BAD: Generic Error
const fetchUser = (id: string): Effect.Effect<User, Error> =>
  Effect.fail(new Error("Something went wrong"));

// ❌ BAD: String errors
const fetchUser = (id: string): Effect.Effect<User, string> =>
  Effect.fail("User not found");
```

---

### Service Architecture (Already Excellent!)

✅ **MODEL** all external dependencies as services with `Context.Tag`
✅ **USE** `Layer.effect` for service construction with dependencies
✅ **COMPOSE** layers explicitly: `ConfigService → Level1 → Level2 → Level3`

**Pattern (already in use):**

```typescript
import { Effect, Layer, Context } from 'effect';

// Service definition
export class DatabaseService extends Context.Tag('DatabaseService')<
  DatabaseService,
  {
    readonly query: (sql: string) => Effect.Effect<Result, QueryError>;
  }
>() {}

// Live implementation
export const DatabaseServiceLive = Layer.effect(
  DatabaseService,
  Effect.gen(function* () {
    const config = yield* ConfigService;
    const connectionString = yield* config.get('DATABASE_URL');

    return {
      query: (sql: string) => Effect.gen(function* () {
        // Implementation
      })
    };
  })
);

// Test implementation
export const DatabaseServiceTest = Layer.succeed(
  DatabaseService,
  {
    query: (sql: string) => Effect.succeed(mockResult)
  }
);
```

---

### HTTP Client Details

**Complete migration pattern for HTTP services:**

```typescript
import * as Http from "@effect/platform/HttpClient";
import { Schema } from '@effect/schema';

// 1. Define response schema
const ResponseSchema = Schema.Struct({
  success: Schema.Boolean,
  data: Schema.Unknown
});

// 2. Build request with proper error handling
const makeRequest = <A>(
  method: 'GET' | 'POST' | 'PUT' | 'DELETE',
  url: string,
  body?: unknown
): Effect.Effect<A, YourError> =>
  Effect.gen(function* () {
    const request = Http.request(method)(url);

    const withBody = body
      ? request.pipe(Http.client.setBody(JSON.stringify(body)))
      : request;

    const response = yield* withBody.pipe(
      Http.client.setHeaders({
        'Content-Type': 'application/json'
      }),
      Http.client.execute,
      Effect.retry(
        Schedule.exponential("100 millis").pipe(
          Schedule.compose(Schedule.recurs(3))
        )
      ),
      Effect.timeout("30 seconds")
    );

    const json = yield* response.json;
    const decoded = yield* Schema.decode(ResponseSchema)(json);

    return decoded as A;
  }).pipe(
    Effect.mapError(error =>
      new YourError({
        endpoint: url,
        cause: error
      })
    )
  );
```

**Why not axios?**
- Axios errors don't integrate with Effect's error channel
- No automatic retry/timeout integration
- No type-safe error handling
- Missing structured concurrency benefits

---

### Error Handling Scenarios

**When to use each pattern:**

```typescript
// ✅ catchTag - Single specific error type
const user = yield* getUser(id).pipe(
  Effect.catchTag("NotFoundError", () =>
    Effect.succeed(defaultUser)
  )
);

// ✅ catchTags - Multiple specific error types
const result = yield* operation.pipe(
  Effect.catchTags({
    NetworkError: (e) => retryWithBackoff(e),
    ValidationError: (e) => logAndFail(e),
    TimeoutError: (e) => useCache(e)
  })
);

// ✅ catchAll - When genuinely handling ANY error (rare)
const result = yield* dangerousOperation.pipe(
  Effect.catchAll(error => {
    // Log all errors for debugging, then re-throw
    yield* Effect.logError(`Unexpected error: ${error}`);
    return Effect.fail(error);
  })
);

// ⚠️ catchAll - Acceptable when error type is truly unknown
const result = yield* externalLibrary.someMethod().pipe(
  Effect.catchAll(error =>
    // External library doesn't use tagged errors
    Effect.fail(new ExternalLibraryError({ cause: error }))
  )
);
```

---

## Concurrency Patterns

### Effect.all with Explicit Concurrency

**ALWAYS** specify concurrency option when running multiple effects in parallel.

```typescript
// ✅ GOOD: Explicit unbounded concurrency
const results = yield* Effect.all(
  [fetchUser, fetchPosts, fetchComments],
  { concurrency: "unbounded" }
);

// ✅ GOOD: Limited concurrency for resource control
const results = yield* Effect.all(
  urls.map(url => fetchData(url)),
  { concurrency: 5 } // Max 5 concurrent requests
);

// ❌ BAD: Missing concurrency option (runs sequentially!)
const results = yield* Effect.all([task1, task2, task3]);
// This is SEQUENTIAL by default - must specify concurrency
```

### When to Use Concurrency

```typescript
// ✅ Independent operations - use concurrency
const [user, posts, settings] = yield* Effect.all(
  [fetchUser(id), fetchPosts(id), fetchSettings(id)],
  { concurrency: "unbounded" }
);

// ✅ Dependent operations - sequential is correct
const result = yield* Effect.gen(function* () {
  const user = yield* fetchUser(id);
  const posts = yield* fetchPosts(user.id); // Depends on user
  return { user, posts };
});
```

---

## Resource Management

### Scope Pattern (When Needed)

**Use for acquire/release resources** (database connections, file handles, etc.)

```typescript
// ✅ GOOD: Scoped resources
const program = Effect.acquireUseRelease(
  openDatabaseConnection, // acquire
  connection => runQuery(connection), // use
  connection => closeConnection(connection) // release (guaranteed)
);

// ✅ GOOD: Multiple resources
const program = Effect.gen(function* () {
  const db = yield* Effect.scoped(acquireDatabase);
  const cache = yield* Effect.scoped(acquireCache);
  // Both cleaned up automatically on completion/error/interruption
  yield* businessLogic(db, cache);
});
```

**Note**: evt-svc appropriately uses long-lived connections (ClickHouse client, HTTP clients). Scoped resources not needed for these cases.

---

## Testing Patterns (Already Good!)

### Mock Layers

The codebase already follows this pattern excellently - continue this approach:

```typescript
// ✅ Production layer
export const CtxSvcClientServiceLive = Layer.effect(
  CtxSvcClientService,
  Effect.gen(function* () {
    // Real implementation
  })
);

// ✅ Test layer (from ctx-svc-client.service.ts)
export const CtxSvcClientServiceTest = Layer.succeed(
  CtxSvcClientService,
  {
    saveContext: (playerId, contextData) =>
      Effect.gen(function* () {
        testContextStore.set(playerId, { /* mock data */ });
      })
  }
);

// ✅ Usage in tests
const test = Effect.gen(function* () {
  const result = yield* saveContext("player-1", {});
  expect(testContextStore.has("player-1")).toBe(true);
}).pipe(
  Effect.provide(CtxSvcClientServiceTest)
);
```

---

## Structured Logging

✅ **USE** `Effect.log*` functions instead of `console.log`
✅ **INCLUDE** semantic information (player IDs, operations, stages)

```typescript
// ✅ GOOD: Structured logging (already doing this well!)
yield* Effect.logInfo(`[CtxSvcClient] Saving context for player ${playerId}`);
yield* Effect.logDebug(`[QueryOrchestrator] Executing query`, { playerId, query });
yield* Effect.logError(`[EventHandler] Processing failed`, { eventType, error });

// ❌ BAD: Console logging
console.log("Saving context"); // Unstructured, no context
```

---

## Quick Anti-Patterns Checklist

When writing Effect-TS code, avoid these common mistakes:

- ❌ Using axios/fetch instead of `@effect/platform/HttpClient`
- ❌ Using `catchAll` with multiple specific error types
- ❌ Missing `Schema.decode` for external data
- ❌ Using `try/catch` inside `Effect.gen`
- ❌ Mixing `async/await` with Effect
- ❌ Plain variables for shared state (use `Ref` for atomic updates)
- ❌ Loading large datasets into memory (use `Stream` for pagination)
- ❌ Missing concurrency option in `Effect.all` (defaults to sequential!)
- ❌ Generic `Error` instead of `Data.TaggedError`
- ❌ Type assertions without `Schema` validation (`data as User`)
- ❌ Direct dependencies instead of services
- ❌ Testing with live dependencies (use mock layers)

---

## Additional Patterns

### Retry with Schedule

```typescript
import { Schedule } from 'effect';

// ✅ Composable retry policy
const retryPolicy = Schedule.exponential("100 millis").pipe(
  Schedule.jittered,
  Schedule.compose(Schedule.recurs(5))
);

const result = yield* flakyOperation.pipe(
  Effect.retry(retryPolicy)
);
```

### Option for Nullable Values

```typescript
import { Option } from 'effect';

// ✅ GOOD: Option instead of null/undefined
const findUser = (id: string): Option.Option<User> =>
  id === "1"
    ? Option.some({ id, name: "Alice" })
    : Option.none();

// Pattern matching
const result = Option.match(findUser("1"), {
  onNone: () => "User not found",
  onSome: (user) => `Found: ${user.name}`
});

// ❌ BAD: Using null
const findUser = (id: string): User | null =>
  id === "1" ? { id, name: "Alice" } : null;
```

---

## Related Resources

- **Full standards**: `.claude/skills/apply-effect-ts-standards/references/effect-ts.standards.md` (1963 lines - source of truth)
- **Active enforcement**: Use Effect-TS Standards skill for comprehensive audits
- **Examples**: `.claude/skills/apply-effect-ts-standards/examples/`
- **Templates**: `.claude/skills/apply-effect-ts-standards/templates/`
- **Current errors**: `src/evt-svc/src/errors.ts` (excellent reference for tagged errors)
- **Official docs**: https://effect.website

---

## Enforcement Notes

This rule file provides **passive enforcement** - it automatically loads when you edit Effect-TS service files and provides context-aware guidance.

For **active enforcement** (auditing existing code, refactoring workflows), use the Effect-TS Standards skill for comprehensive analysis and migration support.

**Last Updated**: 2026-03-04
**Standards Version**: Based on `.claude/skills/apply-effect-ts-standards/references/effect-ts.standards.md` v1.0 (2025-10-08)
