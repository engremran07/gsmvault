---
name: quality-gate
description: "Quality gate enforcement: ruff lint, ruff format, Django system check, Pylance/Pyright. Zero tolerance policy. Use when enforcing code quality before commits or after edits."
user-invocable: true
---

# Quality Gate Skill

Full detail: @.github/skills/quality-gate/SKILL.md

## Mandatory Commands (Windows PowerShell)

```powershell
# Step 1: Lint auto-fix
& .\.venv\Scripts\python.exe -m ruff check . --fix

# Step 2: Format
& .\.venv\Scripts\python.exe -m ruff format .

# Step 3: Django system check
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev

# Step 4: Type check (call get_errors() in VS Code agent)
# Must return zero items.

# Step 5 (optional): Full type run
& .\.venv\Scripts\python.exe -m pyright apps/

# Step 6 (after package changes): Dependency health
& .\.venv\Scripts\pip.exe check
```

## Completion Criteria

ALL of the following must be true:
- `ruff check .` exits 0 with no unfixed warnings
- `ruff format . --check` exits 0 (nothing would change)
- `manage.py check` outputs `System check identified no issues (0 silenced)`
- `get_errors()` returns empty list

## Common Fix Patterns

| Pylance Error | Fix |
|---|---|
| Missing `[T]` on `ModelAdmin` | `class MyAdmin(admin.ModelAdmin[MyModel]):` |
| `attr-defined` on reverse FK | `# type: ignore[attr-defined]` + comment |
| `import-untyped` | `# type: ignore[import-untyped]` |
| Missing return annotation | Add `-> ReturnType:` |
| `union-attr` on `.first()` result | Guard with `if obj is not None:` |

Never use bare `# type: ignore` — always specify the error code.
