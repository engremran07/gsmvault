---
name: quality-gate
description: "Quality gate enforcement, zero-error policy. Use when: running ruff, pylance, pyright, problems tab, lint, format, type check, Django check, zero errors, fix warnings, pre-commit, CI quality."
---

# Quality Gate

## When to Use

- Before and after ANY code change
- When VS Code Problems tab shows any issues
- When running CI/CD pipeline checks
- When fixing lint, format, or type errors
- When validating a clean repo state

## Zero Tolerance Policy

**Every task, every agent, every commit** — all checks must pass with ZERO issues.

## Commands

```powershell
# Step 1: Lint fix + format
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .

# Step 2: Django system check
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev

# Step 3: VS Code Problems tab
# Call get_errors() — must return "No errors found"

# Step 4 (optional): Type checking (Pyright is authoritative, mypy secondary)
& .\.venv\Scripts\python.exe -m pyright apps/

# Step 5 (optional): Tests
& .\.venv\Scripts\python.exe -m pytest --cov=apps --cov-report=term-missing

# Step 6 (when adding/removing packages): Dependency health
& .\.venv\Scripts\pip.exe check
# Must output "No broken requirements found"
# See .github/skills/requirements-management/SKILL.md for full audit
```

## Ruff Rules Enforced

| Code | Category |
| --- | --- |
| E | pycodestyle errors |
| W | pycodestyle warnings |
| F | pyflakes |
| I | isort (import sorting) |
| N | pep8-naming |
| UP | pyupgrade |
| B | flake8-bugbear |
| C4 | flake8-comprehensions |
| SIM | flake8-simplify |
| S | bandit (security) |
| DJ | flake8-django |
| RUF | Ruff-specific |

## Audit-on-Read Rule

**When reading ANY file for ANY task**, also audit for the following issues and fix them inline or report them:

### Model Hygiene

- [ ] Every model class has a `__str__` method returning a human-readable representation
- [ ] Every model has `class Meta` with `verbose_name`, `verbose_name_plural`, `ordering`, and `db_table`
- [ ] Every `ForeignKey` and `ManyToManyField` has an explicit `related_name`
- [ ] No model is defined in `models.py` but missing from the Django model registry (i.e., not imported or not in an installed app)

### Serializer Consistency

- [ ] Serializer `fields` tuple/list matches actual model fields — no stale or misspelled field names
- [ ] `read_only_fields` only references fields that exist on the model
- [ ] Nested serializers reference the correct related model

### URL Wiring

- [ ] Every view function/class imported in `urls.py` is actually used in `urlpatterns`
- [ ] No `urlpatterns` entry references a view that doesn't exist or was renamed
- [ ] App `urls.py` is included in the project-level `app/urls.py`

### Dependency Health (when `requirements.txt` or imports change)

- [ ] Every third-party `import` in code has a corresponding entry in `requirements.txt`
- [ ] Every entry in `requirements.txt` is actually used (imported, in INSTALLED_APPS, or CLI tool)
- [ ] No packages in `requirements.txt` that aren't installed (`pip show <pkg>` succeeds)
- [ ] `pip check` reports "No broken requirements found"
- [ ] Before removing any package, `pip show <pkg>` → `Required-by:` is empty

See `.github/skills/requirements-management/SKILL.md` for full audit checklist.

### Stub Detection

- [ ] No functions that only contain `pass` (unless abstract or protocol methods)
- [ ] No view functions returning empty `{}`, `[]`, or `HttpResponse("")` as placeholder
- [ ] No service functions that are no-ops — every defined function must have real logic or a `# TODO:` with a tracking comment

## Template Validation

When reading or editing any template or view, verify these rules:

### Template Existence

- [ ] Every `render(request, "template_name.html", ...)` references a template file that actually exists in `templates/`
- [ ] Every `template_name` attribute on class-based views points to an existing template
- [ ] HTMX fragment templates referenced in views exist in `templates/<app>/fragments/`

### Template Inheritance

- [ ] Every `{% extends "..." %}` target file exists
- [ ] Every `{% include "..." %}` target file exists
- [ ] No circular `{% extends %}` chains
- [ ] Admin templates extend `layouts/admin.html` (not `base/base.html` directly)

### HTMX Attributes

- [ ] HTMX fragments use proper `hx-*` attributes (`hx-get`, `hx-post`, `hx-target`, `hx-swap`)
- [ ] `hx-post` endpoints have CSRF token handling (`hx-headers` on `<body>` or per-element)
- [ ] `hx-target` references match existing element IDs in the DOM
- [ ] Fragment templates do NOT include `{% extends %}` — they are partial HTML only

### Template Best Practices

- [ ] No inline `<style>` blocks except the `[x-cloak]` rule in `<head>`
- [ ] No inline `onclick`/`onsubmit` handlers — use Alpine.js `@click`/`@submit` instead
- [ ] All conditional Alpine.js elements have `x-cloak` to prevent FOUC

### Backend/Frontend Synchronization

- [ ] Backend contract changes (models/services/views/api/urls) that affect UX have matching template/component updates
- [ ] Frontend behavior changes map to canonical backend contracts (no duplicated client-only business logic)
- [ ] For `apps/seo`, `apps/distribution`, and `apps/ads`, enhancements are in-place and do not create parallel "v2/new/refactor" modules

### Static Asset Governance

- [ ] New static files are avoided unless there is a proven split/performance need
- [ ] Existing static modules are extended before introducing additional files
- [ ] CSS/JS assets remain within performance budgets; oversized files are split into cohesive modules

## Model Registration Checks

When reading any app's `models.py`, `admin.py`, or `apps.py`, verify:

### Registry Verification

- [ ] Every model class defined or imported in `models.py` is discoverable by Django (exists in an installed app)
- [ ] Every model intended for admin has a corresponding `ModelAdmin` registered in `admin.py`
- [ ] `admin.site.register(Model, ModelAdmin)` or `@admin.register(Model)` exists for each model

### Tracking Models

- [ ] If the app defines tracking/audit models in a separate `tracking_models.py`, that file is imported in `models.py` or `__init__.py` so Django discovers them
- [ ] Proxy models and unmanaged models are explicitly listed in the appropriate `models.py`

### Signal Handlers

- [ ] `apps.py` has a `ready()` method that imports signal handlers: `import apps.<appname>.signals  # noqa: F401`
- [ ] Signal files use `@receiver` decorator and are not dead code
- [ ] No duplicate signal connections (signals should be imported once in `ready()`)

## Common Pylance/Pyright Fixes Reference

Quick-reference for the most frequent type-checking issues in this codebase:

### ModelAdmin Typing

```python
# WRONG — triggers Pyright "missing type argument"
class MyAdmin(admin.ModelAdmin):
    ...

# CORRECT
class MyAdmin(admin.ModelAdmin[MyModel]):
    ...
```

### QuerySet Return Types

```python
# WRONG — Pyright can't infer return type
def get_queryset(self):
    return super().get_queryset().filter(active=True)

# CORRECT
def get_queryset(self) -> QuerySet[MyModel]:
    return super().get_queryset().filter(active=True)
```

### Missing Type Stubs

```powershell
# Install stubs for common untyped packages
pip install djangorestframework-stubs django-stubs types-requests
```

### Import from Untyped Package

```python
# WRONG — blanket ignore
from solo.models import SingletonModel  # type: ignore

# CORRECT — specific error code
from solo.models import SingletonModel  # type: ignore[import-untyped]
```

### Common Attribute Access Patterns

| Pattern | Fix |
| --- | --- |
| `ModelAdmin` without type param | `admin.ModelAdmin[MyModel]` |
| `get_queryset` missing return type | Annotate `-> QuerySet[MyModel]` |
| `is_staff` on AbstractBaseUser | `getattr(request.user, "is_staff", False)` |
| Model `.id` not found | Use `.pk` instead |
| FK `_id` attribute | `# type: ignore[attr-defined]` |
| `get_*_display()` | `# type: ignore[attr-defined]` |
| `create_user` on Manager | `# type: ignore[attr-defined]` |
| `timezone.timedelta` | `from datetime import timedelta; timedelta(...)` |
| `timezone.datetime` | `import datetime; datetime.datetime` |
| Celery `.delay()` | `# type: ignore[attr-defined]` |
| `cache.lock()` | `# type: ignore[attr-defined]` |
| No stub for package | `# type: ignore[import-untyped]` |
| Forward string ref | `# type: ignore[name-defined]` |

## Common Fix Patterns

### Ruff

| Issue | Fix |
| --- | --- |
| Unused import | Remove it or add `# noqa: F401` if re-exported |
| Import order | `ruff check --select I --fix` |
| Line too long | Break line or restructure |
| f-string without placeholder | Use plain string |
| Mutable default argument | Use `None` + `if arg is None: arg = []` |

### Django Check

| Issue | Fix |
| --- | --- |
| No `related_name` | Add explicit `related_name` to FK/M2M |
| Conflicting `related_name` | Use unique `related_name` per FK |
| Missing migration | Run `makemigrations` |
| SECURITY WARNING | Review and fix setting (HSTS, SSL, etc.) |

## Markdown Lint (for .md files)

| Rule | Fix |
| --- | --- |
| MD040 | Add language to fenced code blocks |
| MD032 | Blank lines around lists |
| MD022 | Blank lines around headings |
| MD060 | Spaces in table separators: `\| --- \| --- \|` |

## Frontend Visual Checklist

Run this checklist after any template, CSS, or JavaScript change. These are the issues that cause visual bugs visible to users:

### Anti-FOUC

- [ ] `[x-cloak] { display: none !important; }` exists in `_head.html` as inline `<style>`
- [ ] Every element with `x-show` or `x-if` has `x-cloak` attribute
- [ ] Theme init script runs before body renders (in `<head>`, not `<body>`)
- [ ] No empty containers render when data is missing — wrap sections in `{% if data %}...{% endif %}`

### Template Variables

- [ ] No use of `|default` filter on variables that may be undefined (Django `string_if_invalid` makes `|default` useless in DEBUG mode)
- [ ] Use `{% now "Y" %}` for current year, hardcode placeholder text, use `{% if %}{% else %}{% endif %}` for fallbacks

### Theme Consistency (Color Drift Prevention)

- [ ] Every `--color-*` variable exists in ALL 3 themes: `_variables.scss` (dark), `_light.scss`, `_contrast.scss`
- [ ] `static/css/dist/main.css` is in sync with SCSS sources
- [ ] No hardcoded hex colors in templates — only `var(--color-*)` via Tailwind brackets
- [ ] `<body>` has `antialiased` class

### CSP & Security

- [ ] Every `<script>` tag (inline and CDN) has `nonce="{{ request.csp_nonce }}"`
- [ ] Every `<form method="post">` has `{% csrf_token %}`
- [ ] HTMX CSRF: `hx-headers='{"X-CSRFToken": "{{ csrf_token }}"}'` on `<body>` tag

### Responsive Design

- [ ] All grids use mobile-first breakpoints: `grid-cols-1 sm:grid-cols-2 lg:grid-cols-3`
- [ ] All headings use responsive text sizing: `text-2xl md:text-3xl`
- [ ] Images use responsive height: `h-40 sm:h-48`
- [ ] Pagination / tag lists have `flex-wrap`
- [ ] `<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">`

### Cross-Browser

- [ ] `<meta http-equiv="X-UA-Compatible" content="IE=edge">`
- [ ] `<meta name="color-scheme" content="dark light">`
- [ ] `<meta name="theme-color">` with both dark and light media queries
- [ ] `text-size-adjust` vendor prefixes in `main.css`
- [ ] `img { max-width: 100%; height: auto; }` in `main.css`

### Notification System

- [ ] No browser `alert()` or `confirm()` — use `$store.notify` / `$store.confirm`
- [ ] `_confirm_dialog.html` included in `_base.html`
- [ ] `_messages.html` converts Django messages to `$store.notify` toasts

## Procedure

1. Run `ruff check . --fix` and `ruff format .`
2. Run `manage.py check --settings=app.settings_dev`
3. Check VS Code Problems tab (call `get_errors()`)
4. Fix ALL issues — no exceptions
5. Repeat until zero issues across all three checks
6. When reading any file, apply **Audit-on-Read** checks and fix or flag issues
7. When touching templates, apply **Template Validation** checks
8. When touching models/admin, apply **Model Registration Checks**
9. Block completion when backend/frontend synchronization checks fail
10. Block completion when static-asset minimization and regression checks fail
