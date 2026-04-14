---
name: sec-sql-injection-raw
description: "Why raw SQL is forbidden and ORM alternatives. Use when: tempted to use raw SQL, reviewing legacy code with raw queries."
---

# Raw SQL Prohibition

## When to Use

- When tempted to write raw SQL for "performance"
- Reviewing code that uses `cursor.execute()` or `.raw()`
- Migrating legacy code with raw queries to ORM

## Rules

**Raw SQL is FORBIDDEN in all application code.** The Django ORM covers 100% of needed query patterns.

| Forbidden | ORM Alternative |
|-----------|----------------|
| `cursor.execute("SELECT ...")` | `Model.objects.filter(...)` |
| `Model.objects.raw("SELECT ...")` | `Model.objects.filter(...)` with lookups |
| `.extra(where=["..."])` | `Q()` objects, `Subquery`, `Exists` |
| `RawSQL()` expressions | `F()`, `Value()`, `Case/When` |
| Stored procedures | Celery tasks or service functions |

## Patterns

### Complex Conditions — Use Q Objects
```python
# FORBIDDEN: .extra(where=["status = 'active' AND downloads > 100"])
# CORRECT:
from django.db.models import Q
Firmware.objects.filter(Q(status="active") & Q(downloads__gt=100))
```

### Subqueries — Use Subquery/Exists
```python
# FORBIDDEN: raw SQL subquery
# CORRECT:
from django.db.models import Subquery, OuterRef, Exists
latest_download = DownloadSession.objects.filter(
    firmware=OuterRef("pk")
).order_by("-created_at")
Firmware.objects.annotate(
    last_download=Subquery(latest_download.values("created_at")[:1])
)
```

### Conditional Updates — Use Case/When
```python
# FORBIDDEN: cursor.execute("UPDATE ... CASE WHEN ...")
# CORRECT:
from django.db.models import Case, When, Value
Firmware.objects.update(
    priority=Case(
        When(downloads__gt=1000, then=Value("high")),
        When(downloads__gt=100, then=Value("medium")),
        default=Value("low"),
    )
)
```

### Window Functions — Use Django Window
```python
from django.db.models import Window, F
from django.db.models.functions import Rank
Firmware.objects.annotate(
    download_rank=Window(expression=Rank(), order_by=F("downloads").desc())
)
```

## Red Flags

- Any import of `django.db.connection`
- `cursor.execute()` calls
- `.raw()` on any QuerySet
- `.extra()` calls (deprecated)
- SQL strings in Python files
- Comments like "ORM can't do this" — it almost certainly can

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
