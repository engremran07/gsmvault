---
name: sec-session-timeout
description: "Session timeout configuration: age, idle timeout, absolute timeout. Use when: setting session expiry, configuring idle logout."
---

# Session Timeout Configuration

## When to Use

- Setting session expiry policies
- Implementing idle timeout (inactivity logout)
- Configuring absolute session lifetimes

## Rules

| Timeout Type | Setting | Purpose |
|-------------|---------|---------|
| Cookie age | `SESSION_COOKIE_AGE` | Maximum session lifetime |
| Idle timeout | Custom middleware | Logout after inactivity |
| Browser close | `SESSION_EXPIRE_AT_BROWSER_CLOSE` | End session on tab close |
| Staff sessions | Shorter lifetime | Higher security for admin |

## Patterns

### Settings
```python
# settings.py
SESSION_COOKIE_AGE = 1209600         # 2 weeks absolute max
SESSION_EXPIRE_AT_BROWSER_CLOSE = False  # Persistent sessions
SESSION_SAVE_EVERY_REQUEST = True     # Refresh expiry on activity
```

### Idle Timeout Middleware
```python
import time
from django.conf import settings
from django.contrib.auth import logout

class IdleTimeoutMiddleware:
    """Log out users after period of inactivity."""
    IDLE_TIMEOUT = getattr(settings, "SESSION_IDLE_TIMEOUT", 3600)  # 1 hour

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if request.user.is_authenticated:
            last = request.session.get("_last_activity")
            now = time.time()
            if last and (now - last) > self.IDLE_TIMEOUT:
                logout(request)
            else:
                request.session["_last_activity"] = now
        return self.get_response(request)
```

### Staff Shorter Sessions
```python
class StaffSessionMiddleware:
    """Enforce shorter session for staff users."""
    STAFF_SESSION_AGE = 3600  # 1 hour for staff

    def __call__(self, request):
        if request.user.is_authenticated and getattr(request.user, "is_staff", False):
            request.session.set_expiry(self.STAFF_SESSION_AGE)
        return self.get_response(request)
```

### JavaScript Idle Warning
```html
<script nonce="{{ csp_nonce }}">
    let idleTimer;
    function resetIdle() {
        clearTimeout(idleTimer);
        idleTimer = setTimeout(() => {
            if (confirm('Session expiring. Stay logged in?')) {
                fetch('/api/v1/heartbeat/', { credentials: 'same-origin' });
                resetIdle();
            } else {
                window.location.href = '/accounts/logout/';
            }
        }, 55 * 60 * 1000); // Warn at 55 minutes
    }
    document.addEventListener('mousemove', resetIdle);
    document.addEventListener('keypress', resetIdle);
    resetIdle();
</script>
```

## Red Flags

- No session timeout configured — sessions last forever
- `SESSION_SAVE_EVERY_REQUEST = False` with idle timeout (timeout resets wrong)
- Idle timeout > 4 hours for staff users
- Missing client-side idle warning

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
