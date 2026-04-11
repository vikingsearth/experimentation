---
name: plan-development
description: Creates and maintains structured development plan documents for implementation work. Initializes plans from the project template, tracks use case and feature progress with checklists, performs gap analysis, and updates plan status as work completes. Use when creating a development plan, updating plan progress, performing gap analysis, or when the user mentions planning implementation work.
compatibility: Designed for Claude Code and GitHub Copilot with shell access.
metadata:
  author: nebula-aurora
  version: "0.1.0"
  purpose: development
  type: P1
disable-model-invocation: false
user-invocable: true
argument-hint: "Describe what you want to plan or update (e.g., 'create plan for auth refactor', 'mark user-identity backend complete')"
---

# Plan Development

Creates and maintains structured development plan documents that track use cases, features, and implementation progress through checklists.

## When to Use

- User wants to create a new development plan for a feature or refactor
- User wants to update progress on an existing plan (mark tasks done, add use cases)
- User asks for a gap analysis on current implementation progress
- User wants to see the current status of a plan
- User says "plan", "create a plan", "update the plan", "what's the status", "gap analysis"

## Design Principles

**Plan as single source of truth**: The plan at `.tmp/state/plan.md` is the canonical record of what needs to be done and what's been completed. Other skills and workflows defer to this skill for plan management.

**Use case → feature → task hierarchy**: Plans are structured as nested checklists. Use cases contain features, features contain implementation tasks (database, backend, frontend, integration). This mirrors the `__plan.md` template.

**Status is always current**: After every implementation change, the CURRENT STATUS section must be updated to reflect reality. Stale status is worse than no status.

## Operation Detection

Infer the operation from user intent. If ambiguous, ask.

| User says... | Operation |
|-------------|-----------|
| "create a plan for X", "plan out X", "new plan" | **create** |
| "mark X as done", "update the plan", "add a use case" | **update** |
| "gap analysis", "what's left", "what remains" | **gap-analysis** |
| "plan status", "where are we", "show progress" | **status** |

## Workflow

### create

1. Run `bash scripts/init-plan.sh` to scaffold `.tmp/state/plan.md` from the template.
2. Read the created plan file.
3. Fill in the **User Requirement** section with the summary, affected files, and scope from the user's description.
4. Structure use cases and features as nested checklists following the template pattern.
5. Define the **Integration Verification Strategy** with concrete validation steps.
6. Initialize the **CURRENT STATUS** section with all items unchecked.
7. Present the plan to the user for review. Iterate if needed.

### update

1. Read `.tmp/state/plan.md` to understand current state.
2. Apply the requested changes:
   - **Mark complete**: Change `- [ ]` to `- [x]` (or `- ✅`) for completed items.
   - **Add use case/feature**: Insert new checklist blocks following the existing structure.
   - **Update status**: Refresh the CURRENT STATUS section to reflect current reality.
3. Write the updated plan back.

### gap-analysis

1. Read `.tmp/state/plan.md` for planned work.
2. Read relevant design docs (`docs/designs/architecture.md`, `docs/designs/use_cases.md`) for requirements.
3. Compare planned vs actual progress.
4. Produce `.tmp/state/gap_analysis.md` with:
   - What's been completed
   - What remains for the current iteration
   - Blockers or dependencies
   - Recommended focus areas

### status

1. Read `.tmp/state/plan.md`.
2. Count completed vs total checklist items.
3. Present a summary: completed tasks, in-progress tasks, remaining tasks, and any blockers.

## Example Inputs

- "Create a development plan for the auth refactor affecting ctx-svc and frontend"
- "Mark the backend implementation for user-identity as complete"
- "Run a gap analysis on the current plan"
- "What's the status of the plan?"
- "Add a new use case for event tracking to the plan"

## Edge Cases

- **No existing plan**: If `update`, `gap-analysis`, or `status` is requested but `.tmp/state/plan.md` doesn't exist, offer to create one first.
- **Plan already exists on create**: Ask the user whether to overwrite or update the existing plan.
- **Minimal input**: If the user says "create a plan" without context, ask for the feature/requirement summary and affected files/services.
- **Gap analysis without design docs**: If `docs/designs/architecture.md` or `docs/designs/use_cases.md` don't exist, perform gap analysis using only the plan file and note the missing context.

## File References

| File | Purpose | When loaded |
|------|---------|-------------|
| `references/REFERENCE.md` | Plan anatomy, conventions, workflow relationship | During all operations |
| `scripts/init-plan.sh` | Scaffold `.tmp/state/` and copy plan template | During create |
| `scripts/validate-plan.sh` | Validate plan structure | During create/update |
| `assets/plan-template.md` | Plan document template | During create |
