---
name: services-csv-export
description: "CSV export patterns: StreamingHttpResponse, large dataset handling. Use when: exporting data as CSV, streaming large exports, admin data downloads."
---

# CSV Export Patterns

## When to Use
- Exporting model data as downloadable CSV
- Admin bulk data export (users, orders, analytics)
- Streaming large datasets without memory issues
- Scheduled report generation

## Rules
- Use `StreamingHttpResponse` for large exports (1000+ rows)
- Use `.iterator()` on querysets to avoid loading all rows into memory
- Set proper `Content-Disposition` header for file download
- Use `csv.writer` with `Echo` pseudo-buffer for streaming
- Sanitize cell values to prevent CSV injection (prefix `=`, `+`, `-`, `@` with `'`)

## Patterns

### Streaming CSV Export
```python
import csv
from django.http import StreamingHttpResponse

class Echo:
    """Pseudo-buffer for CSV writer streaming."""
    def write(self, value):
        return value

def export_firmwares_csv() -> StreamingHttpResponse:
    """Stream firmware data as CSV."""
    queryset = Firmware.objects.select_related("brand", "model").iterator(chunk_size=1000)

    def generate():
        writer = csv.writer(Echo())
        yield writer.writerow(["ID", "Name", "Brand", "Model", "Size", "Status"])
        for fw in queryset:
            yield writer.writerow([
                fw.pk,
                sanitize_csv_cell(fw.name),
                fw.brand.name if fw.brand else "",
                fw.model.name if fw.model else "",
                fw.file_size,
                fw.status,
            ])

    response = StreamingHttpResponse(generate(), content_type="text/csv")
    response["Content-Disposition"] = 'attachment; filename="firmwares_export.csv"'
    return response
```

### CSV Injection Prevention
```python
def sanitize_csv_cell(value: str) -> str:
    """Prevent CSV injection by escaping dangerous prefixes."""
    if isinstance(value, str) and value and value[0] in ("=", "+", "-", "@", "\t", "\r"):
        return f"'{value}"
    return value
```

### View for CSV Download
```python
from django.contrib.auth.decorators import login_required, user_passes_test

@login_required
@user_passes_test(lambda u: u.is_staff)
def admin_export_users(request):
    """Admin-only CSV export of user data."""
    from . import services
    return services.export_users_csv()
```

### Small Dataset CSV (In-Memory)
```python
import csv
from django.http import HttpResponse

def export_small_csv(queryset, filename: str, fields: list[str]) -> HttpResponse:
    """Simple CSV export for small datasets (<1000 rows)."""
    response = HttpResponse(content_type="text/csv")
    response["Content-Disposition"] = f'attachment; filename="{filename}"'
    writer = csv.writer(response)
    writer.writerow(fields)
    for obj in queryset:
        writer.writerow([sanitize_csv_cell(str(getattr(obj, f, ""))) for f in fields])
    return response
```

### Async CSV Generation for Large Exports
```python
from celery import shared_task

@shared_task
def generate_analytics_csv(month: int, year: int) -> str:
    """Generate large analytics CSV asynchronously."""
    import csv
    from django.core.files.storage import default_storage
    from io import StringIO

    buffer = StringIO()
    writer = csv.writer(buffer)
    writer.writerow(["Date", "Page", "Views", "Downloads"])
    for event in AnalyticsEvent.objects.filter(
        created_at__month=month, created_at__year=year
    ).iterator(chunk_size=5000):
        writer.writerow([event.date, event.page, event.views, event.downloads])

    path = f"exports/{year}/{month:02d}/analytics.csv"
    default_storage.save(path, ContentFile(buffer.getvalue().encode()))
    return path
```

## Anti-Patterns
- Loading all rows into memory with `list()` before CSV writing
- No CSV injection prevention — `=cmd()` in cells can execute
- Missing `Content-Disposition` header — browser tries to render instead of download
- Exporting without authentication check — data exposure

## Red Flags
- `.all()` without `.iterator()` for 10k+ row exports
- User-supplied data written directly to CSV without sanitization
- CSV export endpoint without `@login_required`

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
