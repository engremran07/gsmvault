---
agent: 'agent'
description: 'Plan a new feature implementation across all affected layers: models, services, views, templates, URLs, admin, tests, docs.'
tools: ['semantic_search', 'read_file', 'grep_search', 'list_dir', 'file_search', 'run_in_terminal']
---

# Feature Plan

Plan the full implementation of a new feature. The user will describe the feature they want to add.

## Step 1 — Understand the Feature

1. Clarify the feature requirements from the user's description.
2. Identify which existing app(s) this feature belongs to. Reference the 31 apps in `apps/`.
3. Determine if this is a single-app feature or crosses app boundaries.
4. Check if similar functionality already exists — search the codebase before planning anything new.

## Step 2 — Identify Affected Layers

For each affected app, determine changes needed at every layer:

### Models (`apps/<app>/models.py`)
- New models needed? List fields, relationships, Meta options, `__str__`, `db_table`.
- Existing model changes? New fields, new constraints, index additions.
- Base class selection: `TimestampedModel`, `SoftDeleteModel`, or `AuditFieldsModel` from `apps.core.models`.
- Every FK/M2M must have `related_name`.
- Financial models must support `select_for_update()`.

### Services (`apps/<app>/services.py`)
- Business logic functions needed. Views must stay thin — logic goes here.
- Cross-app communication via `apps.core.events.EventBus` — never direct imports.
- Financial operations need `@transaction.atomic` and `select_for_update()`.
- Input sanitization via `apps.core.sanitizers.sanitize_html_content()` for user HTML.

### Views (`apps/<app>/views.py`)
- New view functions or CBVs needed.
- HTMX support: views should detect `HX-Request` header and return fragments.
- Auth checks: `@login_required`, `getattr(request.user, "is_staff", False)`.
- Ownership validation for user-specific resources.

### Templates (`templates/<app>/`)
- Full page templates extending `templates/base/base.html` or a layout.
- HTMX fragment templates in `templates/<app>/fragments/` — must NOT use `{% extends %}`.
- Use existing components from `templates/components/` (23 available).
- Alpine.js elements need `x-cloak` to prevent FOUC.
- Theme-safe: use CSS custom properties, never hardcode colors.

### URLs (`apps/<app>/urls.py`)
- New URL patterns with proper naming.
- URL namespace already configured in `app/urls.py`.

### Admin (`apps/admin/`)
- Admin view module to update (one of 8: `views_auth`, `views_content`, `views_distribution`, `views_extended`, `views_infrastructure`, `views_security`, `views_settings`, `views_users`).
- Use `_render_admin()` helper from `views_shared.py`.
- Admin templates use components from `templates/components/_admin_*.html`.

### API (`apps/<app>/api.py`)
- DRF serializers, viewsets, permissions needed.
- Consistent error format: `{"error": "message", "code": "ERROR_CODE"}`.
- Throttling via `apps.core.throttling` classes.

### Tests
- Model tests: validation, constraints, `__str__`.
- Service tests: business logic, edge cases, `@transaction.atomic`.
- View tests: auth, permissions, HTMX branching, status codes.
- API tests: CRUD, permissions, throttling, pagination.

### Documentation
- Update `README.md` with feature description.
- Update `AGENTS.md` with new models/services if applicable.
- Update `.github/copilot-instructions.md` with feature notes.

## Step 3 — Dependency Graph

List the implementation order based on dependencies:

1. Models first (data layer)
2. Migrations (`makemigrations`)
3. Services (business logic)
4. Views + URLs (presentation)
5. Templates (UI)
6. Admin views (management)
7. API endpoints (external access)
8. Tests (verification)
9. Documentation (completeness)

## Step 4 — Output the Task List

Generate a numbered checklist:

```markdown
## Feature: [Name]

### Prerequisites
- [ ] Verify no existing implementation covers this (search first)
- [ ] Confirm target app(s)

### Implementation
- [ ] 1. Add models to `apps/<app>/models.py`
- [ ] 2. Run `makemigrations` and `migrate`
- [ ] 3. Add service functions to `apps/<app>/services.py`
- [ ] 4. Add views to `apps/<app>/views.py`
- [ ] 5. Add URL patterns to `apps/<app>/urls.py`
- [ ] 6. Create templates in `templates/<app>/`
- [ ] 7. Add admin views in `apps/admin/views_<module>.py`
- [ ] 8. Add API endpoints in `apps/<app>/api.py`
- [ ] 9. Write tests

### Quality Gate
- [ ] `ruff check . --fix` — zero errors
- [ ] `ruff format .` — formatted
- [ ] `manage.py check --settings=app.settings_dev` — no issues
- [ ] All new public APIs have type hints
- [ ] Documentation updated (README, AGENTS.md, copilot-instructions.md)
```
