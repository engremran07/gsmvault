# Deployment Checklist â€” Pre-Deploy Verification

Run this checklist before deploying to staging or production. Every critical
item must pass. Warnings should be reviewed and resolved where possible.

---

## Pre-Flight Checks

### Django Settings

- [ ] `DEBUG = False` in production settings
- [ ] `ALLOWED_HOSTS` configured with production domain(s)
- [ ] `CSRF_TRUSTED_ORIGINS` set for production domain(s)
- [ ] `SECRET_KEY` loaded from environment variable (not in source code)
- [ ] `SECURE_SSL_REDIRECT = True`
- [ ] `SECURE_HSTS_SECONDS` set (minimum 31536000 = 1 year)
- [ ] `SECURE_HSTS_INCLUDE_SUBDOMAINS = True`
- [ ] `SECURE_HSTS_PRELOAD = True`
- [ ] `X_FRAME_OPTIONS = "DENY"`
- [ ] `SECURE_CONTENT_TYPE_NOSNIFF = True`
- [ ] `SESSION_COOKIE_SECURE = True`
- [ ] `CSRF_COOKIE_SECURE = True`
- [ ] `SESSION_COOKIE_HTTPONLY = True`
- [ ] `SECURE_BROWSER_XSS_FILTER = True` (legacy but harmless)

### CSP Headers

- [ ] Content-Security-Policy header configured
- [ ] CSP nonce generated per request (via `csp_nonce` middleware)
- [ ] `script-src` uses nonce, not `unsafe-inline`
- [ ] `style-src` allows Tailwind CDN and local styles
- [ ] CSP report-uri configured for violation monitoring

### Environment Variables

- [ ] `DATABASE_URL` configured for production PostgreSQL
- [ ] `REDIS_URL` configured for production Redis
- [ ] `SECRET_KEY` is a strong random value (50+ characters)
- [ ] `DJANGO_SETTINGS_MODULE=app.settings_production`
- [ ] All API keys (AI, storage, email) loaded from environment
- [ ] No `.env` file committed to repository

---

## Database

### Migrations

- [ ] All migrations applied: `manage.py migrate --check` returns clean
- [ ] No pending migrations: `manage.py makemigrations --check --dry-run`
- [ ] Migration files committed to repository
- [ ] Dissolved model migrations preserve `db_table` values

### Backup

- [ ] Database backup taken before deployment
- [ ] Backup verified: can restore to a test instance
- [ ] Backup retention policy configured (7 days minimum)
- [ ] Point-in-time recovery enabled (if supported by hosting)

### Data Integrity

- [ ] No orphaned records in critical tables
- [ ] Foreign key constraints intact
- [ ] `manage.py check --deploy --settings=app.settings_production` passes

---

## Static Files

### Collection

- [ ] `manage.py collectstatic --noinput` completed successfully
- [ ] WhiteNoise configured for static file serving
- [ ] `STATICFILES_STORAGE` set to compressed manifest storage
- [ ] Static file hash manifest generated

### CDN & Fallbacks

- [ ] Primary CDN (jsDelivr) accessible
- [ ] Fallback chain tested: jsDelivr â†’ cdnjs â†’ unpkg â†’ local vendor
- [ ] Local vendor copies present in `static/vendor/`
- [ ] Tailwind CSS compiled: `static/css/dist/main.css` exists
- [ ] All three themes render correctly (dark, light, contrast)

---

## Dependencies

### Package Integrity

- [ ] `pip check` passes (no broken dependency chains)
- [ ] `requirements.txt` matches installed packages
- [ ] No known CVEs in dependencies (`pip-audit` or `safety check`)
- [ ] All type stubs installed (`django-stubs`, `djangorestframework-stubs`, `types-requests`)

### Version Locks

- [ ] All packages pinned with version ranges in `requirements.txt`
- [ ] No bare package names without versions
- [ ] Critical packages locked to patch versions (e.g., `Django>=5.2.9,<5.3`)

---

## Security

### Endpoint Protection

- [ ] No debug endpoints exposed (`/debug/`, `/__debug__/`, `/silk/`)
- [ ] Django Debug Toolbar disabled in production
- [ ] Admin panel behind authentication (`/admin/` requires `is_staff`)
- [ ] Health check endpoint (`/health/`) returns 200 without auth
- [ ] API endpoints require authentication (JWT or session)

### Rate Limiting

- [ ] WAF rate limiting active (`apps.security` middleware enabled)
- [ ] `RateLimitRule` entries configured for critical paths
- [ ] `BlockedIP` enforcement working
- [ ] Download quota system active (`QuotaTier` configured)
- [ ] API throttling configured (DRF throttle classes)

### Secrets Audit

- [ ] No secrets in source code (`grep -r "password\|secret\|api_key"`)
- [ ] No secrets in git history (`git log --all -p | grep -i "password"`)
- [ ] Storage credentials in `storage_credentials/` (gitignored)
- [ ] `.env` file in `.gitignore`

---

## Monitoring

### Logging

- [ ] Logging configured for production (file + remote)
- [ ] Log level set to `WARNING` or `ERROR` (not `DEBUG`)
- [ ] No PII in log output (passwords, tokens, emails)
- [ ] Log rotation configured

### Error Reporting

- [ ] Error reporting service configured (Sentry or equivalent)
- [ ] Unhandled exceptions captured and reported
- [ ] Error alerts configured for critical failures
- [ ] Source maps uploaded (if applicable)

### Health Checks

- [ ] `/health/` endpoint responds with 200
- [ ] Database connectivity verified in health check
- [ ] Redis connectivity verified in health check
- [ ] Celery worker status checkable

---

## Celery & Background Tasks

### Workers

- [ ] Celery workers configured and running
- [ ] Worker concurrency set appropriately for server resources
- [ ] Worker auto-restart configured (systemd, supervisor, or equivalent)
- [ ] Task timeout configured (prevent infinite hangs)

### Beat Schedule

- [ ] Celery beat running with correct schedule
- [ ] Periodic tasks verified (ad aggregation, cleanup, backups)
- [ ] Beat schedule stored in database (not code) for runtime changes
- [ ] No overlapping task executions

### Redis

- [ ] Redis server accessible from application server
- [ ] Redis memory limit configured
- [ ] Redis persistence configured (RDB or AOF)
- [ ] Redis password set (not default/empty)

---

## Rollback Plan

### Preparation

- [ ] Previous release tagged in git (`git tag v<previous>`)
- [ ] Database backup from pre-deployment available
- [ ] Rollback procedure documented and tested
- [ ] Team notified of deployment window

### Rollback Procedure

1. Stop application servers
2. Revert to previous git tag: `git checkout v<previous>`
3. Restore database backup if migrations were applied
4. Reinstall dependencies: `pip install -r requirements.txt`
5. Collect static files: `manage.py collectstatic --noinput`
6. Start application servers
7. Verify health check endpoint responds
8. Monitor error rates for 15 minutes

### Post-Deployment Verification

- [ ] Health check endpoint responds with 200
- [ ] Login flow works (regular user + admin)
- [ ] Firmware download flow works (all tiers)
- [ ] Payment/wallet operations work
- [ ] Background tasks executing (check Celery logs)
- [ ] No spike in error rates
- [ ] CDN resources loading correctly
- [ ] All three themes rendering properly

---

## Sign-Off

- [ ] Pre-flight settings — Status: [pending] — Verified By: [name] — Date: [yyyy-mm-dd]
- [ ] Database ready — Status: [pending] — Verified By: [name] — Date: [yyyy-mm-dd]
- [ ] Static files built — Status: [pending] — Verified By: [name] — Date: [yyyy-mm-dd]
- [ ] Dependencies clean — Status: [pending] — Verified By: [name] — Date: [yyyy-mm-dd]
- [ ] Security verified — Status: [pending] — Verified By: [name] — Date: [yyyy-mm-dd]
- [ ] Monitoring active — Status: [pending] — Verified By: [name] — Date: [yyyy-mm-dd]
- [ ] Celery configured — Status: [pending] — Verified By: [name] — Date: [yyyy-mm-dd]
- [ ] Rollback plan ready — Status: [pending] — Verified By: [name] — Date: [yyyy-mm-dd]
- [ ] Post-deploy verified — Status: [pending] — Verified By: [name] — Date: [yyyy-mm-dd]

---

*Last updated: 2026-04-14. Review before every production deployment.*
