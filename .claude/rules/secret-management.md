---
paths: ["app/settings*.py", ".env*"]
---

# Secret Management

All secrets, credentials, and API keys MUST be managed through environment variables. Hardcoded secrets in source code are a critical vulnerability — any commit containing secrets requires immediate rotation.

## Environment Variable Pattern

- ALL secrets MUST be loaded via `os.environ.get()` or `os.environ[]` in settings files — NEVER hardcode values.
- `.env` files provide secrets locally — they MUST be in `.gitignore` and NEVER committed.
- `.env.sample` (or `.env.example`) MUST exist with placeholder/sentinel values (e.g., `SECRET_KEY=change-me-in-production`) — NEVER real credentials.
- Use `python-dotenv` or `django-environ` to load `.env` files in development settings.
- Production: secrets injected via deployment environment (container env vars, secret manager, etc.).

## Secret Categories

- **Django `SECRET_KEY`** — MUST be unique per environment (dev, staging, production). Minimum 50 characters, cryptographically random.
- **Database credentials** — via `DATABASE_URL` environment variable. NEVER in settings files.
- **Redis/Celery broker** — via `REDIS_URL` or `CELERY_BROKER_URL` env var.
- **JWT signing key** — separate from Django `SECRET_KEY`. Rotated independently.
- **API keys** (AI providers, email services, CDN, ad networks) — individual env vars per service.
- **Service account JSON** — stored in `storage_credentials/` directory (gitignored). NEVER in the repo.
- **OAuth client secrets** (allauth social auth) — via env vars, NEVER in settings or admin fixtures.

## Logging Safety

- NEVER log passwords, tokens, API keys, or full request bodies that may contain credentials.
- Mask secrets in logs: show only first/last 4 characters (e.g., `sk-abc...xyz`).
- NEVER include secrets in error messages returned to users.
- NEVER include secrets in Django admin change lists or detail views — use `***` masking in display.
- Celery task arguments containing secrets MUST be excluded from result backends and flower monitoring.

## Rotation and Incident Response

- On suspected exposure: rotate the secret IMMEDIATELY — NEVER just invalidate without replacement.
- Rotation checklist: 1) generate new secret → 2) deploy new secret → 3) verify functionality → 4) revoke old secret.
- `SECRET_KEY` rotation invalidates all sessions — plan for user re-authentication.
- JWT key rotation: support key ID (`kid`) header for graceful rollover.
- Document rotation procedures for each secret type in the operations runbook.

## Git Safety

- Pre-commit hooks SHOULD scan for high-entropy strings and known secret patterns.
- If a secret is accidentally committed: 1) rotate immediately, 2) use `git filter-branch` or BFG to remove from history, 3) force-push (with team coordination).
- NEVER assume a secret is safe because the repo is private — treat all secrets as potentially exposed.
- Review `.gitignore` entries: `.env`, `*.pem`, `*.key`, `id_rsa*`, `storage_credentials/` MUST all be ignored.
