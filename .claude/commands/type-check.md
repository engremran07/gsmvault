# /type-check â€” Run pyright type checking

Run pyright on the specified scope, identify type errors, and ensure proper type annotations across the codebase.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Run Pyright

- [ ] Full project: `& .\.venv\Scripts\python.exe -m pyright apps/`

- [ ] Specific app: `& .\.venv\Scripts\python.exe -m pyright apps/$ARGUMENTS/`

- [ ] Specific file: `& .\.venv\Scripts\python.exe -m pyright $ARGUMENTS`

### Step 2: Fix Common Type Errors

- [ ] `ModelAdmin` must be typed: `class MyAdmin(admin.ModelAdmin[MyModel]):`

- [ ] `get_queryset()` must annotate return: `-> QuerySet[MyModel]`

- [ ] Never blanket `# type: ignore` â€” always specify: `[attr-defined]`, `[import-untyped]`, etc.

- [ ] Django reverse FK managers â†’ `# type: ignore[attr-defined]`

- [ ] Missing stubs â†’ `pip install django-stubs djangorestframework-stubs types-requests`

- [ ] `solo.models` has no stubs â†’ `# type: ignore[import-untyped]`

- [ ] `QuerySet.first()` returns `Model | None` â†’ narrow type before passing to helpers

### Step 3: Verify Public API Annotations

- [ ] All public functions have full type hints (params + return type)

- [ ] Service layer functions are fully annotated

- [ ] API serializer fields have proper types

- [ ] No `Any` types without justification

### Step 4: Validate

- [ ] Re-run pyright â€” zero errors on scoped files

- [ ] Check VS Code Problems tab for Pylance issues

- [ ] Run quality gate: `& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev`
