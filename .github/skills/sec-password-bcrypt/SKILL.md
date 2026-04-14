---
name: sec-password-bcrypt
description: "bcrypt password hashing as alternative. Use when: setting up bcrypt hasher, environments where Argon2 unavailable."
---

# bcrypt Password Hashing

## When to Use

- Environments where Argon2 is not available
- Legacy systems migrating to stronger hashing
- As secondary hasher behind Argon2

## Rules

| Parameter | Recommended | Purpose |
|-----------|-------------|---------|
| Rounds | 12-14 | Work factor (2^rounds iterations) |
| Max length | 72 bytes | bcrypt truncates beyond this |
| Encoding | UTF-8 | Password encoding before hashing |

## Patterns

### Django Configuration
```python
# settings.py — Argon2 primary, bcrypt secondary
PASSWORD_HASHERS = [
    "django.contrib.auth.hashers.Argon2PasswordHasher",
    "django.contrib.auth.hashers.BCryptSHA256PasswordHasher",  # SHA256 pre-hash avoids 72-byte limit
    "django.contrib.auth.hashers.PBKDF2PasswordHasher",
]
```

### Requirement
```text
# requirements.txt
bcrypt>=4.1.0,<5.0
```

### Custom Rounds
```python
from django.contrib.auth.hashers import BCryptSHA256PasswordHasher

class StrongerBCryptHasher(BCryptSHA256PasswordHasher):
    rounds = 14  # Default is 12; increase for more security
```

### Why BCryptSHA256 Over BCrypt
```python
# BCryptSHA256PasswordHasher:
#   1. SHA-256 hashes password first
#   2. Then bcrypt hashes the SHA-256 digest
#   3. Avoids bcrypt's 72-byte truncation
#   4. Handles NUL bytes safely

# BCryptPasswordHasher (avoid):
#   1. Truncates at 72 bytes — long passwords lose entropy
#   2. NUL byte terminates input early
```

### Timing Comparison
```python
# bcrypt rounds vs time (approximate on modern hardware):
# rounds=10: ~100ms per hash
# rounds=12: ~400ms per hash (Django default)
# rounds=14: ~1.6s per hash (strong)
# rounds=16: ~6.4s per hash (too slow for login)
```

## Red Flags

- Using `BCryptPasswordHasher` instead of `BCryptSHA256PasswordHasher`
- `bcrypt` not in `requirements.txt`
- Rounds below 10 — too fast for brute-force resistance
- Rounds above 16 — too slow for user login experience
- bcrypt as primary hasher when Argon2 is available

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
