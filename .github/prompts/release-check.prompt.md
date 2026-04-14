---
agent: 'agent'
description: 'Verify release readiness including changelog, tests, documentation, and breaking changes'
tools: ['semantic_search', 'read_file', 'grep_search', 'file_search', 'run_in_terminal', 'get_changed_files']
---

# Release Readiness Check

Verify the codebase is ready for a new release. All checks must pass before tagging a release.

## 1 — CHANGELOG.md Updated

Read `CHANGELOG.md` and verify:
1. A new entry exists for the upcoming release version
2. Entry is dated (today or recent)
3. Changes are categorized: Added, Changed, Fixed, Removed, Security, Deprecated
4. Each entry has a brief, clear description
5. Breaking changes are prominently marked with `**BREAKING:**` prefix

## 2 — Version Bumped

Check version references are consistent:
1. `pyproject.toml` version field
2. Any `__version__` in `app/__init__.py` or package init
3. Version in `CHANGELOG.md` header matches

Verify version follows semantic versioning (MAJOR.MINOR.PATCH):
- MAJOR: breaking changes
- MINOR: new features, backward compatible
- PATCH: bug fixes only

## 3 — All Tests Pass

Run the full test suite:
```powershell
& .\.venv\Scripts\python.exe -m pytest --tb=short -q
```

All tests must pass. No test may be skipped without documented justification.

## 4 — Quality Gate Clean

Run the full quality gate:
```powershell
& .\.venv\Scripts\python.exe -m ruff check .
& .\.venv\Scripts\python.exe -m ruff format --check .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

Zero issues allowed.

## 5 — No TODO/FIXME in Changed Files

Get the diff of changes since the last release tag. Grep changed files for:
```
TODO, FIXME, HACK, XXX, TEMP, TEMPORARY, WORKAROUND
```

Each match must be resolved or explicitly documented as known issue in the release notes.

## 6 — Documentation Updated

If new features or apps were added, verify updates in:
1. **README.md** — Project overview reflects current state
2. **AGENTS.md** — Architecture section includes new apps/models
3. **`.github/copilot-instructions.md`** — Quick-reference card updated
4. **CONTRIBUTING.md** — Development workflow still accurate
5. **API documentation** — New endpoints documented

## 7 — Migration Squashing Considered

If there are many migrations in a single app (10+), consider squashing:
```powershell
& .\.venv\Scripts\python.exe manage.py squashmigrations <app_name> <migration_name> --settings=app.settings_dev
```

Check each app's `migrations/` directory for excessive migration count.

## 8 — Breaking Changes Documented

If any of the following occurred, they must be documented in CHANGELOG and release notes:
1. Model field removals or renames
2. URL pattern changes
3. API endpoint changes (path, parameters, response format)
4. Settings key changes
5. Removed features or apps
6. Changed default values
7. Python/Django version requirements changed
8. New required environment variables

## 9 — Dependencies Verified

```powershell
& .\.venv\Scripts\pip.exe check
& .\.venv\Scripts\pip.exe list --outdated --format=columns
```

1. No broken dependency chains
2. No known CVEs in current versions
3. `requirements.txt` is clean and organized
4. All entries have version ranges (not bare package names)

## 10 — Database Migration Safety

```powershell
& .\.venv\Scripts\python.exe manage.py makemigrations --check --settings=app.settings_dev
```

1. No pending migrations (all model changes have corresponding migrations)
2. New migrations are backward-compatible (no data loss)
3. RemoveField operations have data backup strategy
4. RunPython operations have reverse functions
5. Dissolved models retain `db_table` for data preservation

## 11 — Static Assets Built

1. CSS compiled: `static/css/dist/main.css` exists and is minified
2. JS minified: `static/js/dist/` files are up to date
3. Vendor libraries version-pinned and present in `static/vendor/`
4. No stale compiled assets (check timestamps)

## 12 — Security Pre-Check

Quick security scan:
1. No hardcoded secrets in codebase
2. No `DEBUG = True` in production settings
3. No `@csrf_exempt` without justification
4. No raw SQL queries
5. `SECRET_KEY` from environment variable

## Report

```
╔══════════════════════════════════════════╗
║        RELEASE READINESS CHECK           ║
╠══════════════════════════════════════════╣
║  Version: X.Y.Z                          ║
║  Date: YYYY-MM-DD                        ║
╠══════════════════════════════════════════╣
║  1. CHANGELOG Updated      [✅/❌]       ║
║  2. Version Bumped          [✅/❌]       ║
║  3. All Tests Pass          [✅/❌]       ║
║  4. Quality Gate Clean      [✅/❌]       ║
║  5. No TODO/FIXME           [✅/❌]       ║
║  6. Docs Updated            [✅/❌]       ║
║  7. Migration Squashing     [✅/⚠️/N/A]  ║
║  8. Breaking Changes Docs   [✅/❌/N/A]  ║
║  9. Dependencies Verified   [✅/❌]       ║
║ 10. Migration Safety        [✅/❌]       ║
║ 11. Static Assets Built     [✅/❌]       ║
║ 12. Security Pre-Check      [✅/❌]       ║
╠══════════════════════════════════════════╣
║  RELEASE STATUS: READY / BLOCKED         ║
╚══════════════════════════════════════════╝
```

If blocked, list every failing check with remediation steps.
