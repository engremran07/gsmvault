---
name: htmx-auth-expiry-redirect
description: "Auth expiry handling with redirect to login on 401. Use when: handling expired sessions during HTMX requests, redirecting unauthenticated users to login page."
---

# HTMX Auth Expiry Redirect

## When to Use

- User's session expires while they're on an HTMX-powered page
- HTMX request returns 401 and user needs to be redirected to login
- Handling `@login_required` rejections in HTMX context

## Rules

1. Detect 401 responses in `htmx:responseError` handler
2. Use `HX-Redirect` header from server OR client-side `window.location`
3. Preserve the original URL as `?next=` parameter for post-login redirect
4. Django's `@login_required` returns 302 to login — HTMX follows redirects by default

## Patterns

### Client-Side 401 Redirect Handler

```html
{# templates/base/base.html #}
<script nonce="{{ request.csp_nonce }}">
document.addEventListener('htmx:responseError', function(event) {
  if (event.detail.xhr.status === 401) {
    const next = encodeURIComponent(window.location.pathname + window.location.search);
    window.location.href = '/accounts/login/?next=' + next;
  }
});
</script>
```

### Server-Side HX-Redirect for Auth Failures

```python
from django.http import HttpResponse

def protected_fragment(request):
    if not request.user.is_authenticated:
        response = HttpResponse(status=401)
        response["HX-Redirect"] = f"/accounts/login/?next={request.path}"
        return response
    return render(request, "protected/fragment.html")
```

### Middleware for HTMX Auth Redirect

```python
# app/middleware/htmx_auth.py
from django.http import HttpResponse

class HtmxAuthMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)
        # If Django redirects to login and request is HTMX, send HX-Redirect
        if (response.status_code == 302
            and "/accounts/login/" in response.get("Location", "")
            and request.headers.get("HX-Request")):
            htmx_response = HttpResponse(status=204)
            htmx_response["HX-Redirect"] = response["Location"]
            return htmx_response
        return response
```

## Anti-Patterns

```python
# WRONG — returning login HTML as fragment (replaces page section with login form)
if not request.user.is_authenticated:
    return render(request, "accounts/login.html")  # fragments page

# WRONG — no next parameter (user loses their place)
window.location.href = '/accounts/login/';  # missing ?next=
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| Login form appears inside a div | Fragment replaced with full login page | Use `HX-Redirect` header |
| No `?next=` on login redirect | User loses their place after login | Include `next` parameter |
| 302 followed by HTMX swap | Login page swapped into fragment area | Intercept in middleware |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
