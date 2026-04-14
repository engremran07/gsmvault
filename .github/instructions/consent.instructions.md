---
applyTo: 'apps/consent/**'
---

# Consent App Instructions

## Overview

`apps.consent` is the privacy/consent enforcement layer. It provides consent UI views, REST API, middleware, decorators, context processors, signals, and utilities.

## Critical: models.py Is a SHIM

`apps/consent/models.py` is a **re-export shim** — it does NOT define models. All consent models live in `apps.users`:

```python
# apps/consent/models.py — THIS IS A SHIM
from apps.users.models import (  # noqa: F401
    ConsentPolicy,
    ConsentRecord,
    ConsentDecision,
    ConsentEvent,
    ConsentLog,
    ConsentCategory,
)
```

All other files in `apps/consent/` are active production code (views, middleware, decorators, utils, API).

## Consent Scopes

| Scope | Required | Purpose |
|---|---|---|
| `functional` | **Yes** (always on) | Core site functionality, session, CSRF |
| `analytics` | No | Traffic analytics, page view tracking |
| `seo` | No | SEO tracking, search engine optimization features |
| `ads` | No | Personalized ad serving, ad tracking |

## Form Views — NEVER Return JSON

**CRITICAL PATTERN**: Consent form views (`accept_all`, `reject_all`, `accept`) always return `HttpResponseRedirect` to `HTTP_REFERER`. The consent cookie is set on the redirect response.

```python
# apps/consent/views.py — canonical pattern
def _consent_done(request, consent_data):
    """Set cookie and redirect back — NEVER return JSON from form views."""
    referer = request.META.get("HTTP_REFERER", "/")
    response = HttpResponseRedirect(referer)
    response.set_cookie(
        "consent",
        json.dumps(consent_data),
        max_age=365 * 24 * 60 * 60,  # 1 year
        httponly=True,
        secure=not settings.DEBUG,
        samesite="Lax",
    )
    return response
```

**Why**: Returning JSON from form views causes "raw JSON on blank screen" bugs when `fetch()` follows redirects. The redirect pattern eliminates this entire class of bugs.

## JSON API — Separate Endpoints

For programmatic consent management, use the DRF endpoints:

```
GET  /consent/api/status/   → Returns current consent state as JSON
POST /consent/api/update/   → Updates consent preferences via JSON body
```

These endpoints are separate from the form views and correctly return JSON responses.

## @consent_required Decorator

Gate views behind consent checks:

```python
from apps.consent.decorators import consent_required

@consent_required("analytics")
def analytics_dashboard(request):
    # Only accessible if user has analytics consent
    pass
```

## Middleware

`apps.consent.middleware.ConsentMiddleware` runs on every request to:
1. Read consent cookie
2. Attach consent state to `request.consent`
3. Enforce consent-gated functionality (e.g., block analytics tracking if no consent)

## Context Processor

`apps.consent.context_processors.consent_context` adds consent state to all templates:

```html
{% if consent.analytics %}
  {# Include analytics scripts #}
{% endif %}

{% if consent.ads %}
  {# Include personalized ad scripts #}
{% endif %}
```

## Utility Functions

```python
from apps.consent.utils import (
    hash_ip,           # Hash IP for privacy-compliant logging
    hash_ua,           # Hash User-Agent for fingerprinting
    check_consent,     # Check if user has consented to a scope
    get_active_policy, # Get the current ConsentPolicy
)

# Usage
if check_consent(request, "ads"):
    serve_personalized_ads(request)
else:
    serve_generic_ads(request)
```

## Signals

```python
from apps.consent.signals import consent_updated

# Emitted when user changes consent preferences
# Receivers in other apps can react (e.g., clear analytics data on revoke)
```

## Cookie Structure

```json
{
  "functional": true,
  "analytics": true,
  "seo": false,
  "ads": false,
  "timestamp": "2024-01-15T10:30:00Z",
  "policy_version": "1.2"
}
```

## Forbidden Practices

- Never return JSON from consent form views — always `HttpResponseRedirect`
- Never set consent cookie without checking policy version
- Never bypass consent checks for analytics/ads
- Never store raw IP addresses — use `hash_ip()` for privacy
- Never import consent models directly from `apps.users` — import from `apps.consent.models` (the shim)
- Never auto-accept consent on behalf of users
