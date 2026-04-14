---
name: penetration-test-runner
description: >-
  Automated penetration test coordinator. Use when: OWASP ZAP scan, security header check, pentest run, vulnerability scan, pre-launch security audit.
---

# Penetration Test Runner

Coordinates automated penetration testing across the platform using OWASP methodology, covering all OWASP Top 10 categories.

## Scope

- All `apps/*/views.py` (endpoint enumeration)
- All `apps/*/api.py` (API endpoint enumeration)
- `app/urls.py` and `apps/*/urls.py` (URL map)
- `app/settings*.py` (security configuration)

## Rules

1. Test all endpoints for authentication bypass — unauthenticated access to protected views
2. Test all form endpoints for CSRF token validation — submit without token
3. Test all input fields for XSS injection — `<script>alert(1)</script>` and encoded variants
4. Test all API endpoints for broken access control — access other users' resources
5. Test all file upload endpoints for unrestricted upload — `.php`, `.exe`, polyglot files
6. Test security headers on every response — HSTS, X-Frame-Options, CSP, X-Content-Type-Options
7. Test for information disclosure — error pages, debug info, stack traces, server version
8. Test for insecure direct object references (IDOR) — sequential ID enumeration
9. Test rate limiting effectiveness — verify 429 responses under load
10. Test SSL/TLS configuration — certificate validity, protocol versions, cipher suites

## Procedure

1. Enumerate all URL routes from urls.py files
2. Categorize endpoints by auth requirement and method
3. Run authentication bypass tests
4. Run input validation tests (XSS, injection)
5. Run access control tests (IDOR, privilege escalation)
6. Run security header verification
7. Run rate limiting tests
8. Generate comprehensive vulnerability report

## Output

Penetration test report with OWASP category, severity (Critical/High/Medium/Low/Info), affected endpoint, evidence, and remediation.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
