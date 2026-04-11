# Skill Spec: reviewer

## Identity

- **Name**: reviewer
- **Purpose**: development
- **Complexity**: full
- **Description**: Performs comprehensive, multi-aspect code review by orchestrating 6 specialized review passes — code quality, code simplification, comment accuracy, test coverage, error handling, and type design. Each pass runs as a subagent with dedicated instructions, and the orchestrator aggregates all findings into a unified severity-ranked report. Adapted from Anthropic's pr-review-toolkit agents for this project's conventions (Effect-TS, Vue 3, CLAUDE.md rules). Use when reviewing code changes, preparing for a PR, or when the user mentions code review, review my changes, check my code, or PR review.

## Behavior

- **Input**: Optional review aspects to run (e.g., `code errors tests`) and optional scope (defaults to `git diff` of unstaged changes). Accepts `all` (default), or any combination of: `code`, `simplify`, `comments`, `tests`, `errors`, `types`.
- **Output format**: mixed (structured markdown report)
- **Output structure**: Single aggregated report with sections per aspect. Each subagent produces its own findings, orchestrator merges into: Critical Issues → Important Issues → Suggestions → Strengths.
- **Operations**:
  1. **Scope determination** — identify changed files via git diff (script)
  2. **Aspect selection** — parse user args to determine which review passes to run
  3. **Subagent dispatch** — spawn one subagent per selected review aspect, each receiving its dedicated instruction file + the diff scope
  4. **Result aggregation** — collect all subagent reports, deduplicate, rank by severity
  5. **Report generation** — produce unified review report using output template
- **External dependencies**: `git` CLI, project's CLAUDE.md/rules for standards context

## File Plan

- **scripts/**:
  - `get-review-scope.sh` — extracts changed files and diff from git. Supports `--staged`, `--branch <base>`, `--files <path...>` flags. Outputs JSON with `{ files: [...], diff: "...", stats: { added, modified, deleted } }`.

- **references/**:
  - `REFERENCE.md` — orchestration workflow, aspect selection logic, aggregation rules, severity classification
  - `FORMS.md` — structured intake for review requests
  - `code-reviewer.md` — subagent instructions for general code quality review (confidence scoring, CLAUDE.md compliance, bug detection). Adapted from Anthropic's code-reviewer agent.
  - `code-simplifier.md` — subagent instructions for simplification pass (clarity, nesting, redundancy, project standards). Adapted from Anthropic's code-simplifier agent.
  - `comment-analyzer.md` — subagent instructions for comment accuracy audit (factual verification, rot detection, maintainability). Adapted from Anthropic's comment-analyzer agent.
  - `test-analyzer.md` — subagent instructions for test coverage analysis (behavioral coverage, critical gaps, test quality, criticality rating). Adapted from Anthropic's pr-test-analyzer agent.
  - `error-handler-auditor.md` — subagent instructions for silent failure hunting (catch block specificity, logging quality, user feedback, fallback behavior). Adapted from Anthropic's silent-failure-hunter agent.
  - `type-analyzer.md` — subagent instructions for type design quality (encapsulation, invariant expression/usefulness/enforcement, anti-patterns). Adapted from Anthropic's type-design-analyzer agent.

- **assets/**:
  - `review-report-template.md` — output skeleton for the aggregated review report (header, per-aspect sections, summary counts, action plan)

## Edge Cases

- **No changed files**: If `git diff` returns empty, report "No changes detected" and suggest specifying files or a base branch.
- **Subagent failure**: If one aspect's subagent fails or returns empty, include a warning in the report and continue with remaining aspects. SRP means each aspect is independent.
- **Large diffs**: If diff exceeds ~2000 lines, warn the user and suggest narrowing scope to specific files or directories.
- **No CLAUDE.md**: If project has no CLAUDE.md or rules, the code-reviewer and code-simplifier still work — they just skip the "project guidelines compliance" checks and note this in their output.
- **Aspect not applicable**: If `types` is requested but no type definitions were changed, skip that aspect with a note rather than running an empty analysis.

## Open Questions

- **Subagent model**: In Copilot Chat, subagents inherit the current model. The original Anthropic agents specify `model: opus` for code-reviewer and code-simplifier. Should we note a model recommendation in the reference files, or leave it to the runtime? → **Decision: leave it to runtime** — Copilot Chat doesn't support model overrides, and the prompts work well with any capable model.
- **Parallel vs sequential**: Copilot Chat's `runSubagent` is sequential (not parallel like Claude Code's Task tool). Should the skill explicitly state sequential execution? → **Decision: yes**, document as sequential with a note that parallel is model-dependent.
- **Interactive mode**: Should the skill support a "fix issues" mode after review, or stay read-only? → **Decision: read-only**. Fixing is a separate concern (SRP). The review skill reports; separate skills/commands handle fixes.
