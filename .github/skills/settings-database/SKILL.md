---
name: settings-database
description: "Database configuration: DATABASES dict, connection pooling, read replicas. Use when: configuring PostgreSQL, setting up connection pooling, adding read replicas, optimizing DB settings."
---

# Database Configuration

## When to Use
- Configuring PostgreSQL connection for new environments
- Setting up connection pooling for production performance
- Adding read replicas for query distribution
- Tuning database settings for development vs production

## Rules
- PostgreSQL 17 is the only supported database — no SQLite in production
- Use `CONN_MAX_AGE = 600` in production for connection reuse
- Use `CONN_MAX_AGE = 0` in development for clean connections
- Use `conn_health_checks = True` (Django 4.1+) to verify connections
- Database name: `appdb` (dev default)
- NEVER expose database credentials in source code

## Patterns

### Development Database
```python
# app/settings_dev.py
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": "appdb",
        "USER": "postgres",
        "PASSWORD": "postgres",
        "HOST": "localhost",
        "PORT": "5432",
        "CONN_MAX_AGE": 0,  # Close after each request in dev
        "OPTIONS": {
            "connect_timeout": 5,
        },
    }
}
```

### Production Database
```python
# app/settings_production.py
import os

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.environ["DB_NAME"],
        "USER": os.environ["DB_USER"],
        "PASSWORD": os.environ["DB_PASSWORD"],
        "HOST": os.environ["DB_HOST"],
        "PORT": os.environ.get("DB_PORT", "5432"),
        "CONN_MAX_AGE": 600,  # Reuse connections for 10 min
        "CONN_HEALTH_CHECKS": True,  # Verify connections before use
        "OPTIONS": {
            "connect_timeout": 5,
            "options": "-c statement_timeout=30000",  # 30s query timeout
        },
    }
}
```

### Using DATABASE_URL
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

### Read Replica Configuration
```python
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.environ["DB_NAME"],
        # ... primary config
    },
    "replica": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.environ["DB_REPLICA_NAME"],
        "HOST": os.environ["DB_REPLICA_HOST"],
        # ... replica config
        "CONN_MAX_AGE": 600,
        "TEST": {"MIRROR": "default"},  # Use default in tests
    },
}

# Database router
class PrimaryReplicaRouter:
    def db_for_read(self, model, **hints):  # type: ignore[no-untyped-def]
        return "replica"

    def db_for_write(self, model, **hints):  # type: ignore[no-untyped-def]
        return "default"

    def allow_relation(self, obj1, obj2, **hints):  # type: ignore[no-untyped-def]
        return True

    def allow_migrate(self, db, app_label, model_name=None, **hints):  # type: ignore[no-untyped-def]
        return db == "default"

DATABASE_ROUTERS = ["app.routers.PrimaryReplicaRouter"]
```

### Test Database (In-Memory)
```python
# conftest.py or settings_test.py
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": "test_appdb",
        "USER": "postgres",
        "PASSWORD": "postgres",
        "HOST": "localhost",
        "PORT": "5432",
        "TEST": {
            "NAME": "test_appdb",  # Explicit test DB name
        },
    }
}
```

### Connection Pool Sizing Guide

| Setting | Dev | Production | Notes |
|---------|-----|------------|-------|
| `CONN_MAX_AGE` | `0` | `600` | Seconds to keep connection open |
| `CONN_HEALTH_CHECKS` | `False` | `True` | Verify before reuse |
| `connect_timeout` | `5` | `5` | Seconds to establish connection |
| `statement_timeout` | None | `30000` | Max query time (ms) |

## Anti-Patterns
- NEVER use SQLite in production — PostgreSQL only
- NEVER set `CONN_MAX_AGE = None` (infinite) — stale connections
- NEVER hardcode database credentials in settings files
- NEVER disable `CONN_HEALTH_CHECKS` in production
- NEVER use the same database for dev and production

## Red Flags
- `CONN_MAX_AGE = 0` in production — connection overhead on every request
- Missing `connect_timeout` — queries hang indefinitely on connection failure
- Database password visible in source code

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `app/settings.py` — base database config
- `.claude/rules/connection-pooling.md` — pooling rules
