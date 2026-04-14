---
name: seo-interlinking-broken-repair
description: "Broken link detection and repair. Use when: scanning for dead internal links, finding 404 targets, auto-repairing stale URLs via redirect lookup."
---

# Broken Link Detection and Repair

## When to Use

- Scanning site content for dead internal links (404 targets)
- Repairing stale URLs by matching against `Redirect` records
- Building a periodic broken-link audit Celery task

## Rules

### Broken Link Scanner Service

```python
# apps/seo/services.py
import re
from django.test import RequestFactory
from django.urls import resolve, Resolver404

def scan_broken_links(content: str) -> list[dict[str, str]]:
    """Extract internal links and check if they resolve."""
    broken: list[dict[str, str]] = []
    href_pattern = re.compile(r'href=["\'](/[^"\']*)["\']')
    for match in href_pattern.finditer(content):
        path = match.group(1)
        try:
            resolve(path)
        except Resolver404:
            broken.append({"path": path, "position": str(match.start())})
    return broken
```

### Auto-Repair via Redirect Lookup

```python
def repair_broken_link(broken_path: str) -> str | None:
    """Attempt to find a redirect for a broken path."""
    from apps.seo.models import Redirect
    redirect = Redirect.objects.filter(
        source_path=broken_path, is_active=True
    ).first()
    if redirect:
        return redirect.target_path
    return None

def repair_content_links(content: str) -> tuple[str, int]:
    """Scan and repair broken links in HTML content."""
    repaired_count = 0
    broken = scan_broken_links(content)
    for link in broken:
        new_path = repair_broken_link(link["path"])
        if new_path:
            content = content.replace(
                f'href="{link["path"]}"',
                f'href="{new_path}"',
            )
            repaired_count += 1
    return content, repaired_count
```

### Celery Periodic Scan Task

```python
# apps/seo/tasks.py
from celery import shared_task

@shared_task(bind=True, max_retries=0)
def scan_broken_links_task(self) -> dict[str, int]:
    """Scan all linkable content for broken internal links."""
    from apps.seo.models import LinkableEntity
    total_broken = 0
    total_repaired = 0
    for entity in LinkableEntity.objects.filter(is_linkable=True).iterator():
        # Implementation: fetch content, scan, report
        pass
    return {"broken": total_broken, "repaired": total_repaired}
```

### Broken Link Report Model Pattern

| Field | Type | Purpose |
|-------|------|---------|
| `source_path` | CharField | Page containing the broken link |
| `broken_url` | CharField | The dead target URL |
| `suggested_fix` | CharField | Auto-suggested replacement URL |
| `status` | CharField | `detected` / `repaired` / `ignored` |
| `detected_at` | DateTimeField | When the broken link was found |

### Admin Action: Bulk Repair

```python
@admin.action(description="Auto-repair broken links via redirects")
def auto_repair_links(modeladmin, request, queryset):
    repaired = 0
    for report in queryset.filter(status="detected"):
        fix = repair_broken_link(report.broken_url)
        if fix:
            report.suggested_fix = fix
            report.status = "repaired"
            report.save(update_fields=["suggested_fix", "status"])
            repaired += 1
    modeladmin.message_user(request, f"Repaired {repaired} links.")
```

## Anti-Patterns

- Scanning external URLs in sync requests — use Celery for external checks
- Auto-replacing links without redirect verification — may create new broken links
- No audit trail of repairs — track what was changed and when

## Red Flags

- Broken link scan runs in a view (sync) — must be a background task
- No fallback when redirect not found — should flag for manual review
- Repairs applied without `repaired_count` tracking

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
