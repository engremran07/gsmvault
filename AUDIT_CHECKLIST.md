# Audit Checklist — Post-Implementation Gates

Run this checklist after completing any feature, bug fix, or refactor.
Every item must pass before the task is considered complete.

---

## Quick Gate (MANDATORY — Run First)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

- [ ] Ruff check: zero warnings (E, W, F, I, N, UP, B, C4, SIM, RUF)
- [ ] Ruff format: zero formatting issues
- [ ] Django check: `System check identified no issues (0 silenced)`
- [ ] VS Code Problems tab: zero errors (check all items, remove filters)

**If the quick gate fails, fix all issues before proceeding.**

---

## Code Quality

### Type Safety

- [ ] All new public functions have full type hints (parameters + return)
- [ ] `ModelAdmin` classes typed: `class MyAdmin(admin.ModelAdmin[MyModel]):`
- [ ] `get_queryset()` annotated: `-> QuerySet[MyModel]`
- [ ] No blanket `# type: ignore` — always specify: `[attr-defined]`, `[import-untyped]`, etc.
- [ ] Django reverse FK managers use `# type: ignore[attr-defined]`
- [ ] Pyright/Pylance reports zero errors on modified files

### Code Patterns

- [ ] Business logic in `services.py` — views are thin orchestrators
- [ ] No god files (>500 lines without justification)
- [ ] No versioned files (`_v2.py`, `_new.py`, `_backup.py`)
- [ ] No duplicate infrastructure (check `templates/components/` first)
- [ ] `related_name` on every FK and M2M relationship
- [ ] Every model has `__str__`, `class Meta` with `verbose_name`, `verbose_name_plural`, `ordering`, `db_table`

---

## Security

### Input Handling

- [ ] All user-supplied HTML sanitized with `apps.core.sanitizers.sanitize_html_content()` (nh3-based)
- [ ] Never use `bleach` — it has been replaced by `nh3`
- [ ] File uploads validated: MIME type, extension, and file size checked in service layer
- [ ] All user inputs validated through Django form/serializer validation

### Authentication & Authorization

- [ ] Protected views have `@login_required` or equivalent
- [ ] Admin views check `is_staff` (use `getattr(request.user, "is_staff", False)` pattern)
- [ ] Ownership checks on object access: `.get(pk=pk, user=request.user)`
- [ ] No endpoint exposes data without proper authorization

### Infrastructure

- [ ] CSRF protection on all mutating endpoints
- [ ] No raw SQL — Django ORM exclusively
- [ ] No hardcoded secrets, API keys, or passwords in source code
- [ ] Credentials via environment variables (`.env`, never committed)
- [ ] No sensitive data in logs (passwords, tokens, full request bodies)
- [ ] `select_for_update()` on all wallet/financial mutations
- [ ] `@transaction.atomic` on multi-model service operations

---

## Architecture

### App Boundaries

- [ ] No cross-app model imports in `models.py` or `services.py`
- [ ] Cross-app communication uses `apps.core.events.EventBus` or Django signals
- [ ] Only `apps/admin/` imports models from all other apps
- [ ] `apps.core.*` and `apps.site_settings.*` imports are allowed everywhere
- [ ] Views (orchestrators) may import from multiple apps

### Service Layer

- [ ] Business logic lives in `services.py`, not in views
- [ ] Services use `@transaction.atomic` for multi-model operations
- [ ] No circular imports between apps
- [ ] Dissolved app models preserve `db_table = "original_app_tablename"`

---

## Frontend

### Templates

- [ ] Full pages extend appropriate layout (`layouts/default.html`, etc.)
- [ ] HTMX fragments do NOT use `{% extends %}` — standalone snippets only
- [ ] All `x-show`/`x-if` elements have `x-cloak` to prevent FOUC
- [ ] Alpine.js `x-show` elements do NOT have CSS `animate-*` classes
- [ ] Reusable components used via `{% include %}` (check `templates/components/`)
- [ ] No inline KPI cards, pagination, modals, or search bars

### HTMX & Interactivity

- [ ] HTMX CSRF handled via global `<body hx-headers>` (no per-request CSRF)
- [ ] HTMX fragments return proper HTML (no JSON from fragment views)
- [ ] Views detect `HX-Request` header for dual-mode rendering

### Theme Compliance

- [ ] Uses CSS custom properties (`--color-*`), never hardcoded colors
- [ ] `--color-accent-text` used on accent backgrounds (WHITE in dark/light, BLACK in contrast)
- [ ] All three themes tested: dark (default), light, contrast

---

## Database

### Migrations

- [ ] `manage.py makemigrations` run for any model changes
- [ ] Migrations tested: `manage.py migrate` completes without errors
- [ ] No manual edits to migration files
- [ ] Dissolved model migrations preserve `db_table` in Meta

### Data Safety

- [ ] `select_for_update()` on financial record mutations (wallet, escrow)
- [ ] `@transaction.atomic` on operations spanning multiple tables
- [ ] No raw SQL anywhere in application code
- [ ] Parameterized queries enforced by ORM (no string formatting)

---

## Documentation

- [ ] `README.md` updated if new feature is user-facing
- [ ] `AGENTS.md` updated if new app, model, or architectural change
- [ ] `.github/copilot-instructions.md` updated if new convention or gotcha
- [ ] `BREAKAGE_CHAINS.md` updated if new coupling chain discovered
- [ ] Inline code comments for non-obvious logic

---

## Testing

- [ ] Tests written for new functionality (models, services, views, API)
- [ ] Test coverage maintained or improved (no coverage decrease)
- [ ] No regressions in existing tests (`pytest` passes clean)
- [ ] Edge cases covered (empty inputs, boundary values, error paths)
- [ ] Financial operations tested with concurrent access patterns

---

## Governance

- [ ] New rule files follow `.claude/rules/` format (YAML frontmatter, paths)
- [ ] New hooks are non-destructive (exit 0/2, not 1 unless blocking is intended)
- [ ] New commands have step-by-step checklists
- [ ] New agents include Quality Gate section
- [ ] New skills include When to Use, Rules, Procedure sections

---

## Final Verification

```powershell
# Full quality gate (repeat after all fixes)
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

- [ ] Quick gate passes clean (re-run after all changes)
- [ ] `manage.py runserver --settings=app.settings_dev` starts without errors
- [ ] No new entries needed in `REGRESSION_REGISTRY.md`

---

*Last updated: 2026-04-14. See `GOVERNANCE.md` for governance system documentation.*
