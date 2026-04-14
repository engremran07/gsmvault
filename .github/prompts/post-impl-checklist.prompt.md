---
agent: 'agent'
description: 'Run the 22-gate post-implementation checklist to verify code quality before commit'
tools: ['semantic_search', 'read_file', 'grep_search', 'list_dir', 'file_search', 'run_in_terminal', 'get_errors', 'get_changed_files']
---

# 22-Gate Post-Implementation Checklist

Run every gate against the current workspace. Each gate produces PASS ✅ or FAIL ❌ with details. All 22 gates must pass before code is considered commit-ready.

## Gate Execution

First, identify changed files using `get_changed_files` to focus the audit on what was modified.

### Gate 1 — Ruff Lint
Run `& .\.venv\Scripts\python.exe -m ruff check . --fix` and verify zero issues remain. Report any unfixable errors.

### Gate 2 — Ruff Format
Run `& .\.venv\Scripts\python.exe -m ruff format .` and verify no files were reformatted. If files changed, they were not formatted before.

### Gate 3 — Django System Check
Run `& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev` and verify output is `System check identified no issues (0 silenced)`.

### Gate 4 — Type Check
Check `get_errors()` for any Pylance/Pyright errors in changed files. Zero type errors allowed. Common fixes:
- `ModelAdmin` needs type parameter: `admin.ModelAdmin[MyModel]`
- Blanket `# type: ignore` forbidden — must specify error code like `[attr-defined]`
- Missing stubs → add to `requirements.txt`
- Reverse FK managers → `# type: ignore[attr-defined]`

### Gate 5 — Test Pass
Run `& .\.venv\Scripts\python.exe -m pytest --tb=short -q` for changed apps. All tests must pass.

### Gate 6 — Import Boundaries
In changed `models.py` and `services.py` files, verify no cross-app imports except:
- `apps.core.*` — allowed everywhere
- `apps.site_settings.*` — allowed everywhere
- `settings.AUTH_USER_MODEL` — allowed everywhere
- `apps.consent` decorators/middleware — allowed everywhere
- `apps/admin/` — allowed to import from all apps

### Gate 7 — Model Meta Completeness
Every model in changed files must have `class Meta` with:
- `verbose_name` and `verbose_name_plural`
- `ordering`
- `db_table`
- `__str__` method on the model class

### Gate 8 — related_name Coverage
Every `ForeignKey` and `ManyToManyField` in changed models must have explicit `related_name`.

### Gate 9 — Admin Registration
Every new model in changed files must have admin registration in the app's `admin.py` or in `apps/admin/`.

### Gate 10 — URL Namespaces
If `urls.py` was changed, verify `app_name` is defined. Verify all `path()` entries have `name=` parameter. Check `app/urls.py` includes use `namespace=`.

### Gate 11 — Template Extends
Changed templates (not fragments) must use `{% extends %}` from proper base template (`base/base.html`, `layouts/default.html`, etc.).

### Gate 12 — HTMX Fragment Isolation
Changed files in `templates/*/fragments/` must NOT contain `{% extends %}`. They are standalone HTML snippets.

### Gate 13 — Alpine x-cloak
In changed templates, every element with `x-show` or `x-if` must also have `x-cloak` attribute. Also verify no CSS `animate-*` class on elements with `x-show`.

### Gate 14 — CSRF Protection
Changed templates with `<form method="POST">` must include `{% csrf_token %}`. Changed views with mutating endpoints must not use `@csrf_exempt` without documented justification.

### Gate 15 — XSS Sanitization
Any changed code that stores user-supplied HTML must pass through `sanitize_html_content()` from `apps.core.sanitizers`. Changed templates using `|safe` must have sanitized source data.

### Gate 16 — Auth Checks
Changed views must have authentication/authorization:
- Public views: document why they're public
- Staff views: `@login_required` + `@user_passes_test(lambda u: u.is_staff)` or `_render_admin`
- User views: `@login_required` with ownership checks (`.get(pk=pk, user=request.user)`)
- Use `getattr(request.user, "is_staff", False)` pattern, never bare `request.user.is_staff`

### Gate 17 — select_for_update
Changed code modifying wallet balances, credit operations, or inventory must use `select_for_update()` within a transaction.

### Gate 18 — transaction.atomic
Changed service functions writing to multiple models must be wrapped in `@transaction.atomic` or `with transaction.atomic():`.

### Gate 19 — Migration Check
If models were changed, run `& .\.venv\Scripts\python.exe manage.py makemigrations --check --settings=app.settings_dev` to verify migrations are up to date. Dissolved models must keep `db_table = "original_app_tablename"`.

### Gate 20 — Documentation Updated
If a new feature or app was added, verify it is documented in:
- `README.md`
- `AGENTS.md`
- `.github/copilot-instructions.md`

### Gate 21 — Regression Registry
If a bug was fixed, check if `REGRESSION_REGISTRY.md` should be updated with a new entry describing the regression pattern, detection method, and prevention rule.

### Gate 22 — Session Log
Append a summary of changes to `SESSION_LOG.md` with:
- Date and scope of changes
- Files modified
- Key decisions made

## Final Report

```
╔══════════════════════════════════════════╗
║     POST-IMPLEMENTATION CHECKLIST        ║
╠══════════════════════════════════════════╣
║  Gate  1 — Ruff Lint           [✅/❌]  ║
║  Gate  2 — Ruff Format         [✅/❌]  ║
║  Gate  3 — Django Check        [✅/❌]  ║
║  Gate  4 — Type Check          [✅/❌]  ║
║  Gate  5 — Test Pass           [✅/❌]  ║
║  Gate  6 — Import Boundaries   [✅/❌]  ║
║  Gate  7 — Model Meta          [✅/❌]  ║
║  Gate  8 — related_name        [✅/❌]  ║
║  Gate  9 — Admin Registration  [✅/❌]  ║
║  Gate 10 — URL Namespaces      [✅/❌]  ║
║  Gate 11 — Template Extends    [✅/❌]  ║
║  Gate 12 — HTMX Fragments     [✅/❌]  ║
║  Gate 13 — Alpine x-cloak     [✅/❌]  ║
║  Gate 14 — CSRF Protection    [✅/❌]  ║
║  Gate 15 — XSS Sanitization   [✅/❌]  ║
║  Gate 16 — Auth Checks        [✅/❌]  ║
║  Gate 17 — select_for_update  [✅/❌]  ║
║  Gate 18 — transaction.atomic [✅/❌]  ║
║  Gate 19 — Migration Check    [✅/❌]  ║
║  Gate 20 — Docs Updated       [✅/❌]  ║
║  Gate 21 — Regression Registry [✅/❌]  ║
║  Gate 22 — Session Log        [✅/❌]  ║
╠══════════════════════════════════════════╣
║  PASSED: NN/22   STATUS: READY/BLOCKED  ║
╚══════════════════════════════════════════╝
```

If any gate fails, list the specific violations with file paths and line numbers, plus the exact fix required.
