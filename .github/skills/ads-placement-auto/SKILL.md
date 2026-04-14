---
name: ads-placement-auto
description: "Auto placement: template scanning, AI-discovered positions. Use when: running auto-ads scanner, reviewing scan discoveries, approving AI-suggested placements."
---

# Auto Ad Placement

## When to Use
- Running the auto-ads template scanner (`scan_templates_for_ad_placements` Celery task)
- Reviewing `AutoAdsScanResult` and `ScanDiscovery` records
- Approving/rejecting AI-suggested placement positions
- Excluding templates from scanning via `TemplateAdExclusion`

## Rules
- Scanner creates `AutoAdsScanResult` per template with `review_status = PENDING`
- Each result has multiple `ScanDiscovery` records (individual placement zones)
- Discoveries require admin approval before becoming live `AdPlacement` records
- Templates in `TemplateAdExclusion` are always skipped
- `ad_density_warning = True` flags templates with too many existing ads
- Scanner detects viewport zones: above-fold, mid-content, sidebar, footer, sticky

## Patterns

### Running the Scanner
```python
# apps/ads/tasks.py
from celery import shared_task

@shared_task(name="ads.scan_templates")
def scan_templates_for_ad_placements() -> dict:
    from apps.ads.services import auto_scan
    return auto_scan.run_full_scan()
```

### Processing Scan Results
```python
# apps/ads/services/auto_scan.py
from apps.ads.models import AutoAdsScanResult, ScanDiscovery

def approve_discovery(*, discovery_id: int, admin_user) -> ScanDiscovery:
    discovery = ScanDiscovery.objects.select_related("scan_result").get(pk=discovery_id)
    discovery.status = ScanDiscovery.Status.APPROVED
    discovery.reviewed_by = admin_user
    discovery.reviewed_at = timezone.now()
    # Create the actual AdPlacement from discovery
    placement = AdPlacement.objects.create(
        name=discovery.placement_name,
        slot_id=discovery.placement_code,
        is_enabled=False,  # Admin enables after review
    )
    discovery.placement = placement
    discovery.save()
    return discovery
```

### Excluding Templates
```python
from apps.ads.models import TemplateAdExclusion

def exclude_template(*, template_path: str, reason: str, user) -> TemplateAdExclusion:
    return TemplateAdExclusion.objects.create(
        template_path=template_path,
        reason=reason,
        excluded_by=user,
    )
```

## Anti-Patterns
- Auto-approving scan discoveries without admin review
- Scanning HTMX fragment templates — they're partial, not full pages
- Ignoring `ad_density_warning` — leads to CLS penalties and bad UX
- Creating placements directly without going through scanner workflow

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
