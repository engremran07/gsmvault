---
name: sec-session-fixation
description: "Session fixation prevention: rotate session on login. Use when: implementing login, reviewing session handling, security audit."
---

# Session Fixation Prevention

## When to Use

- Implementing custom login flows
- Reviewing session handling security
- Auditing for session fixation vulnerabilities

## Rules

| Rule | Implementation |
|------|----------------|
| Rotate on login | `request.session.cycle_key()` — Django `login()` does this |
| Rotate on privilege escalation | Any elevation (e.g., MFA verified) |
| Never accept external session IDs | Django session middleware rejects unknown IDs |
| Regenerate after password change | `update_session_auth_hash()` |

## Patterns

### Django login() — Automatic Rotation
```python
from django.contrib.auth import login as auth_login

def login_view(request: HttpRequest) -> HttpResponse:
    form = AuthenticationForm(request, data=request.POST)
    if form.is_valid():
        user = form.get_user()
        # auth_login() calls request.session.cycle_key() internally
        # This creates a new session ID, invalidating the old one
        auth_login(request, user)
        return redirect("dashboard")
    return render(request, "users/login.html", {"form": form})
```

### Manual Session Rotation (Privilege Escalation)
```python
def verify_mfa(request: HttpRequest) -> HttpResponse:
    code = request.POST.get("code", "")
    if verify_totp(request.user, code):
        # Rotate session after MFA verification (privilege escalation)
        request.session.cycle_key()
        request.session["mfa_verified"] = True
        return redirect("admin:index")
    return render(request, "users/mfa_verify.html", {"error": "Invalid code"})
```

### Password Change — Session Preservation
```python
from django.contrib.auth import update_session_auth_hash

def change_password_view(request: HttpRequest) -> HttpResponse:
    form = PasswordChangeForm(request.user, request.POST)
    if form.is_valid():
        user = form.save()
        # Regenerate session hash — keeps user logged in
        # Also invalidates all other sessions for this user
        update_session_auth_hash(request, user)
        return redirect("profile")
```

## Red Flags

- Custom login that calls `authenticate()` but not `login()` — no session rotation
- Missing `update_session_auth_hash()` after password change
- `request.session.session_key` used as authentication token
- Accepting session IDs from URL parameters or POST data

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
