---
agent: 'agent'
description: 'Create a new SKILL.md file with frontmatter, overview, rules, patterns, code examples, anti-patterns, and quality gate.'
tools: ['semantic_search', 'read_file', 'grep_search', 'list_dir', 'file_search', 'run_in_terminal']
---

# New Skill

Create a new `.github/skills/<skill-name>/SKILL.md` file following the GSMFWs skill format. The user will provide the skill topic.

## Step 1 — Validate the Skill Topic

1. Check `.github/skills/` to ensure no existing skill already covers this topic.
2. If a similar skill exists, suggest extending it instead of creating a new one.
3. Determine the skill's domain: admin, API, frontend, security, testing, SEO, services, models, etc.

## Step 2 — Research Existing Patterns

1. Search the codebase for existing implementations related to the skill topic.
2. Read 2-3 existing skills in `.github/skills/` to understand the format and depth expected.
3. Identify real code examples from the GSMFWs codebase to use as illustrations.

## Step 3 — Read the Skill Format Rule

Read `.claude/rules/skill-format.md` to ensure full compliance with the expected format.

## Step 4 — Create the Skill Directory and File

Create `.github/skills/<skill-name>/SKILL.md` with this structure:

```markdown
# <Skill Title>

## Overview

One paragraph explaining:
- What this skill covers.
- When an agent should use it.
- Which apps/layers it applies to.

## When to Use

Trigger keywords and scenarios:
- "When the user asks to..."
- "When a task involves..."
- "When creating/modifying..."

## Rules

Numbered rules that MUST be followed:

1. **Rule Name**: Specific, actionable instruction.
   - Detail or rationale.
2. **Rule Name**: Another rule.
   - Detail.
...

## Patterns

### Pattern Name

Context for when this pattern applies.

```python
# Correct implementation
from apps.core.models import TimestampedModel
# ... actual GSMFWs-style code example
```

### Another Pattern

```python
# Another correct example
```

## Anti-Patterns

### ❌ What NOT to Do

```python
# WRONG — explanation of why this is wrong
bad_example_code()
```

### ✅ Correct Alternative

```python
# RIGHT — explanation of why this is correct
good_example_code()
```

## Integration Points

- **Related skills**: [List skills that complement this one]
- **Related rules**: [List rules in `.claude/rules/` that enforce these patterns]
- **Affected apps**: [List apps where this skill applies]

## Quality Gate

Verification steps after applying this skill:

- [ ] [Specific check relevant to this skill domain]
- [ ] `ruff check . --fix` — zero errors
- [ ] `ruff format .` — formatted
- [ ] `manage.py check --settings=app.settings_dev` — no issues
```

## Step 5 — Populate with Real Content

- Use actual GSMFWs patterns, not generic Django examples.
- Reference real files, models, services from the codebase.
- Include at least 3 rules, 2 patterns, and 2 anti-patterns.
- Code examples must be syntactically correct and follow GSMFWs conventions:
  - Full type hints on public APIs.
  - `ModelAdmin[MyModel]` generic typing.
  - `related_name` on FK/M2M.
  - `apps.core.sanitizers` for HTML input.
  - `select_for_update()` for financial operations.
  - `@transaction.atomic` for multi-model writes.

## Step 6 — Register in Documentation

After creating the skill, verify it appears in:
- The skill listing used by Copilot/Claude (skills are auto-discovered from directory structure).
- If skill counts are documented in `AGENTS.md` or `GOVERNANCE.md`, update the count.

## Step 7 — Verify Quality

- Read the completed skill file to ensure it's comprehensive and actionable.
- Verify all code examples compile (no syntax errors).
- Ensure the skill doesn't duplicate guidance from existing skills.
