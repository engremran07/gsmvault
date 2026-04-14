---
name: sec-auth-session
description: "Session authentication security: session fixation, timeout, rotation. Use when: configuring session backend, login flow, session security."
---

# Session Authentication Security

## When to Use

- Configuring Django session settings
- Implementing login/logout flows
- Auditing session security posture

## Rules

| Setting | Value | Purpose |
|---------|-------|---------|
| `SESSION_COOKIE_SECURE` | `True` | HTTPS-only cookie |
| `SESSION_COOKIE_HTTPONLY` | `True` | No JS access |
| `SESSION_COOKIE_SAMESITE` | `"Lax"` | CSRF protection |
| `SESSION_COOKIE_AGE` | `1209600` | 2 weeks max |
| `SESSION_EXPIRE_AT_BROWSER_CLOSE` | `False` | Explicit expiry |

## Patterns

### Settings Configuration
```python
# settings.py
SESSION_ENGINE = "django.contrib.sessions.backends.db"
SESSION_COOKIE_SECURE = True
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = "Lax"
SESSION_COOKIE_AGE = 1209600  # 2 weeks
SESSION_COOKIE_NAME = "sessionid"
SESSION_SAVE_EVERY_REQUEST = False  # Only save on changes
```

### Session Rotation on Login
```python
from django.contrib.auth import login as auth_login

def login_view(request: HttpRequest) -> HttpResponse:
    form = AuthenticationForm(request, data=request.POST)
    if form.is_valid():
        user = form.get_user()
        # Django's login() calls request.session.cycle_key()
        # This rotates the session ID — prevents fixation
        auth_login(request, user)
        return redirect("dashboard")
```

### Session Invalidation on Password Change
```python
from django.contrib.auth import update_session_auth_hash

def change_password(request: HttpRequest) -> HttpResponse:
    form = PasswordChangeForm(request.user, request.POST)
    if form.is_valid():
        user = form.save()
        # Keep user logged in with new session
        update_session_auth_hash(request, user)
        return redirect("profile")
```

### Idle Timeout Middleware
```python
from django.utils import timezone

class SessionIdleTimeoutMiddleware:
    IDLE_TIMEOUT = 3600  # 1 hour

    def __call__(self, request):
        if request.user.is_authenticated:
            last_activity = request.session.get("last_activity")
            now = timezone.now().timestamp()
            if last_activity and (now - last_activity) > self.IDLE_TIMEOUT:
                request.session.flush()
            request.session["last_activity"] = now
        return self.get_response(request)
```

## Red Flags

- `SESSION_COOKIE_SECURE = False` in production
- Not calling `auth_login()` (which rotates session)
- Manual session ID assignment
- Missing `update_session_auth_hash()` after password change

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
