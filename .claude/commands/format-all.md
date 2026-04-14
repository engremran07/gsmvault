# /format-all â€” Format entire codebase with ruff

Run ruff format across the full codebase and report all formatting changes.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Check Current State

- [ ] Preview changes: `& .\.venv\Scripts\python.exe -m ruff format . --check --diff`

- [ ] Count files that would change

### Step 2: Apply Formatting

- [ ] Run formatter: `& .\.venv\Scripts\python.exe -m ruff format .`

- [ ] Note: line-length 88, target-version py312 (from pyproject.toml)

### Step 3: Run Lint Check

- [ ] Auto-fix lint issues that formatting may surface: `& .\.venv\Scripts\python.exe -m ruff check . --fix`

- [ ] Verify zero remaining warnings: `& .\.venv\Scripts\python.exe -m ruff check .`

### Step 4: Validate

- [ ] Run Django check: `& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev`

- [ ] Verify no regressions: check VS Code Problems tab

- [ ] Report number of files reformatted
