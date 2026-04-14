---
paths: ["app/settings*.py"]
---

# CORS Policy

Cross-Origin Resource Sharing MUST be explicitly configured per environment. Overly permissive CORS enables cross-site data theft from authenticated API endpoints.

## Production Configuration

- NEVER use `CORS_ALLOW_ALL_ORIGINS = True` in production — this is equivalent to disabling CORS entirely.
- `CORS_ALLOWED_ORIGINS` MUST be an explicit allowlist of trusted domains (e.g., `["https://gsmfws.com", "https://www.gsmfws.com"]`).
- `CORS_ALLOW_CREDENTIALS = True` ONLY when `CORS_ALLOWED_ORIGINS` is an explicit list — NEVER with wildcard origins.
- Adding a new origin to the allowlist requires security review — document why each origin is trusted.
- NEVER add third-party ad network or analytics domains to CORS origins — they use their own embedding mechanisms.

## Development Configuration

- Development settings MAY allow `localhost` origins: `["http://localhost:3000", "http://localhost:8000", "http://127.0.0.1:8000"]`.
- NEVER copy development CORS settings into production — use separate settings files (`settings_dev.py` vs `settings_production.py`).
- `CORS_ALLOW_ALL_ORIGINS = True` is acceptable ONLY in `settings_dev.py`.

## API Endpoint Scoping

- CORS MUST be scoped to API paths only — use `CORS_URLS_REGEX = r"^/api/.*$"` to restrict CORS to `/api/v1/` endpoints.
- Django-served HTML pages (templates) do NOT need CORS headers — they are same-origin by definition.
- Webhook endpoints that receive external callbacks MUST use CORS or skip CORS with proper signature verification.

## Headers and Methods

- `CORS_ALLOW_METHODS` — restrict to methods the API actually uses: `["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]`.
- `CORS_ALLOW_HEADERS` — include standard headers plus `Authorization`, `X-CSRFToken`, `HX-Request`, `HX-Trigger`.
- `CORS_EXPOSE_HEADERS` — expose only headers the frontend needs (e.g., `X-Total-Count` for pagination).
- `CORS_PREFLIGHT_MAX_AGE = 3600` — cache preflight responses for 1 hour to reduce OPTIONS requests.

## Security Considerations

- CORS does NOT replace authentication — it only controls which origins can make cross-origin requests.
- Sensitive endpoints (wallet, account deletion, password change) MUST verify the `Origin` header server-side even with CORS configured.
- If an endpoint is public and read-only, consider using `CORS_ALLOW_ALL_ORIGINS` for that specific endpoint via `@cors_allow_any` decorator rather than globally.
