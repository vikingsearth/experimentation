/**
 * Schema Definitions Template
 *
 * Patterns for defining schemas with @effect/schema
 * Based on src/evt-svc/src/schemas.ts
 *
 * USAGE:
 * 1. Copy patterns to your schemas.ts file
 * 2. Define schemas BEFORE implementation (schema-first design)
 * 3. Export both schemas and TypeScript types
 * 4. Use Schema.decode for runtime validation
 */

import { Schema } from '@effect/schema';
import { Brand } from 'effect';

// ============================================================================
// Basic Schema Patterns
// ============================================================================

// Simple struct schema
const UserSchema = Schema.Struct({
  id: Schema.String,
  name: Schema.String,
  email: Schema.String,
  age: Schema.Number,
  isActive: Schema.Boolean,
});

// Extract TypeScript type from schema
export type User = Schema.Schema.Type<typeof UserSchema>;

// ============================================================================
// Optional Fields
// ============================================================================

const ProductSchema = Schema.Struct({
  id: Schema.String,
  name: Schema.String,
  price: Schema.Number,

  // Optional fields
  description: Schema.optional(Schema.String),
  category: Schema.optional(Schema.String),
  tags: Schema.optional(Schema.Array(Schema.String)),
});

export type Product = Schema.Schema.Type<typeof ProductSchema>;

// ============================================================================
// Nullable Fields (Union with Null)
// ============================================================================

const OrderSchema = Schema.Struct({
  id: Schema.String,
  userId: Schema.String,
  total: Schema.Number,

  // Nullable field (can be null or string)
  shippingAddress: Schema.Union(Schema.String, Schema.Null),

  // Nullable array (can be null or array)
  items: Schema.Union(Schema.Array(Schema.String), Schema.Null),
});

export type Order = Schema.Schema.Type<typeof OrderSchema>;

// ============================================================================
// Nested Schemas
// ============================================================================

const AddressSchema = Schema.Struct({
  street: Schema.String,
  city: Schema.String,
  state: Schema.String,
  zipCode: Schema.String,
  country: Schema.String,
});

const CustomerSchema = Schema.Struct({
  id: Schema.String,
  name: Schema.String,
  email: Schema.String,

  // Nested schema
  shippingAddress: AddressSchema,
  billingAddress: Schema.optional(AddressSchema),

  // Array of nested schemas
  previousAddresses: Schema.Array(AddressSchema),
});

export type Address = Schema.Schema.Type<typeof AddressSchema>;
export type Customer = Schema.Schema.Type<typeof CustomerSchema>;

// ============================================================================
// Enums and Literals
// ============================================================================

// String literals (specific values only)
const OrderStatusSchema = Schema.Literal('pending', 'processing', 'shipped', 'delivered', 'cancelled');

// Union of literals (explicit enum)
const PaymentMethodSchema = Schema.Union(
  Schema.Literal('credit_card'),
  Schema.Literal('debit_card'),
  Schema.Literal('paypal'),
  Schema.Literal('crypto')
);

const PaymentSchema = Schema.Struct({
  id: Schema.String,
  amount: Schema.Number,
  method: PaymentMethodSchema,
  status: OrderStatusSchema,
});

export type OrderStatus = Schema.Schema.Type<typeof OrderStatusSchema>;
export type PaymentMethod = Schema.Schema.Type<typeof PaymentMethodSchema>;
export type Payment = Schema.Schema.Type<typeof PaymentSchema>;

// ============================================================================
// Records (Dynamic Keys)
// ============================================================================

// Record with string keys and specific value type
const UserPreferencesSchema = Schema.Record(Schema.String, Schema.Boolean);

// Record with string keys and union value type
const MetadataSchema = Schema.Record(
  Schema.String,
  Schema.Union(Schema.String, Schema.Number, Schema.Boolean, Schema.Null)
);

// More specific: Record with constrained values
const ScoresSchema = Schema.Record(Schema.String, Schema.Number);

export type UserPreferences = Schema.Schema.Type<typeof UserPreferencesSchema>;
export type Metadata = Schema.Schema.Type<typeof MetadataSchema>;
export type Scores = Schema.Schema.Type<typeof ScoresSchema>;

// ============================================================================
// Arrays
// ============================================================================

// Simple array
const TagsSchema = Schema.Array(Schema.String);

// Array of structs
const CommentSchema = Schema.Struct({
  id: Schema.String,
  userId: Schema.String,
  text: Schema.String,
  createdAt: Schema.Date,
});

const PostSchema = Schema.Struct({
  id: Schema.String,
  title: Schema.String,
  content: Schema.String,
  comments: Schema.Array(CommentSchema),
  tags: Schema.Array(Schema.String),
});

export type Comment = Schema.Schema.Type<typeof CommentSchema>;
export type Post = Schema.Schema.Type<typeof PostSchema>;

// ============================================================================
// Dates and Timestamps
// ============================================================================

const EventSchema = Schema.Struct({
  id: Schema.String,
  name: Schema.String,

  // Date object
  createdAt: Schema.Date,
  updatedAt: Schema.Date,

  // Optional date
  deletedAt: Schema.optional(Schema.Date),

  // Nullable date
  lastSeenAt: Schema.Union(Schema.Date, Schema.Null),
});

export type Event = Schema.Schema.Type<typeof EventSchema>;

// ============================================================================
// Branded Types (Domain Validation)
// ============================================================================

// Email brand with validation
type Email = string & Brand.Brand<'Email'>;

const EmailSchema = Schema.String.pipe(
  Schema.pattern(/^[^@]+@[^@]+$/),
  Schema.brand('Email')
);

// UUID brand with validation
type UUID = string & Brand.Brand<'UUID'>;

const UUIDSchema = Schema.String.pipe(
  Schema.pattern(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i),
  Schema.brand('UUID')
);

// Positive number brand
type PositiveNumber = number & Brand.Brand<'PositiveNumber'>;

const PositiveNumberSchema = Schema.Number.pipe(
  Schema.greaterThan(0),
  Schema.brand('PositiveNumber')
);

// PlayerId brand (domain-specific)
type PlayerId = string & Brand.Brand<'PlayerId'>;

const PlayerIdSchema = Schema.String.pipe(
  Schema.pattern(/^player_[a-zA-Z0-9]+$/),
  Schema.brand('PlayerId')
);

// Using branded types in schemas
const AccountSchema = Schema.Struct({
  id: UUIDSchema,
  email: EmailSchema,
  balance: PositiveNumberSchema,
  playerId: Schema.optional(PlayerIdSchema),
});

export type Account = Schema.Schema.Type<typeof AccountSchema>;

// ============================================================================
// Schema Composition (Extending Schemas)
// ============================================================================

// Base schema
const BaseEntitySchema = Schema.Struct({
  id: Schema.String,
  createdAt: Schema.Date,
  updatedAt: Schema.Date,
});

// Extend base schema
const ArticleSchema = Schema.Struct({
  ...BaseEntitySchema.fields,
  title: Schema.String,
  content: Schema.String,
  authorId: Schema.String,
});

const VideoSchema = Schema.Struct({
  ...BaseEntitySchema.fields,
  title: Schema.String,
  url: Schema.String,
  duration: Schema.Number,
});

export type Article = Schema.Schema.Type<typeof ArticleSchema>;
export type Video = Schema.Schema.Type<typeof VideoSchema>;

// ============================================================================
// Request/Response Pairs
// ============================================================================

// Request schema (input)
const CreateUserRequestSchema = Schema.Struct({
  name: Schema.String,
  email: EmailSchema,
  age: Schema.Number,
});

// Response schema (output)
const CreateUserResponseSchema = Schema.Struct({
  success: Schema.Boolean,
  user: UserSchema,
  message: Schema.optional(Schema.String),
});

// Update request (partial updates)
const UpdateUserRequestSchema = Schema.Struct({
  name: Schema.optional(Schema.String),
  email: Schema.optional(EmailSchema),
  age: Schema.optional(Schema.Number),
  isActive: Schema.optional(Schema.Boolean),
});

export type CreateUserRequest = Schema.Schema.Type<typeof CreateUserRequestSchema>;
export type CreateUserResponse = Schema.Schema.Type<typeof CreateUserResponseSchema>;
export type UpdateUserRequest = Schema.Schema.Type<typeof UpdateUserRequestSchema>;

// ============================================================================
// Union Types (Variants)
// ============================================================================

// Discriminated union (tagged union)
const SuccessResultSchema = Schema.Struct({
  type: Schema.Literal('success'),
  data: Schema.Unknown,
});

const ErrorResultSchema = Schema.Struct({
  type: Schema.Literal('error'),
  error: Schema.String,
  code: Schema.Number,
});

const ResultSchema = Schema.Union(SuccessResultSchema, ErrorResultSchema);

export type Result = Schema.Schema.Type<typeof ResultSchema>;

// ============================================================================
// Complex Nested Structures
// ============================================================================

const WorkflowConfigSchema = Schema.Struct({
  eventType: Schema.String,
  isEnabled: Schema.Boolean,

  // Array of queries
  queries: Schema.Array(Schema.String),

  // Nested record of property mappings
  propertyMappings: Schema.Record(
    Schema.String,
    Schema.Struct({
      source: Schema.String,
      target: Schema.String,
      transform: Schema.optional(Schema.String),
    })
  ),

  // Array of nested semantic field definitions
  semanticFields: Schema.Array(
    Schema.Struct({
      field: Schema.String,
      template: Schema.String,
      embeddingModel: Schema.String,
    })
  ),
});

export type WorkflowConfig = Schema.Schema.Type<typeof WorkflowConfigSchema>;

// ============================================================================
// Validation Functions
// ============================================================================

import { Effect } from 'effect';

// Decode function (Effect-based)
const decodeUser = (input: unknown): Effect.Effect<User, Schema.ParseError> =>
  Schema.decodeUnknown(UserSchema)(input);

// Decode with custom error mapping
const decodeUserWithError = (input: unknown) =>
  Schema.decodeUnknown(UserSchema)(input).pipe(
    Effect.mapError((error) => ({
      type: 'ValidationError' as const,
      message: 'Invalid user data',
      cause: error,
    }))
  );

// Either-based validation (synchronous)
import { Either } from 'effect';

const validateUserSync = (input: unknown): Either.Either<User, Schema.ParseError> =>
  Schema.decodeUnknownEither(UserSchema)(input);

// ============================================================================
// Schema Best Practices
// ============================================================================

/*
1. Schema-First Design
   - Define schemas BEFORE implementation
   - Schemas serve as the contract
   - Implementation follows the schema

2. Type Extraction
   - Always extract TypeScript types with Schema.Schema.Type
   - Export both schemas and types
   - Use types for function signatures

3. Validation at Boundaries
   - Decode ALL external data (HTTP, pub/sub, DB)
   - Validate as early as possible
   - Map parse errors to domain errors

4. Branded Types
   - Use for domain-specific primitives
   - Prevents mixing semantically different values
   - Compile-time safety for IDs, emails, etc.

5. Nullable vs Optional
   - Use Schema.optional for fields that may not be present
   - Use Schema.Union(T, Schema.Null) for fields that can be null
   - Be explicit about the difference

6. Composition
   - Extend base schemas for common fields
   - Reuse schemas (don't duplicate)
   - Build complex schemas from simple ones

7. Documentation
   - Document what each schema represents
   - Document constraints and validation rules
   - Provide examples of valid data

8. Naming Conventions
   - Schema names: PascalCase + "Schema" suffix
   - Type names: Match schema without "Schema"
   - Example: UserSchema → type User

9. Organization
   - Group related schemas together
   - Keep schemas in dedicated files (schemas.ts)
   - Export schemas and types together
*/

// ============================================================================
// Real-World Example from evt-svc
// ============================================================================

/*
// From src/evt-svc/src/schemas.ts:

const SemanticFieldSchema = Schema.Struct({
  field: Schema.String,
  template: Schema.String,
  embeddingModel: Schema.String,
});

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
  semanticFields: Schema.Array(SemanticFieldSchema),
});

export type SemanticField = Schema.Schema.Type<typeof SemanticFieldSchema>;
export type WorkflowConfig = Schema.Schema.Type<typeof WorkflowConfigSchema>;
*/

// ============================================================================
// Usage Example
// ============================================================================

/*
import { Schema } from '@effect/schema';
import { Effect } from 'effect';

// Define schema
const UserSchema = Schema.Struct({
  id: Schema.String,
  name: Schema.String,
  email: Schema.String,
});

type User = Schema.Schema.Type<typeof UserSchema>;

// Validate HTTP response
const fetchUser = (id: string) =>
  Http.get(`/users/${id}`).pipe(
    Http.client.execute,
    Effect.flatMap(response => response.json),
    Effect.flatMap(Schema.decode(UserSchema)), // ← Validation
    Effect.mapError(error => new UserError({ cause: error }))
  );

// Validate pub/sub message
const handleMessage = (rawMessage: unknown) =>
  Effect.gen(function* () {
    const user = yield* Schema.decode(UserSchema)(rawMessage);
    // Process validated user...
  });
*/
