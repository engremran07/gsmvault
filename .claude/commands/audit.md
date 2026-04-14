# /audit â€” Full Repository Audit

Perform a comprehensive repository audit across code quality, security, type coverage, dependencies, and architecture compliance.

## Audit Dimensions

### 1. Type Coverage Audit

- Find all `# type: ignore` instances and verify they have error codes (no bare `# type: ignore`)
- Find all functions missing return type annotations in `services.py` and `api.py` files
- Find all `ModelAdmin` subclasses missing the `[Model]` type parameter
- Report: file path, line, current state, required fix

### 2. Code Quality Audit

- Find bare `except Exception: pass` or `except Exception: continue` (anti-pattern â€” must log)
- Find views with database queries (ORM calls outside `services.py`)
- Find `fields = "__all__"` in any DRF serializer
- Find `permission_classes` missing from ViewSets
- Find cross-app model imports in `models.py` or `services.py` (forbidden except allowed patterns)

### 3. Model Completeness Audit

For every model in `apps/*/models.py`, check:
- Has `__str__` method
- Has `class Meta` with `db_table`, `verbose_name`, `verbose_name_plural`, `ordering`
- Has `related_name` on every FK/M2M
- If it's a financial model (Wallet, Transaction, Credit), uses `select_for_update()`

### 4. Security Audit

Run `/security` in abbreviated form:
- Scan for hardcoded credentials patterns
- Verify `AllowAny` not on mutating endpoints
- Verify admin views have staff checks
- Verify input sanitization on HTML-accepting fields

### 5. Dependency Audit

```powershell
& .\.venv\Scripts\pip.exe check
& .\.venv\Scripts\pip.exe list --outdated --format=columns
```
- Identify packages in `requirements.txt` with no corresponding import (dead deps)
- Identify imports of packages NOT in `requirements.txt` (missing deps)

### 6. Dead Code Audit

- Find `TODO` and `FIXME` comments
- Find functions defined but never called (within services.py / api.py files)
- Find commented-out code blocks (>5 lines)

### 7. Test Coverage Audit

- List all apps that have a `tests.py` or `tests/` directory
- List all apps that lack any tests
- Count test functions per app
- Identify untested service functions in `services.py`

### 8. Documentation Audit

- Verify every app in `INSTALLED_APPS` is documented in `AGENTS.md`
- Verify the dissolved apps table in `AGENTS.md` is complete
- Verify `README.md` lists all 31 apps

## Output Format

Produce a structured audit report:

```
## Audit Report â€” {date}

### Summary

- Type issues: X
- Code quality issues: X
- Model completeness gaps: X
- Security findings: X
- Dependency issues: X
- Dead code: X
- Test gaps: X apps with zero tests

### Critical (fix immediately)

...

### High Priority

...

### Medium Priority

...

### Low / Informational

...
```
