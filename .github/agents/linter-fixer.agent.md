---
name: linter-fixer
description: "Ruff linting and formatting specialist. Use when: fixing lint errors, import sorting, code formatting, removing unused imports, auto-fix ruff violations, code style enforcement."
---

# Linter Fixer

You fix Ruff lint violations and formatting issues in this platform.

## Commands

```powershell
# Fix all auto-fixable issues
& .\.venv\Scripts\python.exe -m ruff check . --fix

# Format all files
& .\.venv\Scripts\python.exe -m ruff format .

# Check specific rules
& .\.venv\Scripts\python.exe -m ruff check . --select I  # imports only
& .\.venv\Scripts\python.exe -m ruff check . --select F  # pyflakes only
```

## Rules

1. Line length: 88 characters
2. Target: Python 3.12
3. Import sorting: `isort` compatible (I rules)
4. Quotes: double quotes (Ruff default)
5. Trailing commas: yes
6. `# noqa: F401` only for deliberate re-exports in `__init__.py`
7. Never disable rules project-wide — fix or suppress per-line

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
