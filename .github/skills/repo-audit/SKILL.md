---
name: repo-audit
description: "Full recursive repo audit — every .py, every template, every static file. Use when: comprehensive audit, cross-app validation, missing templates, broken imports, dead code, stub detection, signal wiring, URL routing, admin registration, frontend validation, console errors, Alpine/HTMX/Tailwind issues."
---

# Repo Audit — Comprehensive Recursive Audit Skill

## Purpose

Enterprise-grade recursive audit of the entire GSMFWs codebase. This skill covers
EVERY layer — Python backend, Django templates, static assets, cross-app dependencies,
URL wiring, signals, tasks, middleware, context processors, admin registrations, and
frontend rendering validation.

**Zero partial reads. Zero skipping. Every file, every line.**

---

## Audit Dimensions (17 Total)

### 1. Model Integrity Audit
For EVERY `models.py` across all 31 apps:
- [ ] Every model has `__str__`, `class Meta` with `verbose_name`, `verbose_name_plural`, `ordering`, `db_table`
- [ ] Every FK/M2M has explicit `related_name`
- [ ] Dissolved models have `db_table = "original_app_tablename"` preserved
- [ ] No orphaned models (defined but not imported/registered)
- [ ] Choice fields use TextChoices/IntegerChoices (not raw tuples)
- [ ] `default_auto_field = "django.db.models.BigAutoField"` in apps.py
- [ ] No circular model imports between apps

### 2. Admin Registration Audit
For EVERY `admin.py` across all apps:
- [ ] Every model has a corresponding `@admin.register()` or `admin.site.register()`
- [ ] `ModelAdmin` is typed: `admin.ModelAdmin[MyModel]`
- [ ] `list_display`, `list_filter`, `search_fields` are populated (not empty)
- [ ] `readonly_fields` only reference fields that exist
- [ ] Singleton models use `SingletonModelAdmin` from django-solo

### 3. View-Template Wiring Audit
For EVERY `views.py` across all apps:
- [ ] Every `render(request, "template.html", ...)` references a template that EXISTS
- [ ] Every `template_name` on CBVs points to an existing file
- [ ] HTMX views return fragment templates (no `{% extends %}`)
- [ ] Full-page views return templates that extend a layout
- [ ] `redirect()` targets use `reverse()` or named URLs (not hardcoded paths)
- [ ] No stub views (returning empty HttpResponse or pass-only functions)

### 4. URL Routing Audit
For EVERY `urls.py` (app-level and project-level):
- [ ] Every view imported is used in `urlpatterns`
- [ ] Every `urlpatterns` entry references an existing view
- [ ] App URLs included in `app/urls.py` with proper namespace
- [ ] No duplicate URL patterns (same path, different views)
- [ ] Named URL patterns are unique across the project

### 5. Signal & Event Audit
For EVERY app:
- [ ] If `signals.py` exists, `apps.py` has `ready()` importing it
- [ ] No duplicate `@receiver` connections
- [ ] Signal handlers don't import cross-app models directly (use EventBus)
- [ ] EventBus subscriptions are registered in `apps.py` ready()
- [ ] No orphaned signal files (exist but never imported)

### 6. Celery Task Audit
For EVERY `tasks.py`:
- [ ] All tasks are decorated with `@shared_task` or `@app.task`
- [ ] Task names are unique
- [ ] Tasks don't do direct cross-app model imports in function body (use lazy imports)
- [ ] Retry logic configured for external calls
- [ ] No infinite retry loops

### 7. Middleware Audit
- [ ] All middleware in `MIDDLEWARE` setting exists and is importable
- [ ] Middleware ordering is correct (SecurityMiddleware first, etc.)
- [ ] Custom middleware has proper `__init__` and `__call__`/`process_request`/`process_response`
- [ ] No middleware importing from dissolved apps

### 8. Context Processor Audit
- [ ] All context processors in `TEMPLATES` setting exist and are importable
- [ ] Context processors don't do expensive queries (N+1 on every request)
- [ ] No duplicate context variable names across processors

### 9. Cross-App Dependency Audit
- [ ] models.py/services.py do NOT import from other apps (except core, site_settings, AUTH_USER_MODEL)
- [ ] views.py CAN import from multiple apps (orchestrator role)
- [ ] apps/admin/ CAN import from all apps (admin role)
- [ ] No circular imports (A imports B imports A)
- [ ] Cross-app communication uses EventBus or Django signals
- [ ] No model inheritance across app boundaries (except abstract bases in core)

### 10. Template Integrity Audit
For EVERY template file:
- [ ] `{% extends %}` target exists
- [ ] `{% include %}` targets exist
- [ ] `{% url %}` tags reference valid URL names
- [ ] No orphaned templates (exist but no view renders them)
- [ ] HTMX fragments don't use `{% extends %}`
- [ ] Admin templates extend `layouts/admin.html`
- [ ] Public templates extend `layouts/default.html`
- [ ] Error templates extend `layouts/minimal.html`
- [ ] All `x-show`/`x-if` elements have `x-cloak`

### 11. Static Asset Audit
- [ ] Every `{% static %}` reference points to a file that exists
- [ ] No orphaned static files (exist but never referenced)
- [ ] Vendor libraries in `static/vendor/` match CDN fallback versions
- [ ] SCSS imports all resolve
- [ ] No duplicate CSS class definitions

### 12. Alpine.js Audit
- [ ] `x-data` components have valid JSON/JavaScript object
- [ ] `x-show` elements have `x-cloak`
- [ ] No `x-show` + CSS `animate-*` conflicts
- [ ] `@click`/`@submit` handlers reference defined methods
- [ ] Alpine stores accessed via `$store` are defined
- [ ] `x-bind`/`:class` expressions are syntactically valid

### 13. HTMX Audit
- [ ] `hx-get`/`hx-post` URLs resolve to valid endpoints
- [ ] `hx-target` references match existing DOM element IDs
- [ ] `hx-post` has CSRF token handling
- [ ] Fragment responses don't include `<html>`/`<head>`/`<body>` tags
- [ ] `hx-swap` values are valid (innerHTML, outerHTML, beforeend, etc.)
- [ ] No `hx-boost` usage (prohibited in this project)

### 14. CSS/Tailwind Audit
- [ ] Theme variables used correctly (`--color-*` tokens, not hardcoded colors)
- [ ] `--color-accent-text` not assumed to be white (BLACK in contrast theme)
- [ ] No inline `<style>` blocks (except `[x-cloak]` in head)
- [ ] Responsive breakpoints cover mobile/tablet/desktop
- [ ] Dark/light/contrast themes all render correctly

### 15. Security Audit
- [ ] No hardcoded secrets/API keys/tokens in source
- [ ] All mutating endpoints have CSRF protection
- [ ] `@login_required` on all authenticated views
- [ ] Admin views check `is_staff` (not just `is_authenticated`)
- [ ] File uploads validated (MIME, extension, size)
- [ ] No raw SQL — ORM only
- [ ] HTML content sanitized with `nh3` (not bleach)
- [ ] `select_for_update()` on wallet transactions

### 16. Service Layer Audit
For EVERY `services.py`:
- [ ] Business logic in services (not views)
- [ ] `@transaction.atomic` on multi-model operations
- [ ] No cross-app model imports (use events/signals)
- [ ] Error handling doesn't swallow exceptions silently
- [ ] Return types annotated

### 17. Import & Dependency Health
- [ ] Every import resolves (no `ModuleNotFoundError`)
- [ ] Every `requirements.txt` entry is used
- [ ] No unused imports in source files
- [ ] `pip check` passes
- [ ] Type stubs installed for all typed dependencies

---

## Execution Strategy

### Phase 1: Automated Static Analysis (Machine-Readable)
```powershell
# Lint
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .

# Django checks
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
& .\.venv\Scripts\python.exe manage.py check --deploy --settings=app.settings_production

# Type checking
& .\.venv\Scripts\python.exe -m pyright apps/

# Security scan
& .\.venv\Scripts\python.exe -m bandit -r apps/ -ll -ii --exclude "*/tests*,*/migrations/*"

# Dependency health
& .\.venv\Scripts\pip.exe check

# VS Code errors
# get_errors() → must be zero
```

### Phase 2: Parallel Agent Audit (6 Agents)
Deploy 6 parallel subagents, each reading FULL files (not targeted):

| Agent | Scope | What It Reads |
|-------|-------|---------------|
| Agent 1 | Backend Core | core, consent, site_settings, users, user_profile — ALL .py files |
| Agent 2 | Content Apps | blog, comments, pages, tags, forum, distribution — ALL .py files |
| Agent 3 | Commerce Apps | shop, wallet, marketplace, bounty, referral, gamification — ALL .py files |
| Agent 4 | Platform Apps | firmwares, devices, security, storage, backup, ai, analytics — ALL .py files |
| Agent 5 | Infrastructure | admin, ads, seo, notifications, moderation, changelog, api, i18n — ALL .py files |
| Agent 6 | Frontend | ALL templates, ALL static files, ALL SCSS, ALL JS |

### Phase 3: Cross-Reference Validation
After individual audits, validate:
- Template references from views actually exist
- URL names used in templates are defined
- Signal handlers connect to signals that are emitted
- Context processor variables are used in templates
- Admin sidebar links point to valid URLs

### Phase 4: Browser Validation (if dev server running)
- Load each page URL in browser
- Capture console errors (JS, CSS, 404s)
- Validate Alpine.js initialization
- Validate HTMX endpoints respond correctly
- Check responsive breakpoints

### Phase 5: Recursive Fix Loop
```
while issues_found:
    fix_all_issues()
    run_full_audit()
    issues_found = check_for_new_issues()
```

---

## Output Format

Each audit dimension produces a findings list:

```
## [Dimension Name] Audit — [App Name]

### PASS ✅
- Model X: all checks pass
- View Y: template exists, URL wired

### FAIL ❌
- Model Z: missing `related_name` on FK `user` (line 45)
- View W: references `template.html` that does not exist
- Signal S: `apps.py` missing `ready()` import

### WARN ⚠️
- Service Q: no `@transaction.atomic` on multi-model operation
- Template T: `x-show` without `x-cloak`
```
