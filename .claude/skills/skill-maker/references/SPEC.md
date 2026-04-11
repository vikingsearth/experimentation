# Agent Skills Specification Reference

> Condensed from [agentskills.io/specification](https://agentskills.io/specification).

## Directory Structure

```txt
skill-name/
├── SKILL.md          # Required: metadata + instructions
├── scripts/          # Optional: executable code
├── references/       # Optional: supplementary docs
└── assets/           # Optional: templates, data, images
```

## SKILL.md Format

YAML frontmatter (`---` delimiters) followed by Markdown body.

### Required Frontmatter Fields

| Field | Constraints |
| ----- | ----------- |
| `name` | 1-64 chars. Lowercase alphanumeric + hyphens only. No leading/trailing/consecutive hyphens. Must match parent directory name. |
| `description` | 1-1024 chars. Non-empty. What it does + when to use it. Third-person voice. Keyword-rich for discovery. |

### Optional Frontmatter Fields

| Field | Constraints |
| ----- | ----------- |
| `license` | License name or reference to bundled LICENSE file. |
| `compatibility` | 1-500 chars. Environment requirements (products, packages, network). |
| `metadata` | Arbitrary key-value map (string → string). Use for author, version, purpose, etc. |
| `allowed-tools` | Space-delimited list of pre-approved tools. Experimental. **Not supported by Claude Code — do not use.** |

### Name Validation Rules

```txt
Valid:    pdf-processing, data-analysis, code-review, my-skill-v2
Invalid:  PDF-Processing (uppercase), -pdf (leading hyphen), pdf--x (consecutive hyphens), skill.name (dots)
```

Regex: `^[a-z0-9]+(-[a-z0-9]+)*$`

### Description Guidelines

- Describe **what** it does and **when** to use it
- Include specific keywords for agent discovery
- Write in third person ("Extracts text...", not "I extract..." or "Use this to extract...")
- Avoid vague descriptions ("Helps with PDFs" is poor)

### Body Content

No format restrictions. Recommended sections:

- Step-by-step instructions
- Input/output examples
- Edge cases and fallbacks

Keep under **500 lines**. Move detailed reference to separate files.

## Optional Directories

### scripts/

Executable code agents can run. Requirements:

- Self-contained or clearly documented dependencies
- Helpful error messages
- Edge case handling
- No interactive prompts (agents run in non-interactive shells)
- Structured output (JSON/CSV preferred over free text)
- Support `--help` for discoverability

### references/

Supplementary documentation loaded on demand:

- Focused, one topic per file
- Keep individual files small to minimize context usage
- Common files: REFERENCE.md, FORMS.md, domain-specific docs

### assets/

Static resources:

- Templates (document, config skeletons)
- Data files (lookup tables, schemas)
- Images (diagrams, examples)

## Progressive Disclosure

| Stage | Size | Content |
| ----- | ---- | ------- |
| **Metadata** | ~100 tokens | `name` + `description` — loaded at startup for all skills |
| **Instructions** | < 5000 tokens | Full SKILL.md body — loaded on activation |
| **Resources** | As needed | Files in scripts/, references/, assets/ — loaded on demand |

## File References

Use relative paths from skill root. Keep references one level deep from SKILL.md. Avoid nested reference chains.

```markdown
See [the reference guide](references/REFERENCE.md) for details.
Run: `bash scripts/validate.sh`
```
