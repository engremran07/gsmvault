---
name: settings-split
description: "Settings file splitting: base, dev, production, test configurations. Use when: organizing settings files, adding environment-specific config, creating test settings."
---

# Settings File Splitting

## When to Use
- Adding environment-specific settings (dev vs production)
- Creating test-specific configuration
- Understanding the settings inheritance chain
- Adding a new setting that differs between environments

## Rules
- Base settings in `app/settings.py` — shared across all environments
- Dev overrides in `app/settings_dev.py` — `from .settings import *`
- Prod overrides in `app/settings_production.py` — `from .settings import *`
- NEVER import `settings_production` in `settings_dev` or vice versa
- NEVER run with `--settings=app.settings_production` during development
- Dev server: `--settings=app.settings_dev` (always)
- Use `DJANGO_SETTINGS_MODULE` env var for production deployment

## Patterns

### Base Settings (app/settings.py)
```python
# app/settings.py — shared foundation
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
SECRET_KEY = os.environ.get("DJANGO_SECRET_KEY", "dev-insecure-key-change-me")
DEBUG = False  # Overridden in dev settings

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    # ... Django built-in apps
    "rest_framework",
    # ... third-party apps
    "apps.core",
    "apps.site_settings",
    # ... all 31 apps
]

MIDDLEWARE = [...]
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.environ.get("DB_NAME", "appdb"),
        "USER": os.environ.get("DB_USER", "postgres"),
        "PASSWORD": os.environ.get("DB_PASSWORD", "postgres"),
        "HOST": os.environ.get("DB_HOST", "localhost"),
        "PORT": os.environ.get("DB_PORT", "5432"),
    }
}

# Security defaults — tightened in production
X_FRAME_OPTIONS = "DENY"
```

### Dev Settings (app/settings_dev.py)
```python
# app/settings_dev.py
from .settings import *  # noqa: F403, F401

DEBUG = True
ALLOWED_HOSTS = ["localhost", "127.0.0.1", "[::1]"]

# Template debugging — catch missing variables
TEMPLATES[0]["OPTIONS"]["string_if_invalid"] = "!!! MISSING: %s !!!"  # noqa: F405

# No persistent connections in dev
DATABASES["default"]["CONN_MAX_AGE"] = 0  # noqa: F405

# Console email backend — never send real emails
EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"

# Debug toolbar
INSTALLED_APPS += ["debug_toolbar"]  # noqa: F405
MIDDLEWARE.insert(0, "debug_toolbar.middleware.DebugToolbarMiddleware")  # noqa: F405
INTERNAL_IPS = ["127.0.0.1"]
```

### Production Settings (app/settings_production.py)
```python
# app/settings_production.py
from .settings import *  # noqa: F403, F401

DEBUG = False
SECRET_KEY = os.environ["DJANGO_SECRET_KEY"]  # noqa: F405 — MUST be set
ALLOWED_HOSTS = os.environ["DJANGO_ALLOWED_HOSTS"].split(",")  # noqa: F405

# HTTPS enforcement
SECURE_SSL_REDIRECT = True
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")

# Database connection pooling
DATABASES["default"]["CONN_MAX_AGE"] = 600  # noqa: F405
DATABASES["default"]["OPTIONS"] = {"connect_timeout": 5}  # noqa: F405

# Static files served by WhiteNoise
STATICFILES_STORAGE = "whitenoise.storage.CompressedManifestStaticFilesStorage"
```

### Test Settings
```python
# app/settings_test.py (optional)
from .settings import *  # noqa: F403, F401

DEBUG = False
DATABASES["default"] = {  # noqa: F405
    "ENGINE": "django.db.backends.sqlite3",
    "NAME": ":memory:",
}
PASSWORD_HASHERS = ["django.contrib.auth.hashers.MD5PasswordHasher"]
EMAIL_BACKEND = "django.core.mail.backends.locmem.EmailBackend"
CACHES = {"default": {"BACKEND": "django.core.cache.backends.locmem.LocMemCache"}}
```

### Using Settings in Management Commands
```powershell
# Development
& .\.venv\Scripts\python.exe manage.py runserver --settings=app.settings_dev

# Migrations
& .\.venv\Scripts\python.exe manage.py migrate --settings=app.settings_dev

# Production check
& .\.venv\Scripts\python.exe manage.py check --deploy --settings=app.settings_production
```

## Anti-Patterns
- NEVER import between dev and production settings files
- NEVER set `DEBUG = True` in production settings
- NEVER hardcode `ALLOWED_HOSTS = ["*"]` in production
- NEVER run dev server with production settings
- NEVER put secrets in base settings with real values

## Red Flags
- `DEBUG = True` in `settings_production.py`
- `from .settings_production import *` in `settings_dev.py`
- Missing `SECRET_KEY` required env var in production settings
- `ALLOWED_HOSTS = ["*"]` in any non-dev settings

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `app/settings.py` — base settings
- `app/settings_dev.py` — development overrides
- `app/settings_production.py` — production overrides
