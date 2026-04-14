# /fix-all â€” Fix All VS Code Errors

Fix every error and warning in the VS Code Problems tab to reach zero issues.

## Priority Order

Work through issues in this order (highest impact first):

### 1. Django System Check

```powershell
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
Fix any model, URL, admin, or middleware errors first â€” they can cascade into false Pylance issues.

### 2. Ruff Lint Auto-Fix

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
```
This fixes: import ordering, unused imports, style issues, formatting. Only manual attention needed for unfixed items.

### 3. Pyright / Pylance Type Errors

Use `get_errors()` to see all Problems tab items. Fix by category:

**Common patterns and their fixes:**
- `Missing type annotation` â†’ add type hint to function parameter / return type
- `"X" is not a known attribute of "Y"` (reverse FK manager) â†’ `# type: ignore[attr-defined]` with comment
- `import-untyped` for packages without stubs â†’ `# type: ignore[import-untyped]`
- `ModelAdmin` without type param â†’ `class MyAdmin(admin.ModelAdmin[MyModel]):`
- `get_queryset()` return type â†’ `def get_queryset(self) -> QuerySet[MyModel]:`
- `QuerySet.first()` returns `Model | None` â†’ guard with `if obj is not None`
- Unresolved import â†’ check the app is in `INSTALLED_APPS`, or the module path is correct

### 4. Missing Stubs

If Pylance complains about untyped imports:
```powershell
& .\.venv\Scripts\pip.exe install django-stubs djangorestframework-stubs types-requests
```
Verify the stubs are in `requirements.txt`.

## Completion Check

After fixing all items, run the full gate:
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

Then call `get_errors()` â€” must return zero items. Do NOT mark task complete until this is achieved.
