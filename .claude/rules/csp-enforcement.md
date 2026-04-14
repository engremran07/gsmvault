---
paths: ["app/middleware/csp_nonce.py", "templates/base/base.html"]
---

# Content Security Policy Enforcement

CSP is the primary defence against XSS in production. Every inline script MUST use a per-request nonce. Weakening CSP directives is a critical security regression.

## Nonce Generation

- CSP nonce is generated per request in `app/middleware/csp_nonce.py` (`CspNonceMiddleware`).
- The nonce is stored on `request.csp_nonce` and available in templates.
- Nonces MUST be cryptographically random (use `secrets.token_urlsafe()` or equivalent) — NEVER use predictable values.
- A new nonce MUST be generated for every request — NEVER cache or reuse nonces across requests.

## Inline Script Rules

- ALL inline `<script>` tags MUST include `nonce="{{ request.csp_nonce }}"`.
- HTMX, Alpine.js, and Lucide initialization scripts in `base.html` MUST carry the nonce.
- NEVER use `'unsafe-inline'` in `script-src` — it defeats the purpose of CSP.
- NEVER use `'unsafe-eval'` in `script-src` — if a library requires `eval()`, find an alternative or use a worker.
- Event handler attributes (`onclick`, `onload`, etc.) are blocked by CSP — use `addEventListener()` or Alpine.js directives instead.

## CSP Header Directives

- `default-src 'self'` — fallback for all resource types.
- `script-src 'self' 'nonce-{nonce}'` plus whitelisted CDN domains (jsDelivr, cdnjs, unpkg for the multi-CDN fallback chain).
- `style-src 'self' 'unsafe-inline'` — allowed because Tailwind CSS v4 generates inline styles. This is an accepted trade-off.
- `img-src 'self' data: https:` — allow data URIs for inline images and HTTPS sources for CDN/external images.
- `connect-src 'self'` plus whitelisted API/CDN domains for HTMX requests and asset loading.
- `frame-ancestors 'none'` — equivalent to `X-Frame-Options: DENY`, prevents clickjacking.
- `form-action 'self'` — restrict form submissions to same origin.

## Violation Reporting

- CSP violations MUST be reported to `/csp-report/` endpoint (`report-uri` directive).
- Violation reports are logged to `apps.security.CSPViolationReport` model for analysis.
- Monitor violation reports for false positives and legitimate attack attempts.
- Use `Content-Security-Policy-Report-Only` header for testing new directives before enforcement.

## CDN Allowlist Maintenance

- Only CDN domains used in the multi-CDN fallback chain (jsDelivr, cdnjs, unpkg) are whitelisted.
- Adding a new CDN domain requires security review — NEVER add domains without explicit justification.
- Remove CDN domains that are no longer used in the fallback chain.
