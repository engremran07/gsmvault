---
agent: 'agent'
description: 'Plan and implement a new feature across existing apps: models, services, views, templates, tests, and documentation.'
tools: ['semantic_search', 'read_file', 'grep_search', 'list_dir', 'file_search', 'run_in_terminal']
---

# New Feature

Implement a complete new feature across one or more existing apps. The user will describe what they want built.

## Step 1 — Feature Analysis

1. Understand the feature requirements from the user's description.
2. Determine which existing app(s) should own this feature. Prefer extending existing apps over creating new ones.
3. Search the codebase for any existing implementation that covers partial or full functionality.
4. Check `templates/components/` for reusable UI components that apply.

## Step 2 — Design the Data Model

If new models are needed:

- Choose the correct base class: `TimestampedModel` (most common), `SoftDeleteModel` (for deletable records), `AuditFieldsModel` (for audited records). All from `apps.core.models`.
- Define all fields with appropriate types and constraints.
- Add `related_name` on every FK and M2M.
- Add `class Meta` with `db_table`, `verbose_name`, `verbose_name_plural`, `ordering`.
- Add `__str__` method.
- Add database indexes on frequently queried fields.
- For financial models: ensure `select_for_update()` compatibility.

If existing models need changes:

- Add fields to existing models — never create parallel model versions.
- Create migration with `makemigrations`.
- Provide default values or make fields nullable for existing data.

## Step 3 — Implement Business Logic

Add service functions to `apps/<app>/services.py`:

- Keep views thin — all logic in services.
- Use `@transaction.atomic` for multi-model operations.
- Use `select_for_update()` for financial records (wallet, credits, balances).
- Sanitize user HTML input with `apps.core.sanitizers.sanitize_html_content()`.
- For cross-app effects, emit events via `apps.core.events.EventBus` — never import other apps' services directly.
- Full type hints on all function signatures.

## Step 4 — Create Views

Add views to `apps/<app>/views.py`:

- Function-based for simple endpoints, class-based for complex CRUD.
- Support HTMX: detect `request.headers.get("HX-Request")` and return fragment templates.
- Auth: use `@login_required` for authenticated views.
- Staff: use `getattr(request.user, "is_staff", False)` (anonymous-safe).
- Ownership: filter by `user=request.user` for user-specific data.
- Pagination: use Django's `Paginator` for list views.

## Step 5 — Define URL Patterns

Add URL patterns to `apps/<app>/urls.py`:

- Use descriptive names for all patterns.
- Follow existing naming conventions in the app.
- Use path converters (`<int:pk>`, `<slug:slug>`) consistently.

## Step 6 — Build Templates

Create templates following platform conventions:

### Full Page Templates (`templates/<app>/`)
- Extend `templates/base/base.html` or appropriate layout.
- Use components from `templates/components/` — never inline duplicates.
- Use CSS custom properties for theming — never hardcode colors.
- Add Alpine.js `x-cloak` on all `x-show`/`x-if` elements.

### HTMX Fragment Templates (`templates/<app>/fragments/`)
- Must NOT use `{% extends %}` — standalone HTML snippets only.
- Include only the content being swapped.
- Support OOB swaps if multiple page sections need updating.

## Step 7 — Add Admin Support

If the feature needs admin management:

- Identify the correct admin view module in `apps/admin/` (one of 8 modules).
- Use `_render_admin()` from `views_shared.py` — never call `render()` directly.
- Use admin components: `_admin_kpi_card.html`, `_admin_table.html`, `_admin_search.html`.
- Add admin URL patterns in `apps/admin/urls.py`.

## Step 8 — Add API Endpoints (if needed)

If the feature needs API access:

- Add DRF serializers and viewsets to `apps/<app>/api.py`.
- Add proper permission classes.
- Add throttling from `apps.core.throttling`.
- Use consistent error format: `{"error": "message", "code": "ERROR_CODE"}`.
- Add URL patterns to the API router.

## Step 9 — Write Tests

Create tests covering:

- Model creation, validation, constraints, `__str__`.
- Service function happy path and error cases.
- View authentication, permissions, status codes, HTMX branching.
- API CRUD, auth, permissions, validation.

## Step 10 — Run Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## Step 11 — Update Documentation

- `README.md` — Feature description.
- `AGENTS.md` — New models/services in architecture.
- `.github/copilot-instructions.md` — Feature summary.
