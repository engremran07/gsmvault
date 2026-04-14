---
agent: 'agent'
description: 'Audit Django code quality including models, views, services, admin, URLs, and type hints'
tools: ['semantic_search', 'read_file', 'grep_search', 'list_dir', 'file_search', 'run_in_terminal', 'get_errors']
---

# Django Code Quality Audit

Perform a comprehensive audit of all Django code in the `apps/` directory against the GSMFWs platform conventions.

## 1 — Model Meta Completeness

Scan every model class in `apps/*/models.py`. Each model MUST have:

```python
class Meta:
    verbose_name = "Human Readable Name"
    verbose_name_plural = "Human Readable Names"
    ordering = ["-created_at"]  # or appropriate default
    db_table = "appname_modelname"  # especially for dissolved app models
```

Also verify every model has a `__str__` method.

**Dissolved model check**: Models migrated from dissolved apps must retain `db_table = "original_app_tablename"`:
- `crawler_guard` models → `db_table = "crawler_guard_*"`
- `fw_scraper` models → `db_table = "fw_scraper_*"`
- `download_links` models → `db_table = "download_links_*"`
- `admin_audit` models → `db_table = "admin_audit_*"`
- `email_system` models → `db_table = "email_system_*"`
- `webhooks` models → `db_table = "webhooks_*"`

## 2 — related_name on FK/M2M

Every `ForeignKey` and `ManyToManyField` across all `apps/*/models.py` must have explicit `related_name`. Pattern: `"<appname>_<field>"` or a descriptive unique name.

```python
# PASS
user = models.ForeignKey(settings.AUTH_USER_MODEL, related_name="forum_topics", on_delete=models.CASCADE)

# FAIL — missing related_name
user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
```

## 3 — Business Logic Placement

Views must be thin orchestrators. Grep `apps/*/views*.py` for:
- Complex querysets with multiple `.filter()`, `.annotate()`, `.aggregate()` chains
- Multi-model write operations
- Business rules (pricing calculations, quota checks, eligibility logic)

These belong in `apps/*/services.py` or `apps/*/services/*.py`.

## 4 — Type Hints

### Public API Coverage
All public functions and methods in `apps/*/services*.py`, `apps/*/views*.py`, `apps/*/api.py` must have type annotations on parameters and return values.

### ModelAdmin Typing
Every `ModelAdmin` must be typed with generic parameter:
```python
class MyModelAdmin(admin.ModelAdmin[MyModel]):  # PASS
class MyModelAdmin(admin.ModelAdmin):            # FAIL
```

### get_queryset Return Type
```python
def get_queryset(self) -> QuerySet[MyModel]:  # Required annotation
```

### Type Ignore Specificity
Grep for `# type: ignore` without error code specification. Every ignore must specify the code:
```python
brand.models  # type: ignore[attr-defined]     # PASS — reverse FK manager
from solo.models import SingletonModel  # type: ignore[import-untyped]  # PASS
result = obj.method()  # type: ignore           # FAIL — blanket ignore
```

## 5 — Admin Registration

For every model defined in `apps/*/models.py`, verify there is a corresponding `admin.site.register()` call or `@admin.register()` decorator in either:
- `apps/<appname>/admin.py`
- `apps/admin/` view modules (for the custom admin panel)

Abstract models and proxy models without custom admin are exempt.

## 6 — URL Namespaces

### App Names
Every `apps/*/urls.py` must define `app_name = "<appname>"` at module level.

### Named Patterns
Every `path()` or `re_path()` in URL configs must have a `name=` parameter.

### Include Namespaces
In `app/urls.py`, every `include()` call must use `namespace=` parameter matching the app's `app_name`.

## 7 — No Raw SQL

Zero tolerance search across all `apps/**/*.py`:
```
raw(        → Use Django ORM querysets
.extra(     → Use .annotate() with F/Q expressions
RawSQL(     → Use Django ORM expressions
.cursor()   → Use Django ORM
.execute(   → Use Django ORM
```

Each finding is a CRITICAL violation.

## 8 — Middleware Order

Read `app/settings.py` `MIDDLEWARE` list and verify correct ordering:
1. `SecurityMiddleware` (first)
2. `WhiteNoiseMiddleware` (if used, second)
3. `SessionMiddleware`
4. `CommonMiddleware`
5. `CsrfViewMiddleware`
6. `AuthenticationMiddleware`
7. `MessageMiddleware`
8. Custom middleware (CSP nonce, consent, HTMX auth, etc.)

## 9 — App Boundary Enforcement

### Forbidden Cross-App Imports
In `apps/*/models.py` and `apps/*/services*.py`, grep for imports from other apps except:
- `apps.core.*` — allowed everywhere
- `apps.site_settings.*` — allowed everywhere
- `settings.AUTH_USER_MODEL` — allowed everywhere
- `apps.consent.decorators` / `apps.consent.middleware` — allowed everywhere

The `apps/admin/` app is the ONLY app allowed to import from all other apps.

### Dissolved App References
Grep for any import referencing dissolved app names:
```
from apps.security_suite     → FORBIDDEN (use apps.security)
from apps.crawler_guard       → FORBIDDEN (use apps.security)
from apps.fw_scraper          → FORBIDDEN (use apps.firmwares)
from apps.download_links      → FORBIDDEN (use apps.firmwares)
from apps.admin_audit         → FORBIDDEN (use apps.admin)
from apps.email_system        → FORBIDDEN (use apps.notifications)
from apps.webhooks            → FORBIDDEN (use apps.notifications)
from apps.ai_behavior         → FORBIDDEN (use apps.devices)
from apps.device_registry     → FORBIDDEN (use apps.devices)
from apps.gsmarena_sync       → FORBIDDEN (use apps.firmwares)
from apps.fw_verification     → FORBIDDEN (use apps.firmwares)
```

## 10 — Settings Safety

### Production Settings
Check `app/settings_production.py` for:
- `DEBUG = False`
- `ALLOWED_HOSTS` explicitly set (not `["*"]`)
- `SECURE_SSL_REDIRECT = True`
- `SECURE_HSTS_SECONDS` > 0
- `CSRF_TRUSTED_ORIGINS` explicitly set
- `SECRET_KEY` from environment variable

### Dev Settings
Check `app/settings_dev.py` has:
- `DEBUG = True`
- `string_if_invalid` set to catch template variable errors
- No production secrets or credentials

## Report Format

For each finding:
```
[CRITICAL/HIGH/MEDIUM/LOW] Category — Description
  File: apps/appname/file.py:LINE
  Code: offending code snippet
  Fix: specific remediation
```

Produce summary table with pass/fail per category and total counts by severity.
