/**
 * HTTP Service Template
 *
 * Complete template for HTTP client services using @effect/platform
 * Based on patterns from evt-svc client services
 *
 * USAGE:
 * 1. Copy this template
 * 2. Replace [ServiceName] with your service name (e.g., CtxSvc, PaymentGateway)
 * 3. Define your response schemas
 * 4. Implement service methods
 * 5. Create test implementation
 */

import { Effect, Layer, Context, Schedule } from 'effect';
import { Schema } from '@effect/schema';
import * as Http from '@effect/platform/HttpClient';
import type { ConfigService } from './config.service.js'; // TODO: Adjust import path
import { [ServiceName]Error } from '../errors.js'; // TODO: Define your error types

// ============================================================================
// TODO: Define Response Schemas
// ============================================================================

// TODO: Define your API response schemas here
const [Operation]ResponseSchema = Schema.Struct({
  success: Schema.Boolean,
  data: Schema.Unknown, // TODO: Define actual data structure
  message: Schema.optional(Schema.String),
});

// TODO: Add more schemas for different endpoints
const Get[Entity]ResponseSchema = Schema.Struct({
  id: Schema.String,
  // TODO: Add entity fields
});

const List[Entities]ResponseSchema = Schema.Struct({
  items: Schema.Array(Get[Entity]ResponseSchema),
  total: Schema.Number,
  page: Schema.optional(Schema.Number),
});

// Extract TypeScript types
type [Operation]Response = Schema.Schema.Type<typeof [Operation]ResponseSchema>;
type Get[Entity]Response = Schema.Schema.Type<typeof Get[Entity]ResponseSchema>;
type List[Entities]Response = Schema.Schema.Type<typeof List[Entities]ResponseSchema>;

// ============================================================================
// Service Definition
// ============================================================================

/**
 * [ServiceName]ClientService
 *
 * HTTP client for calling [ServiceName] API endpoints
 * Following Effect-TS pattern: Service for inter-service communication
 *
 * TODO: Document what this service does
 * TODO: Document available methods
 */
export class [ServiceName]ClientService extends Context.Tag('[ServiceName]ClientService')<
  [ServiceName]ClientService,
  {
    // TODO: Define service methods

    /**
     * Get entity by ID
     *
     * @param id - Entity ID
     * @returns Effect with entity data or error
     */
    readonly get[Entity]: (id: string) => Effect.Effect<Get[Entity]Response, [ServiceName]Error>;

    /**
     * List all entities
     *
     * @param page - Optional page number
     * @param limit - Optional page size
     * @returns Effect with list of entities or error
     */
    readonly list[Entities]: (
      page?: number,
      limit?: number
    ) => Effect.Effect<List[Entities]Response, [ServiceName]Error>;

    /**
     * Create new entity
     *
     * @param data - Entity data
     * @returns Effect with created entity or error
     */
    readonly create[Entity]: (data: Record<string, unknown>) => Effect.Effect<Get[Entity]Response, [ServiceName]Error>;

    /**
     * Update existing entity
     *
     * @param id - Entity ID
     * @param data - Updated entity data
     * @returns Effect with updated entity or error
     */
    readonly update[Entity]: (
      id: string,
      data: Record<string, unknown>
    ) => Effect.Effect<Get[Entity]Response, [ServiceName]Error>;

    /**
     * Delete entity
     *
     * @param id - Entity ID
     * @returns Effect with void or error
     */
    readonly delete[Entity]: (id: string) => Effect.Effect<void, [ServiceName]Error>;
  }
>() {}

// ============================================================================
// Live Implementation (Production)
// ============================================================================

export const [ServiceName]ClientServiceLive = Layer.effect(
  [ServiceName]ClientService,
  Effect.gen(function* () {
    // Get configuration service
    const config = yield* ConfigService;

    // TODO: Get base URL from environment/config
    const baseUrl = yield* Effect.tryPromise({
      try: () => Promise.resolve(process.env.[SERVICE_NAME]_URL || 'http://localhost:3000'), // TODO: Adjust env var
      catch: () =>
        new [ServiceName]Error({
          operation: 'config',
          cause: 'Failed to get [ServiceName] URL from config',
        }),
    });

    yield* Effect.logInfo(`[[ServiceName]Client] Initialized with base URL: ${baseUrl}`);

    // ✅ GOOD: Define retry policy
    const retryPolicy = Schedule.exponential('100 millis').pipe(
      Schedule.jittered,
      Schedule.compose(Schedule.recurs(3)) // Retry up to 3 times
    );

    /**
     * Helper function to make HTTP requests with full Effect integration
     *
     * @param method - HTTP method
     * @param path - API endpoint path
     * @param schema - Response schema for validation
     * @param body - Optional request body
     * @returns Effect with validated response or error
     */
    const makeRequest = <A, I, R>(
      method: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH',
      path: string,
      schema: Schema.Schema<A, I, R>,
      body?: unknown
    ): Effect.Effect<A, [ServiceName]Error> =>
      Effect.gen(function* () {
        yield* Effect.logInfo(`[[ServiceName]Client] ${method} ${path}`);
        if (body) {
          yield* Effect.logDebug(`[[ServiceName]Client] Request body: ${JSON.stringify(body)}`);
        }

        // ✅ Build HTTP request
        const request = Http.request(method)(`${baseUrl}${path}`);

        // ✅ Add body if present
        const requestWithBody = body
          ? request.pipe(
              Http.request.setHeader('Content-Type', 'application/json'),
              Http.request.setBody(Http.body.unsafeJson(body))
            )
          : request.pipe(Http.request.setHeader('Content-Type', 'application/json'));

        // ✅ Execute with retry, timeout, and schema validation
        const result = yield* requestWithBody.pipe(
          Http.client.execute,
          Effect.flatMap((response) => response.json),
          Effect.flatMap(Schema.decode(schema)),
          Effect.retry(retryPolicy),
          Effect.timeout('30 seconds'),
          Effect.mapError(
            (error) =>
              new [ServiceName]Error({
                operation: `${method} ${path}`,
                cause: error,
              })
          )
        );

        yield* Effect.logDebug(`[[ServiceName]Client] Response received`);
        return result;
      });

    // ============================================================================
    // Implement Service Methods
    // ============================================================================

    return {
      get[Entity]: (id: string) =>
        Effect.gen(function* () {
          yield* Effect.logInfo(`[[ServiceName]Client] Getting [entity] ${id}`);

          const result = yield* makeRequest('GET', `/[entities]/${id}`, Get[Entity]ResponseSchema);

          yield* Effect.logInfo(`[[ServiceName]Client] Retrieved [entity] ${id}`);
          return result;
        }),

      list[Entities]: (page?: number, limit?: number) =>
        Effect.gen(function* () {
          yield* Effect.logInfo(`[[ServiceName]Client] Listing [entities] (page: ${page}, limit: ${limit})`);

          // Build query params
          const queryParams = new URLSearchParams();
          if (page !== undefined) queryParams.append('page', page.toString());
          if (limit !== undefined) queryParams.append('limit', limit.toString());
          const queryString = queryParams.toString();
          const path = queryString ? `/[entities]?${queryString}` : '/[entities]';

          const result = yield* makeRequest('GET', path, List[Entities]ResponseSchema);

          yield* Effect.logInfo(`[[ServiceName]Client] Retrieved ${result.total} [entities]`);
          return result;
        }),

      create[Entity]: (data: Record<string, unknown>) =>
        Effect.gen(function* () {
          yield* Effect.logInfo(`[[ServiceName]Client] Creating [entity]`);

          const result = yield* makeRequest('POST', '/[entities]', Get[Entity]ResponseSchema, data);

          yield* Effect.logInfo(`[[ServiceName]Client] Created [entity] ${result.id}`);
          return result;
        }),

      update[Entity]: (id: string, data: Record<string, unknown>) =>
        Effect.gen(function* () {
          yield* Effect.logInfo(`[[ServiceName]Client] Updating [entity] ${id}`);

          const result = yield* makeRequest('PUT', `/[entities]/${id}`, Get[Entity]ResponseSchema, data);

          yield* Effect.logInfo(`[[ServiceName]Client] Updated [entity] ${id}`);
          return result;
        }),

      delete[Entity]: (id: string) =>
        Effect.gen(function* () {
          yield* Effect.logInfo(`[[ServiceName]Client] Deleting [entity] ${id}`);

          yield* makeRequest('DELETE', `/[entities]/${id}`, [Operation]ResponseSchema);

          yield* Effect.logInfo(`[[ServiceName]Client] Deleted [entity] ${id}`);
        }),
    };
  })
);

// ============================================================================
// Test Implementation (For Tests)
// ============================================================================

/**
 * Test/Mock stores for simulating service behavior
 */
const test[Entities]Store = new Map<
  string,
  {
    id: string;
    // TODO: Add entity fields
  }
>();

export const [ServiceName]ClientServiceTest = Layer.succeed([ServiceName]ClientService, {
  get[Entity]: (id: string) =>
    Effect.gen(function* () {
      yield* Effect.logDebug(`[Test] Getting [entity] ${id}`);

      const entity = test[Entities]Store.get(id);
      if (!entity) {
        return yield* Effect.fail(
          new [ServiceName]Error({
            operation: 'get',
            cause: `[Entity] ${id} not found in test store`,
          })
        );
      }

      return entity as Get[Entity]Response;
    }),

  list[Entities]: (page?: number, limit?: number) =>
    Effect.gen(function* () {
      yield* Effect.logDebug(`[Test] Listing [entities] (page: ${page}, limit: ${limit})`);

      const allEntities = Array.from(test[Entities]Store.values());
      const pageSize = limit || 10;
      const pageNum = page || 1;
      const start = (pageNum - 1) * pageSize;
      const items = allEntities.slice(start, start + pageSize);

      return {
        items: items as Get[Entity]Response[],
        total: allEntities.length,
        page: pageNum,
      };
    }),

  create[Entity]: (data: Record<string, unknown>) =>
    Effect.gen(function* () {
      yield* Effect.logDebug(`[Test] Creating [entity]`);

      const id = `test-${Date.now()}`;
      const entity = { id, ...data };
      test[Entities]Store.set(id, entity as any);

      return entity as Get[Entity]Response;
    }),

  update[Entity]: (id: string, data: Record<string, unknown>) =>
    Effect.gen(function* () {
      yield* Effect.logDebug(`[Test] Updating [entity] ${id}`);

      const existing = test[Entities]Store.get(id);
      if (!existing) {
        return yield* Effect.fail(
          new [ServiceName]Error({
            operation: 'update',
            cause: `[Entity] ${id} not found in test store`,
          })
        );
      }

      const updated = { ...existing, ...data };
      test[Entities]Store.set(id, updated as any);

      return updated as Get[Entity]Response;
    }),

  delete[Entity]: (id: string) =>
    Effect.gen(function* () {
      yield* Effect.logDebug(`[Test] Deleting [entity] ${id}`);

      const deleted = test[Entities]Store.delete(id);
      if (!deleted) {
        return yield* Effect.fail(
          new [ServiceName]Error({
            operation: 'delete',
            cause: `[Entity] ${id} not found in test store`,
          })
        );
      }
    }),
});

/**
 * Helper to clear test stores (call in test cleanup)
 */
export const clearTest[ServiceName]Stores = () => {
  test[Entities]Store.clear();
};

// ============================================================================
// Usage Examples
// ============================================================================

/*
// Example 1: Using the service in another service
export const MyServiceLive = Layer.effect(
  MyService,
  Effect.gen(function* () {
    const [serviceName]Client = yield* [ServiceName]ClientService;

    return {
      doSomething: () =>
        Effect.gen(function* () {
          const entities = yield* [serviceName]Client.list[Entities]();
          // Process entities...
        })
    };
  })
);

// Example 2: Composing layers
const AppLive = Layer.merge(
  ConfigServiceLive,
  [ServiceName]ClientServiceLive
);

// Example 3: Using test layer in tests
const testProgram = Effect.gen(function* () {
  const client = yield* [ServiceName]ClientService;

  const created = yield* client.create[Entity]({ name: 'Test' });
  const retrieved = yield* client.get[Entity](created.id);

  expect(retrieved.id).toBe(created.id);
}).pipe(
  Effect.provide([ServiceName]ClientServiceTest)
);

await Effect.runPromise(testProgram);
*/

// ============================================================================
// TODO Checklist
// ============================================================================

/*
TODO: Replace placeholders:
- [ServiceName] → Your service name (e.g., CtxSvc, PaymentGateway)
- [Entity] → Your entity name (e.g., User, Order, Payment)
- [Entities] → Plural entity name (e.g., Users, Orders, Payments)
- [Operation] → Operation name (e.g., Save, Process, Validate)
- [SERVICE_NAME] → Environment variable prefix (e.g., CTX_SVC, PAYMENT_GATEWAY)

TODO: Define schemas:
- Response schemas for all endpoints
- Request schemas if needed for validation

TODO: Implement methods:
- Add all required service methods
- Ensure proper error handling
- Add logging for observability

TODO: Add error types (in errors.ts):
- [ServiceName]Error with relevant context fields
- Specific error types if needed

TODO: Test implementation:
- Implement test layer methods
- Add test stores if needed
- Write tests using test layer

TODO: Documentation:
- Document service purpose
- Document each method
- Document error scenarios
*/
