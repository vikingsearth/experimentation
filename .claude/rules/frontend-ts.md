---
paths:
  - "src/frontend/**/*.ts"
---

# Frontend TypeScript Conventions

## Pinia Stores

- Composition API style: `defineStore('id', () => { ... })` — never Options API stores
- State as `ref()`, getters as `computed()`, actions as plain functions
- Map reactivity: create a new `Map()` copy to trigger Vue reactivity (Vue can't track Map mutations in-place)
- Store files in `stores/<domain>.store.ts`, export `useXxxStore`

```ts
export const useChatStore = defineStore('chat', () => {
  const sessions = ref<Map<string, ChatSession>>(new Map());

  const activeSession = computed(() =>
    activeSessionId.value ? sessions.value.get(activeSessionId.value) : null
  );

  function createSession(id: string, session: ChatSession) {
    const updated = new Map(sessions.value); // New Map for reactivity
    updated.set(id, session);
    sessions.value = updated;
  }

  return { sessions, activeSession, createSession };
});
```

## Composables

- Naming: `useXxx` prefix, domain-grouped in `composables/<domain>/`
- Barrel exports via `composables/<domain>/index.ts`
- Accept handler objects as parameters for dependency injection
- Return cleanup functions from subscription-based composables
- Lifecycle hooks (`onMounted`, `onBeforeUnmount`) only in top-level composables — pure logic composables stay lifecycle-free

```ts
export function useWebSocketConnection(handlers: {
  handleCompletionMessage: (msg: AuroraMessage, chatId: string) => Promise<void>;
  handleStreamingEvent: (event: StreamEvent) => Promise<void>;
}) {
  const error = ref<string | null>(null);
  let cleanup: (() => void) | null = null;

  onMounted(() => { cleanup = subscribe(handlers); });
  onBeforeUnmount(() => { cleanup?.(); });

  return { error };
}
```

## Services

- Class-based singletons with `interface` + `class` separation for testability
- DI via config objects passed to constructor (`ApiServiceConfig`, `WebSocketConfig`)
- Subscription pattern: handler registration returns an unsubscribe function
- Error wrapping: catch and wrap in typed `ServiceError` subclasses — never throw raw errors

```ts
export interface IApiService {
  get<T>(url: string): Promise<ApiResponse<T>>;
}

class ApiService implements IApiService { /* ... */ }

// Subscriptions
onMessage(callback: MessageHandler): () => void {
  this.handlers.add(callback);
  return () => this.handlers.delete(callback);
}
```

## Type Definitions

- Types in `types/` directory with barrel export via `types/index.ts`
- `interface` for object shapes, `type` for unions and utilities
- Regular `enum` (not const enum) — allows runtime introspection
- No `I` prefix on interfaces — use descriptive names (`ApiResponse`, not `IApiResponse`)
- Abstract base class `ServiceError` hierarchy for error types
- `Result<T>` pattern: `{ success: true; data: T } | { success: false; error: ServiceError }`

```ts
// Result pattern
export type Result<T> =
  | { success: true; data: T }
  | { success: false; error: ServiceError };

export async function toResult<T>(promise: Promise<T>): Promise<Result<T>> {
  try { return { success: true, data: await promise }; }
  catch (e) { return { success: false, error: toServiceError(e) }; }
}
```

## Imports

- `@/` alias for all absolute imports (maps to `src/`)
- `import type` for type-only imports (tree-shaking)
- Ordering: Vue/external → types → services/stores → utils → relative

```ts
import { ref, computed, onMounted } from 'vue';
import type { AuroraMessage } from '@/types';
import { useChatStore } from '@/stores/chat.store';
import { debug } from '@/utils/core/debug';
```

## Utilities

- Organise in `utils/<domain>/` (core, messaging, formatting, storage)
- Pure functions — no side effects, no store dependencies
- Debug logging: semantic tags with `import.meta.env.DEV` guards

```ts
export const debug = {
  routing: (...args: any[]) => DEBUG_FLAGS.messageRouting && console.log('[MessageRouter]', ...args),
  stream: (...args: any[]) => DEBUG_FLAGS.streaming && console.log('[Streaming]', ...args),
};
```

## Anti-patterns

- Don't use `reactive()` for store state — `ref()` is standard
- Don't destructure store state without `storeToRefs()` — loses reactivity
- Don't mutate `Map`/`Set` refs in-place — always create a new instance
- Don't throw raw `Error` from services — wrap in `ServiceError` subclass
