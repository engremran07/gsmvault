---
paths: ["apps/*/api.py"]
---

# API Layer Rules

These rules apply to all DRF API files (`api.py`) across every Django app.

## Serializer Fields

- **NEVER** use `fields = "__all__"` in any serializer.
  - Always specify an explicit `fields` list.
  - Prevents accidental exposure of sensitive fields (passwords, tokens, internal IDs).
- Every serializer must have `read_only_fields` where appropriate.
- Sensitive fields (`password`, `secret_key`, `token`, `api_key`) MUST be `write_only=True` and excluded from read operations.

## Permissions

- **Every ViewSet and APIView** MUST explicitly declare `permission_classes`.
  - No implicit reliance on global defaults.
  - `AllowAny` is FORBIDDEN on any mutating endpoint (POST, PUT, PATCH, DELETE).
- Public read endpoints use: `permission_classes = [IsAuthenticatedOrReadOnly]`
- Staff-only endpoints use: `permission_classes = [IsAdminUser]`
- User-specific endpoints use: `permission_classes = [IsAuthenticated]`

## Pagination

- Use cursor-based pagination for datasets that may exceed 100 items.
- Default page size: 20. Maximum page size: 100.
- Large time-series or analytics data: always cursor-based.

## Error Responses

All error responses MUST follow this consistent format:
```json
{"error": "Human-readable description", "code": "ERROR_CODE_SNAKE_CASE"}
```
- Use DRF's built-in `ValidationError` for 400s.
- Use `PermissionDenied` for 403s.
- Use `NotFound` for 404s.
- Never expose stack traces or internal model details in error responses.
- Set `DEBUG = False` in production — DRF will auto-hide details.

## URL Versioning

- All endpoints under `/api/v1/`.
- New breaking changes → increment to `/api/v2/` with deprecation header on v1.

## Throttling

- Import throttle classes from `apps.core.throttling`: `UploadRateThrottle`, `DownloadRateThrottle`, `APIRateThrottle`.
- Apply `DownloadRateThrottle` on any endpoint that serves or initiates file downloads.
- Apply `UploadRateThrottle` on any endpoint that accepts file uploads.

## Rate Limiting Context

- WAF-level rate limits live in `apps.security` (`RateLimitRule`, `BlockedIP`, `CrawlerRule`).
- Download quotas live in `apps.firmwares` (`DownloadToken`) + `apps.devices` (`QuotaTier`).
- **NEVER** import `RateLimitRule` in firmware API code or `DownloadToken` in security API code.

## Input Validation and Security

- Always validate and sanitize user-supplied HTML content using `apps.core.sanitizers.sanitize_html_content()`.
- Never trust `request.user` without an `is_authenticated` check in CBVs.
- CSRF protection: `enforce_csrf_checks = True` unless for JWT-authenticated endpoints with `SessionAuthentication` explicitly excluded.
