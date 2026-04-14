---
name: drf-authentication-jwt
description: "JWT authentication: token generation, refresh, validation. Use when: implementing JWT auth for API endpoints, configuring PyJWT, token refresh flows."
---

# DRF JWT Authentication

## When to Use
- API authentication for mobile/SPA clients
- Stateless token-based auth (no server-side session)
- Token refresh flows for persistent login

## Rules
- Platform uses PyJWT directly — not `djangorestframework-simplejwt`
- Tokens signed with `settings.SECRET_KEY` (HS256)
- Access tokens: short-lived (15-30 min), Refresh tokens: long-lived (7 days)
- Never store tokens in localStorage — use httpOnly cookies for web clients
- Validate `exp`, `iat`, `sub` claims on every request

## Patterns

### Token Generation Service
```python
# apps/users/services.py
import jwt
from datetime import datetime, timedelta, timezone
from django.conf import settings

def generate_access_token(user) -> str:
    payload = {
        "sub": str(user.pk),
        "email": user.email,
        "iat": datetime.now(timezone.utc),
        "exp": datetime.now(timezone.utc) + timedelta(minutes=30),
        "type": "access",
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm="HS256")

def generate_refresh_token(user) -> str:
    payload = {
        "sub": str(user.pk),
        "iat": datetime.now(timezone.utc),
        "exp": datetime.now(timezone.utc) + timedelta(days=7),
        "type": "refresh",
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm="HS256")

def decode_token(token: str) -> dict:
    return jwt.decode(token, settings.SECRET_KEY, algorithms=["HS256"])
```

### Custom Authentication Class
```python
# apps/core/authentication.py
import jwt
from django.conf import settings
from django.contrib.auth import get_user_model
from rest_framework.authentication import BaseAuthentication
from rest_framework.exceptions import AuthenticationFailed

User = get_user_model()

class JWTAuthentication(BaseAuthentication):
    keyword = "Bearer"

    def authenticate(self, request):
        auth_header = request.headers.get("Authorization", "")
        if not auth_header.startswith(f"{self.keyword} "):
            return None

        token = auth_header[len(self.keyword) + 1:]
        try:
            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=["HS256"])
        except jwt.ExpiredSignatureError:
            raise AuthenticationFailed("Token expired.")
        except jwt.InvalidTokenError:
            raise AuthenticationFailed("Invalid token.")

        if payload.get("type") != "access":
            raise AuthenticationFailed("Invalid token type.")

        try:
            user = User.objects.get(pk=payload["sub"], is_active=True)
        except User.DoesNotExist:
            raise AuthenticationFailed("User not found.")

        return (user, payload)
```

### Login Endpoint
```python
# apps/users/api.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, serializers
from django.contrib.auth import authenticate

class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

class LoginView(APIView):
    permission_classes = []
    authentication_classes = []

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = authenticate(
            request,
            email=serializer.validated_data["email"],
            password=serializer.validated_data["password"],
        )
        if user is None:
            return Response(
                {"error": "Invalid credentials", "code": "INVALID_CREDENTIALS"},
                status=status.HTTP_401_UNAUTHORIZED,
            )
        from .services import generate_access_token, generate_refresh_token
        return Response({
            "access": generate_access_token(user),
            "refresh": generate_refresh_token(user),
        })
```

### Token Refresh Endpoint
```python
class RefreshView(APIView):
    permission_classes = []
    authentication_classes = []

    def post(self, request):
        refresh_token = request.data.get("refresh")
        if not refresh_token:
            return Response(
                {"error": "Refresh token required", "code": "MISSING_TOKEN"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        from .services import decode_token, generate_access_token
        try:
            payload = decode_token(refresh_token)
        except Exception:
            return Response(
                {"error": "Invalid refresh token", "code": "INVALID_TOKEN"},
                status=status.HTTP_401_UNAUTHORIZED,
            )
        if payload.get("type") != "refresh":
            return Response(
                {"error": "Invalid token type", "code": "WRONG_TOKEN_TYPE"},
                status=status.HTTP_401_UNAUTHORIZED,
            )
        from django.contrib.auth import get_user_model
        User = get_user_model()
        user = User.objects.filter(pk=payload["sub"], is_active=True).first()
        if not user:
            return Response(
                {"error": "User not found", "code": "USER_NOT_FOUND"},
                status=status.HTTP_401_UNAUTHORIZED,
            )
        return Response({"access": generate_access_token(user)})
```

### Settings Configuration
```python
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "apps.core.authentication.JWTAuthentication",
        "rest_framework.authentication.SessionAuthentication",
    ],
}
```

## Anti-Patterns
- Storing JWT in localStorage → XSS vulnerability
- No `exp` claim → token never expires
- Using refresh token as access token → extended window of compromise
- Embedding sensitive data in JWT payload → tokens are base64, not encrypted

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- Skill: `drf-authentication-session` — session auth for browsers
- Skill: `drf-authentication-token` — DRF TokenAuthentication
