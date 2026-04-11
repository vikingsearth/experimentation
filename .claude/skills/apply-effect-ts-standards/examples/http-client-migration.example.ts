/**
 * HTTP Client Migration Example
 *
 * This file demonstrates the complete migration from axios to @effect/platform HttpClient
 * Based on actual patterns from src/evt-svc/src/services/ctx-svc-client.service.ts
 *
 * BEFORE: Uses axios with Effect.tryPromise
 * AFTER: Uses @effect/platform HttpClient with full Effect integration
 */

import { Effect, Layer, Context, Schedule } from 'effect';
import { Schema } from '@effect/schema';

// ============================================================================
// BEFORE: Axios-based implementation
// ============================================================================

// --- BAD: Using axios ---
import axios from 'axios';
import type { ConfigService } from './config.service.js';
import { PersistenceError } from '../errors.js';

export class CtxSvcClientServiceAxios extends Context.Tag('CtxSvcClientService')<
  CtxSvcClientServiceAxios,
  {
    readonly saveContext: (
      playerId: string,
      contextData: Record<string, unknown>
    ) => Effect.Effect<void, PersistenceError>;
  }
>() {}

export const CtxSvcClientServiceAxiosLive = Layer.effect(
  CtxSvcClientServiceAxios,
  Effect.gen(function* () {
    const config = yield* ConfigService;

    // ❌ BAD: Getting URL synchronously
    const ctxSvcBaseUrl = process.env.CTX_SVC_URL || 'http://localhost:3002';

    yield* Effect.logInfo(`[CtxSvcClient] Initialized with base URL: ${ctxSvcBaseUrl}`);

    // ❌ BAD: Creating axios client
    const httpClient = axios.create({
      baseURL: ctxSvcBaseUrl,
      timeout: 30000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // ❌ BAD: Helper function using axios with Effect.tryPromise
    const callCtxSvc = <T>(
      method: string,
      path: string,
      body?: unknown
    ): Effect.Effect<T, PersistenceError> =>
      Effect.gen(function* () {
        yield* Effect.logInfo(`[CtxSvcClient.callCtxSvc] ${method} ${path}`);

        // ❌ BAD: Effect.tryPromise wrapping axios
        const result = yield* Effect.tryPromise({
          try: async () => {
            const response = await httpClient.request({
              method,
              url: path,
              data: body,
            });
            return response.data as T;
          },
          catch: (error: unknown) => {
            const errorMessage =
              (error as { response?: { data?: { error?: string } }; message?: string })?.response?.data?.error ||
              (error as { message?: string })?.message ||
              String(error);
            const statusCode = (error as { response?: { status?: number } })?.response?.status || 'unknown';

            // Error mapping is manual and verbose
            return new PersistenceError({
              playerId: 'unknown',
              operation: 'http-invoke',
              storeType: 'http',
              cause: `HTTP ${statusCode}: ${errorMessage}`,
            });
          },
        });

        return result;
      });

    return {
      saveContext: (playerId: string, contextData: Record<string, unknown>) =>
        Effect.gen(function* () {
          yield* Effect.logInfo(`[CtxSvcClient] Saving context for player ${playerId}`);

          const requestBody = { contextData };

          // ❌ BAD: No schema validation, no retry, no timeout composition
          yield* callCtxSvc<{ message: string; playerId: string }>('POST', `/context/${playerId}`, requestBody);

          yield* Effect.logInfo(`[CtxSvcClient] Context saved for player ${playerId}`);
        }),
    };
  })
);

// ============================================================================
// AFTER: @effect/platform HttpClient implementation
// ============================================================================

// --- GOOD: Using @effect/platform ---
import * as Http from '@effect/platform/HttpClient';

// ✅ GOOD: Define response schemas first
const SaveContextResponseSchema = Schema.Struct({
  message: Schema.String,
  playerId: Schema.String,
});

const GetContextResponseSchema = Schema.Struct({
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
      createdAt: Schema.Date,
    })
  ),
});

export class CtxSvcClientService extends Context.Tag('CtxSvcClientService')<
  CtxSvcClientService,
  {
    readonly saveContext: (
      playerId: string,
      contextData: Record<string, unknown>
    ) => Effect.Effect<void, PersistenceError>;

    readonly getContext: (
      playerId: string
    ) => Effect.Effect<{ context: Record<string, unknown> | null; embeddings: unknown[] }, PersistenceError>;
  }
>() {}

export const CtxSvcClientServiceLive = Layer.effect(
  CtxSvcClientService,
  Effect.gen(function* () {
    const config = yield* ConfigService;

    // ✅ GOOD: Get configuration through Effect
    const ctxSvcBaseUrl = yield* Effect.tryPromise({
      try: () => Promise.resolve(process.env.CTX_SVC_URL || 'http://localhost:3002'),
      catch: () =>
        new PersistenceError({
          playerId: 'unknown',
          operation: 'config',
          storeType: 'http',
          cause: 'Failed to get ctx-svc URL from config',
        }),
    });

    yield* Effect.logInfo(`[CtxSvcClient] Initialized with base URL: ${ctxSvcBaseUrl}`);

    // ✅ GOOD: Retry policy
    const retryPolicy = Schedule.exponential('100 millis').pipe(
      Schedule.jittered,
      Schedule.compose(Schedule.recurs(3))
    );

    // ✅ GOOD: Helper function using @effect/platform HttpClient
    const callCtxSvc = <A, I, R>(
      method: 'GET' | 'POST' | 'PUT' | 'DELETE',
      path: string,
      schema: Schema.Schema<A, I, R>,
      body?: unknown
    ): Effect.Effect<A, PersistenceError> =>
      Effect.gen(function* () {
        yield* Effect.logInfo(`[CtxSvcClient.callCtxSvc] ${method} ${path}`);
        if (body) {
          yield* Effect.logDebug(`[CtxSvcClient.callCtxSvc] Request body: ${JSON.stringify(body)}`);
        }

        // ✅ GOOD: Build HTTP request with @effect/platform
        const request = Http.request(method)(`${ctxSvcBaseUrl}${path}`);

        const requestWithBody = body
          ? request.pipe(
              Http.request.setHeader('Content-Type', 'application/json'),
              Http.request.setBody(
                Http.body.unsafeJson(body)
              )
            )
          : request.pipe(
              Http.request.setHeader('Content-Type', 'application/json')
            );

        // ✅ GOOD: Execute with retry, timeout, and schema validation
        const result = yield* requestWithBody.pipe(
          Http.client.execute,
          Effect.flatMap(response => response.json),
          Effect.flatMap(Schema.decode(schema)),
          Effect.retry(retryPolicy),
          Effect.timeout('30 seconds'),
          Effect.mapError(error =>
            new PersistenceError({
              playerId: 'unknown',
              operation: 'http-invoke',
              storeType: 'http',
              cause: error,
            })
          )
        );

        yield* Effect.logDebug(`[CtxSvcClient.callCtxSvc] Response received`);
        return result;
      });

    return {
      saveContext: (playerId: string, contextData: Record<string, unknown>) =>
        Effect.gen(function* () {
          yield* Effect.logInfo(`[CtxSvcClient] Saving context for player ${playerId}`);

          const requestBody = { contextData };

          // ✅ GOOD: Schema validation, retry, timeout all integrated
          yield* callCtxSvc('POST', `/context/${playerId}`, SaveContextResponseSchema, requestBody);

          yield* Effect.logInfo(`[CtxSvcClient] Context saved for player ${playerId}`);
        }),

      getContext: (playerId: string) =>
        Effect.gen(function* () {
          yield* Effect.logInfo(`[CtxSvcClient] Fetching context for player ${playerId}`);

          // ✅ GOOD: Type-safe response with schema validation
          const result = yield* callCtxSvc('GET', `/context/${playerId}`, GetContextResponseSchema);

          yield* Effect.logInfo(`[CtxSvcClient] Retrieved context for player ${playerId}`);
          return result;
        }),
    };
  })
);

// ✅ GOOD: Test layer with mock HTTP responses
export const CtxSvcClientServiceTest = Layer.succeed(CtxSvcClientService, {
  saveContext: (playerId: string, contextData: Record<string, unknown>) =>
    Effect.gen(function* () {
      yield* Effect.logDebug(`[Test] Saving context for player ${playerId}`);
      // Mock implementation
    }),

  getContext: (playerId: string) =>
    Effect.gen(function* () {
      yield* Effect.logDebug(`[Test] Fetching context for player ${playerId}`);
      return {
        context: { mock: 'data' },
        embeddings: [],
      };
    }),
});

// ============================================================================
// Key Differences Summary
// ============================================================================

/*
BEFORE (axios):
- ❌ Manual error handling with try/catch
- ❌ No retry logic
- ❌ Timeout buried in axios config
- ❌ No schema validation
- ❌ Verbose error mapping
- ❌ Less type-safe
- ❌ Effect.tryPromise bypasses Effect's error channel

AFTER (@effect/platform):
- ✅ Integrated error handling through Effect
- ✅ Composable retry with Schedule
- ✅ Explicit timeout as part of Effect pipeline
- ✅ Schema validation with @effect/schema
- ✅ Clean error mapping with mapError
- ✅ Fully type-safe
- ✅ All effects flow through Effect's error channel
- ✅ Better testability with mock HTTP clients
- ✅ Structured concurrency benefits (interruption, resource management)

Migration Effort:
- Replace: axios import → @effect/platform/HttpClient
- Add: Schema definitions for responses
- Change: axios.create() → Http.request()
- Change: Effect.tryPromise → Http.client.execute
- Add: Schema.decode for validation
- Add: Retry policy with Schedule
- Change: Timeout from config to Effect.timeout
- Update: Test layers to use mock HTTP clients

Breaking Changes:
- Internal only (service implementation)
- Public API (Effect signatures) remains the same
- No changes to calling code
*/
