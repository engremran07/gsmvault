# Copilot Instructions

> Quick-reference card for AI agents. Full details in [`AGENTS.md`](../AGENTS.md).

## Identity

Enterprise-grade Django 5.2 firmware distribution platform. Django-served frontend (Tailwind CSS v4 + Alpine.js v3 + HTMX v2 + Lucide Icons) + DRF API. PostgreSQL 17, Celery + Redis.

## Environment

- **Python**: 3.12+ — venv at `.venv` (NOT `venv`)
- **Django**: 5.2 — dev settings: `app.settings_dev`, prod: `app.settings_production`
- **Database**: PostgreSQL 17 — `appdb` on localhost:5432
- **OS**: Windows — use PowerShell (`;` not `&&`)

## Quality Gate — MANDATORY

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

**Zero tolerance**: no lint warnings, no type errors, no Django check issues, no VS Code Problems tab errors.

## Architecture at a Glance

- 31 Django apps in `apps/` — all consolidated, zero dissolved stubs
- `apps.core` = Enterprise infrastructure layer (NOT a shim — only `models.py` re-exports)
- `apps.consent` = Privacy enforcement layer (models.py is shim, rest is active code)
- `apps.forum` = Full community forum (4PDA/vBulletin/Discourse) — self-contained with services layer
- `apps.ads` = Autonomous ads management (18+ models, rotation/targeting engines, rewarded ads, affiliate pipeline, AI optimizer)
- `apps.seo` = Full SEO engine (metadata, sitemaps, JSON-LD, redirects, internal linking, AI automation, 7 admin toggles)
- WAF rate limiting (`apps.security`) ≠ Download quotas (`apps.firmwares` + `apps.devices`)
- 23 reusable components in `templates/components/` — always use them, never inline
- 3 themes via CSS custom properties: `dark` (default), `light`, `contrast`
- Multi-CDN fallback: jsDelivr → cdnjs → unpkg → local vendor

## Code Style Essentials

- Full type hints on all public APIs (Pyright authoritative, mypy secondary)
- `ModelAdmin` typed: `class MyAdmin(admin.ModelAdmin[MyModel]):`
- Never blanket `# type: ignore` — always specify: `[attr-defined]`, `[import-untyped]`, etc.
- `related_name` on every FK/M2M
- Business logic in `services.py` — views stay thin
- No raw SQL — Django ORM exclusively
- Django reverse FK managers → `# type: ignore[attr-defined]`
- For cross-app communication: use `apps.core.events.EventBus` or Django signals

## Critical Gotchas

1. `--color-accent-text` is WHITE in dark/light but BLACK in contrast — use the token, never hardcode
2. Alpine.js `x-show` + CSS animations conflict → remove animation classes on `x-show` elements
3. All `x-show`/`x-if` elements need `x-cloak` to prevent FOUC
4. HTMX fragments must NOT use `{% extends %}` — they are standalone snippets
5. Scraped data never auto-inserts — always goes through `IngestionJob` → admin approval
6. Dissolved apps fully removed — never reference their names in imports
7. Dissolved models keep `db_table = "original_app_tablename"` in Meta
8. Always `select_for_update()` on wallet transactions
9. Views CAN import from multiple apps (they are orchestrators); models/services must NOT cross boundaries
10. `apps/admin/` is the ONLY app allowed to import models from ALL other apps
11. Consent form views NEVER return JSON — always `HttpResponseRedirect` to `HTTP_REFERER`. Cookie set on redirect. For JSON API, use `consent/api/status/` and `consent/api/update/` (separate DRF endpoints). See `apps/consent/views.py` `_consent_done()`.
12. `requirements.txt` is the single source of truth — every `pip install` must update it, every entry must be used, check `Required-by:` before removing
13. Every new feature/app MUST be documented in `README.md`, `AGENTS.md`, and this file before the task is considered complete

## Key References

| Document | Purpose |
| --- | --- |
| [`AGENTS.md`](../AGENTS.md) | Full architecture, conventions, quality gate, code style |
| [`MASTER_PLAN.md`](../MASTER_PLAN.md) | Strategy, agent/skill architecture, implementation phases |
| [`CONTRIBUTING.md`](../CONTRIBUTING.md) | Developer workflow, commit format, PR process |
| [`README.md`](../README.md) | Public project documentation |

