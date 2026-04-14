---
name: sec-authz-abac
description: "Attribute-based access control: user tier, device trust, consent. Use when: complex access rules, multi-factor authorization, tier-based features."
---

# Attribute-Based Access Control

## When to Use

- Access decisions based on multiple user attributes
- Tier-based feature gating (free, subscriber, premium)
- Device trust level affecting permissions
- Consent-based feature availability

## Rules

| Attribute | Source | Example Gate |
|-----------|--------|-------------|
| Subscription tier | `user.subscription.tier` | Premium downloads |
| Device trust | `device.trust_score` | Skip captcha if score > 80 |
| Consent scope | `ConsentRecord` | Analytics features |
| Account age | `user.date_joined` | Forum posting after 24h |
| Download count | `DownloadToken.count()` | Quota enforcement |

## Patterns

### Multi-Attribute Permission
```python
from rest_framework.permissions import BasePermission

class CanDownloadPremium(BasePermission):
    """User must be subscriber + trusted device + active consent."""

    def has_permission(self, request, view) -> bool:
        user = request.user
        if not user.is_authenticated:
            return False
        # Check tier
        tier = getattr(user, "subscription_tier", "free")
        if tier not in ("subscriber", "premium"):
            return False
        # Check device trust (if device fingerprint exists)
        device = getattr(request, "device", None)
        if device and device.trust_score < 50:
            return False
        return True
```

### Tier-Based Feature Gate
```python
def check_download_access(user, firmware) -> tuple[bool, str]:
    """Check if user can download this firmware. Returns (allowed, reason)."""
    if firmware.tier_required == "premium" and user.subscription_tier == "free":
        return False, "Premium subscription required"
    daily_count = DownloadToken.objects.filter(
        user=user, created_at__date=timezone.now().date()
    ).count()
    quota = QuotaTier.objects.get(tier=user.subscription_tier)
    if daily_count >= quota.daily_limit:
        return False, f"Daily limit of {quota.daily_limit} reached"
    return True, "ok"
```

### Consent-Gated Features
```python
from apps.consent.utils import check_consent

def analytics_dashboard(request: HttpRequest) -> HttpResponse:
    if not check_consent(request, scope="analytics"):
        return render(request, "consent/required.html", {
            "scope": "analytics",
            "feature": "Analytics Dashboard",
        })
    return render(request, "analytics/dashboard.html")
```

## Red Flags

- Only checking one attribute when multiple are required
- Tier checks in templates but not in views
- Hardcoded tier names instead of model-driven lookup
- Missing consent check for analytics/tracking features

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
