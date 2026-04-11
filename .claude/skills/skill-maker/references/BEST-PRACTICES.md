# Skill Authoring Best Practices

> Condensed from [Anthropic best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) and the Agent Skills docs.

## Core Principles

### 1. Be Concise

Claude is smart. Only add context it doesn't already have. Challenge each paragraph: "Does this justify its token cost?"

**Good** (~50 tokens):

```markdown
## Extract PDF text
Use pdfplumber:
\`\`\`python
import pdfplumber
with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
\`\`\`
```

**Bad** (~150 tokens): Explaining what PDFs are and which libraries exist before showing the code.

### 2. Match Freedom to Fragility

| Freedom level | When | Example |
| ------------- | ---- | ------- |
| **High** (text instructions) | Multiple valid approaches, context-dependent | Code review guidelines |
| **Medium** (pseudocode/params) | Preferred pattern with acceptable variation | Report generation |
| **Low** (exact scripts) | Fragile ops, consistency critical | Database migrations |

### 3. Write Third-Person Descriptions

The description is injected into the system prompt. Inconsistent POV causes discovery problems.

- **Good**: "Processes Excel files and generates reports"
- **Bad**: "I can help you process Excel files"
- **Bad**: "You can use this to process Excel files"

### 4. Use Consistent Terminology

Pick one term and stick with it throughout the skill. Don't mix "API endpoint" / "URL" / "route" / "path".

## Structure Guidelines

### Naming

- Prefer gerund form: `processing-pdfs`, `analyzing-data`, `managing-databases`
- Acceptable alternatives: `pdf-processing`, `process-pdfs`
- Avoid: `helper`, `utils`, `tools`, `documents` (too vague)

### Progressive Disclosure

- SKILL.md = overview + navigation (< 500 lines)
- Detail lives in references/ (loaded on demand)
- Keep file references one level deep
- Add table of contents to reference files > 100 lines

### Description Field

Must include:

1. **What** the skill does (specific verbs + nouns)
2. **When** to use it (triggers, contexts, keywords)

```yaml
# Good
description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.

# Bad
description: Helps with PDFs.
```

## Common Patterns

### Template Pattern

Provide output templates. Strict for data formats, flexible for creative output.

### Examples Pattern

Show input/output pairs. More effective than describing the desired style.

### Workflow Pattern

Break complex tasks into numbered steps. For multi-step workflows, provide a checklist:

```markdown
Task Progress:
- [ ] Step 1: Analyze input
- [ ] Step 2: Generate plan
- [ ] Step 3: Execute
- [ ] Step 4: Validate
```

### Feedback Loop Pattern

Run validator → fix errors → repeat. Catches errors early.

### Conditional Workflow

Guide through decision points: "Creating new? → follow A. Editing existing? → follow B."

### Interactive Decision Pattern

When a skill presents choices to the user (triage tables, option lists, action plans), **accept natural language — never require rigid syntax**. The user should be able to say any of these and have the agent understand:

- "fix 2, 3, and 4, ignore the rest"
- "address items 1 and 5, skip everything else with 'out of scope'"
- "fix all the high priority ones"
- "do 1 and 3, let me think about the others"

Don't define a command grammar like `fix N` / `ignore N "reason"`. Instead, describe the **intent categories** (fix, ignore, discuss, skip) and let the agent interpret natural language references to the presented data. The skill's REFERENCE.md should define what each intent means and how to execute it — the user's phrasing is the agent's problem, not the user's.

## Script Design

- **No interactive prompts** — agents run in non-interactive shells
- **Support `--help`** — use a heredoc in `show_help()`, not sed header parsing (self-contained, won't break if script header changes)
- **Helpful error messages** — say what went wrong, what was expected, what to try
- **Structured output** — JSON/CSV over free text. Data to stdout, diagnostics to stderr
- **Idempotent** — "create if not exists" is safer than "create and fail on duplicate"
- **Safe defaults** — destructive ops should require confirmation flags
- **Predictable output size** — support pagination or output files for large results

### Script Substance (beyond structure)

Structure (SRP, `--help`, JSON output) is necessary but not sufficient. Scripts must also be rich in the data they provide. **These are requirements, not suggestions** — scripts that meet structural criteria but lack substance produce weak skills.

- **Graceful degradation** — warn and continue when a fetch fails partway. Return what was fetched with a `warnings` array in the JSON output. The agent can work with partial data. **Never hard-exit on the first API error** when partial results are useful. This applies to both consolidated and SRP scripts: if page 3 of pagination fails, return pages 1-2 with a warning.
- **Metadata context** — if the skill triages or analyzes data, include relevant metadata (e.g., PR title, state, author, change stats) so the agent has context without extra API calls.
- **Summary stats** — every fetch script must include a `summary` object in its JSON output. Compute counts, totals, and breakdowns in the script. **Don't force the agent to count items from raw arrays** — it wastes tokens, introduces counting errors, and makes the agent slower. Example: `"summary": {"total": 12, "open": 8, "resolved": 4}`.
- **Bot/automation detection** — when fetching user-attributed data, use multiple detection signals. Check `user.type`, login suffix patterns (`[bot]`), and known bot names (dependabot, github-actions, etc.). A single check misses bots that don't set the `type` field.
- **Selective fetch flags** — for multi-source scripts, support flags like `--threads-only` or `--no-threads` so the agent can skip unnecessary API calls on retry or partial runs.

**SRP does not mean lean output.** When splitting a consolidated script into SRP scripts, each script should still be individually rich — include summary stats, detection logic, and metadata in each script's output. The decomposition is about separation of concerns for fetching, not reduction of output quality.

## Anti-Patterns

- Offering too many alternative approaches (pick a default, mention alternatives briefly)
- Using Windows-style paths (`\` instead of `/`)
- Deeply nested file references (keep one level deep from SKILL.md)
- Time-sensitive information (use "old patterns" sections instead of dates)
- Over-explaining what Claude already knows
- Vague naming (`helper`, `utils`, `misc`)
- Magic constants without justification

## Quality Checklist Summary

1. Description specific + keyword-rich + third-person + includes "when to use"
2. SKILL.md < 500 lines
3. Detail in reference files, not SKILL.md
4. Consistent terminology
5. Concrete examples with input/output
6. Edge cases documented with fallbacks
7. Scripts: self-contained, --help, structured output, error handling
8. No time-sensitive content
9. File references one level deep
10. Progressive disclosure: metadata → instructions → resources
