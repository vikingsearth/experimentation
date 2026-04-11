/**
 * Schema Validation Example
 *
 * This file demonstrates schema-first design and validation patterns
 * Based on patterns from src/evt-svc/src/schemas.ts and service integrations
 *
 * Shows: Schema definition, decode usage, error handling, branded types
 */

import { Effect } from 'effect';
import { Schema } from '@effect/schema';
import { Brand } from 'effect';
import { Data } from 'effect';
import * as Http from '@effect/platform/HttpClient';

// ============================================================================
// Error Definitions
// ============================================================================

export class ValidationError extends Data.TaggedError('ValidationError')<{
  readonly field: string;
  readonly value: unknown;
  readonly reason: string;
}> {}

export class ParseError extends Data.TaggedError('ParseError')<{
  readonly input: string;
  readonly expectedType: string;
  readonly cause: unknown;
}> {}

export class PersistenceError extends Data.TaggedError('PersistenceError')<{
  readonly playerId: string;
  readonly operation: string;
  readonly cause: unknown;
}> {}

// ============================================================================
// EXAMPLE 1: Basic Schema Definitions (from src/evt-svc/src/schemas.ts)
// ============================================================================

// ✅ GOOD: Define schemas before implementation

// Simple struct schema
const PlayerEventSchema = Schema.Struct({
  eventType: Schema.String,
  playerId: Schema.String,
  timestamp: Schema.Date,
  properties: Schema.Record(Schema.String, Schema.Unknown),
});

// Extract TypeScript type from schema
export type PlayerEvent = Schema.Schema.Type<typeof PlayerEventSchema>;

// Validation function
const parsePlayerEvent = (input: unknown): Effect.Effect<PlayerEvent, ParseError> =>
  Schema.decodeUnknown(PlayerEventSchema)(input).pipe(
    Effect.mapError(
      (error) =>
        new ParseError({
          input: JSON.stringify(input),
          expectedType: 'PlayerEvent',
          cause: error,
        })
    )
  );

// ============================================================================
// EXAMPLE 2: HTTP Response Schemas
// ============================================================================

// ✅ GOOD: Define schemas for ALL HTTP responses

// Context Service response schemas
const EmbeddingSchema = Schema.Struct({
  id: Schema.String,
  playerId: Schema.String,
  fieldName: Schema.String,
  embedding: Schema.Array(Schema.Number),
  sourceText: Schema.String,
  embeddingModel: Schema.String,
  createdAt: Schema.Date,
});

const PlayerContextSchema = Schema.Struct({
  playerId: Schema.String,
  contextData: Schema.Record(Schema.String, Schema.Unknown),
  lastUpdated: Schema.Date,
  version: Schema.Number,
  createdAt: Schema.Date,
});

// Response with optional/nullable fields
const GetContextResponseSchema = Schema.Struct({
  context: Schema.Union(PlayerContextSchema, Schema.Null),
  embeddings: Schema.Array(EmbeddingSchema),
});

const SaveContextResponseSchema = Schema.Struct({
  message: Schema.String,
  playerId: Schema.String,
  embeddingIds: Schema.optional(Schema.Array(Schema.String)),
});

// Extract types
export type GetContextResponse = Schema.Schema.Type<typeof GetContextResponseSchema>;
export type SaveContextResponse = Schema.Schema.Type<typeof SaveContextResponseSchema>;

// ============================================================================
// EXAMPLE 3: Using Schemas with HTTP Clients
// ============================================================================

// ❌ BAD: No schema validation
const getContextBad = (playerId: string, baseUrl: string): Effect.Effect<unknown, PersistenceError> =>
  Http.get(`${baseUrl}/context/${playerId}`).pipe(
    Http.client.execute,
    Effect.flatMap((response) => response.json),
    // ❌ No validation - data could be anything!
    Effect.mapError(
      (error) =>
        new PersistenceError({
          playerId,
          operation: 'load',
          cause: error,
        })
    )
  );

// ✅ GOOD: Schema validation integrated
const getContextGood = (
  playerId: string,
  baseUrl: string
): Effect.Effect<GetContextResponse, PersistenceError | ParseError> =>
  Http.get(`${baseUrl}/context/${playerId}`).pipe(
    Http.client.execute,
    Effect.flatMap((response) => response.json),
    Effect.flatMap(Schema.decode(GetContextResponseSchema)),
    Effect.mapError((error) => {
      // Distinguish parse errors from HTTP errors
      if (error instanceof ParseError) {
        return error;
      }
      return new PersistenceError({
        playerId,
        operation: 'load',
        cause: error,
      });
    })
  );

// ✅ EVEN BETTER: Parse errors mapped to domain errors
const getContextBest = (playerId: string, baseUrl: string): Effect.Effect<GetContextResponse, PersistenceError> =>
  Http.get(`${baseUrl}/context/${playerId}`).pipe(
    Http.client.execute,
    Effect.flatMap((response) => response.json),
    Effect.flatMap(Schema.decode(GetContextResponseSchema)),
    Effect.mapError(
      (error) =>
        new PersistenceError({
          playerId,
          operation: 'load',
          cause: error, // Parse errors become part of cause
        })
    )
  );

// ============================================================================
// EXAMPLE 4: Branded Types for Domain Validation
// ============================================================================

// ✅ GOOD: Branded types prevent mixing semantically different strings

// Email brand
type Email = string & Brand.Brand<'Email'>;

const EmailSchema = Schema.String.pipe(
  Schema.pattern(/^[^@]+@[^@]+$/),
  Schema.brand('Email')
);

// PlayerId brand (prevents mixing with other string IDs)
type PlayerId = string & Brand.Brand<'PlayerId'>;

const PlayerIdSchema = Schema.String.pipe(
  Schema.pattern(/^player_[a-zA-Z0-9]+$/),
  Schema.brand('PlayerId')
);

// UserId brand
type UserId = string & Brand.Brand<'UserId'>;

const UserIdSchema = Schema.String.pipe(
  Schema.pattern(/^user_[a-zA-Z0-9]+$/),
  Schema.brand('UserId')
);

// ❌ BAD: Without brands, IDs can be mixed
const sendMessageBad = (playerId: string, userId: string) => {
  // Nothing prevents passing userId as playerId!
  // doSomething(userId, playerId); // Oops, swapped!
};

// ✅ GOOD: With brands, compiler prevents mixing
const sendMessageGood = (playerId: PlayerId, userId: UserId) => {
  // doSomething(userId, playerId); // ❌ Compiler error!
  // Type 'UserId' is not assignable to type 'PlayerId'
};

// Validation functions
const parseEmail = (input: string): Effect.Effect<Email, ValidationError> =>
  Schema.decodeUnknown(EmailSchema)(input).pipe(
    Effect.mapError(
      (error) =>
        new ValidationError({
          field: 'email',
          value: input,
          reason: 'Invalid email format',
        })
    )
  );

const parsePlayerId = (input: string): Effect.Effect<PlayerId, ValidationError> =>
  Schema.decodeUnknown(PlayerIdSchema)(input).pipe(
    Effect.mapError(
      (error) =>
        new ValidationError({
          field: 'playerId',
          value: input,
          reason: 'Invalid player ID format (expected: player_xxx)',
        })
    )
  );

// ============================================================================
// EXAMPLE 5: Schema Composition and Transformation
// ============================================================================

// Base schema
const BaseEventSchema = Schema.Struct({
  eventType: Schema.String,
  timestamp: Schema.Date,
});

// Extended schema (composition)
const PlayerEventExtendedSchema = Schema.Struct({
  ...BaseEventSchema.fields,
  playerId: PlayerIdSchema, // Using branded type
  properties: Schema.Record(Schema.String, Schema.Unknown),
});

// Schema with transformations
const WorkflowConfigSchema = Schema.Struct({
  eventType: Schema.String,
  isEnabled: Schema.Boolean,
  queries: Schema.Array(Schema.String),
  propertyMappings: Schema.Record(
    Schema.String,
    Schema.Struct({
      source: Schema.String,
      target: Schema.String,
      transform: Schema.optional(Schema.String),
    })
  ),
  semanticFields: Schema.Array(
    Schema.Struct({
      field: Schema.String,
      template: Schema.String,
      embeddingModel: Schema.String,
    })
  ),
});

// Optional fields
const UpdateWorkflowRequestSchema = Schema.Struct({
  eventType: Schema.String,
  isEnabled: Schema.optional(Schema.Boolean),
  queries: Schema.optional(Schema.Array(Schema.String)),
  // Only fields being updated need to be present
});

// ============================================================================
// EXAMPLE 6: Schema Validation in Service Layer
// ============================================================================

// Complete service implementation with schema validation

class WorkflowService {
  static saveWorkflow(
    eventType: string,
    data: unknown
  ): Effect.Effect<void, ValidationError | PersistenceError> {
    return Effect.gen(function* () {
      // ✅ STEP 1: Validate input with schema
      const validWorkflow = yield* Schema.decodeUnknown(WorkflowConfigSchema)(data).pipe(
        Effect.mapError(
          (error) =>
            new ValidationError({
              field: 'workflow',
              value: data,
              reason: 'Invalid workflow configuration',
            })
        )
      );

      // ✅ STEP 2: Business logic with validated data
      yield* Effect.logInfo(`Saving workflow for ${validWorkflow.eventType}`);

      // ✅ STEP 3: Persist (simulated)
      yield* Effect.tryPromise({
        try: async () => {
          // await database.save(validWorkflow);
        },
        catch: (error) =>
          new PersistenceError({
            playerId: validWorkflow.eventType,
            operation: 'save',
            cause: error,
          }),
      });

      yield* Effect.logInfo(`Workflow saved successfully`);
    });
  }
}

// ============================================================================
// EXAMPLE 7: Schema Validation for Pub/Sub Messages (NATS/Dapr)
// ============================================================================

// ✅ GOOD: Validate pub/sub messages

const handleIncomingEvent = (rawMessage: unknown): Effect.Effect<void, ParseError | PersistenceError> =>
  Effect.gen(function* () {
    // ✅ Validate message schema
    const event = yield* Schema.decodeUnknown(PlayerEventSchema)(rawMessage).pipe(
      Effect.mapError(
        (error) =>
          new ParseError({
            input: JSON.stringify(rawMessage),
            expectedType: 'PlayerEvent',
            cause: error,
          })
      )
    );

    yield* Effect.logInfo(`Processing event ${event.eventType} for player ${event.playerId}`);

    // Process validated event
    // ...
  });

// ============================================================================
// EXAMPLE 8: Schema Validation for Database Results
// ============================================================================

// ✅ GOOD: Validate ClickHouse query results

const ClickHouseResultSchema = Schema.Struct({
  rows: Schema.Array(
    Schema.Struct({
      playerId: Schema.String,
      totalWagers: Schema.Number,
      lastSeenAt: Schema.Date,
      // ... other fields
    })
  ),
  rowCount: Schema.Number,
});

const queryPlayerStats = (playerId: string): Effect.Effect<unknown[], ParseError> =>
  Effect.gen(function* () {
    // Execute query (simulated)
    const rawResult = yield* Effect.tryPromise({
      try: async () => {
        // return await clickhouse.query(`SELECT ...`);
        return { rows: [], rowCount: 0 };
      },
      catch: (error) => error,
    });

    // ✅ Validate result schema
    const validResult = yield* Schema.decodeUnknown(ClickHouseResultSchema)(rawResult).pipe(
      Effect.mapError(
        (error) =>
          new ParseError({
            input: JSON.stringify(rawResult),
            expectedType: 'ClickHouseResult',
            cause: error,
          })
      )
    );

    return validResult.rows;
  });

// ============================================================================
// EXAMPLE 9: Using Schema.decodeUnknownEither for Either-based validation
// ============================================================================

import { Either } from 'effect';

// Sometimes you want Either instead of Effect for synchronous validation

const validateEventSync = (input: unknown): Either.Either<PlayerEvent, ParseError> =>
  Schema.decodeUnknownEither(PlayerEventSchema)(input).pipe(
    Either.mapLeft(
      (error) =>
        new ParseError({
          input: JSON.stringify(input),
          expectedType: 'PlayerEvent',
          cause: error,
        })
    )
  );

// Use in conditional logic
const processIfValid = (input: unknown) =>
  Effect.gen(function* () {
    const validation = validateEventSync(input);

    if (Either.isLeft(validation)) {
      yield* Effect.logWarning(`Invalid event: ${validation.left.reason}`);
      return null;
    }

    const event = validation.right;
    yield* Effect.logInfo(`Processing valid event: ${event.eventType}`);
    return event;
  });

// ============================================================================
// Migration Checklist: Adding Schema Validation
// ============================================================================

/*
To add schema validation to existing code:

1. Identify external data sources:
   - HTTP responses
   - Pub/sub messages
   - Database query results
   - File reads
   - Environment variables

2. Define schemas FIRST (schema-first design):
   - Use Schema.Struct for objects
   - Use Schema.Array for arrays
   - Use Schema.Union for nullable or variant types
   - Use Schema.optional for optional fields
   - Consider branded types for domain-specific strings/numbers

3. Integrate validation:
   - Use Schema.decodeUnknown in Effect pipelines
   - Use Schema.decodeUnknownEither for Either-based validation
   - Map schema errors to domain errors

4. Handle parse errors:
   - Option 1: Map to domain error (PersistenceError, ValidationError)
   - Option 2: Keep ParseError as separate error type
   - Option 3: Both (use Either to distinguish)

5. Update tests:
   - Test valid schemas pass
   - Test invalid schemas fail with correct errors
   - Test edge cases (null, undefined, empty arrays, etc.)

Benefits:
- ✅ Runtime validation prevents type errors
- ✅ Self-documenting (schema IS the contract)
- ✅ Early error detection
- ✅ Better error messages
- ✅ Prevents invalid data propagation
- ✅ Type safety at boundaries

Where to add validation (evt-svc):
- ✅ PlayerEvent pub/sub messages (already done!)
- ❌ ctx-svc HTTP responses (needs adding)
- ❌ agent-proxy-svc HTTP responses (needs adding)
- ❌ cc-svc HTTP responses (needs adding)
- ❌ ClickHouse query results (needs adding)
*/
