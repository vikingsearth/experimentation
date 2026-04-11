# Skill Spec: plan-development

## Identity

- **Name**: plan-development
- **Purpose**: development
- **Complexity**: standard
- **Description**: Creates and maintains structured development plan documents for implementation work. Initializes plans from the project template, tracks use case and feature progress with checklists, performs gap analysis, and updates plan status as work completes. Use when creating a development plan, updating plan progress, performing gap analysis, or when the user mentions planning implementation work.

## Behavior

- **Input**: User describes a feature, requirement, or implementation scope via natural language (optionally with affected files/services)
- **Output format**: Markdown plan document following the `__plan.md` template
- **Output structure**: Primary artifact — `.tmp/state/plan.md`. May also produce `.tmp/state/gap_analysis.md` for focused iteration analysis.
- **Operations**:
  1. **create** — Initialize a new plan from the `__plan.md` template, filling in the user requirement summary, affected files, use case structure, and validation strategy
  2. **update** — Modify an existing plan: mark tasks complete/in-progress, add new use cases or features, update the CURRENT STATUS section
  3. **gap-analysis** — Read the current plan + relevant design docs, produce a gap analysis identifying what remains for the current iteration
  4. **status** — Display the current plan's progress: completed vs remaining tasks, blockers, next steps
- **External dependencies**: Filesystem access

## File Plan

- **SKILL.md** — router, workflow steps, operation detection, design principles, file references
- **scripts/**:
  - `init-plan.sh` — creates `.tmp/state/` directory and copies the plan template into `.tmp/state/plan.md`, outputs the file path
  - `validate-plan.sh` — validates a plan file against structural requirements (required sections, checklist syntax, status section present)
- **references/**:
  - `REFERENCE.md` — domain context: plan anatomy, use case structure patterns, checklist conventions, status tracking rules, relationship to workflow files
- **assets/**:
  - `plan-template.md` — the plan document template
