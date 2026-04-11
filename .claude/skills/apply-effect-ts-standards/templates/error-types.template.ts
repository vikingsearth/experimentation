/**
 * Error Types Template
 *
 * Copy-paste template for creating tagged errors in Effect-TS services
 * Based on excellent patterns from src/evt-svc/src/errors.ts
 *
 * USAGE:
 * 1. Copy this template to your service's errors.ts file
 * 2. Replace [YourDomain] with your domain name (e.g., Payment, User, Order)
 * 3. Customize error types and fields for your use case
 * 4. Create error unions for common patterns
 */

import { Data } from 'effect';

// ============================================================================
// TODO: Replace [YourDomain] with your actual domain name
// Examples: Payment, User, Order, Notification, Analytics
// ============================================================================

// ============================================================================
// Entity Not Found Errors
// ============================================================================

/**
 * Thrown when a [YourDomain] entity is not found
 *
 * Use case: GET requests that return 404
 */
export class [YourDomain]NotFoundError extends Data.TaggedError('[YourDomain]NotFoundError')<{
  readonly id: string; // TODO: Customize ID field name (userId, orderId, etc.)
}> {}

// ============================================================================
// Operation Errors
// ============================================================================

/**
 * Thrown when a [YourDomain] operation fails
 *
 * Use case: Update, delete, or other mutations that fail
 */
export class [YourDomain]OperationError extends Data.TaggedError('[YourDomain]OperationError')<{
  readonly id: string; // Entity ID
  readonly operation: 'create' | 'update' | 'delete' | 'process'; // TODO: Customize operations
  readonly cause: unknown; // Root cause of the error
}> {}

// ============================================================================
// Validation Errors
// ============================================================================

/**
 * Thrown when [YourDomain] data validation fails
 *
 * Use case: Invalid input data, schema validation failures
 */
export class [YourDomain]ValidationError extends Data.TaggedError('[YourDomain]ValidationError')<{
  readonly field: string; // Which field failed validation
  readonly value: unknown; // The invalid value
  readonly reason: string; // Why it's invalid
  readonly validationErrors?: Array<string>; // Optional: Multiple validation errors
}> {}

// ============================================================================
// Configuration Errors
// ============================================================================

/**
 * Thrown when [YourDomain] configuration is invalid or missing
 *
 * Use case: Missing env vars, invalid config files
 */
export class [YourDomain]ConfigError extends Data.TaggedError('[YourDomain]ConfigError')<{
  readonly field: string; // Which config field is problematic
  readonly value?: string; // Optional: The invalid value
  readonly reason: string; // Why it's invalid
}> {}

// ============================================================================
// External Service Errors (if your domain calls external services)
// ============================================================================

/**
 * Thrown when an external API call fails
 *
 * Use case: HTTP calls to other services
 */
export class External[YourDomain]Error extends Data.TaggedError('External[YourDomain]Error')<{
  readonly service: string; // Which external service (e.g., 'payment-gateway', 'email-service')
  readonly endpoint: string; // API endpoint that failed
  readonly statusCode?: number; // HTTP status code if available
  readonly cause: unknown; // Original error
}> {}

// ============================================================================
// Database/Persistence Errors
// ============================================================================

/**
 * Thrown when database operations fail
 *
 * Use case: DB connection errors, query failures, constraint violations
 */
export class [YourDomain]PersistenceError extends Data.TaggedError('[YourDomain]PersistenceError')<{
  readonly id: string; // Entity ID
  readonly operation: 'save' | 'load' | 'delete' | 'query'; // TODO: Customize operations
  readonly storeType: 'relational' | 'vector' | 'cache' | 'file'; // TODO: Customize store types
  readonly cause: unknown; // Root cause
}> {}

// ============================================================================
// Network/Communication Errors
// ============================================================================

/**
 * Thrown when network operations fail
 *
 * Use case: Timeouts, connection errors, DNS failures
 */
export class [YourDomain]NetworkError extends Data.TaggedError('[YourDomain]NetworkError')<{
  readonly endpoint: string; // URL or endpoint
  readonly operation: 'connect' | 'send' | 'receive' | 'timeout'; // Network operation
  readonly cause: unknown; // Root cause
}> {}

// ============================================================================
// Business Logic Errors
// ============================================================================

/**
 * Thrown when business rules are violated
 *
 * Use case: Invalid state transitions, business rule violations
 * Example: "Cannot cancel already-shipped order", "Insufficient balance"
 */
export class [YourDomain]BusinessRuleError extends Data.TaggedError('[YourDomain]BusinessRuleError')<{
  readonly id: string; // Entity ID
  readonly rule: string; // Which business rule was violated
  readonly currentState?: string; // Optional: Current state of the entity
  readonly attemptedOperation?: string; // Optional: What was attempted
}> {}

// ============================================================================
// Parse/Decode Errors
// ============================================================================

/**
 * Thrown when data parsing/decoding fails
 *
 * Use case: JSON parsing, schema decoding, data transformation
 */
export class [YourDomain]ParseError extends Data.TaggedError('[YourDomain]ParseError')<{
  readonly input: string; // What we tried to parse (truncated if large)
  readonly expectedType: string; // Expected type/schema name
  readonly cause: unknown; // Schema validation error
}> {}

// ============================================================================
// TODO: Add your domain-specific error types below
// Examples:
// - PaymentDeclinedError
// - InsufficientBalanceError
// - DuplicateEntityError
// - ExpiredTokenError
// - RateLimitExceededError
// ============================================================================

// Example: Domain-specific error
export class [YourSpecific]Error extends Data.TaggedError('[YourSpecific]Error')<{
  // TODO: Add relevant context fields
  readonly customField1: string;
  readonly customField2: number;
  readonly cause: unknown;
}> {}

// ============================================================================
// Error Unions (Combine Related Errors)
// ============================================================================

/**
 * All errors related to [YourDomain] entity operations
 *
 * Use this union in Effect signatures for entity CRUD operations
 */
export type [YourDomain]EntityError = [YourDomain]NotFoundError | [YourDomain]OperationError;

/**
 * All errors related to [YourDomain] data validation
 *
 * Use this union for validation-heavy operations
 */
export type [YourDomain]DataError = [YourDomain]ValidationError | [YourDomain]ParseError;

/**
 * All errors related to [YourDomain] external communication
 *
 * Use this union for operations involving external services
 */
export type [YourDomain]CommunicationError = [YourDomain]NetworkError | External[YourDomain]Error;

/**
 * All errors related to [YourDomain] persistence
 *
 * Use this union for database operations
 */
export type [YourDomain]StorageError = [YourDomain]PersistenceError;

/**
 * Comprehensive error union for all [YourDomain] operations
 *
 * Use this for top-level service methods that might encounter any error
 */
export type [YourDomain]ServiceError =
  | [YourDomain]EntityError
  | [YourDomain]DataError
  | [YourDomain]CommunicationError
  | [YourDomain]StorageError
  | [YourDomain]ConfigError
  | [YourDomain]BusinessRuleError;

// ============================================================================
// Usage Examples
// ============================================================================

/*
// Example 1: Service method with specific error union
const get[YourDomain] = (id: string): Effect.Effect<[YourDomain], [YourDomain]EntityError> =>
  Effect.gen(function* () {
    // Implementation
  });

// Example 2: Service method with comprehensive error union
const create[YourDomain] = (data: unknown): Effect.Effect<[YourDomain], [YourDomain]ServiceError> =>
  Effect.gen(function* () {
    // Validation
    const valid = yield* validate(data); // May throw ValidationError or ParseError

    // Business rules
    yield* checkBusinessRules(valid); // May throw BusinessRuleError

    // Persistence
    const saved = yield* saveTo Database(valid); // May throw PersistenceError

    return saved;
  });

// Example 3: Error handling with catchTags
const handle[YourDomain]Error = <A>(
  effect: Effect.Effect<A, [YourDomain]ServiceError>
): Effect.Effect<A | null, never> =>
  effect.pipe(
    Effect.catchTags({
      [YourDomain]NotFoundError: (e) =>
        Effect.gen(function* () {
          yield* Effect.logWarning(`[YourDomain] not found: ${e.id}`);
          return null;
        }),

      [YourDomain]ValidationError: (e) =>
        Effect.gen(function* () {
          yield* Effect.logError(`Validation failed for ${e.field}: ${e.reason}`);
          return null;
        }),

      [YourDomain]PersistenceError: (e) =>
        Effect.gen(function* () {
          yield* Effect.logError(`Persistence error: ${e.operation} failed for ${e.id}`);
          return null;
        }),

      // Handle other errors...
    })
  );
*/

// ============================================================================
// Best Practices
// ============================================================================

/*
1. Rich Context
   - Always include relevant entity IDs
   - Include operation context (what were we trying to do?)
   - Include cause for errors wrapping other errors
   - Include state information when relevant

2. Naming Conventions
   - Use PascalCase + "Error" suffix
   - Tag name matches class name
   - Use descriptive names (NotFoundError, not GenericError)

3. Error Unions
   - Group related errors into unions
   - Use unions in Effect signatures
   - Create hierarchical unions (specific → general)

4. Error Fields
   - Make fields readonly
   - Use specific types (not just 'string' everywhere)
   - Include optional fields for extra context
   - Use union types for operation/state enums

5. Documentation
   - Document when each error is thrown
   - Provide use case examples
   - Link to related errors in comments

6. Evolution
   - Start with basic errors, add specific ones as needed
   - Don't over-engineer - add errors when you need them
   - Refactor as patterns emerge

7. Testing
   - Test that errors are thrown in correct scenarios
   - Test error context is populated correctly
   - Test error unions work with catchTags
*/

// ============================================================================
// Real-World Example from evt-svc
// ============================================================================

/*
// From src/evt-svc/src/errors.ts:

export class PersistenceError extends Data.TaggedError('PersistenceError')<{
  readonly playerId: string;
  readonly operation: 'save' | 'load' | 'delete' | 'config' | 'http-invoke';
  readonly storeType: 'relational' | 'vector' | 'dapr' | 'http';
  readonly cause: unknown;
}> {}

export class QueryExecutionError extends Data.TaggedError('QueryExecutionError')<{
  readonly playerId: string;
  readonly query: string;
  readonly cause: unknown;
}> {}

export type QueryError =
  | ClickHouseError
  | QueryExecutionError
  | EnrichmentError;
*/
