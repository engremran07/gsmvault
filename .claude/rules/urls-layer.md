---
paths: ["apps/*/urls.py", "app/urls.py"]
---

# URLs Layer Rules

URL configuration follows strict namespacing and naming conventions for reliable reverse resolution.

## Namespace Requirements

- Every app MUST define `app_name = "<appname>"` in its `urls.py`.
- The root `app/urls.py` MUST `include()` each app with its namespace: `path("blog/", include("apps.blog.urls", namespace="blog"))`.
- API endpoints live under `/api/v1/` — configured in `app/urls.py`.
- Admin panel URLs are in `apps/admin/urls.py`, which imports 8 view modules directly.

## URL Pattern Rules

- ALWAYS use `path()` — use `re_path()` only when regex matching is genuinely required.
- EVERY URL pattern MUST have a `name` parameter for `{% url %}` and `reverse()` usage.
- Use angle-bracket converters: `<int:pk>`, `<slug:slug>`, `<uuid:token>`.
- NEVER hardcode URLs in templates or views — ALWAYS use `{% url "namespace:name" %}` or `reverse()`.
- Keep URL paths lowercase with hyphens: `/firmware-downloads/` not `/firmwareDownloads/`.

## URL Organization

- Group related URLs logically within each app's `urls.py`.
- List-detail pattern: `""` for list, `"<int:pk>/"` for detail, `"<int:pk>/edit/"` for edit.
- HTMX fragment endpoints: prefix with `fragments/` or suffix with `/partial/`.
- API pattern: `urlpatterns` for page views, `api_urlpatterns` for DRF endpoints (if in same file).

## Admin URL Structure

- `apps/admin/urls.py` imports all 8 view modules: `views_auth`, `views_content`, `views_distribution`, `views_extended`, `views_infrastructure`, `views_security`, `views_settings`, `views_users`.
- Admin URLs use the `custom_admin` namespace.
- Grouped by section: `auth/`, `content/`, `security/`, `settings/`, etc.

## Security

- NEVER expose internal IDs in URLs for sensitive resources — use UUIDs or tokens.
- Authenticated endpoints MUST have corresponding `@login_required` on views — the URL alone provides no protection.
- NEVER create catch-all URL patterns that could shadow other routes.
- API URLs MUST be versioned: `/api/v1/`, `/api/v2/`.
