# /repo-hygiene-audit - Repository Hygiene Audit

Run a full cleanup and integrity workflow for temporary artifacts and cross-file references.

## Steps

### Step 1: Run baseline quality checks

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

### Step 2: Enumerate candidate temporary artifacts

```powershell
Get-ChildItem output -Recurse -File | Select-Object FullName, LastWriteTime
Get-ChildItem logs -Recurse -File | Select-Object FullName, LastWriteTime
```

### Step 3: Search stale references

```powershell
Get-ChildItem -Recurse -File | Select-String -Pattern 'tmp|temp|scratch|artifact|draft' | Select-Object Path, LineNumber, Line -First 300
```

### Step 4: Remove disposable local artifacts and stale references

- Delete non-canonical temporary files created during the task
- Update docs/prompts/workflows/governance references to match current files

### Step 5: Re-verify

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## Output

- List of removed artifacts
- List of fixed stale references
- Final status of diagnostics and quality checks
