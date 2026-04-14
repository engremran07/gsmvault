---
name: sec-sql-injection-orm
description: "SQL injection prevention via Django ORM exclusively. Use when: writing queries, reviewing data access, auditing for raw SQL."
---

# SQL Injection Prevention — ORM Only

## When to Use

- Writing any database query
- Reviewing data access patterns
- Auditing codebase for raw SQL usage

## Rules

| Rule | Enforcement |
|------|-------------|
| No raw SQL | `cursor.execute()` and `.raw()` are forbidden |
| ORM only | All queries via Django QuerySet API |
| Parameterized | ORM handles parameterization automatically |
| No string formatting | Never f-string or `.format()` in queries |

## Patterns

### Safe ORM Queries
```python
# SAFE: ORM parameterizes automatically
results = Firmware.objects.filter(name__icontains=user_query)
device = Device.objects.get(pk=device_id, user=request.user)
brands = Brand.objects.filter(slug__in=slug_list).order_by("name")

# SAFE: Complex lookups with Q objects
from django.db.models import Q
results = Firmware.objects.filter(
    Q(name__icontains=query) | Q(description__icontains=query),
    is_active=True,
)

# SAFE: Aggregation
from django.db.models import Count, Avg
stats = Firmware.objects.aggregate(
    total=Count("id"),
    avg_size=Avg("file_size"),
)
```

### ORM Alternatives to Raw SQL
```python
# Instead of: SELECT * FROM firmware WHERE name LIKE '%query%'
Firmware.objects.filter(name__icontains=query)

# Instead of: SELECT DISTINCT brand_id FROM firmware
Firmware.objects.values_list("brand_id", flat=True).distinct()

# Instead of: UPDATE firmware SET downloads = downloads + 1 WHERE id = ?
from django.db.models import F
Firmware.objects.filter(pk=fw_id).update(downloads=F("downloads") + 1)

# Instead of: complex JOIN
Firmware.objects.select_related("brand", "model").filter(brand__slug=slug)
```

## Red Flags

- `connection.cursor()` anywhere in application code
- `.raw()` QuerySet method
- `.extra()` QuerySet method (deprecated and unsafe)
- f-strings or `.format()` near any query construction
- `RawSQL()` expressions
- SQL in management commands — use ORM there too

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
