---
paths: ["apps/*/views.py", "apps/*/views_*.py"]
---

# Views Layer Rules

Views are thin orchestrators: parse request, call service, return response. All business logic lives in `services.py`.

## Orchestration Pattern

- Views MUST follow the pattern: parse request → call service → return response.
- NEVER put ORM queries (`.filter()`, `.get()`, `.create()`, etc.) directly in views — delegate to services or managers.
- NEVER put business logic in views — call `services.py` functions instead.
- Views CAN import models from multiple apps (views are orchestrators).
- Keep view functions under 30 lines. If longer, extract logic to a service function.

## HTMX Detection

- ALWAYS detect HTMX requests with `request.headers.get("HX-Request")`.
- Return full page templates for normal requests, fragments for HTMX requests:
  ```python
  if request.headers.get("HX-Request"):
      return render(request, "app/fragments/partial.html", context)
  return render(request, "app/full_page.html", context)
  ```
- HTMX fragment templates MUST NOT use `{% extends %}` — they are standalone HTML snippets.
- Set `HX-Trigger` response headers for client-side event dispatch when needed.

## Authentication & Permissions

- ALWAYS use `@login_required` on protected views.
- ALWAYS use `getattr(request.user, "is_staff", False)` — never bare `request.user.is_staff` (fails for AnonymousUser).
- Staff-only views: `@login_required` + `@user_passes_test(lambda u: u.is_staff)`.
- Ownership checks: ALWAYS verify `obj.user == request.user` or use `.filter(user=request.user)`.
- NEVER trust user-supplied IDs without an ownership or permission check.

## View Selection

- Use function-based views for simple endpoints (single-purpose, under 20 lines).
- Use class-based views for complex CRUD with multiple HTTP methods.
- API views MUST use DRF serializers — never return hand-built JSON from regular views.
- Template views return `render()` or `TemplateResponse`.
- Redirect views return `HttpResponseRedirect` or `redirect()`.

## Response Types

- Page views → `render(request, "app/template.html", context)`
- HTMX fragments → `render(request, "app/fragments/partial.html", context)`
- JSON API → DRF `Response(serializer.data)` (in `api.py`, not `views.py`)
- Form success → `HttpResponseRedirect` (POST-redirect-GET pattern)
- NEVER return raw `JsonResponse` from page views — use DRF for API endpoints.

## Error Handling

- Let Django's built-in error handling manage 404/500 — don't catch broad exceptions in views.
- Use `get_object_or_404()` for single-object lookups.
- Form validation errors: re-render the form with errors, never redirect on failure.
- Log unexpected errors with `logger.exception()` — never swallow exceptions silently.
