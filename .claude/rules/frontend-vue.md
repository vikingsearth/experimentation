---
paths:
  - "src/frontend/**/*.vue"
---

# Vue Component Conventions

## Component Structure

- Always use `<script setup lang="ts">` — no Options API, no `<script>` without `setup`
- Block order: `<script setup>` → `<template>` → `<style>`
- One component per file, PascalCase filenames (`ChatPanel.vue`, `MessageBubble.vue`)
- Organise components in kebab-case domain directories (`chat/`, `smart-panel/`, `settings/`)

## Props & Emits

- Define props with TypeScript generics: `defineProps<{ title: string; count?: number }>()`
- Use `withDefaults()` for optional props with defaults
- Define emits with typed events: `defineEmits<{ (e: 'update', value: string): void }>()`
- Never mutate props directly — emit events or use `v-model` with `defineModel()`

```vue
const props = withDefaults(defineProps<{
  messages: AuroraMessage[];
  isStreaming?: boolean;
}>(), {
  isStreaming: false,
});

const emit = defineEmits<{
  (e: 'send', text: string): void;
  (e: 'cancel'): void;
}>();
```

## Template Patterns

- `:key` with stable IDs (use `message._id` or `session.id`), never array index
- `v-if` for structural show/hide (removes from DOM), `v-show` for visibility toggles (frequent changes)
- Named slots for extensibility in shared components
- Prefer `computed()` over inline expressions in templates for complex logic

```vue
<div v-for="msg in messages" :key="msg._id">
  <MessageBubble v-if="msg.role === 'ai'" :message="msg" />
</div>

<slot name="header" :session="activeSession" />
```

## State & Reactivity

- Access Pinia stores via `useXxxStore()` composables
- Use `storeToRefs()` to destructure reactive state from stores — plain destructuring loses reactivity
- Use `computed()` for derived values, `watch()` for side effects
- Prefer `ref()` over `reactive()` for component state

```vue
const chatStore = useChatStore();
const { activeSession, isLoading } = storeToRefs(chatStore);

const messageCount = computed(() => activeSession.value?.messages.length ?? 0);
```

## Styling

- Tailwind utility classes as primary styling — apply directly in template
- Scoped `<style scoped>` for component-specific CSS
- Use `@apply` in scoped styles only for repeated utility combinations
- No CSS modules — Tailwind handles utility extraction
- Federation-exposed components must use scoped styles only (no global CSS leakage)

## Anti-patterns

- Don't use Options API (`data()`, `methods`, `computed` object syntax)
- Don't use `this` — `<script setup>` has no component instance
- Don't import global CSS in federation entry (`federation-entry.ts`)
- Don't use array index as `:key` — causes stale renders with dynamic lists
