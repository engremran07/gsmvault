---
paths: ["apps/admin/views*.py"]
---

# Admin Views Rules

All admin views use the centralized `_render_admin()` helper and follow a strict module structure. The admin app is the ONLY app allowed to import from all other apps.

## Module Structure

- Admin views are split across 8 modules: `views_auth`, `views_content`, `views_distribution`, `views_extended`, `views_infrastructure`, `views_security`, `views_settings`, `views_users`.
- Every admin view module MUST begin with `from .views_shared import *`.
- Shared helpers, decorators, and imports live in `views_shared.py` — NEVER duplicate them in individual modules.
- NEVER create new view modules without updating `apps/admin/urls.py` to import them.

## Rendering Pattern

- ALWAYS use `_render_admin(request, template, context, breadcrumbs)` — NEVER call `render()` directly in admin views.
- `_render_admin` enforces `@login_required` + staff check automatically.
- Breadcrumbs MUST be provided on every page as a list of `(label, url)` tuples.
- Template paths follow: `admin/<section>/<page>.html`.

## Cross-App Imports

- `apps/admin/` is the ONLY app permitted to import models and services from ALL other apps.
- This is by design — admin is the central orchestration and monitoring layer.
- Admin views CAN call service functions from any app.
- Admin views CAN query models from any app for dashboard aggregation.
- Other apps MUST NOT import from `apps/admin/` — the dependency is one-directional.

## Authentication & Authorization

- ALL admin views MUST require authentication and staff status.
- The `_render_admin` decorator handles this — but when writing standalone utility functions, verify `getattr(request.user, "is_staff", False)`.
- Superuser-only actions MUST additionally check `request.user.is_superuser`.
- Log all admin actions to `AdminAction` / `AuditLog` models for audit trail.

## Dashboard & Data Display

- Use `{% include "components/_admin_kpi_card.html" %}` for all KPI/stat cards — NEVER inline card HTML.
- Use `{% include "components/_admin_table.html" %}` for sortable data tables.
- Use `{% include "components/_admin_search.html" %}` for search bars.
- Use `{% include "components/_admin_bulk_actions.html" %}` for multi-select actions.
- Paginate all list views — use Django's `Paginator` or `{% include "components/_pagination.html" %}`.

## HTMX in Admin

- Admin HTMX fragments go in `templates/admin/<section>/fragments/`.
- Use `hx-target` and `hx-swap` for partial page updates.
- HTMX fragments MUST NOT use `{% extends %}`.
- Return `HX-Redirect` header when an action requires full page navigation.
