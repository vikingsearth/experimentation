---
paths:
  - "src/frontend/**"
---

# Frontend Architecture Patterns

## Module Federation

- Exposed components defined in `vite.config.ts` via `@originjs/vite-plugin-federation`
- `federation-entry.ts` exports components — **never import global CSS here**
- Shared deps (`vue`, `pinia`) are singletons — host and remote share one instance
- Federation-exposed components must be fully self-contained with scoped styles
- Build target: `es2023`, no module preload, no CSS code splitting

## WebSocket

- Singleton `WebSocketService` with connection lifecycle, heartbeat, and auto-reconnect
- Connection generation tracking: increment on reconnect, skip stale handler callbacks
- Subscription pattern: `onMessage()` / `onStatusChange()` return unsubscribe functions
- Connection states: `connecting` → `connected` → `disconnected` / `error` / `auth_error`
- Heartbeat interval: 30s, reconnect: up to 20 attempts with 1s base delay

## Message System

- `AuroraMessage` is the canonical message type across all services
- `routeMessage()` classifies incoming messages: `stream_event`, `completion`, `heartbeat`, `start`, `user_message`, `ai_message`, `ignored`
- Stable message IDs (`_id`) for Vue `:key` — use `crypto.randomUUID()` with counter fallback
- Deduplication: filter ephemeral messages, detect duplicate final responses by content comparison
- Streaming: accumulator pattern in chat store, finalize on completion message with merged metadata
- `shouldUpdateStreamingMessage()` decides whether to update last message or add new one

## Runtime Configuration

- `window.envconfig` injected via `envconfig.js` (Docker runtime injection)
- Fallback to `import.meta.env.VITE_*` for local dev
- Dynamic URL resolution: `getApiBaseUrl()` / `getWebSocketUrl()` per-request, not at startup
- Dev mode: Vite proxy handles API calls (empty base URL), WebSocket connects to `localhost:3001`

## Feature Flags

- `VITE_*` env vars evaluated at startup in `useFeatureFlags()` composable
- Exposed as `computed()` refs for reactive UI binding
- Flags: memories, voice input, image upload, PWA
- Flags are constants (not runtime-toggleable) — requires app restart to change

## App Modes

- Standalone: full Vue Router, owns routes (`/chat`, `/settings`)
- Embedded (module federation): no router, host app controls navigation
- Detection: `useAppMode()` checks if router has Aurora routes (`router.hasRoute('chat')`)
- Services receive mode-appropriate base URLs via DI config
