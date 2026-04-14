---
name: fin-affiliate-tracking
description: "Affiliate click/conversion tracking pipeline. Use when: recording affiliate link clicks, attributing conversions, building affiliate analytics."
---

# Affiliate Click/Conversion Tracking

## When to Use

- User clicks an affiliate link
- Attributing a purchase to an affiliate source
- Building affiliate performance dashboards

## Rules

1. **Record every click** with timestamp, user (if auth'd), IP, referrer
2. **Cookie-based attribution** — set cookie on click, read on conversion
3. **Attribution window** — typically 30 days from last click
4. **Deduplicate clicks** — don't count rapid re-clicks from same user
5. **Track conversions** separately from clicks — link via cookie/session

## Pattern: Click Tracking

```python
from django.utils import timezone
from apps.ads.models import AffiliateLink, AffiliateClick

def track_affiliate_click(
    link_id: int,
    request,
) -> AffiliateClick:
    """Record an affiliate link click."""
    link = AffiliateLink.objects.get(pk=link_id)
    user_id = request.user.pk if request.user.is_authenticated else None
    ip = get_client_ip(request)

    # Deduplicate: skip if same user/IP clicked same link within 1 hour
    recent = AffiliateClick.objects.filter(
        affiliate_link=link,
        ip_address=ip,
        clicked_at__gte=timezone.now() - timezone.timedelta(hours=1),
    ).exists()
    if recent:
        return None  # Skip duplicate

    click = AffiliateClick.objects.create(
        affiliate_link=link,
        user_id=user_id,
        ip_address=ip,
        referrer=request.META.get("HTTP_REFERER", ""),
        user_agent=request.META.get("HTTP_USER_AGENT", "")[:255],
    )
    # Update click count on link
    AffiliateLink.objects.filter(pk=link_id).update(
        click_count=models.F("click_count") + 1
    )
    return click
```

## Pattern: Conversion Attribution

```python
def attribute_conversion(
    user_id: int,
    order_id: int,
    cookie_value: str,
) -> AffiliateClick | None:
    """Attribute a conversion to the last affiliate click within window."""
    from datetime import timedelta
    window = timezone.now() - timedelta(days=30)

    click = (
        AffiliateClick.objects
        .filter(
            user_id=user_id,
            clicked_at__gte=window,
            conversion_order_id__isnull=True,
        )
        .order_by("-clicked_at")
        .first()
    )
    if click:
        click.conversion_order_id = order_id
        click.converted_at = timezone.now()
        click.save(update_fields=["conversion_order_id", "converted_at"])
    return click
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| No click deduplication | Inflated click counts | Check recent clicks |
| Attributing to first click instead of last | Inaccurate attribution | Last-click wins |
| No attribution window | Ancient clicks get credit | 30-day window |
| Storing full User-Agent without truncation | Database bloat | Truncate to 255 chars |

## Red Flags

- Click tracking without IP/referrer recording
- Missing conversion attribution logic
- No cookie-based tracking for anonymous users

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `apps/ads/models.py` — AffiliateLink, AffiliateClick
- `apps/ads/services/affiliate.py` — affiliate link resolution
