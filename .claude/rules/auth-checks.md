---
paths: ["apps/*/views.py", "apps/*/views_*.py", "apps/*/api.py"]
---

# Authentication & Authorization Checks

Every view and API endpoint MUST enforce proper authentication and authorization. Anonymous users, permission escalation, and IDOR are critical threats.

## Anonymous User Safety

- ALWAYS use `getattr(request.user, "is_staff", False)` — NEVER access `request.user.is_staff` directly. `AnonymousUser` does not guarantee the attribute exists in all code paths.
- ALWAYS use `getattr(request.user, "is_authenticated", False)` when the view might be reached by unauthenticated users without `@login_required`.
- NEVER assume `request.user` is a `User` instance — it may be `AnonymousUser`.

## Ownership and Object-Level Checks

- ALWAYS filter by ownership: `.get(pk=pk, user=request.user)` or `.filter(user=request.user)`.
- NEVER trust user-supplied IDs alone — always pair with an ownership or permission check.
- For shared resources: use explicit permission checks (e.g., `obj.is_visible_to(request.user)`).
- Raise `Http404` on failed ownership lookups — NEVER reveal that the object exists to unauthorized users.

## Admin View Protection

- All admin views MUST use the `_render_admin()` helper from `views_shared.py`, which enforces `@login_required` + `is_staff` check.
- NEVER call `render()` directly in admin views — always go through `_render_admin()`.
- Admin CRUD operations MUST verify `is_staff` in the view, not just in the template.
- Staff-only API endpoints MUST use `IsAdminUser` permission class.

## DRF API Authorization

- EVERY `ViewSet` and `APIView` MUST declare `permission_classes` explicitly — NEVER rely on defaults.
- `AllowAny` is FORBIDDEN on mutating endpoints (`POST`, `PUT`, `PATCH`, `DELETE`).
- `IsAuthenticated` is the minimum for any endpoint that reads user-specific data.
- Custom permissions MUST inherit from `BasePermission` and implement `has_permission()` and/or `has_object_permission()`.
- Token-based endpoints (JWT): validate token expiry and signature in the authentication backend.

## Session and MFA

- Session timeout is configurable via `SESSION_COOKIE_AGE` — middleware handles HTMX auth expiry via `app/middleware/htmx_auth.py`.
- MFA is enforced for all staff accounts via `apps.security.SecurityConfig`.
- NEVER bypass MFA checks for convenience — staff accounts are high-value targets.
- Password reset tokens MUST have short expiry (configurable, default ≤ 1 hour).

## Social Auth

- django-allauth handles social authentication (Google, GitHub, etc.).
- Social auth callbacks MUST validate the `state` parameter to prevent CSRF.
- NEVER auto-link social accounts to existing emails without verification.
- New social auth providers MUST be reviewed for security before enabling.
