---
paths: ["app/settings*.py"]
---

# Settings Safety

Rules for Django settings files. Base: `app/settings.py`, Dev: `settings_dev.py`, Prod: `settings_production.py`.

## Production Hardening

- `DEBUG = False` in production — ALWAYS. No exceptions.
- `ALLOWED_HOSTS` MUST list explicit hostnames in production — never `["*"]`.
- `SECRET_KEY` MUST come from environment variable — NEVER hardcoded in source.
- `SECURE_SSL_REDIRECT = True` in production.
- `SECURE_HSTS_SECONDS = 31536000` with `SECURE_HSTS_INCLUDE_SUBDOMAINS = True`.
- `SESSION_COOKIE_SECURE = True` and `CSRF_COOKIE_SECURE = True` in production.
- `X_FRAME_OPTIONS = "DENY"` — always, both dev and production.

## Development Settings

- `string_if_invalid = "!!! MISSING: %s !!!"` in `TEMPLATES` options for template debugging.
- `CONN_MAX_AGE = 0` — close DB connections after each request for clean state.
- `EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"` — never send real emails in dev.
- Enable Django Debug Toolbar only in `settings_dev.py` — never in production.
- `INTERNAL_IPS = ["127.0.0.1"]` for Debug Toolbar — never expose to external networks.

## Settings Isolation

- NEVER import `settings_production` in `settings_dev.py` or vice versa.
- NEVER run with `--settings=app.settings_production` during development.
- Both dev and production settings import base via `from .settings import *`.
- Environment-specific overrides go ONLY in the corresponding settings file.
- NEVER use `os.environ.get()` with a production-value default in base settings.

## Secrets & Credentials

- All secrets via `os.environ` or `.env` files (never committed to git).
- Database URL via `DATABASE_URL` env var in production.
- Redis URL via `REDIS_URL` or `CELERY_BROKER_URL` env var.
- Storage credentials via files in `storage_credentials/` (gitignored).
- NEVER log or expose settings values that contain secrets.

## Installed Apps & Middleware

- All 31 apps MUST be listed in `INSTALLED_APPS` — missing apps cause silent failures.
- Middleware order matters: security middleware first, then session, auth, CSRF, app-specific.
- NEVER add `CorsMiddleware` without explicit `CORS_ALLOWED_ORIGINS` whitelist.
- Third-party apps: add to `INSTALLED_APPS` AND `requirements.txt` atomically.
