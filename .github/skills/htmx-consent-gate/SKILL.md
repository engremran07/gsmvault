---
name: htmx-consent-gate
description: "Consent-gated HTMX requests. Use when: blocking HTMX analytics/tracking until user consent, checking consent before loading third-party content, GDPR compliance."
---

# HTMX Consent-Gated Requests

## When to Use

- Blocking analytics HTMX calls until consent is given
- Preventing third-party content loading without consent
- GDPR-compliant lazy loading of tracking pixels
- Conditional HTMX requests based on consent status

## Rules

1. Check consent status before making HTMX requests for analytics/ads/SEO
2. Use `apps.consent` scopes: `functional` (required), `analytics`, `seo`, `ads`
3. Functional HTMX requests are always allowed — no consent gate needed
4. Use `hx-trigger` conditions or Alpine.js to gate requests
5. Server-side: use `@consent_required` decorator or check in view

## Patterns

### Alpine.js Consent-Gated Load

```html
<div x-data="{ consented: false }"
     x-init="consented = document.cookie.includes('consent_analytics=true')">

  {# Only load analytics widget if consent given #}
  <div x-show="consented" x-cloak
       hx-get="{% url 'analytics:widget' %}"
       hx-trigger="revealed"
       hx-target="this">
  </div>

  <div x-show="!consented" x-cloak>
    <p class="text-sm text-[var(--color-text-muted)]">
      Enable analytics cookies to view this content.
    </p>
  </div>
</div>
```

### Server-Side Consent Check

```python
from apps.consent.utils import check_consent

def analytics_widget(request):
    if not check_consent(request, "analytics"):
        return HttpResponse(
            '<p class="text-sm text-muted">Analytics consent required</p>',
            status=403,
        )
    # ... render analytics data
    return render(request, "analytics/fragments/widget.html", context)
```

### Consent-Gated Ad Loading

```html
{# Only load ad unit if ads consent is given #}
{% if request.consent.ads %}
<div hx-get="{% url 'ads:serve_ad' placement.pk %}"
     hx-trigger="revealed"
     hx-target="this"
     hx-swap="innerHTML">
</div>
{% else %}
<div class="ad-placeholder text-center py-4 text-sm text-[var(--color-text-muted)]">
  <p>Ad content blocked by privacy settings</p>
</div>
{% endif %}
```

### Consent Change Re-evaluation

```html
<script nonce="{{ request.csp_nonce }}">
document.addEventListener('consent-updated', function() {
  // Re-check consent and reload gated sections
  htmx.trigger(document.body, 'consent-changed');
});
</script>
```

## Anti-Patterns

```html
<!-- WRONG — loading analytics regardless of consent -->
<div hx-get="/analytics/tracking-pixel/" hx-trigger="load">

<!-- WRONG — checking consent only client-side (bypassable) -->
<!-- Always validate server-side too -->
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| Analytics HTMX calls without consent check | GDPR violation | Gate with consent check |
| Client-only consent check | Bypassable | Add server-side check |
| `@csrf_exempt` on consent endpoints | Security hole | Keep CSRF, use body `hx-headers` |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
