---
name: htmx-auth-expiry-modal
description: "Auth expiry modal popup for re-authentication. Use when: showing a re-login modal instead of redirecting, keeping user context on session expiry, AJAX re-authentication."
---

# HTMX Auth Expiry Modal

## When to Use

- User has unsaved work and session expires — redirect would lose their data
- Showing an in-page re-auth modal instead of losing context
- Long-lived pages (dashboards, forms) where session may expire

## Rules

1. Detect 401 in `htmx:responseError` and show a modal
2. Use `$store.confirm` or a dedicated re-auth modal
3. Modal submits credentials via HTMX to a re-auth endpoint
4. On success, retry the original failed request
5. Never store credentials in JavaScript — only send via form POST

## Patterns

### Re-Auth Modal Template

```html
{# templates/base/fragments/reauth_modal.html #}
<div id="reauth-modal" x-data="{ open: false }" x-cloak
     @show-reauth.window="open = true"
     @keydown.escape.window="open = false">
  <div x-show="open" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
    <div class="bg-[var(--color-bg-secondary)] rounded-lg p-6 w-96">
      <h3 class="text-lg font-semibold mb-4">Session Expired</h3>
      <p class="text-sm mb-4 text-[var(--color-text-muted)]">
        Your session expired. Please re-enter your password to continue.
      </p>
      <form hx-post="{% url 'users:reauth' %}"
            hx-target="#reauth-result"
            hx-swap="innerHTML">
        <input type="hidden" name="username" value="{{ request.user.username }}">
        <input type="password" name="password" placeholder="Password"
               class="w-full px-3 py-2 rounded border mb-3" required>
        <div id="reauth-result"></div>
        <button type="submit" class="btn btn-primary w-full">Re-authenticate</button>
      </form>
      <button @click="open = false" class="mt-2 text-sm text-[var(--color-text-muted)]">
        Cancel (go to login)
      </button>
    </div>
  </div>
</div>
```

### JavaScript 401 Handler Showing Modal

```html
<script nonce="{{ request.csp_nonce }}">
document.addEventListener('htmx:responseError', function(event) {
  if (event.detail.xhr.status === 401) {
    window.dispatchEvent(new CustomEvent('show-reauth'));
  }
});
</script>
```

### Re-Auth View

```python
from django.contrib.auth import authenticate, login

def reauth(request):
    if request.method != "POST":
        return HttpResponse(status=405)
    user = authenticate(
        request,
        username=request.POST.get("username"),
        password=request.POST.get("password"),
    )
    if user:
        login(request, user)
        return HttpResponse(
            '<p class="text-green-500">✓ Session restored</p>',
            headers={"HX-Trigger": "reauth-success"},
        )
    return HttpResponse(
        '<p class="text-red-500">Invalid password</p>', status=401,
    )
```

## Anti-Patterns

```javascript
// WRONG — prompt() for password (blocks UI, no styling)
const pwd = prompt("Session expired. Enter password:");

// WRONG — storing credentials in localStorage
localStorage.setItem('password', pwd);  // SECURITY VIOLATION
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| `prompt()` for re-auth | Blocks UI, no styling, insecure | Use modal form |
| Credentials in localStorage/JS | Security vulnerability | Only send via form POST |
| No CSRF on re-auth form | Vulnerable to CSRF attack | Body `hx-headers` covers it |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
