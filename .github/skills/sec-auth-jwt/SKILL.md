---
name: sec-auth-jwt
description: "JWT security: short expiry, refresh flow, PyJWT best practices. Use when: configuring JWT auth, token generation, API authentication."
---

# JWT Security Best Practices

## When to Use

- Configuring JWT authentication for API endpoints
- Implementing token refresh flows
- Auditing JWT security settings

## Rules

| Setting | Value | Reason |
|---------|-------|--------|
| Access token expiry | 15 minutes | Limits stolen token window |
| Refresh token expiry | 7 days | Longer-lived, stored securely |
| Algorithm | HS256 or RS256 | Never `none` |
| Secret key | Django `SECRET_KEY` min | 256-bit minimum |
| Audience/Issuer | Validate always | Prevents token reuse |

## Patterns

### Token Generation with PyJWT
```python
import jwt
from datetime import datetime, timedelta, timezone
from django.conf import settings

def generate_access_token(user_id: int) -> str:
    payload = {
        "user_id": user_id,
        "exp": datetime.now(timezone.utc) + timedelta(minutes=15),
        "iat": datetime.now(timezone.utc),
        "iss": "gsmfws",
        "aud": "gsmfws-api",
        "type": "access",
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm="HS256")

def generate_refresh_token(user_id: int) -> str:
    payload = {
        "user_id": user_id,
        "exp": datetime.now(timezone.utc) + timedelta(days=7),
        "iat": datetime.now(timezone.utc),
        "type": "refresh",
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm="HS256")
```

### Token Verification
```python
def verify_token(token: str, expected_type: str = "access") -> dict:
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=["HS256"],
            audience="gsmfws-api",
            issuer="gsmfws",
        )
        if payload.get("type") != expected_type:
            raise jwt.InvalidTokenError("Wrong token type")
        return payload
    except jwt.ExpiredSignatureError:
        raise
    except jwt.InvalidTokenError:
        raise
```

### Token Refresh Endpoint
```python
def refresh_token_view(request: HttpRequest) -> JsonResponse:
    refresh = request.POST.get("refresh_token", "")
    try:
        payload = verify_token(refresh, expected_type="refresh")
        new_access = generate_access_token(payload["user_id"])
        return JsonResponse({"access_token": new_access})
    except jwt.ExpiredSignatureError:
        return JsonResponse({"error": "Refresh token expired"}, status=401)
```

## Red Flags

- Access token expiry > 1 hour
- Algorithm set to `"none"` or `algorithms=["none"]`
- Missing `exp` claim — tokens never expire
- Storing JWT in localStorage (use httpOnly cookies)
- Not validating `iss`/`aud` claims

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
