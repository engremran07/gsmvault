# /health â€” Run project health check

Comprehensive project health check covering Django system checks, linting, database connectivity, Redis/Celery status, and static files integrity.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Django System Check

- [ ] Run `& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev`

- [ ] Run `& .\.venv\Scripts\python.exe manage.py check --deploy --settings=app.settings_production` (report only, don't fail on expected dev differences)

- [ ] Confirm output: `System check identified no issues (0 silenced)`

### Step 2: Ruff Lint & Format

- [ ] Run `& .\.venv\Scripts\python.exe -m ruff check . --fix`

- [ ] Run `& .\.venv\Scripts\python.exe -m ruff format .`

- [ ] Confirm zero lint warnings and zero format changes

### Step 3: Database Connectivity

- [ ] Run `& .\.venv\Scripts\python.exe manage.py dbshell --settings=app.settings_dev` or test connection via `manage.py shell -c "from django.db import connection; connection.ensure_connection(); print('DB OK')"`

- [ ] Verify PostgreSQL 17 on localhost:5432, database `appdb`

- [ ] Check for unapplied migrations: `& .\.venv\Scripts\python.exe manage.py showmigrations --settings=app.settings_dev | Select-String "\[ \]"`

### Step 4: Redis & Celery Status

- [ ] Test Redis connectivity: `& .\.venv\Scripts\python.exe -c "import redis; r = redis.Redis(); r.ping(); print('Redis OK')"`

- [ ] Verify Celery config in `app/celery.py`

- [ ] Check broker URL in settings

### Step 5: Static Files Integrity

- [ ] Verify `static/vendor/` contains local CDN fallbacks (tailwind, alpine, htmx, lucide)

- [ ] Verify `static/css/dist/` has compiled CSS

- [ ] Verify `static/js/dist/` has minified JS

- [ ] Check `templates/base/base.html` multi-CDN fallback chain is intact

### Step 6: VS Code Problems Tab

- [ ] Check `get_errors()` for zero Pylance/Pyright issues

- [ ] Confirm no unresolved imports or type errors

### Step 7: Report Summary

- [ ] Print pass/fail summary for each subsystem

- [ ] Flag any items needing attention
