# Skill Quality Checklist

Use during audit mode. Score each dimension as pass/warn/fail.

## Spec Compliance

- [ ] SKILL.md exists in skill root directory
- [ ] Valid YAML frontmatter between `---` delimiters
- [ ] `name` field present, valid kebab-case, 1-64 chars
- [ ] `name` matches parent directory name
- [ ] `description` field present, non-empty, <= 1024 chars
- [ ] No reserved words in name ("anthropic", "claude")
- [ ] No XML tags in name or description
- [ ] Optional fields (if present) are within constraints

## Description Quality

- [ ] Describes **what** the skill does (specific verbs + nouns)
- [ ] Describes **when** to use it (triggers, contexts)
- [ ] Written in third person ("Extracts...", not "I extract...")
- [ ] Includes keywords for agent discovery
- [ ] Specific enough to avoid false triggers
- [ ] Broad enough to catch legitimate triggers

## Conciseness

- [ ] SKILL.md body < 500 lines
- [ ] No explanations Claude already knows
- [ ] Each paragraph justifies its token cost
- [ ] No redundant information between SKILL.md and references

## Progressive Disclosure

- [ ] SKILL.md is overview + navigation
- [ ] Detailed content lives in references/
- [ ] File references are one level deep (no nested chains)
- [ ] Reference files > 100 lines have a table of contents

## Script Quality (if scripts/ present)

- [ ] Scripts are self-contained or document dependencies
- [ ] `--help` output available
- [ ] Helpful error messages (what went wrong, what was expected, what to try)
- [ ] Structured output (JSON/CSV preferred)
- [ ] No interactive prompts
- [ ] Data to stdout, diagnostics to stderr
- [ ] Idempotent where possible
- [ ] No magic constants (all values justified)

## Examples

- [ ] Concrete input/output examples present
- [ ] Examples match realistic use cases
- [ ] Not abstract or placeholder content

## Edge Cases

- [ ] Documented with fallback behavior
- [ ] Missing input handling specified
- [ ] Default behaviors stated

## Naming & Terminology

- [ ] Consistent terminology throughout
- [ ] No Windows-style paths (all forward slashes)
- [ ] No time-sensitive information (or in "old patterns" section)

## Output Quality (for skills producing tables/reports)

- [ ] Column definitions are explicit (not just column names)
- [ ] Sort/grouping order is specified
- [ ] Deduplication rules stated (if multiple data sources may overlap)
- [ ] Next-step suggestions included after output

## Invocation Control (Claude Code)

- [ ] `disable-model-invocation` set correctly for skill purpose
- [ ] `user-invocable` set correctly for skill purpose
- [ ] `allowed-tools` is NOT present (unsupported by Claude Code despite being in the Agent Skills spec)
- [ ] Side-effect skills have `disable-model-invocation: true`
- [ ] Background knowledge skills have `user-invocable: false`
