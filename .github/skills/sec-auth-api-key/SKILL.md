---
name: sec-auth-api-key
description: "API key authentication: hashing, rotation, scope restrictions. Use when: issuing API keys, implementing key-based auth, rotating keys."
---

# API Key Authentication

## When to Use

- Providing API access to external integrations
- Service-to-service authentication
- Webhook verification with shared secrets

## Rules

| Rule | Implementation |
|------|----------------|
| Hash before storage | Store `sha256(key)`, never plaintext |
| Show once | Display full key only at creation time |
| Prefix for identification | `gsmfw_` prefix for easy identification |
| Scope restriction | Each key has explicit allowed endpoints |
| Expiry | Keys expire after configurable period |

## Patterns

### API Key Model
```python
import hashlib
import secrets
from django.db import models

class APIKey(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
                             related_name="api_keys")
    name = models.CharField(max_length=100)
    prefix = models.CharField(max_length=8, unique=True, db_index=True)
    key_hash = models.CharField(max_length=64)  # SHA-256 hash
    scopes = models.JSONField(default=list)  # ["read:firmware", "write:comments"]
    expires_at = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    last_used_at = models.DateTimeField(null=True, blank=True)

    @classmethod
    def create_key(cls, user, name: str, scopes: list[str]) -> tuple["APIKey", str]:
        raw_key = f"gsmfw_{secrets.token_urlsafe(32)}"
        prefix = raw_key[:8]
        key_hash = hashlib.sha256(raw_key.encode()).hexdigest()
        instance = cls.objects.create(
            user=user, name=name, prefix=prefix,
            key_hash=key_hash, scopes=scopes,
        )
        return instance, raw_key  # raw_key shown once

    def verify(self, raw_key: str) -> bool:
        return hashlib.sha256(raw_key.encode()).hexdigest() == self.key_hash
```

### Authentication Backend
```python
from rest_framework.authentication import BaseAuthentication
from django.utils import timezone

class APIKeyAuthentication(BaseAuthentication):
    def authenticate(self, request):
        auth_header = request.headers.get("Authorization", "")
        if not auth_header.startswith("Bearer gsmfw_"):
            return None
        raw_key = auth_header.split(" ", 1)[1]
        prefix = raw_key[:8]
        try:
            api_key = APIKey.objects.select_related("user").get(
                prefix=prefix, is_active=True
            )
        except APIKey.DoesNotExist:
            return None
        if not api_key.verify(raw_key):
            return None
        if api_key.expires_at and api_key.expires_at < timezone.now():
            return None
        api_key.last_used_at = timezone.now()
        api_key.save(update_fields=["last_used_at"])
        return (api_key.user, api_key)
```

## Red Flags

- API keys stored in plaintext in database
- No expiry mechanism for API keys
- Keys without scope restrictions (full access)
- API keys in URL query parameters (visible in logs)

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
