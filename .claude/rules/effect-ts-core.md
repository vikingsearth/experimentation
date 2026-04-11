---
paths:
  - "src/agent-proxy-svc/**/*.ts"
  - "src/ctx-svc/**/*.ts"
  - "src/evt-svc/**/*.ts"
---

# Effect-TS Core Patterns

Standards for composition, error handling, dependency injection, concurrency, and resource management in Effect-TS services.

## Composition: Effect.gen vs .pipe

- Use `Effect.gen` for **all sequential business logic** (multi-step workflows, conditional branching)
- Use `.pipe` for **transformations and wrappers** (`Effect.map`, `Effect.tap`, `Effect.catchTag`, `Effect.withSpan`, `Effect.timeout`, `Effect.retry`)
- Combine both: `Effect.gen` for logic body, `.pipe` for error handling outside

```typescript
// ✅ Effect.gen for sequential logic, .pipe for error handling
const createUser = (data: unknown) =>
  Effect.gen(function* () {
    const validated = yield* validateUser(data)
    const hashed = yield* hashPassword(validated.password)
    return yield* db.createUser({ ...validated, password: hashed })
  }).pipe(
    Effect.catchTag("ValidationError", handleValidation),
    Effect.catchAll(handleGeneric)
  )
```

### Forbidden

- **Never nest flatMap chains** — use `Effect.gen` instead of `.pipe(Effect.flatMap(x => ... Effect.flatMap(...)))` callback hell
- **Never nest Effect.gen inside Effect.gen** for error handling — use `.pipe(Effect.catchTag(...))` outside
- **Never use `async/await`** with Effect — use `Effect.gen` + `yield*`
- **Never use `try/catch`** inside `Effect.gen` — use `Effect.tryPromise` for external calls

## Error Handling

- Define errors with `Data.TaggedError` — never use generic `Error` or untagged errors
- Use `Effect.catchTag` for specific error recovery, `Effect.catchAll` for catch-all
- Map errors to domain types at service boundaries with `Effect.mapError`
- Wrap external/Promise calls with `Effect.tryPromise` and a tagged error

```typescript
// ✅ Tagged error definition
class DbError extends Data.TaggedError("DbError")<{
  readonly message: string
  readonly cause?: unknown
}> {}

// ✅ Wrapping external calls
const query = (sql: string) =>
  Effect.tryPromise({
    try: () => pool.query(sql),
    catch: (cause) => new DbError({ message: "Query failed", cause })
  })
```

### Forbidden

- Generic `new Error("...")` — always use `Data.TaggedError`
- Letting external library errors leak into domain — map at boundaries
- `try/catch` blocks — use `Effect.tryPromise` or `Effect.catchTag`

## Dependency Injection

- Model dependencies as services using `Effect.Service` (or `Context.Tag`)
- Provide implementations via `Layer.succeed` (sync) or `Layer.effect` (async)
- Compose layers with `Layer.merge` — never use constructor injection
- Name layers: `*Live` for production, `*Test` for mocks

```typescript
// ✅ Service definition
class Database extends Effect.Service<Database>()("Database", {
  sync: () => ({
    findUser: (id: string) => Effect.tryPromise({ ... })
  })
}) {}

// ✅ Layer composition
const AppLive = Layer.merge(DatabaseLive, LoggerLive, ConfigLive)
```

### Forbidden

- Resolving the same service multiple times in one function — resolve once and reuse
- Constructor injection or manual instantiation — use Layers
- Direct imports of concrete implementations — depend on service interfaces

## Concurrency

- Use `Effect.all` with **explicit `{ concurrency }` option** for parallel independent effects — the default is sequential
- Use `Effect.fork` for background tasks, `Fiber.join` to await
- Use `Schedule.exponential` + `Schedule.jittered` for retry policies — never write manual retry loops
- Use `Effect.race` for timeout/fallback patterns

```typescript
// ✅ Parallel execution (default is sequential!)
const [user, posts, comments] = yield* Effect.all(
  [fetchUser, fetchPosts, fetchComments],
  { concurrency: "unbounded" }
)

// ✅ Composable retry
const policy = Schedule.exponential("100 millis").pipe(
  Schedule.jittered,
  Schedule.compose(Schedule.recurs(5))
)
const result = yield* Effect.retry(flakyOp, policy)
```

### Forbidden

- `Effect.all([...])` without `{ concurrency }` when tasks are independent — it's sequential by default
- Manual retry loops with sleep — use `Schedule`
- Plain variables for shared state in concurrent code — use `Ref`

## Resource Management

- Use `Effect.acquireRelease` or `Effect.acquireUseRelease` for all resources (connections, file handles)
- Resources are cleaned up automatically on error, interruption, or completion
- Compose scoped resources with `Effect.scoped`

```typescript
// ✅ Scoped resource
const managedPool = Effect.acquireRelease(
  createPool(config),
  (pool) => Effect.promise(() => pool.end())
)

const program = Effect.scoped(
  Effect.gen(function* () {
    const pool = yield* managedPool
    return yield* runQueries(pool)
    // pool.end() called automatically
  })
)
```

### Forbidden

- Manual `try/finally` for cleanup — use `acquireRelease`
- Forgetting cleanup on error paths — `acquireRelease` guarantees it
- Opening resources without a finalizer

## Anti-Patterns Checklist

| Don't | Do Instead |
|-------|-----------|
| `try/catch` inside `Effect.gen` | `Effect.tryPromise` + tagged error |
| `async/await` with Effect | `Effect.gen` + `yield*` |
| `new Error("msg")` | `Data.TaggedError("Tag")<{...}>` |
| Nested `flatMap` chains | `Effect.gen` for sequential logic |
| `Effect.all([...])` (no concurrency) | `Effect.all([...], { concurrency })` |
| Manual retry with `setTimeout` | `Schedule.exponential` + `Effect.retry` |
| `let counter = 0` in concurrent code | `Ref.make(0)` + `Ref.update` |
| Constructor injection | `Layer.succeed` / `Layer.effect` |
