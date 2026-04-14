# /deploy-check â€” Pre-deployment checklist

Verify all production-readiness requirements before deployment: security settings, static files, migrations, HTTPS, and configuration.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Security Settings

- [ ] Verify `DEBUG = False` in `app/settings_production.py`

- [ ] Verify `ALLOWED_HOSTS` is explicitly set (not `["*"]`)

- [ ] Verify `CSRF_TRUSTED_ORIGINS` lists production domains

- [ ] Verify `SECRET_KEY` comes from environment variable, not hardcoded

- [ ] Verify `SECURE_SSL_REDIRECT = True`

- [ ] Verify `SECURE_HSTS_SECONDS` is set (â‰¥ 31536000)

- [ ] Verify `SESSION_COOKIE_SECURE = True`

- [ ] Verify `CSRF_COOKIE_SECURE = True`

- [ ] Verify `X_FRAME_OPTIONS = "DENY"`

### Step 2: Django Deploy Check

- [ ] Run `& .\.venv\Scripts\python.exe manage.py check --deploy --settings=app.settings_production`

- [ ] Resolve all warnings and errors

- [ ] Verify `System check identified no issues`

### Step 3: Database Migrations

- [ ] Run `& .\.venv\Scripts\python.exe manage.py showmigrations --settings=app.settings_dev`

- [ ] Verify no unapplied migrations (`[ ]` entries)

- [ ] Check for conflicting migrations in any app

- [ ] Verify `makemigrations --check` produces no new migrations

### Step 4: Static Files

- [ ] Run `& .\.venv\Scripts\python.exe manage.py collectstatic --noinput --settings=app.settings_production`

- [ ] Verify WhiteNoise configuration for static file serving

- [ ] Confirm compiled CSS in `static/css/dist/`

- [ ] Confirm minified JS in `static/js/dist/`

### Step 5: Dependencies

- [ ] Run `& .\.venv\Scripts\pip.exe check` â€” verify no broken dependency chains

- [ ] Verify `requirements.txt` is up to date

- [ ] Check for known CVEs in dependencies

### Step 6: Environment Variables

- [ ] Verify all required env vars are documented

- [ ] Check `DATABASE_URL` / database config

- [ ] Check Redis/Celery broker URL

- [ ] Verify email backend configuration

- [ ] Check storage credentials are provisioned

### Step 7: Quality Gate

- [ ] Run full quality gate (ruff check, ruff format, manage.py check)

- [ ] Run test suite: `& .\.venv\Scripts\python.exe -m pytest --tb=short`

- [ ] Confirm zero failures

### Step 8: Report

- [ ] Print READY / NOT READY status

- [ ] List all blocking items that must be resolved
