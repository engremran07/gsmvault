---
name: drf-authentication-token
description: "Token authentication: DRF TokenAuthentication, custom token models. Use when: simple token-based API access, API keys for integrations, service-to-service auth."
---

# DRF Token Authentication

## When to Use
- Simple API key authentication for integrations
- Service-to-service internal API calls
- Third-party webhook callbacks that need auth
- Simpler alternative to JWT when statefulness is acceptable

## Rules
- DRF `TokenAuthentication` stores tokens in the database — stateful, unlike JWT
- One token per user by default — revoke by deleting the row
- Send token in `Authorization: Token <key>` header
- For production API keys, prefer custom token model with expiry and scoping

## Patterns

### Settings
```python
INSTALLED_APPS = [
    "rest_framework.authtoken",  # Adds Token model + migration
]

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "apps.core.authentication.JWTAuthentication",
        "rest_framework.authentication.TokenAuthentication",
        "rest_framework.authentication.SessionAuthentication",
    ],
}
```

### Generate Token on User Creation
```python
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.conf import settings
from rest_framework.authtoken.models import Token

@receiver(post_save, sender=settings.AUTH_USER_MODEL)
def create_auth_token(sender, instance=None, created=False, **kwargs):
    if created:
        Token.objects.create(user=instance)
```

### Token Obtain Endpoint
```python
from rest_framework.authtoken.views import ObtainAuthToken
from rest_framework.response import Response

class CustomObtainToken(ObtainAuthToken):
    def post(self, request, *args, **kwargs):
        serializer = self.serializer_class(
            data=request.data, context={"request": request}
        )
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data["user"]
        token, _created = Token.objects.get_or_create(user=user)
        return Response({
            "token": token.key,
            "user_id": user.pk,
            "email": user.email,
        })
```

### Custom API Key Model (With Expiry)
```python
# apps/api/models.py
import secrets
from django.db import models
from django.conf import settings
from apps.core.models import TimestampedModel

class APIKey(TimestampedModel):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="api_keys",
    )
    key = models.CharField(max_length=64, unique=True, db_index=True)
    name = models.CharField(max_length=100)  # e.g., "My Integration"
    is_active = models.BooleanField(default=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    last_used_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "api_apikey"
        verbose_name = "API key"
        verbose_name_plural = "API keys"
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"{self.name} ({self.user})"

    def save(self, *args, **kwargs):
        if not self.key:
            self.key = secrets.token_urlsafe(48)
        super().save(*args, **kwargs)
```

### Custom Authentication for API Keys
```python
from django.utils import timezone
from rest_framework.authentication import BaseAuthentication
from rest_framework.exceptions import AuthenticationFailed

class APIKeyAuthentication(BaseAuthentication):
    keyword = "Api-Key"

    def authenticate(self, request):
        auth = request.headers.get("Authorization", "")
        if not auth.startswith(f"{self.keyword} "):
            return None

        key = auth[len(self.keyword) + 1:]
        from apps.api.models import APIKey
        try:
            api_key = APIKey.objects.select_related("user").get(
                key=key, is_active=True
            )
        except APIKey.DoesNotExist:
            raise AuthenticationFailed("Invalid API key.")

        if api_key.expires_at and api_key.expires_at < timezone.now():
            raise AuthenticationFailed("API key expired.")

        api_key.last_used_at = timezone.now()
        api_key.save(update_fields=["last_used_at"])
        return (api_key.user, api_key)
```

### Client Usage
```bash
# DRF Token
curl -H "Authorization: Token 9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b" \
     https://api.example.com/api/v1/firmwares/

# Custom API Key
curl -H "Authorization: Api-Key abc123..." \
     https://api.example.com/api/v1/firmwares/
```

## Anti-Patterns
- Exposing token in URL query params → logged in server access logs
- No expiry on tokens → compromised token works forever
- Token in response body without HTTPS → intercepted in transit
- Single token per user with no rotation → can't revoke selectively

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- Skill: `drf-authentication-jwt` — JWT auth patterns
- Skill: `drf-authentication-session` — session auth for browsers
