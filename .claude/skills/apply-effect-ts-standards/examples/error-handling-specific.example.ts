/**
 * Error Handling Specificity Example
 *
 * This file demonstrates the migration from catchAll to catchTag/catchTags
 * Based on patterns from src/evt-svc/src/services/event-handler.service.ts
 *
 * BEFORE: Uses catchAll (loses type information)
 * AFTER: Uses catchTag/catchTags (type-safe, explicit)
 */

import { Effect } from 'effect';
import { Data } from 'effect';

// ============================================================================
// Error Definitions (from src/evt-svc/src/errors.ts)
// ============================================================================

export class WorkflowNotFoundError extends Data.TaggedError('WorkflowNotFoundError')<{
  readonly eventType: string;
}> {}

export class WorkflowConfigError extends Data.TaggedError('WorkflowConfigError')<{
  readonly eventType: string;
  readonly cause: unknown;
  readonly operation: 'load' | 'save' | 'validate';
}> {}

export class InvalidWorkflowError extends Data.TaggedError('InvalidWorkflowError')<{
  readonly eventType: string;
  readonly reason: string;
  readonly validationErrors?: Array<string>;
}> {}

export class NetworkError extends Data.TaggedError('NetworkError')<{
  readonly endpoint: string;
  readonly cause: unknown;
}> {}

export class DatabaseError extends Data.TaggedError('DatabaseError')<{
  readonly query: string;
  readonly cause: unknown;
}> {}

// Error union
export type WorkflowError = WorkflowNotFoundError | WorkflowConfigError | InvalidWorkflowError;

// ============================================================================
// Mock Service Methods
// ============================================================================

interface WorkflowConfig {
  eventType: string;
  queries: string[];
  mappings: Record<string, string>;
}

declare const getWorkflow: (
  eventType: string
) => Effect.Effect<WorkflowConfig, WorkflowNotFoundError | WorkflowConfigError>;

declare const validateWorkflow: (
  workflow: WorkflowConfig
) => Effect.Effect<WorkflowConfig, InvalidWorkflowError>;

declare const fetchFromAPI: (
  url: string
) => Effect.Effect<unknown, NetworkError>;

declare const queryDatabase: (
  sql: string
) => Effect.Effect<unknown[], DatabaseError>;

// ============================================================================
// EXAMPLE 1: Single Error Type - WorkflowNotFoundError
// ============================================================================

// --- BAD: Using catchAll for single error type (line 84-90 of event-handler.service.ts) ---
const loadWorkflowBad = (eventType: string): Effect.Effect<WorkflowConfig | null, never> =>
  getWorkflow(eventType).pipe(
    Effect.catchAll(() =>
      Effect.gen(function* () {
        yield* Effect.logWarning(`No workflow found for ${eventType}`);
        return null;
      })
    )
  );

// Problems with catchAll:
// - Loses type information (what error was it?)
// - Catches ALL errors, even ones we don't expect
// - Can silently hide bugs (e.g., WorkflowConfigError also caught)

// --- GOOD: Using catchTag for specific error type ---
const loadWorkflowGood = (eventType: string): Effect.Effect<WorkflowConfig | null, WorkflowConfigError> =>
  getWorkflow(eventType).pipe(
    Effect.catchTag('WorkflowNotFoundError', (e) =>
      Effect.gen(function* () {
        yield* Effect.logWarning(`No workflow for ${e.eventType}`);
        return null;
      })
    )
  );

// Benefits:
// - ✅ Type-safe: Only catches WorkflowNotFoundError
// - ✅ Other errors (WorkflowConfigError) propagate to caller
// - ✅ Error context available (e.eventType)
// - ✅ Compiler checks error type

// ============================================================================
// EXAMPLE 2: Multiple Error Types - Using catchTags
// ============================================================================

// --- BAD: Using catchAll for multiple error types ---
const processWorkflowBad = (eventType: string): Effect.Effect<WorkflowConfig | null, never> =>
  Effect.gen(function* () {
    const workflow = yield* getWorkflow(eventType);
    const validated = yield* validateWorkflow(workflow);
    return validated;
  }).pipe(
    Effect.catchAll((error) => {
      // ❌ No type information - what kind of error is this?
      // ❌ Can't distinguish between error types
      // ❌ All errors handled the same way (bad!)
      return Effect.gen(function* () {
        yield* Effect.logError(`Workflow processing failed: ${error}`);
        return null;
      });
    })
  );

// --- GOOD: Using catchTags for specific handling ---
const processWorkflowGood = (
  eventType: string
): Effect.Effect<WorkflowConfig | null, WorkflowConfigError> =>
  Effect.gen(function* () {
    const workflow = yield* getWorkflow(eventType);
    const validated = yield* validateWorkflow(workflow);
    return validated;
  }).pipe(
    Effect.catchTags({
      WorkflowNotFoundError: (e) =>
        Effect.gen(function* () {
          yield* Effect.logWarning(`No workflow for ${e.eventType}`);
          return null; // Graceful fallback
        }),

      InvalidWorkflowError: (e) =>
        Effect.gen(function* () {
          yield* Effect.logError(`Invalid workflow for ${e.eventType}: ${e.reason}`);
          if (e.validationErrors) {
            yield* Effect.logDebug(`Validation errors: ${e.validationErrors.join(', ')}`);
          }
          return null; // Graceful fallback
        }),

      // Note: WorkflowConfigError is NOT caught here - it propagates to caller
      // This is intentional - config errors are more serious and should bubble up
    })
  );

// Benefits:
// - ✅ Each error type handled explicitly
// - ✅ Different recovery strategies per error
// - ✅ Unhandled errors (WorkflowConfigError) propagate
// - ✅ Full type safety and error context

// ============================================================================
// EXAMPLE 3: When catchAll is Appropriate
// ============================================================================

// Sometimes catchAll IS the right choice - when dealing with truly unknown errors:

// ✅ GOOD: catchAll for external library without typed errors
const callExternalLibrary = (): Effect.Effect<unknown, never> =>
  Effect.tryPromise({
    try: async () => {
      // Some external library that throws random errors
      const result = await someExternalLibrary.doSomething();
      return result;
    },
    catch: (error) => error, // Unknown error type
  }).pipe(
    Effect.catchAll((error) =>
      // This is OK - we genuinely don't know what error types are possible
      Effect.gen(function* () {
        yield* Effect.logError(`External library failed: ${error}`);
        return null;
      })
    )
  );

// ✅ GOOD: catchAll for logging/debugging (then re-throw)
const debugOperation = <A, E, R>(
  operation: Effect.Effect<A, E, R>
): Effect.Effect<A, E, R> =>
  operation.pipe(
    Effect.catchAll((error) =>
      Effect.gen(function* () {
        // Log all errors for debugging
        yield* Effect.logError(`Operation failed with error: ${JSON.stringify(error)}`);
        // Re-throw to preserve error handling
        return yield* Effect.fail(error as E);
      })
    )
  );

// ⚠️ QUESTIONABLE: catchAll when you should be more specific
const loadDataQuestionable = (): Effect.Effect<unknown, never> =>
  Effect.gen(function* () {
    const fromAPI = yield* fetchFromAPI('/data');
    const fromDB = yield* queryDatabase('SELECT * FROM data');
    return { fromAPI, fromDB };
  }).pipe(
    Effect.catchAll((error) => {
      // ❌ This catches both NetworkError AND DatabaseError
      // ❌ Should use catchTags to handle them differently
      return Effect.succeed(null);
    })
  );

// ✅ BETTER: Specific error handling
const loadDataBetter = (): Effect.Effect<unknown, never> =>
  Effect.gen(function* () {
    const fromAPI = yield* fetchFromAPI('/data');
    const fromDB = yield* queryDatabase('SELECT * FROM data');
    return { fromAPI, fromDB };
  }).pipe(
    Effect.catchTags({
      NetworkError: (e) =>
        Effect.gen(function* () {
          yield* Effect.logWarning(`API call failed: ${e.endpoint}`);
          // Maybe retry or use cache
          return null;
        }),

      DatabaseError: (e) =>
        Effect.gen(function* () {
          yield* Effect.logError(`Database query failed: ${e.query}`);
          // Database errors are more serious - maybe alert monitoring
          yield* Effect.logError('Database error - alerting monitoring');
          return null;
        }),
    })
  );

// ============================================================================
// EXAMPLE 4: Error Recovery Strategies
// ============================================================================

// Different errors warrant different recovery strategies:

const processEventWithRecovery = (eventType: string): Effect.Effect<WorkflowConfig | null, never> =>
  Effect.gen(function* () {
    const workflow = yield* getWorkflow(eventType);
    const validated = yield* validateWorkflow(workflow);
    return validated;
  }).pipe(
    Effect.catchTags({
      // NotFound → Use default workflow
      WorkflowNotFoundError: (e) =>
        Effect.gen(function* () {
          yield* Effect.logInfo(`Using default workflow for ${e.eventType}`);
          return {
            eventType: e.eventType,
            queries: [],
            mappings: {},
          };
        }),

      // Invalid → Try to auto-fix
      InvalidWorkflowError: (e) =>
        Effect.gen(function* () {
          yield* Effect.logWarning(`Attempting to fix invalid workflow for ${e.eventType}`);
          // Could attempt automatic fixes here
          return null;
        }),

      // Config error → Alert and fail gracefully
      WorkflowConfigError: (e) =>
        Effect.gen(function* () {
          yield* Effect.logError(`Critical: Workflow config error for ${e.eventType}`);
          yield* Effect.logError(`Operation: ${e.operation}, Cause: ${e.cause}`);
          // This is serious - maybe alert monitoring system
          return null;
        }),
    })
  );

// ============================================================================
// EXAMPLE 5: Practical Migration from event-handler.service.ts
// ============================================================================

// Based on actual code from line 84-90:

// BEFORE (current code)
const handleEventBefore = (eventType: string) =>
  Effect.gen(function* () {
    const workflowConfig = yield* getWorkflowConfigService();

    const workflow = yield* workflowConfig.getWorkflow(eventType).pipe(
      Effect.catchAll(() =>
        Effect.gen(function* () {
          yield* Effect.logWarning(`No workflow configuration found for event type: ${eventType}`);
          yield* Effect.logInfo(`Event will be processed without workflow enrichment`);
          return null;
        })
      )
    );

    if (!workflow) {
      yield* Effect.logInfo(`Processing ${eventType} without workflow`);
      return { processed: true, workflow: null };
    }

    // Continue processing...
  });

// AFTER (refactored with catchTag)
const handleEventAfter = (eventType: string) =>
  Effect.gen(function* () {
    const workflowConfig = yield* getWorkflowConfigService();

    const workflow = yield* workflowConfig.getWorkflow(eventType).pipe(
      Effect.catchTag('WorkflowNotFoundError', (e) =>
        Effect.gen(function* () {
          yield* Effect.logWarning(`No workflow configuration for event type: ${e.eventType}`);
          yield* Effect.logInfo(`Event will be processed without workflow enrichment`);
          return null;
        })
      )
      // Note: WorkflowConfigError is NOT caught - it will propagate
      // This is correct - config errors should bubble up to caller
    );

    if (!workflow) {
      yield* Effect.logInfo(`Processing ${eventType} without workflow`);
      return { processed: true, workflow: null };
    }

    // Continue processing...
  });

// ============================================================================
// Decision Tree: When to Use What
// ============================================================================

/*
Use catchTag when:
- ✅ You know the specific error type
- ✅ You want type-safe error handling
- ✅ You only need to catch ONE error type
- ✅ Other errors should propagate

Use catchTags when:
- ✅ You have multiple specific error types
- ✅ Each error needs different handling
- ✅ You want exhaustive error handling
- ✅ Some errors should propagate (just don't list them)

Use catchAll when:
- ✅ Error type is genuinely unknown (external libraries)
- ✅ You're logging/debugging then re-throwing
- ✅ You're wrapping unknown errors in domain errors
- ⚠️ RARELY for business logic (usually wrong choice!)

Avoid catchAll when:
- ❌ You have specific error types (use catchTag/catchTags)
- ❌ Different errors need different handling
- ❌ You care about type safety
*/

// ============================================================================
// Migration Checklist
// ============================================================================

/*
To migrate catchAll to catchTag/catchTags:

1. Identify the Effect's error signature
   - Look at the Effect type: Effect.Effect<A, E1 | E2, R>
   - Count the error types in the union

2. Determine error handling strategy
   - Single error type → catchTag
   - Multiple error types → catchTags
   - Truly unknown errors → keep catchAll (rare!)

3. Refactor:
   - Replace Effect.catchAll with Effect.catchTag or Effect.catchTags
   - Use error context (e.eventType, e.cause, etc.)
   - Keep recovery logic specific to each error type

4. Verify:
   - TypeScript compiler should help catch errors
   - Unhandled errors should still appear in Effect signature
   - Tests should cover each error path

5. Benefits:
   - ✅ Better type safety
   - ✅ Explicit error handling
   - ✅ No silent failures
   - ✅ Easier debugging
   - ✅ Self-documenting code
*/

declare function getWorkflowConfigService(): Effect.Effect<
  {
    readonly getWorkflow: (eventType: string) => Effect.Effect<WorkflowConfig, WorkflowError>;
  },
  never
>;

declare const someExternalLibrary: {
  doSomething(): Promise<unknown>;
};
