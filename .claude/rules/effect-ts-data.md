---
paths:
  - "src/agent-proxy-svc/**/*.ts"
  - "src/ctx-svc/**/*.ts"
  - "src/evt-svc/**/*.ts"
---

# Effect-TS Data Modeling & Validation

Standards for data types, schema validation, and naming conventions in Effect-TS services.

## Option — Optional Values

- Use `Option<A>` instead of `null`/`undefined` for optional values
- **Use `Option.isSome()` / `Option.isNone()` for checks** — NOT direct `_tag` comparison
- Use `Option.match({ onSome, onNone })` for complex branching
- Existing `_tag === 'Some'` checks in the codebase are **tech debt** (per ADR-0001) — new code MUST use helpers

```typescript
// ✅ NEW STANDARD: Option helpers
if (Option.isSome(existingState)) {
  const ownerId = existingState.value.ownerId
}

// ✅ Pattern matching for complex cases
const ownerId = Option.match(existingState, {
  onSome: (state) => state.ownerId,
  onNone: () => undefined
})

// ❌ DEPRECATED: Direct _tag checks (tech debt)
if (existingState._tag === 'Some') { ... }

// ❌ FORBIDDEN: null/undefined
function findUser(id: string): User | null { ... }
```

## Either — Error Accumulation

- Use `Either<E, A>` for validation that should accumulate multiple errors
- Use `Either.right` for success, `Either.left` for failure
- Use `Either.all` to collect all errors (not fail on first)
- Don't confuse with `Effect` — Either is for synchronous validation, Effect for async operations

## Brand Types — Domain Validation

- Use `Schema.brand("Name")` for domain-specific types (`Email`, `UserId`, `PositiveNumber`)
- Brand types prevent mixing semantically different values at compile time
- Always back brands with runtime validation via Schema

```typescript
// ✅ Branded type with validation
const EmailSchema = Schema.String.pipe(
  Schema.pattern(/^[^@]+@[^@]+$/),
  Schema.brand("Email")
)
type Email = Schema.Schema.Type<typeof EmailSchema>

// ❌ Plain type alias — no safety
type Email = string  // UserId is also string — they're interchangeable!
```

## Ref — Concurrent-Safe State

- Use `Ref<A>` for any mutable state shared between fibers
- `Ref.update` is atomic — no race conditions
- Never use plain `let` variables in concurrent Effect code

```typescript
// ✅ Atomic shared state
const counter = yield* Ref.make(0)
yield* Ref.update(counter, n => n + 1)  // Always atomic

// ❌ Race condition
let counter = 0
// concurrent Effect.all(() => counter++) — unpredictable!
```

## Chunk — Efficient Collections

- Use `Chunk` instead of `Array` when building collections with frequent appends
- `Chunk.append` is O(1) amortized; `[...arr, item]` is O(n)
- Use `Chunk` when working with streams

## Schema — Validation at Boundaries

- **Schema-first design**: Define `Schema.Struct` before implementation for all API contracts and domain models
- Derive TypeScript types from schemas: `type User = Schema.Schema.Type<typeof UserSchema>`
- Always validate external data with `Schema.decode` at system boundaries (API input, DB results, external APIs)
- Handle parse errors — `Schema.decode` returns an Effect that can fail

```typescript
// ✅ Schema-first
const UserSchema = Schema.Struct({
  id: Schema.Number,
  name: Schema.String,
  email: Schema.String.pipe(Schema.pattern(/^[^@]+@[^@]+$/)),
  age: Schema.Number.pipe(Schema.greaterThanOrEqualTo(0))
})
type User = Schema.Schema.Type<typeof UserSchema>

const parseUser = Schema.decode(UserSchema)
// Returns Effect that fails with ParseError on invalid data

// ❌ Unsafe cast
const user = data as User  // No runtime validation!
```

## Naming Conventions

| Kind | Convention | Example |
|------|-----------|---------|
| Services | PascalCase | `Database`, `HttpClient` |
| Layers | Service + `Live`/`Test` | `DatabaseLive`, `DatabaseTest` |
| Effects | camelCase functions | `findUser`, `processOrder` |
| Errors | PascalCase + `Error` | `NotFoundError`, `ValidationError` |
| Schemas | PascalCase + `Schema` | `UserSchema`, `ConfigSchema` |
