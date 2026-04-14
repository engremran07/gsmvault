---
name: settings-env-vars
description: "Environment variable loading: os.environ, python-decouple, .env files. Use when: adding new config values, loading secrets, configuring database URLs, reading env vars."
---

# Environment Variable Loading

## When to Use
- Adding a new secret (API key, database password, token)
- Configuring database connection strings
- Setting feature toggles per environment
- Loading Redis/Celery broker URLs

## Rules
- ALL secrets via `os.environ` — NEVER hardcoded in source
- Use `os.environ.get("KEY", "default")` with safe defaults for non-secrets
- Use `os.environ["KEY"]` (no default) for required secrets — fails fast if missing
- `.env` file for local dev — NEVER committed to git (in `.gitignore`)
- NEVER use production-value defaults in base settings
- NEVER log or print environment variable values containing secrets

## Patterns

### Required Secrets (Fail Fast)
```python
# app/settings.py
import os

# REQUIRED — app won't start without these
SECRET_KEY = os.environ["DJANGO_SECRET_KEY"]
DATABASE_URL = os.environ["DATABASE_URL"]
```

### Optional Config with Defaults
```python
# Non-secret config — safe defaults for dev
DEBUG = os.environ.get("DJANGO_DEBUG", "True").lower() == "true"
ALLOWED_HOSTS = os.environ.get("DJANGO_ALLOWED_HOSTS", "localhost,127.0.0.1").split(",")
LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO")
```

### Database Configuration from URL
```python
import dj_database_url

DATABASES = {
    "default": dj_database_url.config(
        default="postgresql://postgres:postgres@localhost:5432/appdb",
        conn_max_age=600,
        conn_health_checks=True,
    )
}
```

### .env File Structure
```bash
# .env — NEVER commit this file
DJANGO_SECRET_KEY=your-secret-key-here
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/appdb
REDIS_URL=redis://localhost:6379/0
CELERY_BROKER_URL=redis://localhost:6379/1

# Optional toggles
DJANGO_DEBUG=True
LOG_LEVEL=DEBUG
ENABLE_AI_FEATURES=False

# Third-party API keys
OPENAI_API_KEY=sk-...
GCS_CREDENTIALS_PATH=storage_credentials/service_accounts/gcs.json
```

### Type Casting Helpers
```python
def env_bool(key: str, default: bool = False) -> bool:
    """Read a boolean from environment variable."""
    return os.environ.get(key, str(default)).lower() in ("true", "1", "yes")


def env_int(key: str, default: int = 0) -> int:
    """Read an integer from environment variable."""
    return int(os.environ.get(key, str(default)))


def env_list(key: str, default: str = "") -> list[str]:
    """Read a comma-separated list from environment variable."""
    value = os.environ.get(key, default)
    return [item.strip() for item in value.split(",") if item.strip()]


# Usage
ENABLE_AI = env_bool("ENABLE_AI_FEATURES", default=False)
MAX_UPLOAD_SIZE_MB = env_int("MAX_UPLOAD_SIZE_MB", default=100)
CORS_ORIGINS = env_list("CORS_ALLOWED_ORIGINS")
```

### Environment-Specific Overrides
```python
# app/settings_dev.py
from .settings import *  # noqa: F403, F401

DEBUG = True
DATABASES["default"]["CONN_MAX_AGE"] = 0  # noqa: F405
EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"

# app/settings_production.py
from .settings import *  # noqa: F403, F401

DEBUG = False
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
```

## Anti-Patterns
- NEVER hardcode secrets: `SECRET_KEY = "my-secret-key"`
- NEVER use production defaults in base settings: `os.environ.get("DB_URL", "prod-db-url")`
- NEVER commit `.env` to git
- NEVER use `eval()` to parse env vars — use explicit type casting
- NEVER log `SECRET_KEY`, `DATABASE_URL`, or API keys

## Red Flags
- `SECRET_KEY` with a hardcoded value in settings
- `.env` not listed in `.gitignore`
- `os.environ.get()` with production credentials as default
- Missing env var causing silent failures (empty string instead of crash)

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `app/settings.py` — base settings
- `.claude/rules/settings-safety.md` — settings safety rules
- `.claude/rules/secret-management.md` — secrets management
