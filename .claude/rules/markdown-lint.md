---
paths: ["**/*.md"]
---

# Markdown Lint Compliance

All Markdown files MUST pass markdown lint checks with zero warnings.

## Enforced Rules

| Rule | Description | Fix |
|------|-------------|-----|
| MD001 | Heading levels increment by one | Fix heading hierarchy — no skipping levels |
| MD003 | Heading style must be consistent (ATX: `#`) | Use `#` style headings only |
| MD004 | Unordered list style must be consistent (`-`) | Use `-` for all list items |
| MD005 | Inconsistent indentation for list items | Use 2-space indent for nested lists |
| MD009 | Trailing spaces | Remove trailing whitespace |
| MD010 | Hard tabs | Replace tabs with spaces |
| MD011 | Reversed link syntax `(text)[url]` | Use `[text](url)` |
| MD012 | Multiple consecutive blank lines | Use single blank lines |
| MD018 | No space after hash on ATX heading | Add space: `# Heading` not `#Heading` |
| MD019 | Multiple spaces after hash | Use single space after `#` |
| MD022 | Headings should be surrounded by blank lines | Add blank line before and after headings |
| MD023 | Headings must start at beginning of line | No leading spaces before `#` |
| MD024 | Multiple headings with same content | Make heading text unique within scope |
| MD025 | Multiple top-level headings | Only one `# Title` per document |
| MD026 | Trailing punctuation in heading | Remove `.`, `:`, `;` from heading text |
| MD027 | Multiple spaces after blockquote symbol | Use single space after `>` |
| MD028 | Blank line inside blockquote | Remove blank lines or add `>` prefix |
| MD029 | Ordered list item prefix (1. 2. 3.) | Use sequential numbering |
| MD031 | Fenced code blocks should be surrounded by blank lines | Add blank lines around code fences |
| MD032 | Lists should be surrounded by blank lines | Add blank lines around lists |
| MD033 | Inline HTML (allowed for tables and details/summary) | Minimize inline HTML |
| MD034 | Bare URLs should be wrapped in angle brackets or links | Use `<url>` or `[text](url)` |
| MD036 | Emphasis used instead of heading | Use proper `#` headings |
| MD037 | Spaces inside emphasis markers | Remove: `** text **` → `**text**` |
| MD038 | Spaces inside code span markers | Remove: `` ` code ` `` → `` `code` `` |
| MD040 | Fenced code blocks should have a language | Add language: ` ```python ` |
| MD041 | First line should be a top-level heading | Start file with `# Title` |
| MD046 | Code block style should be fenced | Use ` ``` ` not indented blocks |
| MD047 | Files should end with a single newline | Ensure trailing newline |
| MD049 | Emphasis style should be consistent | Use `*italic*` consistently |
| MD050 | Strong style should be consistent | Use `**bold**` consistently |

## Exceptions

- `CHANGELOG.md` — may have repeated heading patterns by design
- Migration files — auto-generated, not linted
- Third-party docs in `node_modules/` or `.venv/` — excluded
- `AGENTS.md`, `MASTER_PLAN.md` — large reference docs may use inline HTML tables

## Pre-Commit Check

Before committing any `.md` file, verify:
1. No markdown lint warnings in VS Code Problems tab
2. Heading hierarchy is logical (h1 → h2 → h3, no skips)
3. All code blocks have language identifiers
4. All links are valid `[text](url)` format
5. File ends with exactly one newline
