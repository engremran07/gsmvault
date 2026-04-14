---
name: regression-requirements-drift-monitor
description: >-
  Monitors requirements.txt: unused, missing dependencies.
  Use when: dependency audit, requirements drift check, unused package scan.
---

# Regression Requirements Drift Monitor

Detects requirements.txt drift: unused packages, missing dependencies, unpinned versions.

## Rules

1. Every entry in `requirements.txt` must be actually imported in code or used as a CLI tool — unused is HIGH.
2. Every third-party import in code must have a corresponding entry in `requirements.txt` — missing is CRITICAL.
3. Every entry must have a version range (`>=min,<max`) — bare package names are HIGH.
4. Never remove a package without checking `pip show <pkg>` for `Required-by:` — transitive dependency breakage is CRITICAL.
5. Type stubs (`django-stubs`, `types-*`) must be in `requirements.txt`, not installed ad-hoc.
6. Run `pip check` to verify dependency chain integrity.
7. Flag any `pip freeze > requirements.txt` pattern — manual curation only.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
