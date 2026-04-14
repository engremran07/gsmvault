---
name: sec-password-argon2
description: "Argon2 password hashing configuration. Use when: configuring password hashers, choosing Argon2id for maximum security."
---

# Argon2 Password Hashing

## When to Use

- Configuring Django password hashers
- Selecting the strongest available hashing algorithm
- Protecting against GPU/ASIC brute-force attacks

## Rules

| Parameter | Recommended | Purpose |
|-----------|-------------|---------|
| Variant | `argon2id` | Hybrid — resists both side-channel and GPU attacks |
| Time cost | 3+ | Number of iterations |
| Memory cost | 65536+ KB (64 MB) | Memory per hash — GPU resistance |
| Parallelism | 4 | Number of threads |
| Hash length | 32 bytes | Output length |

## Patterns

### Django Configuration
```python
# settings.py
PASSWORD_HASHERS = [
    "django.contrib.auth.hashers.Argon2PasswordHasher",  # Primary
    "django.contrib.auth.hashers.PBKDF2PasswordHasher",  # Fallback for old hashes
    "django.contrib.auth.hashers.PBKDF2SHA1PasswordHasher",
]
```

### Requirement
```text
# requirements.txt
argon2-cffi>=23.1.0,<24.0
```

### Custom Argon2 Parameters
```python
from django.contrib.auth.hashers import Argon2PasswordHasher

class CustomArgon2Hasher(Argon2PasswordHasher):
    time_cost = 3        # Iterations
    memory_cost = 65536  # 64 MB
    parallelism = 4      # Threads
```

### Verifying Hash Type
```python
# Management command to check existing password hashes
from django.contrib.auth import get_user_model

User = get_user_model()
for user in User.objects.all():
    algo = user.password.split("$")[0] if user.password else "none"
    if algo != "argon2":
        print(f"User {user.pk}: uses {algo}, needs rehash on next login")
```

### Hash Upgrade (Automatic)
Django automatically rehashes passwords on login when the primary hasher changes.
No manual migration needed — users get upgraded when they authenticate.

```python
# After changing PASSWORD_HASHERS, old PBKDF2 hashes upgrade to Argon2
# on next successful login. No action required.
```

## Red Flags

- `Argon2PasswordHasher` not first in `PASSWORD_HASHERS`
- `argon2-cffi` not in `requirements.txt`
- `memory_cost` below `32768` (32 MB) — weak GPU resistance
- Using MD5 or SHA1 hashers anywhere in the chain
- Custom hasher with `time_cost = 1`

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
