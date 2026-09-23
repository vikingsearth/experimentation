# Problem statement - token burn from agent fan-out

Date: 2026-09-07
Status: draft, agreed between Wikus and Claude in session
Related: [hypothesis_1.md](hypothesis_1.md)

## The gripe, as originally stated

> When working with you while using the Fable model, it uses up my 5h window
> very very fast whenever it spawns a swarm of agents to do work. Same for Opus
> if I'm running multiple sessions in parallel.
>
> Is there a way to have it use e.g. ollama hosted local models to do that work
> instead? Or for Opus to spawn processes that use local models to do work to
> save token costs?
>
> Basically, the overarching question is "how can we reduce token usage and
> increase output while maintaining quality".

## What "quality" means here

Wikus's definition, kept verbatim because every later measurement hangs off it:

| Dimension | What is measured |
|---|---|
| Depth | How far the solution goes - not a surface pass |
| Standards | How well the work keeps to the expected work standards (rules, conventions, style) |
| Alignment | How closely it matches the user's problem statement(s) or requirement(s) |
| Effectivity | Whether it is the *right* fix. Not the complex one, not the oversimplified one, not the one that goes a different direction, and not the deferment ("I can't do it, the user has to") |

## Claude's take on the problem

### What is actually being spent

The 5-hour window is a shared budget across every Claude Code session on the
subscription. Three things drain it faster than solo work:

1. **Every subagent is a full session in miniature.** Each one receives the
   whole Claude Code system prompt, the project rules, the skill listing and the
   memory index before it reads a single project file. That fixed overhead is
   paid once per agent, so 25 agents pay it 25 times.
2. **Subagents re-read what the manager already read.** A fan-out for analysis
   typically has every worker open the same handful of core files. The manager
   then reads all their reports back in. The same content crosses the wire
   several times.
3. **Model weighting.** Usage against the window is not a flat token count. A
   Fable or Opus token counts for far more than a Haiku token. A swarm that
   inherits the manager's model multiplies the most expensive token type.

The parallel-sessions case is the same problem from another side: several
independent managers, each paying the full overhead, all from one window.

### Why this hurts more than it should

The failure is a cliff, not a slope. When the window is exhausted the session
does not slow down, it stops, and the in-flight fan-out's work is lost with it.
A serial pass that takes twice as long still finishes. That asymmetry is why the
standing "one subagent at a time" rule exists, and it is also why that rule is a
workaround rather than a fix: it trades wall-clock and breadth for survival.

### ELI5 - why the window drains

Think of the window as a prepaid phone card and each agent as a separate phone
call. Every call starts with the same five-minute preamble (the system prompt)
before anyone says anything useful. Twenty-five calls means twenty-five
preambles. And calls made on the premium line (Fable) cost several times more
per minute than calls on the basic line (Haiku). A swarm is many premium calls
that each start with the same preamble.

### Reframing the question

The gripe asks "can the swarm run on local models". The underlying need is
narrower and more testable:

> Move the *cheap, parallel, mechanical* part of agent work off the
> subscription window, while keeping the *judgment* part on the strongest
> model available, without lowering the four quality dimensions above.

That split matters because the two halves have different requirements:

| Half | Examples | What it needs from a model |
|---|---|---|
| Mechanical | Find every caller of X, summarise this file, list tests touching Y, draft a table from these inputs | Reliable tool use, decent reading comprehension, cheap, parallel |
| Judgment | Decide the right fix, hold the work standards, synthesise 20 reports into one answer, notice what the workers missed | Strongest available reasoning, full context of the requirement |

The manager/worker split already exists in how Claude Code fans out. The
proposal is only to let the two halves run on different engines.

### What is not the problem

- **Not** the model being "too smart" for simple tasks. The cost is in the
  fixed overhead and the multiplication, not in the manager's own reasoning.
- **Not** a lack of local compute. The machine (Apple M3 Pro, 36 GB unified
  memory) already runs a 30B mixture-of-experts model under ollama. The open
  question is whether that model is *good enough for the mechanical half*, and
  how many of them can run at once.
- **Not** solvable by prompt discipline alone. Telling the manager to spawn
  fewer agents is the current rule, and it caps output rather than raising it.

## Constraints on any solution

| Constraint | Why |
|---|---|
| Manager stays on Fable or Opus | The judgment half is where the four quality dimensions are won or lost |
| Worker output must be verifiable by the manager | Smaller models fabricate paths, defer, or oversimplify. The manager must be able to catch it cheaply |
| Local only, or company-internal infrastructure | This is a personal workflow on a company machine. No public hosting, no unvetted downloads, credentials in a gitignored `.env` |
| The machine is a laptop | 36 GB unified memory shared between the OS, the editor, the browser and every local model instance. Sustained load throttles |
| Must not break the sequential fallback | If the worker tier is down, the current one-at-a-time flow must still work unchanged |

## Success looks like

- More manager-level work completed per 5-hour window on fan-out-heavy tasks,
  measured, not felt.
- No drop in the four quality dimensions on a fixed set of benchmark tasks,
  graded blind by an independent session.
- The one-at-a-time rule becomes a choice rather than a survival tactic.

**Complete results across every arm: [results_ladder.md](results_ladder.md)**

**Follow-on analysis: [results_multiworker.md](results_multiworker.md)** - running one cheap worker several times lifts coverage 38% to 62%, and cannot reach the rest

The concrete hypotheses and the test plans live in:

| Document | Question it tests |
|---|---|
| [hypothesis_1.md](hypothesis_1.md) | Can subagent work leave the subscription window entirely, by running on local models? |
| [hypothesis_2.md](hypothesis_2.md) | Among Anthropic models, how far down can the subagent tier go before quality drops? |
| [hypothesis_2_1.md](hypothesis_2_1.md) | The same five briefs run on local models, extending the tier ladder below Haiku |
| [hypothesis_3.md](hypothesis_3.md) | Does a separate verification tier beat paying for stronger subagents? One spike run |
| [hypothesis_4.md](hypothesis_4.md) | Can the local tier be made fast? **Yes, 15x.** See [results_4.md](results_4.md) |
| [hypothesis_5.md](hypothesis_5.md) | Which open model, once speed is solved? **None better than gemma.** See [results_5.md](results_5.md) |
