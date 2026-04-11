---
paths:
  - "src/agent-proxy-svc/**/*.ts"
  - "src/ctx-svc/**/*.ts"
  - "src/evt-svc/**/*.ts"
---

# Effect-TS Infrastructure Patterns

Standards for HTTP, observability, testing, streams, and performance in Effect-TS services.

## HTTP Client

- Use `@effect/platform` `HttpClient` instead of raw `fetch`
- Wrap HTTP calls in a testable service abstraction (Effect.Service) — never embed `Http.get` directly in business logic
- Always add `Effect.retry(policy)` and `Effect.timeout` for external calls

```typescript
// ✅ Testable HTTP service
export class ApiClient extends Effect.Service<ApiClient>()("ApiClient", {
  sync: () => ({
    getUser: (id: string) =>
      Http.get(`/users/${id}`).pipe(
        Http.client.execute,
        Effect.flatMap(r => r.json),
        Effect.flatMap(Schema.decode(UserSchema)),
        Effect.retry(retryPolicy),
        Effect.timeout("5 seconds")
      )
  })
}) {}

// ❌ Raw fetch in business logic
const user = yield* Effect.tryPromise(() => fetch(`/users/${id}`))
```

## Observability

### Structured Logging

- Use `Effect.logInfo`, `Effect.logDebug`, `Effect.logError`, `Effect.logWarning` — **never `console.log`** in Effect code
- Include structured data as the second argument
- Use appropriate log levels

```typescript
// ✅ Structured logging
yield* Effect.logInfo("Processing user", { userId: 123 })
yield* Effect.logError("Operation failed", { error: err })

// ❌ console.log — unstructured, no context
console.log("Processing user")
```

### Tracing Spans

- Add `Effect.withSpan("name", { attributes })` to critical operations
- Nest spans for distributed tracing — child spans inherit parent context
- Include meaningful attributes (IDs, operation names)

```typescript
// ✅ Span with attributes
const fetchUser = (id: string) =>
  Effect.gen(function* () {
    return yield* database.query(id)
  }).pipe(
    Effect.withSpan("database.fetchUser", { attributes: { userId: id } })
  )
```

### Metrics

- Use `Metric.counter` for counting events, `Metric.histogram` for durations
- Track request counts, error rates, and operation latencies

## Testing

- **Mock dependencies via test Layers** — never use live services in unit tests
- Create `*Test` layers with controlled responses: `Layer.succeed(Database, { findUser: () => Effect.succeed(mockUser) })`
- Test error scenarios with failing mock layers
- Use `Effect.provide(MockLayer)` to inject test dependencies

```typescript
// ✅ Mock layer for testing
const MockDatabase = Layer.succeed(Database, {
  findUser: (id: string) =>
    id === "1"
      ? Effect.succeed({ id, name: "Test User" })
      : Effect.fail(new NotFoundError({ id }))
})

const test = Effect.gen(function* () {
  const result = yield* findUser("1")
  expect(result.name).toBe("Test User")
}).pipe(Effect.provide(MockDatabase))

// ❌ Real database in unit tests — slow, unpredictable
```

## Stream Processing

- Use `Stream` for large datasets, paginated APIs, WebSocket messages, event streams
- Use `Stream.acquireRelease` for resources in streams (file handles, cursors) — never leave streams unclosed
- Use `Stream.mapEffect` with `{ concurrency: N }` for parallel processing of stream elements
- Use `Stream.grouped(N)` for batch processing

```typescript
// ✅ Paginated API as stream
const userStream = Stream.paginateEffect(0, page =>
  fetchPage(page).pipe(
    Effect.map(r => [r.users, Option.fromNullable(r.nextPage)])
  )
)

// ✅ Concurrent stream processing
const results = userStream.pipe(
  Stream.mapEffect(user => enrichUser(user), { concurrency: 5 })
)

// ❌ Load everything into memory
const allUsers = []
while (hasMore) { allUsers.push(...(yield* fetchPage(page++))) }
```

## Performance

### Singleton Runtime

- **Build `AppRuntime` once at startup** from composed layers, reuse for all effects
- Never rebuild layers per request — this is the established project pattern

```typescript
// ✅ Build once, reuse (project pattern)
const AppRuntime = await Effect.runPromise(
  Layer.toRuntime(Layer.merge(DatabaseLive, LoggerLive, ConfigLive))
)
// Reuse for every request
await Runtime.runPromise(AppRuntime)(handleRequest(req))

// ❌ Rebuilding per request
app.get("/", async (req, res) => {
  await Effect.runPromise(
    handler.pipe(Effect.provide(DatabaseLive), Effect.provide(LoggerLive))
    // Reconstructs layers every request!
  )
})
```

### Other Performance Rules

- Use `Effect.gen` over long `.pipe(Effect.flatMap(...))` chains — better readability with same performance
- Use `Chunk` over `Array` for append-heavy collection building (see data rules)
- Set bounded concurrency (`{ concurrency: 5 }`) instead of `"unbounded"` for resource-limited operations (DB connections, external APIs)
