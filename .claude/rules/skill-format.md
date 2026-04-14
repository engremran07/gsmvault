---
paths: [".github/skills/**/SKILL.md"]
---

# Skill File Format Rules

Rules for creating and maintaining skill files in `.github/skills/`.

## Required Structure

Every skill MUST be a directory containing a `SKILL.md` file:

```text
.github/skills/<skill-name>/SKILL.md
```

- Skill names MUST be lowercase kebab-case: `quality-gate`, `admin-components`, `web-scraping`.
- Sub-skills go in nested directories: `.github/skills/<parent>/<sub-skill>/SKILL.md`.
- NEVER create loose `.md` files directly in `.github/skills/` — always a directory with `SKILL.md`.

## Required YAML Frontmatter

```yaml
---
name: skill-name
description: One-line description of what this skill does and when to use it.
---
```

- `name` MUST match the directory name.
- `description` MUST include trigger phrases: "Use when: ..." or "Use for: ...".

## Required Sections

Every SKILL.md MUST have:

1. **When to Use** — clear trigger conditions for invoking this skill.
2. **Rules / Guards / Procedure** — the core actionable content (tables, checklists, commands).
3. **Red Flags** — common mistakes or anti-patterns to detect.
4. **Quality Gate** — 3 mandatory commands:
   ```powershell
   & .\.venv\Scripts\python.exe -m ruff check . --fix
   & .\.venv\Scripts\python.exe -m ruff format .
   & .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
   ```

## Content Guidelines

- ALWAYS write actionable instructions — not explanations or theory.
- Use tables for guard registries: `| Guard | File | Check | Severity |`.
- Use numbered procedures for sequential workflows.
- Reference specific files and line patterns — not abstract concepts.
- NEVER duplicate content that belongs in rules (`.claude/rules/`).
