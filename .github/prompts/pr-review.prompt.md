---
agent: 'agent'
description: 'Review a pull request: lint, types, tests, docs, migrations, breaking changes, security implications across all changed files.'
tools: ['semantic_search', 'read_file', 'grep_search', 'list_dir', 'file_search', 'run_in_terminal']
---

# PR Review

Perform a comprehensive pull request review. The user will provide a branch name, commit range, or list of changed files.

## Step 1 — Gather Changed Files

1. Get the diff: run `git diff main...HEAD --name-only` (or the specified base branch).
2. Categorize changed files by type:
   - **Models**: `apps/*/models.py`
   - **Migrations**: `apps/*/migrations/*.py`
   - **Services**: `apps/*/services*.py`
   - **Views**: `apps/*/views*.py`
   - **Templates**: `templates/**/*.html`
   - **URLs**: `apps/*/urls.py`
   - **API**: `apps/*/api.py`
   - **Admin**: `apps/admin/views_*.py`
   - **Tests**: `apps/*/tests*.py`, `tests/**`
   - **Config**: `app/settings*.py`, `requirements.txt`, `pyproject.toml`
   - **Docs**: `README.md`, `AGENTS.md`, `.github/copilot-instructions.md`
3. Read the full diff for context: `git diff main...HEAD`.

## Step 2 — Lint Compliance

Run the quality gate on changed files:

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

Flag any remaining lint issues, format violations, or Django check warnings.

## Step 3 — Type Safety

For each changed `.py` file:

- All new public functions have complete type hints.
- `ModelAdmin` classes are typed: `admin.ModelAdmin[MyModel]`.
- No new blanket `# type: ignore` — always specify error code.
- Return types annotated on `get_queryset()`, service functions, view helpers.

## Step 4 — Test Coverage

- Check if new code has corresponding tests.
- If models were added/changed: model tests exist?
- If services were added/changed: service tests exist?
- If views were added/changed: view tests (auth, permissions, HTMX) exist?
- If API endpoints were added/changed: API tests exist?
- Run existing tests to verify they pass: `pytest apps/<changed_app>/`.

## Step 5 — Migration Safety

If migration files are included:

- [ ] Migration is auto-generated (not hand-edited).
- [ ] No `RunSQL` with raw SQL (forbidden — use ORM).
- [ ] `RunPython` functions are reversible (include `reverse_code`).
- [ ] No destructive operations without data migration: dropping columns, removing tables.
- [ ] Dissolved models retain `db_table = "original_app_tablename"` in Meta.
- [ ] Migration dependencies are correct (no cross-app dependency cycles).

## Step 6 — Breaking Changes

Check for backward-incompatible changes:

- API response format changes (missing fields, renamed fields).
- URL pattern changes (renamed, removed paths).
- Model field removals or renames without data migration.
- Changed function signatures in services (callers will break).
- Removed template blocks or context variables.
- Changed `settings.py` keys that affect other modules.

## Step 7 — Documentation Updates

If the PR adds features, models, or apps:

- [ ] `README.md` updated with feature description.
- [ ] `AGENTS.md` updated with new models/services/architecture.
- [ ] `.github/copilot-instructions.md` updated with relevant notes.
- [ ] Inline docstrings added to new public APIs.

## Step 8 — Security Implications

- [ ] No new `@csrf_exempt` without clear justification.
- [ ] No `|safe` in templates without prior sanitization.
- [ ] No hardcoded secrets or credentials.
- [ ] Auth checks on all new views accessing user data.
- [ ] File uploads validated (MIME, size, extension).
- [ ] SQL injection safe (ORM only, no raw SQL).
- [ ] XSS safe (nh3 sanitization on user HTML input).

## Step 9 — Output the Review

```markdown
## PR Review: [Branch/Title]

### Files Changed: X

### ✅ Approved Items
- [List of things that look good]

### 🔴 Blockers (must fix)
- [Critical issues preventing merge]

### 🟠 Requested Changes
- [Issues that should be addressed]

### 🟡 Suggestions
- [Non-blocking improvements]

### Checklist
- [ ] Lint clean
- [ ] Types correct
- [ ] Tests pass
- [ ] Tests cover new code
- [ ] Migrations safe
- [ ] No breaking changes
- [ ] Docs updated
- [ ] Security reviewed

### Verdict: APPROVE / REQUEST CHANGES / BLOCK
```
