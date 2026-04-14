# /qa â€” Full Quality Gate

Run the full mandatory quality gate (ruff lint, ruff format, Django system check) and report results. Fix all issues automatically where possible.

## Steps

1. Run ruff lint with auto-fix:
   ```powershell
   & .\.venv\Scripts\python.exe -m ruff check . --fix
   ```

2. Run ruff formatter:
   ```powershell
   & .\.venv\Scripts\python.exe -m ruff format .
   ```

3. Run Django system check:
   ```powershell
   & .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
   ```

4. Check VS Code Problems tab via `get_errors()`.

5. Report:
   - Number of files modified by ruff
   - Any lint issues that could not be auto-fixed
   - Django check result (must be "0 silenced")
   - Pylance/Pyright errors if any
   - Clear "PASS âœ“" or "FAIL âœ—" verdict with a list of remaining issues

**Target**: Zero issues in all four checks. Do not complete the task until the gate is green.
