# PR Review Report

## Scope

- **Mode**: {{MODE}}
- **Files reviewed**: {{FILE_COUNT}}
- **Aspects run**: {{ASPECTS_RUN}}
- **Aspects skipped**: {{ASPECTS_SKIPPED}}

---

## Critical Issues ({{CRITICAL_COUNT}})

> Must fix before merge.

{{#CRITICAL_ISSUES}}
### [{{ASPECT}}] {{DESCRIPTION}}
- **File**: {{FILE}}:{{LINE}}
- **Confidence**: {{CONFIDENCE}}
- **Details**: {{DETAILS}}
- **Fix**: {{RECOMMENDATION}}
{{/CRITICAL_ISSUES}}

{{#NO_CRITICAL}}
No critical issues found.
{{/NO_CRITICAL}}

---

## Important Issues ({{IMPORTANT_COUNT}})

> Should fix.

{{#IMPORTANT_ISSUES}}
### [{{ASPECT}}] {{DESCRIPTION}}
- **File**: {{FILE}}:{{LINE}}
- **Details**: {{DETAILS}}
- **Fix**: {{RECOMMENDATION}}
{{/IMPORTANT_ISSUES}}

{{#NO_IMPORTANT}}
No important issues found.
{{/NO_IMPORTANT}}

---

## Suggestions ({{SUGGESTION_COUNT}})

> Nice to have.

{{#SUGGESTIONS}}
- [{{ASPECT}}] {{DESCRIPTION}} — {{FILE}}:{{LINE}}
{{/SUGGESTIONS}}

{{#NO_SUGGESTIONS}}
No suggestions.
{{/NO_SUGGESTIONS}}

---

## Strengths

{{#STRENGTHS}}
- {{OBSERVATION}}
{{/STRENGTHS}}

---

## Verdict

{{VERDICT}}

### Recommended Actions
1. Fix all critical issues
2. Address important issues
3. Consider suggestions
4. Re-run `reviewer` after fixes to verify
