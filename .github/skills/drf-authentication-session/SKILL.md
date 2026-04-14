---
name: drf-authentication-session
description: "Session authentication for browser-based API access. Use when: API calls from Django-rendered pages, HTMX API requests, admin panel API access."
---

# DRF Session Authentication

## When to Use
- API calls from the same Django-rendered frontend (HTMX, Alpine.js fetch)
- Admin panel API access (user already has a session)
- Browser-based clients where cookies are available

## Rules
- Session auth uses Django's existing session framework — no extra tokens
- CSRF protection is mandatory for session-authenticated mutating requests
- HTMX includes CSRF via global `hx-headers` on `<body>` — already configured
- Combine with JWT auth in settings — session for browsers, JWT for API clients

## Patterns

### Settings Configuration
```python
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "apps.core.authentication.JWTAuthentication",    # API clients
        "rest_framework.authentication.SessionAuthentication",  # Browser
    ],
}
```

### CSRF Handling for HTMX (Already Global)
```html
<!-- templates/base/base.html — already configured -->
<body hx-headers='{"X-CSRFToken": "{{ csrf_token }}"}'>
```

### CSRF for JavaScript fetch()
```javascript
// static/js/src/api.js
function getCookie(name) {
    const value = `; ${document.cookie}`;
    const parts = value.split(`; ${name}=`);
    if (parts.length === 2) return parts.pop().split(';').shift();
    return null;
}

async function apiPost(url, data) {
    const response = await fetch(url, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRFToken': getCookie('csrftoken'),
        },
        credentials: 'same-origin',  // Include cookies
        body: JSON.stringify(data),
    });
    return response.json();
}
```

### View That Works with Both Auth Methods
```python
from rest_framework import viewsets, permissions

class FirmwareViewSet(viewsets.ModelViewSet):
    """Works with session (browser) and JWT (API client)."""
    queryset = Firmware.objects.all()
    serializer_class = FirmwareSerializer
    permission_classes = [permissions.IsAuthenticated]
    # DRF tries each authentication class in order
```

### Session-Only Endpoint
```python
from rest_framework.authentication import SessionAuthentication

class InternalAPIView(APIView):
    """Only accessible from browser with active session."""
    authentication_classes = [SessionAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        return Response({"user": request.user.email})
```

### HTMX API Call Pattern
```html
<button hx-post="/api/v1/firmwares/{{ firmware.id }}/toggle_active/"
        hx-swap="outerHTML"
        hx-target="#firmware-status">
    Toggle Active
</button>
```

### Checking Auth Method in View
```python
class MixedAuthView(APIView):
    def get(self, request):
        if isinstance(request.auth, dict):
            # JWT authentication — request.auth is the decoded payload
            return Response({"auth": "jwt", "user": request.user.email})
        else:
            # Session authentication
            return Response({"auth": "session", "user": request.user.email})
```

## Anti-Patterns
- Session auth without CSRF on POST/PUT/DELETE → CSRF vulnerability
- Using session auth for mobile apps → cookies don't work well cross-origin
- Disabling CSRF with `@csrf_exempt` → forbidden in this codebase
- Missing `credentials: 'same-origin'` in fetch → cookies not sent

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- Skill: `drf-authentication-jwt` — JWT for API clients
- Skill: `drf-authentication-token` — simple token auth
