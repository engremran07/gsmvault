---
paths: ["app/middleware/*.py"]
---

# Middleware Layer Rules

Middleware intercepts every request/response cycle. It must be fast, focused, and safe.

## Structure

- Middleware MUST use the class-based pattern with `__init__(self, get_response)` and `__call__(self, request)`.
- Keep each middleware in its own file in `app/middleware/`.
- ALWAYS register middleware in `settings.py` `MIDDLEWARE` list.
- Order matters: security → session → auth → CSRF → app-specific → response processing.

## Performance

- Middleware runs on EVERY request — MUST be lightweight.
- NEVER do heavy database queries in middleware — cache results if lookup is required.
- NEVER call external APIs from middleware — it blocks the entire request cycle.
- Use `hasattr()` / `getattr()` guards for attributes that may not exist on all request types.
- Short-circuit early when the middleware doesn't apply to the current request path.

## Existing Middleware

- **CSP Nonce** (`csp_nonce.py`): generates a unique `csp_nonce` per request for inline `<script>` tags. Templates access it via `request.csp_nonce`.
- **HTMX Auth** (`htmx_auth.py`): returns `HX-Redirect` header for expired sessions on HTMX requests instead of the default 302, so HTMX can do a full page redirect.
- NEVER duplicate functionality that existing middleware already provides.

## Security Rules

- Middleware MUST NOT modify response bodies — that's too broad and risks corrupting output.
- NEVER log PII (passwords, tokens, full request bodies with credentials) in middleware.
- Log security events (blocked IPs, rate limits, suspicious patterns) to `SecurityEvent` model.
- ALWAYS use constant-time comparison for token/header validation (`hmac.compare_digest`).
- NEVER bypass CSRF middleware — if an endpoint needs exemption, document the security justification.

## Error Handling

- Middleware MUST NOT crash the request cycle — wrap processing in `try/except` and log errors.
- Return appropriate error responses: `HttpResponseForbidden` for blocked requests, `HttpResponseServerError` only as last resort.
- NEVER return raw exception details to the client in production (check `settings.DEBUG`).

## Testing

- Test middleware with Django's `RequestFactory` or `Client`.
- Verify middleware ordering effects by testing the full stack, not individual middleware in isolation.
- Test both the happy path and the error/bypass path.
