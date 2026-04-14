---
agent: 'agent'
description: 'Analyze target code for complexity, duplication, boundary violations, and dead code. Output a prioritized refactor plan.'
tools: ['semantic_search', 'read_file', 'grep_search', 'list_dir', 'file_search', 'run_in_terminal']
---

# Refactor Plan

Analyze the target code and produce a prioritized refactoring plan. The user will specify a file, app, or module to analyze.

## Step 1 — Scope Discovery

1. Identify the target (file, app directory, or module) from the user's request.
2. Read the target files fully. If an app is specified, read `models.py`, `views.py`, `services.py`, `urls.py`, `admin.py`, and `api.py`.
3. List all files in the target directory to understand the full scope.

## Step 2 — Complexity Analysis

Check each file for:

- **God files**: Any `.py` file exceeding 500 lines. Flag with exact line count.
- **God functions**: Any function exceeding 50 lines. Flag with function name and line range.
- **God classes**: Any class exceeding 200 lines. Flag with class name and line range.
- **Cyclomatic complexity**: Functions with deeply nested `if/for/try` (3+ levels deep).
- **Too many parameters**: Functions with 6+ positional parameters.

## Step 3 — Duplication Detection

Search for duplicated patterns:

- Grep for identical or near-identical code blocks across the target and related files.
- Check for duplicated model field patterns (e.g., multiple models with same set of fields that should use an abstract base).
- Check for duplicated queryset filtering logic that should be in a custom Manager.
- Check for inline HTML in templates that duplicates a component from `templates/components/` (23 reusable components exist — `_card.html`, `_modal.html`, `_alert.html`, `_pagination.html`, `_admin_kpi_card.html`, etc.).
- Check for duplicated sanitization logic — all HTML sanitization must use `apps.core.sanitizers.sanitize_html_content()` (nh3-based).

## Step 4 — App Boundary Violations

Scan for forbidden cross-app imports:

- In `models.py` or `services.py`: any import from another app's models (except `apps.core`, `apps.site_settings`, `settings.AUTH_USER_MODEL`).
- Direct service-to-service imports between apps — should use `apps.core.events.EventBus` or Django signals instead.
- References to dissolved app names: `security_suite`, `security_events`, `crawler_guard`, `ai_behavior`, `device_registry`, `gsmarena_sync`, `fw_verification`, `fw_scraper`, `download_links`, `admin_audit`, `email_system`, `webhooks`.
- Circular imports between apps.

## Step 5 — Dead Code Detection

Identify unused code:

- Functions/classes defined but never called (grep for usage across the codebase).
- Unused imports (ruff should catch these, but verify).
- Commented-out code blocks longer than 5 lines.
- Template files in app template directories not referenced by any view.
- URL patterns pointing to views that don't exist.
- Models not registered in admin (check `admin.py` or `apps/admin/` view modules).

## Step 6 — Type Safety Issues

Check for:

- Missing type hints on public function signatures.
- Blanket `# type: ignore` without error code (must be `# type: ignore[attr-defined]`, etc.).
- `ModelAdmin` without type parameter (must be `admin.ModelAdmin[MyModel]`).
- Missing `related_name` on FK/M2M fields.
- `get_queryset()` without return type annotation.

## Step 7 — Output the Plan

Generate a markdown table with columns:

| Priority | Category | File | Issue | Suggested Fix | Effort |
|----------|----------|------|-------|---------------|--------|

Priority levels:
- **P0 — Critical**: Security issues, boundary violations, broken imports
- **P1 — High**: God files, dead code, missing type safety
- **P2 — Medium**: Duplication, complexity, missing tests
- **P3 — Low**: Style improvements, minor refactors

Group by priority. Include exact file paths relative to project root. Estimate effort as S/M/L.
