# Contributing

> Developer workflow and contribution guidelines.
> For full architecture details see [`AGENTS.md`](AGENTS.md).

---

## Prerequisites

- **Python** 3.12+ with `pip`
- **PostgreSQL** 17 — database `appdb` on `localhost:5432`
- **Redis** — for Celery task broker
- **VS Code** with Pylance, Ruff, and Django extensions
- **Git** with commit signing recommended

---

## Setup (Windows)

```powershell
# Clone the repo
git clone <repo-url> GSMFWs
cd GSMFWs

# Create virtual environment (MUST be .venv, not venv)
python -m venv .venv
& .\.venv\Scripts\Activate.ps1

# Install ALL dependencies (type stubs included in requirements.txt)
pip install -r requirements.txt

# Create .env from sample and configure DATABASE_URL
# Create PostgreSQL database "appdb" on localhost:5432

# Run migrations
& .\.venv\Scripts\python.exe manage.py migrate --settings=app.settings_dev

# Create superuser
& .\.venv\Scripts\python.exe manage.py createsuperuser --settings=app.settings_dev

# Start dev server
& .\.venv\Scripts\python.exe manage.py runserver --settings=app.settings_dev
```

## Setup (Linux / macOS)

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python manage.py migrate --settings=app.settings_dev
python manage.py runserver --settings=app.settings_dev
```

---

## Quality Gate — Zero Tolerance

Run **all three** before every commit. Zero issues allowed.

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

Also check the VS Code Problems tab — zero warnings, zero errors.

---

## Branch Naming

| Type | Pattern | Example |
| --- | --- | --- |
| Feature | `feature/<short-description>` | `feature/download-quota-ui` |
| Bug fix | `fix/<short-description>` | `fix/pyright-devices-views` |
| Refactor | `refactor/<short-description>` | `refactor/dissolve-security-suite` |
| Docs | `docs/<short-description>` | `docs/rebuild-readme` |
| Chore | `chore/<short-description>` | `chore/update-dependencies` |

---

## Commit Message Format

```text
<type>(<scope>): <short summary>

<optional body — what and why, not how>
```

**Types**: `feat`, `fix`, `refactor`, `docs`, `style`, `test`, `chore`, `perf`, `ci`

**Scopes**: app name (`firmwares`, `devices`, `admin`, `security`) or `frontend`, `infra`, `deps`

**Examples**:

```text
feat(firmwares): add HMAC token validation to download service
fix(devices): resolve 7 Pyright errors in views.py
refactor(security): dissolve security_suite into security app
docs: rebuild AGENTS.md as single source of truth
chore(deps): update Tailwind CSS to v4.1.8
```

---

## Pull Request Process

1. Create a feature branch from `main`
2. Make changes — keep PRs focused on one concern
3. Run the full quality gate (ruff + format + Django check)
4. Verify VS Code Problems tab shows zero issues
5. Write a descriptive PR title following the commit format
6. Link any related issues
7. Request review — at least one approval required
8. Squash-merge into `main`

---

## Migration Guidelines

- Always run `makemigrations` before pushing model changes
- Dissolved app models use `db_table = "original_app_tablename"` to preserve data
- Never edit migrations that have been applied to shared databases
- Test migrations on a fresh database: `migrate --run-syncdb`
- Use `select_for_update()` for any wallet/credit balance changes

---

## Testing

```powershell
# Run test suite with coverage
& .\.venv\Scripts\python.exe -m pytest --cov=apps --cov-report=term-missing

# Run specific app tests
& .\.venv\Scripts\python.exe -m pytest apps/firmwares/tests/ -v

# Type checking (Pyright is authoritative)
& .\.venv\Scripts\python.exe -m pyright apps/
```

---

## Code Style Quick Reference

| Rule | Details |
| --- | --- |
| Type hints | Required on all public APIs |
| ModelAdmin | `class MyAdmin(admin.ModelAdmin[MyModel]):` |
| `# type: ignore` | Always specify error code: `[attr-defined]`, `[import-untyped]` |
| FK/M2M | Always include `related_name` |
| Business logic | In `services.py`, not views |
| SQL | Django ORM only — no raw SQL |
| Cross-app imports | Use `EventBus` or signals, not direct imports |
| Templates | Always use reusable components from `templates/components/` |
| HTMX fragments | Standalone snippets — never `{% extends %}` |
| JSON-on-POST | Views returning `JsonResponse` for AJAX must redirect non-AJAX POST to referrer |
| Consent scopes | `functional` (required), `analytics`, `seo`, `ads` — use `consent_check(scope, request)` |

See [`AGENTS.md § Code Style`](AGENTS.md#code-style) for the full guide.

---

## Dependency Management

`requirements.txt` is the **single source of truth** for all Python dependencies. Zero drift allowed.

| Rule | Details |
| --- | --- |
| Every `pip install` | Must update `requirements.txt` immediately |
| Every entry | Must be actually used (imported, in INSTALLED_APPS, or CLI tool) |
| Before removing | Run `pip show <pkg>` — check `Required-by:` is empty |
| Version pinning | `>=min,<major_ceiling` (e.g., `Django>=5.2.9,<5.3`) |
| Type stubs | Listed in `requirements.txt`, not separate install commands |
| Never | `pip freeze > requirements.txt` — curate manually |

```powershell
# Verify dependency health
& .\.venv\Scripts\pip.exe check
```

Full details: [`.github/skills/requirements-management/SKILL.md`](.github/skills/requirements-management/SKILL.md)

---

## Security Reporting

If you discover a security vulnerability, **do not** open a public issue. Instead:

1. Email the maintainers privately
2. Include a detailed description and reproduction steps
3. Allow reasonable time for a fix before disclosure
