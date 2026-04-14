# /env-check â€” Validate environment configuration

Check `.env` file for required variables, empty values, stale entries, and security compliance.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Check .env File Exists

- [ ] Verify `.env` file exists in project root

- [ ] Verify `.env` is in `.gitignore` (must NEVER be committed)

- [ ] Check for `.env.example` or `.env.template` for reference

### Step 2: Validate Required Variables

- [ ] `SECRET_KEY` â€” present and non-empty (never the Django default)

- [ ] `DEBUG` â€” set (should be `True` for dev, `False` for production)

- [ ] `DATABASE_URL` or individual DB settings (`DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT`)

- [ ] `REDIS_URL` or `CELERY_BROKER_URL` â€” Redis connection string

- [ ] `ALLOWED_HOSTS` â€” configured for the environment

- [ ] Storage credentials path if using GCS

### Step 3: Check for Empty Values

- [ ] Scan for `KEY=` (empty value) entries â€” flag as potential issues

- [ ] Scan for `KEY=""` or `KEY=''` entries â€” flag as intentionally empty or missing

- [ ] Verify no placeholder values like `changeme`, `TODO`, `xxx`, `your-key-here`

### Step 4: Check for Stale Entries

- [ ] Cross-reference env vars with `settings.py`, `settings_dev.py`, `settings_production.py`

- [ ] Flag variables in `.env` not referenced by any settings file

- [ ] Flag variables referenced in settings but missing from `.env`

### Step 5: Security Checks

- [ ] No secrets in source code (grep for API keys, tokens, passwords in `.py` files)

- [ ] `SECRET_KEY` is at least 50 characters

- [ ] Database password is not a weak/default value

- [ ] No `.env` file in any committed directory

- [ ] `storage_credentials/` directory is gitignored

### Step 6: Report

- [ ] List all missing required variables

- [ ] List all empty-value variables

- [ ] List all stale (unreferenced) variables

- [ ] List any security concerns found
