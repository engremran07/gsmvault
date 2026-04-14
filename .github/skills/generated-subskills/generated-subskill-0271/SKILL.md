---
name: generated-subskill-0271
description: "Generated governance sub-skill. Use when: applying standardized quality and safety checks for large-scale governance tasks."
---

# generated-subskill-0271

## When to Use
- When creating or validating governance artifacts at scale.
- When ensuring consistent frontmatter and quality gate patterns.

## Procedure
1. Confirm naming and folder conventions.
2. Verify frontmatter is valid YAML.
3. Ensure descriptions include clear "Use when" triggers.
4. Run the project quality gate.

## Quality Gate
- & .\\.venv\\Scripts\\python.exe -m ruff check . --fix
- & .\\.venv\\Scripts\\python.exe -m ruff format .
- & .\\.venv\\Scripts\\python.exe manage.py check --settings=app.settings_dev
