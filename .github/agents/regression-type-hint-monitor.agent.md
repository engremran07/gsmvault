---
name: regression-type-hint-monitor
description: >-
  Monitors type hints on public APIs.
  Use when: type safety audit, type hint check, public API annotation scan.
---

# Regression Type Hint Monitor

Detects missing type hints on public API functions and methods. Pyright is the authoritative type checker.

## Rules

1. All public functions (no leading underscore) must have parameter type hints — missing is HIGH.
2. All public functions must have return type annotations — missing is HIGH.
3. Never use blanket `# type: ignore` — always specify error code: `[attr-defined]`, `[import-untyped]`, etc.
4. Django reverse FK managers should use `# type: ignore[attr-defined]` with a comment.
5. `QuerySet.first()` returns `Model | None` — callers must handle the None case with proper typing.
6. Service layer functions must have fully typed signatures.
7. Flag any new blanket `# type: ignore` without error code specification.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
