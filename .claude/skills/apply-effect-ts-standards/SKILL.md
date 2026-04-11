---
name: apply-effect-ts-standards
description: Audit and enforce Effect-TS coding standards across services. Validates HTTP client usage, error handling specificity, schema validation, and all patterns from .claude/skills/apply-effect-ts-standards/references/effect-ts.standards.md
---

# Effect-TS Standards Enforcement Skill

## CRITICAL RULES

- ✅ Focus on priority areas: HTTP client, error handling, schema validation
- ✅ Create detailed audit report before making any changes
- ✅ Get user approval before refactoring code
- ✅ Update tests alongside production code
- ✅ Reference `.claude/skills/apply-effect-ts-standards/references/effect-ts.standards.md` for complete standards (1963 lines)
- ❌ Do not make breaking changes without explicit user approval
- ❌ Do not refactor code unrelated to identified violations
- ❌ Do not skip validation steps (type-check, tests)

## Instructions

### Step 0: Notify User

Inform the user: **"Using the Effect-TS Standards Enforcement Skill"**

### Step 1: Scope Identification

1. Ask user to specify audit scope:
   - **Quick audit** (default) - Priority areas only (HTTP client, error handling, schema validation)
   - **Full audit** - All standards from guide
   - **Specific service(s)** - evt-svc, ctx-svc, aurora-ai, or specific files

2. If user doesn't specify, use: **Quick audit of all Effect-TS services**

3. Confirm scope with user before proceeding

### Step 2: Standards Validation

Run these checks based on audit mode:

#### 2.1 HTTP Client Check (PRIORITY 1 - Always Run)

**Objective**: Find all axios/fetch usage and categorize violations

**Detection:**
1. Search for `import axios` or `import.*from.*'axios'` in service files
2. Search for `import.*fetch` or `node-fetch` imports
3. For each occurrence:
   - Record: file path, line number
   - Identify: HTTP operations (GET, POST, PUT, DELETE)
   - Check: Effect wrapper usage (Effect.tryPromise)
   - Verify: Using @effect/platform or axios

**Categorization:**
- 🔴 **Critical**: Direct axios/fetch usage without Effect wrapper
- 🟡 **Moderate**: Using Effect.tryPromise with axios (but not @effect/platform)
- 🟢 **Good**: Using `@effect/platform/HttpClient`

**Known Locations** (check these first):
- `src/evt-svc/src/services/ctx-svc-client.service.ts:5,71-77`
- `src/evt-svc/src/services/agent-proxy-svc-client.service.ts`
- `src/evt-svc/src/services/cc-svc-client.service.ts`
- `src/ctx-svc/**/*.ts` (if auditing ctx-svc)
- `src/aurora-ai/**/*.ts` (if auditing aurora-ai)

**Example:**
```bash
# Search commands to run
grep -rn "import axios" src/evt-svc/src/services/
grep -rn "axios.create" src/evt-svc/src/services/
grep -rn "import.*fetch" src/evt-svc/src/services/
```

#### 2.2 Error Handling Specificity Check (PRIORITY 2 - Always Run)

**Objective**: Find catchAll usage and verify if specific error handling is appropriate

**Detection:**
1. Search for `.pipe(Effect.catchAll` patterns
2. For each occurrence:
   - Extract surrounding context (20 lines before/after)
   - Identify the Effect's error type signature
   - Count number of error types in union
   - Verify if catchAll is justified

**Analysis:**
- If error signature is `Effect.Effect<A, E1 | E2 | E3, R>` → catchAll is likely wrong
- If error signature is `Effect.Effect<A, UnknownError, R>` → catchAll may be justified
- If only one error type → should use catchTag

**Categorization:**
- 🔴 **Critical**: catchAll with 2+ specific tagged error types
- 🟡 **Moderate**: catchAll with single specific error type (should use catchTag)
- 🟢 **Good**: Using catchTag/catchTags, or justified catchAll for truly unknown errors

**Known Locations** (check these first):
- `src/evt-svc/src/services/event-handler.service.ts:84-90,302`
- Any service file with complex error handling

**Example:**
```bash
# Search commands to run
grep -rn "Effect.catchAll" src/evt-svc/src/services/
grep -rn "pipe(Effect.catchAll" src/evt-svc/src/services/
```

#### 2.3 Schema Validation Check (PRIORITY 3 - Always Run)

**Objective**: Ensure all external data is validated with Schema.decode

**Detection:**
1. Find all HTTP client method calls (axios, fetch, Http.get/post)
2. Find all pub/sub message handlers
3. Find all database query result processing
4. For each external data entry point:
   - Check: Is there a Schema definition?
   - Check: Is `Schema.decode` or `Schema.decodeUnknownEither` used?
   - Check: Is parse error handling present?

**Categorization:**
- 🔴 **Critical**: No schema validation for external data
- 🟡 **Moderate**: Schema exists but not consistently used
- 🟢 **Good**: Full validation with Schema.decode + error handling

**Missing Validations** (check for these):
- HTTP responses from ctx-svc (`/context/:id`, `/context/:id/embeddings`, etc.)
- HTTP responses from agent-proxy-svc
- HTTP responses from cc-svc
- ClickHouse query results in query-orchestrator
- NATS pub/sub messages (may already be validated - verify)

**Example:**
```bash
# Search for HTTP calls without schema validation
grep -rn "response.data" src/evt-svc/src/services/
grep -rn "Http.get\|Http.post" src/evt-svc/src/services/
grep -rn "Schema.decode" src/evt-svc/src/services/
```

#### 2.4 Full Standards Check (Only if Full Audit Selected)

If user requested full audit, additionally check:

**Effect.gen Usage:**
- Multi-step workflows using Effect.gen (not long flatMap chains)
- No try/catch blocks inside Effect.gen

**Service Architecture:**
- All external dependencies as services (Context.Tag)
- Services constructed with Layer.effect
- Test layers available (ServiceTest)

**Concurrency:**
- Effect.all calls include { concurrency: "unbounded" } or { concurrency: N }
- Independent operations run in parallel

**Resource Management:**
- Long-lived resources managed appropriately
- Use of acquireRelease for transient resources

**Logging:**
- Effect.log* functions used (not console.log)
- Structured logging with context

**Testing:**
- Mock layers for all services
- No testing with live dependencies

### Step 3: Generate Audit Report

Create a comprehensive markdown report with the following structure:

```markdown
# Effect-TS Standards Audit Report

**Date:** [YYYY-MM-DD HH:MM]
**Services Audited:** [list of services/files]
**Audit Mode:** [Quick | Full]

## Executive Summary

- 🔴 **Critical Issues**: [count] - Require immediate attention
- 🟡 **Moderate Issues**: [count] - Should be addressed soon
- 🟢 **Compliant Patterns**: [count] - Following standards correctly

### Quick Assessment

[1-2 sentences summarizing overall code quality and primary concerns]

---

## Priority 1: HTTP Client Migration

### Critical Issues ([count])

| File | Line | Current Pattern | Required Action |
|------|------|-----------------|-----------------|
| ctx-svc-client.service.ts | 5, 71-77 | `axios.create()` | Migrate to @effect/platform HttpClient |
| agent-proxy-svc-client.service.ts | 4, 76-82 | `axios.create()` | Migrate to @effect/platform HttpClient |
| [other files...] | ... | ... | ... |

### Moderate Issues ([count])

| File | Line | Current Pattern | Recommended Action |
|------|------|-----------------|-------------------|
| [file] | [line] | `Effect.tryPromise` with axios | Refactor to @effect/platform |
| ... | ... | ... | ... |

### Migration Effort Estimate

- **Files to update**: [count]
- **Total lines to change**: ~[estimate]
- **Breaking changes**: [Yes/No - explain scope]
- **Estimated time**: [hours/days]

### Migration Pattern

```typescript
// BEFORE (Current axios pattern)
import axios from 'axios';

const httpClient = axios.create({
  baseURL: ctxSvcBaseUrl,
  timeout: 30000,
  headers: { 'Content-Type': 'application/json' }
});

const result = yield* Effect.tryPromise({
  try: async () => {
    const response = await httpClient.request({ method, url, data });
    return response.data;
  },
  catch: (error: unknown) => {
    const errorMessage = (error as any)?.response?.data?.error || String(error);
    return new PersistenceError({ playerId: 'unknown', operation: 'http-invoke', /* ... */ });
  }
});

// AFTER (Required @effect/platform pattern)
import * as Http from "@effect/platform/HttpClient";
import { Schedule } from 'effect';

const result = yield* Http.request(method)(url).pipe(
  Http.client.setHeaders({ 'Content-Type': 'application/json' }),
  data ? Http.client.setBody(JSON.stringify(data)) : Effect.identity,
  Http.client.execute,
  Effect.flatMap(response => response.json),
  Effect.retry(
    Schedule.exponential("100 millis").pipe(
      Schedule.compose(Schedule.recurs(3))
    )
  ),
  Effect.timeout("30 seconds"),
  Effect.mapError(error =>
    new PersistenceError({
      playerId: 'unknown',
      operation: 'http-invoke',
      storeType: 'http',
      cause: error
    })
  )
);
```

### Why This Matters

- ✅ Better integration with Effect's error channel
- ✅ Type-safe error handling
- ✅ Built-in retry and timeout composition
- ✅ Structured concurrency benefits
- ✅ Easier testing with mock HTTP clients
- ❌ Axios bypasses Effect's type system and error handling

---

## Priority 2: Error Handling Specificity

### Critical Issues ([count])

| File | Line | Current Pattern | Required Action |
|------|------|-----------------|-----------------|
| event-handler.service.ts | 84-90 | `catchAll` with `WorkflowNotFoundError` | Use `catchTag("WorkflowNotFoundError")` |
| event-handler.service.ts | 302 | `catchAll` | Replace with `catchTag` or `catchTags` |
| [other files...] | ... | ... | ... |

### Refactoring Pattern

```typescript
// BEFORE (Current pattern - event-handler.service.ts line 84-90)
const workflow = yield* workflowConfig.getWorkflow(event.eventType).pipe(
  Effect.catchAll(() =>
    Effect.gen(function* () {
      yield* Effect.logWarning(`No workflow found for ${event.eventType}`);
      return null;
    })
  )
);

// AFTER (Required pattern - specific error handling)
const workflow = yield* workflowConfig.getWorkflow(event.eventType).pipe(
  Effect.catchTag("WorkflowNotFoundError", (e) =>
    Effect.gen(function* () {
      yield* Effect.logWarning(`No workflow for ${e.eventType}`);
      return null;
    })
  )
);

// For multiple error types, use catchTags:
const result = yield* operation.pipe(
  Effect.catchTags({
    WorkflowNotFoundError: (e) => handleNotFound(e),
    WorkflowConfigError: (e) => handleConfigError(e),
    ValidationError: (e) => handleValidation(e)
  })
);
```

### Why This Matters

- ✅ Type-safe error handling (compiler checks error types)
- ✅ Explicit handling of each error case
- ✅ No silent failures or missed error types
- ✅ Better debugging (know exactly which error occurred)
- ❌ catchAll loses type information and may hide bugs

---

## Priority 3: Schema Validation

### Missing Validations ([count])

| Service | Endpoint/Source | Data Type | Required Schema |
|---------|-----------------|-----------|-----------------|
| ctx-svc-client | `GET /context/:id` | HTTP response | `PlayerContextResponseSchema` |
| ctx-svc-client | `POST /context/:id` | HTTP response | `SaveContextResponseSchema` |
| ctx-svc-client | `POST /context/:id/embeddings` | HTTP response | `SaveEmbeddingsResponseSchema` |
| agent-proxy-svc-client | Various endpoints | HTTP response | Define schemas per endpoint |
| cc-svc-client | Various endpoints | HTTP response | Define schemas per endpoint |
| query-orchestrator | ClickHouse results | Database | `ClickHouseResultSchema` |
| ... | ... | ... | ... |

### Schema Definition Pattern

```typescript
import { Schema } from '@effect/schema';

// Define schemas for ctx-svc responses
const PlayerContextResponseSchema = Schema.Struct({
  context: Schema.Union(
    Schema.Record(Schema.String, Schema.Unknown),
    Schema.Null
  ),
  embeddings: Schema.Array(
    Schema.Struct({
      id: Schema.String,
      playerId: Schema.String,
      fieldName: Schema.String,
      embedding: Schema.Array(Schema.Number),
      sourceText: Schema.String,
      embeddingModel: Schema.String,
      createdAt: Schema.Date
    })
  )
});

const SaveContextResponseSchema = Schema.Struct({
  message: Schema.String,
  playerId: Schema.String
});

// Use in HTTP client
const getContext = (playerId: string) =>
  Http.get(`${baseUrl}/context/${playerId}`).pipe(
    Http.client.execute,
    Effect.flatMap(r => r.json),
    Effect.flatMap(Schema.decode(PlayerContextResponseSchema)),
    Effect.mapError(error =>
      new PersistenceError({
        playerId,
        operation: 'load',
        storeType: 'http',
        cause: error
      })
    )
  );
```

### Why This Matters

- ✅ Runtime validation prevents type errors
- ✅ Early detection of API contract changes
- ✅ Self-documenting code (schema = contract)
- ✅ Better error messages for invalid data
- ❌ Without schemas, invalid data causes cryptic runtime errors

---

[If Full Audit]

## Additional Standards Checks

### Effect.gen Usage
- ✅ [count] files using Effect.gen correctly
- ❌ [count] files with long flatMap chains (should use Effect.gen)

### Service Architecture
- ✅ [count] services following Context.Tag pattern
- ❌ [count] direct dependencies (should be services)

### Concurrency
- ✅ [count] Effect.all calls with explicit concurrency
- ❌ [count] Effect.all calls missing concurrency option

### Testing
- ✅ [count] services with Test layers
- ❌ [count] services missing Test layers

[End Full Audit Section]

---

## Recommendations

### Immediate Actions (This Sprint)

1. **HTTP Client Migration** - Highest priority, internal-only breaking changes
   - Files: [list specific files]
   - Impact: Internal services only, no public API changes
   - Risk: Low (comprehensive tests exist)

2. **Error Handling Specificity** - Quick wins, improves type safety
   - Files: [list specific files]
   - Impact: Better error handling, no behavior changes
   - Risk: Very low

3. **Schema Validation** - Important for data integrity
   - Services: [list services]
   - Impact: Catches invalid data earlier
   - Risk: Medium (may expose existing data issues)

### Recommended Sequence

**Phase 1: HTTP Client Migration** (1-2 days)
- Start with ctx-svc-client.service.ts (most critical)
- Then agent-proxy-svc-client and cc-svc-client
- Update tests for each service
- Validate with integration tests

**Phase 2: Error Handling** (0.5-1 day)
- Refactor catchAll to catchTag/catchTags
- Verify error signatures are correct
- Update tests for error scenarios

**Phase 3: Schema Validation** (1-2 days)
- Define schemas for all HTTP responses
- Add Schema.decode to client methods
- Handle parse errors appropriately
- Update tests with schema validation

**Total Estimated Time**: 2.5-5 days

---

## Next Steps

Would you like me to:

1. **Migrate HTTP clients** (recommended first)
   - Files: [list]
   - Show before/after diffs for approval

2. **Refactor error handling** (quick wins)
   - Files: [list]
   - Show specific catchAll → catchTag changes

3. **Add schema validation** (data integrity)
   - Services: [list]
   - Define schemas and integrate

4. **All of the above** (recommended sequence: 1 → 2 → 3)
   - Complete migration in phases
   - Validate after each phase

5. **Custom selection**
   - You choose which files/patterns to address

Please confirm how you'd like to proceed, or ask for more details on any specific area.
```

### Step 4: Wait for User Approval

**Do not proceed with refactoring without explicit user approval.**

Ask the user:
1. Do you approve this audit report?
2. Which issues would you like to address?
3. What sequence should we follow?
4. Should I proceed automatically or show diffs for each change?

### Step 5: Interactive Refactoring (Only After Approval)

For each approved change:

1. **Show Before/After Diff**
   - Display current code
   - Display proposed refactored code
   - Explain the change

2. **Get Confirmation**
   - Wait for user OK before applying

3. **Apply Change**
   - Use Edit tool to make the change
   - Keep changes focused (one pattern at a time)

4. **Update Related Tests**
   - Modify test files to match new patterns
   - Update mock implementations

5. **Validate**
   - Run type check: `cd src/<service> && npm run type-check`
   - Run tests: `cd src/<service> && npm run test`
   - Report any failures immediately

6. **Document**
   - Add inline comments explaining Effect-TS patterns
   - Update function/service documentation if needed

### Step 6: Final Validation

After all approved changes:

1. **Type Checking**: `cd src/<service> && npm run type-check`
2. **Unit Tests**: `cd src/<service> && npm run test`
3. **Integration Tests**: `cd src/<service> && npm run test:integration` (if available)
4. **Linting**: `cd src/<service> && npm run lint`

Report results to user with:
- ✅ What passed
- ❌ What failed (with details)
- 📝 Recommendations for fixes

### Step 7: Documentation

Update as needed (ask user first):

1. **Inline comments** - Explain non-obvious Effect-TS patterns
2. **Service documentation** - Update if architecture changed
3. **CHANGELOG.md** - Note significant refactorings (if user requests)
4. **Design docs** - Update if architectural patterns changed

## Migration Examples

### Example 1: HTTP Client Migration

**See**: `.claude/skills/apply-effect-ts-standards/examples/http-client-migration.example.ts`

This example shows a complete before/after migration based on `ctx-svc-client.service.ts`:
- Replace axios imports with @effect/platform imports
- Replace axios.create() with Http.request()
- Replace Effect.tryPromise with Http.client.execute
- Add retry policies with Schedule
- Add timeout handling
- Map axios errors to domain errors
- Update both Live and Test layer implementations

### Example 2: Error Handling Specificity

**See**: `.claude/skills/apply-effect-ts-standards/examples/error-handling-specific.example.ts`

This example demonstrates:
- catchAll → catchTag migration for single error types
- catchAll → catchTags migration for multiple error types
- When catchAll is appropriate (genuinely unknown errors from external libraries)
- Error type discrimination and recovery strategies

### Example 3: Schema Validation

**See**: `.claude/skills/apply-effect-ts-standards/examples/schema-validation.example.ts`

This example shows:
- Schema definition for HTTP responses
- Schema.decode usage with error handling
- Branded types for domain validation
- Integration with HTTP client pipeline
- Parse error mapping to domain errors

## Templates

### Error Types Template

**See**: `.claude/skills/apply-effect-ts-standards/templates/error-types.template.ts`

Copy-paste template for creating new tagged errors based on the excellent patterns in `src/evt-svc/src/errors.ts`.

### HTTP Service Template

**See**: `.claude/skills/apply-effect-ts-standards/templates/http-service.template.ts`

Complete HTTP client service template with:
- Context.Tag service definition
- Layer.effect Live implementation
- Layer.succeed Test implementation
- @effect/platform HttpClient usage
- Retry policies and timeout handling
- Schema validation
- Error mapping

### Schema Definitions Template

**See**: `.claude/skills/apply-effect-ts-standards/templates/schema-definitions.template.ts`

Patterns for defining schemas:
- Request/Response schemas
- Branded types
- Schema composition
- Type extraction

## Related Resources

- **Full standards**: `.claude/skills/apply-effect-ts-standards/references/effect-ts.standards.md` (1963 lines - source of truth)
- **Passive enforcement**: `.claude/rules/effect-ts-standards.md` (auto-loads for all Effect-TS files)
- **Examples**: `.claude/skills/apply-effect-ts-standards/examples/`
- **Templates**: `.claude/skills/apply-effect-ts-standards/templates/`
- **Current errors**: `src/evt-svc/src/errors.ts` (excellent tagged error reference)
- **Official docs**: https://effect.website
- **Effect patterns**: https://github.com/effect-ptrns

## Usage Tips

**When to use this skill:**
- Before starting work on an Effect-TS service
- After receiving pull request feedback about Effect patterns
- When refactoring existing services to Effect-TS
- Periodically (monthly) to catch drift from standards

**Quick audit command:**
Just invoke the skill and answer the scope questions. Default is a quick audit of all services.

**Focused audit:**
Specify a single service or file for targeted analysis.

**Full audit:**
Request comprehensive analysis against all standards in the guide (takes longer, more thorough).
