# Discussion Facilitation Guide

Guidance for the agent on how to facilitate ideation discussions effectively. Read this when actively facilitating a discussion.

## Core Approach

You are a thinking partner, not a transcription service. Your job is to:

1. **Deepen ideas** — ask probing questions, not just "what else?"
2. **Capture dissent** — trade-offs and rejected alternatives are as valuable as the chosen path
3. **Track threads** — notice when an open question goes unresolved and surface it later
4. **Recognise maturity** — know when an idea is ready to spin out or when the discussion is ready to refine

## Probing Techniques

### Clarification
- "When you say X, do you mean A or B?"
- "What would that look like concretely?"
- "Can you give me an example?"

### Implication
- "If we go with X, what does that mean for Y?"
- "What's the failure mode here?"
- "Who else would be affected?"

### Trade-off surfacing
- "What are we giving up by choosing X?"
- "Is there a simpler version of this that gets us 80%?"
- "What's the cost of NOT doing this?"

### Constraint testing
- "Does this still work if [constraint]?"
- "What assumptions are we making?"
- "What would change your mind about this approach?"

## Scratchpad Discipline

### What to capture

- Every distinct idea, even rough ones (tag as `[idea]`)
- Explicit decisions and their reasoning (tag as `[decision]`)
- Unresolved questions — especially ones the user glosses over (tag as `[open-question]`)
- Context the user provides — current state, constraints, history (tag as `[context]`)
- Direction changes (tag as `[pivot]`)
- Trade-off analyses (tag as `[trade-off]`)
- Concrete next steps identified (tag as `[action]`)

### What NOT to capture

- Back-and-forth clarification dialogue (capture the clarified understanding, not the exchange)
- Pleasantries, meta-discussion about the skill itself
- Duplicate restatements of the same idea (reference the original entry)

### Entry quality

Each entry should be understandable without the conversation context. Write in third person, as if someone else will read the scratchpad later. Include enough context that the entry stands alone.

**Good**: `[idea] Introduce a message queue between agent-proxy-svc and aurora-ai to decouple processing from delivery. This would allow aurora-ai to process at its own pace without blocking the WebSocket response path.`

**Bad**: `[idea] Use a queue. User thinks this would be good.`

## Spin-Out Recognition

An idea is ready to spin out when:

- The user has explored it from multiple angles (pros, cons, implications)
- You find yourself writing a scratchpad entry that's getting long (> 10 lines)
- The idea has internal structure (components, steps, alternatives)
- It could meaningfully inform implementation decisions

Suggest it naturally: "This event sourcing approach is taking shape — want me to pull it into its own doc so we can develop it further?"

Don't force it. If the user says "not yet" or keeps exploring, keep it in the scratchpad.

## Refine Readiness

A discussion is ready to refine when:

- Key decisions have been made (check for `[decision]` entries)
- Major open questions are resolved (or explicitly deferred)
- The user signals closure: "ok where are we?", "let's wrap this up", "summarize"
- There are actionable next steps identified

If the user asks to refine too early (< 3 substantive entries), say so: "We've only captured a few points so far. Want to explore a bit more before summarizing, or should I work with what we have?"

## Pivot Handling

When the user changes direction:

1. Acknowledge the pivot explicitly — don't silently switch
2. Ask what to preserve: "Which of the ideas we've explored still apply?"
3. Archive the old scratchpad with a date prefix
4. Assess concept docs individually — some may still be relevant
5. Start fresh with a `[pivot]` entry that explains the direction change and references the archive

Pivots are not failures — they're a natural part of ideation. Preserve the history.

## Thread Tracking

Keep a mental model of open threads. Periodically (every 5-10 exchanges, or when there's a natural pause):

- Surface unresolved `[open-question]` entries
- Ask if any should be addressed before moving forward
- Note threads that have been implicitly resolved by later discussion

## Multi-Session Continuity

When resuming a topic after a break:

1. Read the existing scratchpad and concept docs
2. Provide a brief "where we left off" summary
3. Surface any open questions or threads
4. Ask the user where they want to pick up

Don't repeat the entire discussion — just enough context to resume productively.
