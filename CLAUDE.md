# CLAUDE.md â€” GSMFWs Project

> Enterprise-grade Django 5.2 firmware distribution platform.
> This file is the quick-reference card. Full architecture details: @AGENTS.md

---

## Identity & Stack

- **Framework**: Django 5.2 + Django REST Framework
- **Database**: PostgreSQL 17 (`appdb` on localhost:5432)
- **Cache / Queue**: Redis + Celery
- **Frontend**: Tailwind CSS v4 + Alpine.js v3 + HTMX v2 + Lucide Icons (Django-served, zero SPA)
- **Auth**: JWT (PyJWT) + django-allauth (social auth) + MFA
- **Python**: 3.12+ â€” venv at `.venv` (NOT `venv`)

---

## Environment

- **OS**: Windows â€” PowerShell only. Use `;` **NOT** `&&` to chain commands.
- **Activate venv**: `& .\.venv\Scripts\Activate.ps1`
- **Python**: `& .\.venv\Scripts\python.exe`
- **Settings**: Dev = `app.settings_dev` | Prod = `app.settings_production`
- **Never** run with `--settings=app.settings_production` unless deploying.

---

## Quality Gate â€” MANDATORY (run before every commit)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

**Zero tolerance**: no ruff warnings, no Pylance errors (`get_errors()` clean), no Django check issues.
Pyright is authoritative for type checking; mypy is secondary.

---

## Architecture Snapshot

31 Django apps in `apps/` â€” all consolidated, zero dissolved stubs.

| App | Role |
| ----- | ------ |
| `core` | Enterprise infra: cache, AI facade, sanitization, throttling, event bus, signals. `models.py` is a re-export shim only. |
| `consent` | Privacy enforcement. `models.py` is a shim; all other files are active code. |
| `firmwares` | Firmware catalog + OEM scraper + download gating (DownloadToken, DownloadSession, AdGateLog) |
| `devices` | Device catalog + trust scoring + quota tiers |
| `ads` | Full autonomous ads: campaigns, rotation, targeting, rewarded ads, affiliate pipeline (18+ models) |
| `seo` | Full SEO engine: metadata, sitemaps, JSON-LD, redirects, internal linking, AI automation |
| `forum` | Full community forum (4PDA + vBulletin + Discourse style, 30+ models) |
| `security` | WAF rate limiting. **NOT** download quotas â€” those live in `firmwares` + `devices`. |
| `admin` | Custom admin panel â€” 8 view modules. **Only** app allowed to import from ALL others. |

### App Boundary Rules (zero tolerance)

| Allowed | Forbidden |
| --------- | ----------- |
| `apps.core.*` imported anywhere | App A's `models.py` importing App B's model |
| `apps.site_settings.*` imported anywhere | App A's `services.py` calling App B's service |
| Views importing from multiple apps | Circular imports between non-core apps |
| `apps/admin/` importing from all apps | Raw SQL or ORM queries across app boundaries in services |

Cross-app communication: use `apps.core.events.EventBus` or Django signals.

---

## Code Style

- Full type hints on ALL public APIs (Pyright authoritative)
- `ModelAdmin` typed: `class MyAdmin(admin.ModelAdmin[MyModel]):`
- `get_queryset()` must return: `def get_queryset(self) -> QuerySet[MyModel]:`
- Never blanket `# type: ignore` â€” always specify: `# type: ignore[attr-defined]`, `[import-untyped]`, etc.
- `related_name` on EVERY FK and M2M relationship
- Business logic in `services.py` â€” views stay thin (orchestrators only)
- No raw SQL â€” Django ORM exclusively
- `select_for_update()` on ALL wallet transactions
- `@transaction.atomic` on all multi-model service operations
- Django reverse FK managers â†’ `# type: ignore[attr-defined]` (Pyright limitation)
- Every model: `__str__`, `class Meta` with `verbose_name`, `verbose_name_plural`, `ordering`, `db_table`
- Every new feature MUST be documented in `README.md`, `AGENTS.md`, and `.github/copilot-instructions.md`

---

## Critical Gotchas

1. `--color-accent-text` is WHITE in dark/light themes but BLACK in contrast theme â€” use the CSS token, never hardcode `text-white` on accent backgrounds.
2. Alpine.js `x-show` + CSS `animate-*` classes conflict â†’ remove animation classes from any element with `x-show`.
3. All `x-show`/`x-if` elements **must** have `x-cloak` to prevent flash of unstyled content.
4. HTMX fragments must **NOT** use `{% extends %}` â€” they are standalone HTML snippets injected into existing pages.
5. Scraped data **never** auto-inserts â€” always goes through `IngestionJob` â†’ admin approval workflow.
6. Dissolved apps fully removed â€” **never** reference their names in imports (e.g., `crawler_guard`, `fw_scraper`).
7. Dissolved models keep `db_table = "original_app_tablename"` in Meta to preserve existing data.
8. Always `select_for_update()` on wallet transactions â€” prevents race conditions on credit balance changes.
9. Views CAN import from multiple apps (they are orchestrators). Models and services must NOT cross boundaries.
10. `apps/admin/` is the ONLY app allowed to import models from ALL other apps.
11. Consent form views (`accept_all`, `reject_all`, `accept`) NEVER return JSON â€” always `HttpResponseRedirect` to `HTTP_REFERER`. The cookie is set on the redirect response.
12. `requirements.txt` is the single source of truth â€” every `pip install` must update it; every entry must be actually used.
13. WAF rate limits (`apps.security`) â‰  Download quotas (`apps.firmwares` + `apps.devices`) â€” two completely separate systems, never conflate them.
14. `apps.core` is NOT a shim â€” it is a full enterprise infrastructure layer. Only `models.py` re-exports base models.

---

## What Never To Do

- Never `git push --force` â€” use `--force-with-lease` if you must.
- Never `rm -rf` / `Remove-Item -Recurse -Force` without explicit confirmation.
- Never edit files in `apps/*/migrations/` manually â€” always use `manage.py makemigrations`.
- Never run with `--settings=app.settings_production` during development.
- Never access `.env` files or private keys (`*.pem`, `*.key`, `id_rsa`).
- Never add blanket `# type: ignore` â€” always specify the error code.
- Never `pip install` without updating `requirements.txt`.
- Never dissolve or rename installed apps without running `manage.py check` afterwards.
- Never create versioned or alternate Python modules (`*_v2.py`, `*_new.py`, `*_backup.py`) anywhere in the repo.
- Never fork feature logic in `apps/seo`, `apps/distribution`, or `apps/ads` into parallel files — enhance existing modules and existing model data flows in place.

---

## SEO / Distribution / Ads Consolidation

- `apps/seo` is the canonical SEO domain. Add capabilities by extending current models/services/admin, not by creating alternate SEO modules.
- `apps/distribution` is the canonical social/content syndication domain. New connectors and retries must extend existing distribution models/services.
- `apps/ads` is the canonical ads and affiliate domain. New monetization features must extend existing ads models/services.
- Dissolved app references are forbidden in code and architecture changes; only target consolidated apps are valid.

---

## Multi-Agent Workflow

This project is configured for Claude Code concurrent agent teams. See `.claude/agents/` for specialist definitions.

```powershell
# Create isolated worktrees for parallel agents (no file collisions)
git worktree add ..\GSMFWs-backend feature/backend-work
git worktree add ..\GSMFWs-frontend feature/frontend-work
git worktree add ..\GSMFWs-tests feature/test-coverage
```

**Specialist agents**: `/agents` to spawn the full team, or call individual agents by name.
**Quality enforcement**: The `quality-enforcer` agent runs the full gate after every parallel session.

---

## Governance System

| Component | Location | Count |
| ----------- | ---------- | ------- |
| Rules | `.claude/rules/` | 58 |
| Hooks | `.claude/hooks/` | 36 |
| Commands | `.claude/commands/` | 50 |

Full docs: [`GOVERNANCE.md`](GOVERNANCE.md) | Audit: [`AUDIT_CHECKLIST.md`](AUDIT_CHECKLIST.md) | Deploy: [`DEPLOYMENT_CHECKLIST.md`](DEPLOYMENT_CHECKLIST.md)

---

*See @AGENTS.md for full architecture, dissolved apps reference, and detailed conventions.*
