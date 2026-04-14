---
name: seo-metadata-bulk
description: "Bulk metadata operations: batch update, import/export. Use when: batch updating meta across pages, CSV import/export of SEO data, admin bulk actions."
---

# Bulk Metadata Operations

## When to Use

- Batch updating titles/descriptions across many pages
- CSV import/export of SEO metadata
- Admin bulk actions for metadata management

## Rules

### Bulk Update Service

```python
# apps/seo/services.py
from django.db import transaction

@transaction.atomic
def bulk_update_metadata(
    updates: list[dict[str, str]],
) -> dict[str, int]:
    """Batch update metadata records. Each dict needs 'path' + fields to update."""
    from apps.seo.models import Metadata
    updated = 0
    errors = 0
    for item in updates:
        path = item.pop("path", None)
        if not path:
            errors += 1
            continue
        count = Metadata.objects.filter(path=path).update(**item)
        if count:
            updated += 1
        else:
            errors += 1
    return {"updated": updated, "errors": errors}
```

### CSV Export

```python
import csv
from django.http import StreamingHttpResponse

def export_metadata_csv() -> StreamingHttpResponse:
    """Stream all metadata as CSV download."""
    from apps.seo.models import Metadata

    def csv_rows():
        writer = csv.writer((row := __import__("io").StringIO()))
        writer.writerow(["path", "title", "description", "keywords", "robots", "canonical_url"])
        yield row.getvalue()
        row.truncate(0); row.seek(0)
        for meta in Metadata.objects.all().iterator(chunk_size=500):
            writer.writerow([meta.path, meta.title, meta.description,
                             meta.keywords, meta.robots, meta.canonical_url])
            yield row.getvalue()
            row.truncate(0); row.seek(0)

    response = StreamingHttpResponse(csv_rows(), content_type="text/csv")
    response["Content-Disposition"] = 'attachment; filename="seo_metadata.csv"'
    return response
```

### CSV Import

```python
def import_metadata_csv(file_obj) -> dict[str, int]:
    """Import metadata from CSV. Creates or updates by path."""
    import csv
    from apps.seo.models import Metadata
    reader = csv.DictReader(file_obj.read().decode("utf-8").splitlines())
    created, updated = 0, 0
    for row in reader:
        path = row.get("path", "").strip()
        if not path:
            continue
        _, was_created = Metadata.objects.update_or_create(
            path=path,
            defaults={
                "title": row.get("title", "")[:70],
                "description": row.get("description", "")[:160],
                "keywords": row.get("keywords", "")[:255],
                "robots": row.get("robots", "index,follow"),
            },
        )
        if was_created:
            created += 1
        else:
            updated += 1
    return {"created": created, "updated": updated}
```

### Admin Bulk Action

```python
# apps/seo/admin.py
@admin.action(description="Set robots to noindex,nofollow")
def bulk_noindex(modeladmin, request, queryset):
    queryset.update(robots="noindex,nofollow")
```

## Anti-Patterns

- Loading all records into memory for export — use `.iterator()` with `StreamingHttpResponse`
- No length validation on CSV import — always truncate to field max_length
- Importing without `@transaction.atomic` — wrap bulk imports in transactions

## Red Flags

- CSV import accepts arbitrary field names without whitelist
- No file size limit on uploaded CSV
- Missing `chunk_size` on `.iterator()` calls

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
