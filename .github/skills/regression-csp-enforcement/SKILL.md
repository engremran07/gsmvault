---
name: regression-csp-enforcement
description: "CSP regression detection skill. Use when: checking Content Security Policy headers, verifying nonce generation, scanning for inline scripts without nonces, detecting CSP header weakening."
---

# CSP Regression Detection

## When to Use

- After editing security headers middleware
- After adding inline `<script>` tags to templates
- After modifying CSP nonce middleware
- After adding third-party scripts or CDN resources

## Guards to Verify

| File | Guard | Critical |
|------|-------|----------|
| `app/middleware/csp_nonce.py` | `secrets.token_urlsafe(16)` for nonce generation | YES |
| `apps/core/middleware/security_headers.py` | CSP header with `nonce-` directive | YES |
| Templates with `<script>` | `nonce="{{ request.csp_nonce }}"` attribute | YES |

## Procedure

1. Verify CSP nonce middleware generates cryptographically random nonces
2. Verify security headers middleware includes nonce in CSP `script-src`
3. Scan templates for inline `<script>` tags — each must have `nonce` attribute
4. Check for `unsafe-inline` in CSP — must NOT be present for scripts
5. Verify nonce is NOT cached (must be per-request)

## Red Flags

- `unsafe-inline` in `script-src` CSP directive
- Inline `<script>` without `nonce="{{ request.csp_nonce }}"`
- Nonce generated with `random` instead of `secrets`
- CSP header missing or set to report-only in production
- Nonce cached across requests (same nonce for multiple users)

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
