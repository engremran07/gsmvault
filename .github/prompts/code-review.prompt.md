---
agent: 'agent'
description: 'Review code changes for type hints, Django conventions, app boundaries, security, performance, and potential bugs.'
tools: ['semantic_search', 'read_file', 'grep_search', 'list_dir', 'file_search', 'run_in_terminal']
---

# Code Review

Review code changes for quality, correctness, and compliance with GSMFWs platform conventions. The user will point to specific files or a diff to review.

## Step 1 — Gather Changes

1. If specific files are mentioned, read them fully.
2. If reviewing recent changes, run `git diff` or `git diff --staged` to see the diff.
3. Identify all changed files and categorize by layer: model, service, view, template, API, task, URL, admin.

## Step 2 — Type Safety Review

For every changed Python file, check:

- [ ] All public functions have full type hints (parameters and return type).
- [ ] `ModelAdmin` uses typed generic: `class MyAdmin(admin.ModelAdmin[MyModel]):`.
- [ ] `get_queryset()` has return type: `-> QuerySet[MyModel]`.
- [ ] No blanket `# type: ignore` — must specify error code: `[attr-defined]`, `[import-untyped]`, `[union-attr]`.
- [ ] Django reverse FK managers use `# type: ignore[attr-defined]` with comment.
- [ ] `QuerySet.first()` return (`Model | None`) is properly narrowed before use.

## Step 3 — Django Convention Review

- [ ] Every model has `__str__`, `class Meta` with `verbose_name`, `verbose_name_plural`, `ordering`, `db_table`.
- [ ] Every FK and M2M field has `related_name`.
- [ ] Business logic is in `services.py`, not in views (views are thin orchestrators).
- [ ] No raw SQL — Django ORM exclusively.
- [ ] Migrations generated for model changes (`makemigrations`).
- [ ] `default_auto_field = "django.db.models.BigAutoField"` in `apps.py`.

## Step 4 — App Boundary Review

- [ ] `models.py` does NOT import from other apps (except `apps.core`, `apps.site_settings`, `AUTH_USER_MODEL`).
- [ ] `services.py` does NOT call other apps' services directly — uses `EventBus` or signals.
- [ ] No references to dissolved app names (`security_suite`, `security_events`, `crawler_guard`, `ai_behavior`, `device_registry`, `gsmarena_sync`, `fw_verification`, `fw_scraper`, `download_links`, `admin_audit`, `email_system`, `webhooks`).
- [ ] Only `apps/admin/` imports models from ALL apps (admin is the orchestrator).
- [ ] Views CAN import from multiple apps (views are orchestrators).

## Step 5 — Security Review

- [ ] User input sanitized with `apps.core.sanitizers.sanitize_html_content()` — never `bleach`.
- [ ] Auth checks present: `@login_required`, staff checks use `getattr(request.user, "is_staff", False)`.
- [ ] Ownership checks on user-specific resources: `.get(pk=pk, user=request.user)`.
- [ ] Financial operations use `select_for_update()` and `@transaction.atomic`.
- [ ] No secrets, API keys, or tokens hardcoded in source.
- [ ] CSRF protection on all mutating endpoints — no `@csrf_exempt` without justification.
- [ ] File uploads validate MIME type, extension, and size.
- [ ] No `|safe` in templates without prior sanitization.

## Step 6 — Performance Review

- [ ] List views use `select_related()` / `prefetch_related()` to avoid N+1 queries.
- [ ] No unbounded querysets (always paginate or limit).
- [ ] Heavy operations deferred to Celery tasks.
- [ ] Database indexes on frequently filtered/sorted fields.
- [ ] No expensive operations in template rendering (queries in templates).

## Step 7 — Frontend Review (if templates changed)

- [ ] Templates extend a proper base (`templates/base/base.html` or layout).
- [ ] HTMX fragments do NOT use `{% extends %}` — standalone snippets only.
- [ ] Alpine.js `x-show`/`x-if` elements have `x-cloak` to prevent FOUC.
- [ ] No animation classes on elements with `x-show` (Alpine conflict).
- [ ] Reusable components used from `templates/components/` — no inline duplicates.
- [ ] Theme-safe: uses CSS custom properties, not hardcoded colors.
- [ ] `--color-accent-text` is WHITE in dark/light but BLACK in contrast — use the token.

## Step 8 — Output Findings

Structure findings by severity:

```markdown
## Code Review Findings

### 🔴 Critical (must fix before merge)
- [Finding with file:line reference]

### 🟠 Major (should fix before merge)
- [Finding with file:line reference]

### 🟡 Minor (fix when convenient)
- [Finding with file:line reference]

### 💡 Suggestions (optional improvements)
- [Finding with file:line reference]

### ✅ Good Practices Observed
- [Positive observations]
```
