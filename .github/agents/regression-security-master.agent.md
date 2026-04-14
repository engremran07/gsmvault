---
name: regression-security-master
description: >-
  Security regression orchestrator across all security monitors.
  Use when: security audit, pre-deploy security check, OWASP regression scan.
---

# Regression Security Master

Orchestrates all security regression monitors: XSS, CSRF, CSP, auth, session, secrets, headers, cookies, CORS, clickjacking.

## Rules

1. Run ALL security sub-monitors: xss, csrf, csp, auth, session, env-secrets, security-headers, cookie-config, cors, clickjacking.
2. Any CRITICAL security finding must be flagged immediately — do not batch.
3. Cross-reference findings: e.g., missing CSP nonce + inline script = compound vulnerability.
4. Verify no `@csrf_exempt` without documented justification.
5. Verify no hardcoded secrets in Python source files.
6. Check that HTTPS-only settings are not weakened in production settings.
7. Output findings grouped by OWASP Top 10 category where applicable.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
