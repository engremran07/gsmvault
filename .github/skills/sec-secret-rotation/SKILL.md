---
name: sec-secret-rotation
description: "Secret rotation: key management, credential lifecycle. Use when: rotating API keys, managing SECRET_KEY, credential renewal."
---

# Secret Rotation

## When to Use

- Rotating Django `SECRET_KEY`
- Renewing API keys and tokens
- Managing credential lifecycle
- Responding to a key compromise

## Rules

| Secret | Rotation Period | Method |
|--------|----------------|--------|
| `SECRET_KEY` | Yearly or on compromise | Dual-key fallback |
| API keys | 90 days | Generate new, deprecate old |
| Database password | 90 days | Coordinated rotation |
| JWT signing key | 90 days | Dual-key during transition |
| OAuth client secrets | Yearly | Provider-specific |

## Patterns

### Django SECRET_KEY Rotation
```python
# settings.py — support old key during transition
SECRET_KEY = os.environ["DJANGO_SECRET_KEY"]

# Django 4.1+ supports fallback keys
SECRET_KEY_FALLBACKS = [
    os.environ.get("DJANGO_SECRET_KEY_OLD", ""),
]
```

### Environment Variable Pattern
```bash
# .env (never committed)
DJANGO_SECRET_KEY=new-key-generated-2024-06
DJANGO_SECRET_KEY_OLD=old-key-from-2023-06
DB_PASSWORD=current-db-password
```

### Secret Generation
```python
# Generate a new SECRET_KEY
from django.core.management.utils import get_random_secret_key
print(get_random_secret_key())

# Or via command line
# python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

### API Key Rotation Service
```python
from django.utils import timezone
from datetime import timedelta

def rotate_api_key(user) -> str:
    """Generate new API key, expire old one after grace period."""
    old_key = APIKey.objects.filter(user=user, is_active=True).first()
    new_key = APIKey.objects.create(
        user=user,
        key=get_random_secret_key(),
        is_active=True,
        expires_at=timezone.now() + timedelta(days=90),
    )
    if old_key:
        # Grace period: old key valid for 24 hours after rotation
        old_key.expires_at = timezone.now() + timedelta(hours=24)
        old_key.save(update_fields=["expires_at"])
    return new_key.key
```

### Rotation Checklist
```markdown
1. Generate new secret
2. Add new secret to environment variables
3. Move old secret to fallback position
4. Deploy with both keys active
5. Monitor for errors using old key
6. Remove fallback key after grace period
7. Audit logs for any authentication failures
```

## Red Flags

- `SECRET_KEY` hardcoded in settings files
- No `SECRET_KEY_FALLBACKS` during rotation
- Same secret used for 1+ years without rotation
- API keys with no expiration date
- No grace period during key rotation — immediate revocation breaks clients

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
