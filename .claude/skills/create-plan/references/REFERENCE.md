# Plan Development Reference

## Plan Anatomy

A development plan follows a strict hierarchy that mirrors the `__plan.md` template:

```
Plan
├── User Requirement (summary + affected files)
├── Use Case Implementation & Testing Strategy
│   └── USE CASE: <name>
│       └── FEATURE: <name>
│           ├── Database Updates Implementation
│           ├── Backend Implementation
│           ├── Frontend Implementation
│           └── Integration Verification
├── Continuous Validation (build/test verification steps)
└── CURRENT STATUS (mirror of the use case tree with ✅/[ ] markers)
```

### User Requirement Section

- **summary**: One-line description of what the plan covers
- **Files affected**: List of files/services that will be created or modified

### Use Case Structure

Each use case contains one or more features. Each feature has up to four implementation layers:

| Layer | Contents |
|-------|----------|
| Database Updates | Schema changes, migrations, seed data |
| Backend | Manager layer (orchestration), Engine layer (business logic), API routes and validation |
| Frontend | Components, state management, API integration, forms, responsive design |
| Integration Verification | Frontend ↔ Backend connectivity, DB persistence, end-to-end error handling |

Not every feature needs all four layers. Omit layers that don't apply.

### Checklist Syntax

Use markdown checkboxes for tracking:

```markdown
- [ ] Not started
- [x] Completed (or use ✅ emoji prefix)
- ✅ Completed (alternative)
```

Nesting conveys hierarchy — indent with 2 spaces per level:

```markdown
- [ ] **USE CASE**: User Authentication
  - [ ] **FEATURE**: Login flow
    - [ ] **Backend Implementation**:
      - [ ] POST /api/auth/login endpoint
      - [ ] JWT token generation
    - [ ] **Frontend Implementation**:
      - [ ] LoginForm component
```

### CURRENT STATUS Section

The CURRENT STATUS section is a **mirror** of the use case tree that reflects actual progress. It must be updated after every implementation change. Rules:

1. Every item in the use case tree appears in CURRENT STATUS
2. Completed items use `✅` prefix
3. Incomplete items use `- [ ]` prefix
4. Status is updated immediately — never batch updates

### Continuous Validation Section

Defines the verification steps that confirm the system still works after changes:

```markdown
- [ ] Confirmed frontend still builds
- [ ] Confirmed backend still builds
- [ ] Confirmed new functionality works as expected
- [ ] Confirmed existing tests pass
```

### Automatic Continuation Rules

Plans include continuation rules that tell the implementing agent to keep going without pausing for approval:

```markdown
✅ PRINT milestone status for visibility
✅ DISPLAY progress updates for tracking
❌ NEVER PAUSE for user acknowledgment
❌ NEVER WAIT for milestone approval
```

## Relationship to Other Skills

The **create-plan** skill owns plan management: read plan, gap analysis, update plan. Other skills and workflows defer to this skill for plan creation and status tracking.

## Plan File Location

Plans live at `.tmp/state/plan.md`. The `.tmp/` directory is for transient working state that may be regenerated. The `state/` subdirectory groups plan artifacts together.

Gap analysis goes to `.tmp/state/gap_analysis.md` alongside the plan.

## Quality Checklist

- [ ] User Requirement section has a clear summary
- [ ] Files affected list is populated
- [ ] At least one USE CASE with at least one FEATURE
- [ ] Each feature has relevant implementation layers
- [ ] Integration Verification defined per feature
- [ ] Continuous Validation section has concrete checks
- [ ] CURRENT STATUS section mirrors the use case tree
- [ ] No orphaned checklist items (every item in a named section)
