---
agent: 'agent'
description: 'Run pre-deployment safety checks including Django deploy check, HTTPS, secure cookies, and static files'
tools: ['read_file', 'grep_search', 'file_search', 'run_in_terminal', 'get_errors']
---

# Pre-Deployment Safety Checklist

Run all pre-deployment safety checks before pushing to production. Every check must pass.

## 1 — Django Deploy Check

Run the Django deployment check:
```powershell
& .\.venv\Scripts\python.exe manage.py check --deploy --settings=app.settings_production
```

This checks for common deployment issues including:
- `SECURE_HSTS_SECONDS` not set
- `SECURE_SSL_REDIRECT` not enabled
- `SESSION_COOKIE_SECURE` not set
- `CSRF_COOKIE_SECURE` not set
- `DEBUG` still True

All warnings must be resolved.

## 2 — HTTPS Settings

Read `app/settings_production.py` and verify:
```python
SECURE_SSL_REDIRECT = True
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
```

## 3 — HSTS Configuration

Verify HTTP Strict Transport Security:
```python
SECURE_HSTS_SECONDS = 31536000  # 1 year minimum
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
```

## 4 — Secure Cookies

Verify all cookie settings in production:
```python
SESSION_COOKIE_SECURE = True
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = "Lax"
CSRF_COOKIE_SECURE = True
CSRF_COOKIE_HTTPONLY = True
```

## 5 — CSRF Trusted Origins

Verify `CSRF_TRUSTED_ORIGINS` is explicitly set with the production domain(s):
```python
CSRF_TRUSTED_ORIGINS = [
    "https://yourdomain.com",
    "https://www.yourdomain.com",
]
```

Must NOT be empty or overly permissive.

## 6 — ALLOWED_HOSTS

Verify `ALLOWED_HOSTS` is explicitly set:
```python
ALLOWED_HOSTS = ["yourdomain.com", "www.yourdomain.com"]
```

Must NOT be `["*"]` in production.

## 7 — Static Files

### Collection
Verify static files are collected:
```powershell
& .\.venv\Scripts\python.exe manage.py collectstatic --noinput --settings=app.settings_production
```

### Serving
Verify WhiteNoise is configured for static file serving:
- `whitenoise.middleware.WhiteNoiseMiddleware` in MIDDLEWARE (position 2, after SecurityMiddleware)
- `STATICFILES_STORAGE` set to compressed manifest storage

### CDN Versions
Verify all CDN library versions are pinned in `templates/base/base.html`:
- Tailwind CSS v4
- Alpine.js v3
- HTMX v2
- Lucide Icons v0.460+

## 8 — Migrations Applied

Verify all migrations are applied:
```powershell
& .\.venv\Scripts\python.exe manage.py showmigrations --settings=app.settings_production 2>&1 | Select-String "\[ \]"
```

Any unapplied migrations (`[ ]`) must be resolved before deployment.

## 9 — Debug Mode

Verify `DEBUG = False` in production settings:
```powershell
& .\.venv\Scripts\python.exe -c "from app.settings_production import DEBUG; print(f'DEBUG={DEBUG}')"
```

If DEBUG is True, deployment is BLOCKED.

## 10 — No Test Credentials

Grep production settings and `.env.production` for test/demo credentials:
```
password, secret, test_, demo_, 12345, admin123, changeme, 
placeholder, TODO, FIXME, HACK, XXX
```

Any match is a CRITICAL security finding.

## 11 — SECRET_KEY

Verify `SECRET_KEY` loads from environment variable, not hardcoded:
```python
SECRET_KEY = os.environ.get("DJANGO_SECRET_KEY")  # or config("SECRET_KEY")
```

Check it's not the Django default or a short/weak key.

## 12 — Database Configuration

Verify production database settings:
- `ENGINE` set to PostgreSQL (not SQLite)
- Credentials from environment variables
- `CONN_MAX_AGE` set for connection pooling
- SSL connection if remote database

## 13 — Logging Configuration

Verify production logging:
- Error-level logging to file or monitoring service
- No DEBUG-level logging in production
- No sensitive data in log format strings
- Sentry or equivalent error tracking configured

## 14 — Email Configuration

Verify production email backend:
- Not `django.core.mail.backends.console.EmailBackend`
- SMTP or transactional email service configured
- `DEFAULT_FROM_EMAIL` set to production address
- Email sending tested

## 15 — Celery Configuration

Verify Celery production settings:
- Broker URL points to production Redis
- Result backend configured
- Task timeouts set (`task_time_limit`, `task_soft_time_limit`)
- Worker concurrency appropriate for server resources
- Beat schedule configured for periodic tasks

## Report

```
╔════════════════════════════════════════════╗
║       PRE-DEPLOYMENT CHECKLIST             ║
╠════════════════════════════════════════════╣
║  1. Django Deploy Check    [✅/❌/⚠️]     ║
║  2. HTTPS Settings         [✅/❌]         ║
║  3. HSTS Configuration     [✅/❌]         ║
║  4. Secure Cookies         [✅/❌]         ║
║  5. CSRF Trusted Origins   [✅/❌]         ║
║  6. ALLOWED_HOSTS          [✅/❌]         ║
║  7. Static Files           [✅/❌]         ║
║  8. Migrations Applied     [✅/❌]         ║
║  9. Debug Mode Off         [✅/❌]         ║
║ 10. No Test Credentials    [✅/❌]         ║
║ 11. SECRET_KEY Secure      [✅/❌]         ║
║ 12. Database Configuration [✅/❌]         ║
║ 13. Logging Configuration  [✅/❌]         ║
║ 14. Email Configuration    [✅/❌]         ║
║ 15. Celery Configuration   [✅/❌]         ║
╠════════════════════════════════════════════╣
║  DEPLOY STATUS: READY / BLOCKED            ║
╚════════════════════════════════════════════╝
```

If any check fails, deployment must be blocked until resolved.
