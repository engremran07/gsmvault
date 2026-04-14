---
name: ads-consent-gating
description: "Consent-gated ad serving: GDPR compliance. Use when: checking consent before serving personalized ads, implementing consent-aware ad loading, GDPR ad compliance."
---

# Consent-Gated Ad Serving

## When to Use
- Checking user consent before serving personalized ads
- Loading ads conditionally based on `ads` consent scope
- GDPR/ePrivacy directive compliance for ad networks
- Falling back to contextual (non-personalized) ads when consent denied

## Rules
- `apps.consent` manages consent scopes: `functional`, `analytics`, `seo`, `ads`
- Ads consent scope = `ads` — check before loading any ad network scripts
- If consent denied: serve contextual ads only (no tracking, no cookies)
- If consent granted: load full personalized ad network scripts
- Use `@consent_required("ads")` decorator on ad-serving API endpoints
- Consent check happens BEFORE network script injection in templates

## Patterns

### Template-Level Consent Check
```html
{# templates/base/base.html — conditional ad network loading #}
{% load consent_tags %}

{% if consent_granted "ads" %}
  {# Full personalized ad scripts #}
  {% for network in active_networks %}
    {{ network.header_script|safe }}
  {% endfor %}
{% else %}
  {# Contextual-only fallback #}
  <script>window.__AD_MODE__ = 'contextual';</script>
{% endif %}
```

### Service-Level Consent Check
```python
# apps/ads/services/rotation.py
from apps.consent.utils import check_consent

def select_ad_for_placement(*, request, placement: AdPlacement):
    """Select ad respecting consent status."""
    has_ads_consent = check_consent(request, "ads")

    if has_ads_consent:
        # Full personalized rotation with targeting
        return get_targeted_creative(placement=placement, request=request)
    else:
        # Contextual only — no user data, no cookies
        return get_contextual_creative(placement=placement)
```

### API Endpoint with Consent Guard
```python
# apps/ads/api.py
from apps.consent.decorators import consent_required

@consent_required("ads")
def serve_personalized_ad(request, slot_id: str):
    """Only serves personalized ads if consent granted."""
    ...
```

## Anti-Patterns
- Loading ad network scripts before checking consent — GDPR violation
- Ignoring consent for "first-party" ads — still requires consent if tracking
- No contextual fallback — losing revenue when consent is denied
- Checking consent client-side only — must verify server-side too

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
