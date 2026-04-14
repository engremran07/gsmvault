# /lint-fix â€” Run ruff linting with auto-fix

Run ruff check with auto-fix and ruff format on specified scope, reporting all changes and remaining issues.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Run Ruff Check with Auto-Fix

- [ ] Full project: `& .\.venv\Scripts\python.exe -m ruff check . --fix`

- [ ] Specific app: `& .\.venv\Scripts\python.exe -m ruff check apps/$ARGUMENTS/ --fix`

- [ ] Specific file: `& .\.venv\Scripts\python.exe -m ruff check $ARGUMENTS --fix`

- [ ] Show unfixable issues: `& .\.venv\Scripts\python.exe -m ruff check $ARGUMENTS --no-fix`

### Step 2: Run Ruff Format

- [ ] Full project: `& .\.venv\Scripts\python.exe -m ruff format .`

- [ ] Specific scope: `& .\.venv\Scripts\python.exe -m ruff format apps/$ARGUMENTS/`

### Step 3: Review Changes

- [ ] List auto-fixed issues by error code (E, W, F, I, N, UP, B, C4, SIM, RUF)

- [ ] Fix remaining unfixable issues manually

- [ ] Verify no unused imports (F401)

- [ ] Verify no undefined names (F821)

- [ ] Verify import sorting (I001)

- [ ] Verify no blanket `noqa` comments â€” always specify codes

### Step 4: Validate

- [ ] Re-run ruff check â€” zero warnings: `& .\.venv\Scripts\python.exe -m ruff check $ARGUMENTS`

- [ ] Run Django check: `& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev`

- [ ] Verify no regressions introduced by auto-fix
