---
paths: ["apps/*/context_processors.py"]
---

# Context Processors Rules

Context processors inject variables into every template context. They must be fast and cache-aware since they run on every request.

## Performance Requirements

- Context processors run on EVERY template-rendered request — MUST be lightweight.
- NEVER execute uncached database queries in context processors.
- ALWAYS use `apps.core.cache.DistributedCacheManager` or Django's cache framework for expensive lookups:
  ```python
  def site_settings(request):
      settings = cache.get("site_settings")
      if settings is None:
          settings = SiteSettings.get_solo()
          cache.set("site_settings", settings, timeout=300)
      return {"site_settings": settings}
  ```
- Cache timeout: 60–300 seconds for settings, 30–60 seconds for dynamic data.

## Return Format

- ALWAYS return a `dict` — even if empty: `return {}`.
- Use descriptive, namespaced keys to avoid collisions: `site_settings`, `consent_status`, `theme_config`.
- NEVER return model querysets — evaluate to lists or dicts before returning.
- NEVER return sensitive data (passwords, tokens, API keys) in context.

## Common Use Cases

- **Site settings**: branding, SEO defaults, feature flags (from `SiteSettings` singleton).
- **Theme config**: current theme slug, CSS custom property overrides.
- **Consent status**: user's consent decisions for functional, analytics, seo, ads categories.
- **Navigation context**: active menu items, breadcrumb stubs, user notification count.
- **Debug info**: `settings.DEBUG` flag for development-only template blocks.

## Registration

- Register in `settings.py` under `TEMPLATES[0]["OPTIONS"]["context_processors"]`.
- Use the full dotted path: `"apps.consent.context_processors.consent_context"`.
- Order doesn't matter for context processors (unlike middleware), but group logically.

## Anti-Patterns

- NEVER do N+1 queries — prefetch/aggregate in a single query if multiple related objects are needed.
- NEVER call external APIs from context processors.
- NEVER modify request state in context processors — they are read-only observers.
- NEVER conditionally skip returning a dict — always return at least `{}` to avoid `TypeError`.
- NEVER add context processors for data only needed on one page — pass it from the view instead.
