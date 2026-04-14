---
paths: ["app/settings*.py", "apps/consent/**"]
---

# Cookie Security

All cookies MUST be configured with secure defaults. Session hijacking and cookie theft are high-severity threats.

## Session Cookie Settings

- `SESSION_COOKIE_HTTPONLY = True` — ALWAYS. Prevents JavaScript access to the session cookie.
- `SESSION_COOKIE_SECURE = True` — MUST be set in production (HTTPS only). May be `False` in dev for `localhost`.
- `SESSION_COOKIE_SAMESITE = "Lax"` — provides CSRF protection while allowing normal navigation.
- `SESSION_COOKIE_AGE` — set to a reasonable timeout. Staff sessions should be shorter than regular user sessions.
- NEVER set `SESSION_COOKIE_SAMESITE = "None"` unless there is a documented cross-origin requirement with `Secure` flag.

## CSRF Cookie Settings

- `CSRF_COOKIE_HTTPONLY = True` — MUST be set in production.
- CSRF token is read via HTMX global header (`<body hx-headers>`) — NOT from the cookie via JavaScript.
- `CSRF_COOKIE_SECURE = True` — MUST be set in production.
- `CSRF_TRUSTED_ORIGINS` — explicit list of allowed origins. NEVER use wildcards in production.

## Consent Cookie Pattern

- Consent cookies MUST be set only via `HttpResponseRedirect` — consent form views NEVER return JSON.
- The cookie is set on the redirect response, and `fetch()` callers follow the redirect automatically.
- Consent scopes: `functional` (required — always set), `analytics`, `seo`, `ads` (opt-in).
- Consent cookies MUST have a reasonable expiry (e.g., 365 days) and be refreshable.
- For JSON consent API: use `consent/api/status/` and `consent/api/update/` — separate DRF endpoints, NOT the form views.

## Cookie Content Rules

- NEVER store sensitive data in cookies — passwords, tokens, API keys, PII.
- Session data MUST be stored server-side (database or cache backend) — the cookie holds only the session ID.
- Consent preferences are the exception: they MAY be stored in the cookie for pre-auth access.
- NEVER store JSON blobs or serialized objects in cookies — use server-side sessions.

## Third-Party Cookies

- Third-party cookies from ad networks are governed by the consent system.
- Analytics cookies (analytics scope) MUST NOT be set without explicit user consent.
- Ad cookies (ads scope) MUST NOT be set without explicit user consent.
- SEO cookies (seo scope): follow the same opt-in pattern.
