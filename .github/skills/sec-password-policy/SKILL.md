---
name: sec-password-policy
description: "Password policy enforcement: length, complexity, breach check. Use when: configuring password validators, strengthening password requirements."
---

# Password Policy Enforcement

## When to Use

- Configuring Django password validators
- Adding breach-check validation (Have I Been Pwned)
- Setting minimum password strength requirements

## Rules

| Validator | Purpose | Setting |
|-----------|---------|---------|
| MinimumLengthValidator | Min characters | 12+ recommended |
| CommonPasswordValidator | Block common passwords | Django built-in list |
| NumericPasswordValidator | Block all-numeric | Django built-in |
| UserAttributeSimilarityValidator | Block username/email similarity | Django built-in |
| Custom complexity | Require mixed chars | Custom validator |

## Patterns

### Django Settings
```python
# settings.py
AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator",
        "OPTIONS": {"user_attributes": ("username", "email", "first_name", "last_name")},
    },
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
        "OPTIONS": {"min_length": 12},
    },
    {
        "NAME": "django.contrib.auth.password_validation.CommonPasswordValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.NumericPasswordValidator",
    },
]
```

### Custom Complexity Validator
```python
import re
from django.core.exceptions import ValidationError

class ComplexityValidator:
    def validate(self, password: str, user=None) -> None:
        if not re.search(r"[A-Z]", password):
            raise ValidationError("Password must contain at least one uppercase letter.")
        if not re.search(r"[a-z]", password):
            raise ValidationError("Password must contain at least one lowercase letter.")
        if not re.search(r"\d", password):
            raise ValidationError("Password must contain at least one digit.")

    def get_help_text(self) -> str:
        return "Password must contain uppercase, lowercase, and a digit."
```

### Breach Check Validator (HaveIBeenPwned)
```python
import hashlib
import requests

class BreachCheckValidator:
    def validate(self, password: str, user=None) -> None:
        sha1 = hashlib.sha1(password.encode()).hexdigest().upper()  # noqa: S324
        prefix, suffix = sha1[:5], sha1[5:]
        try:
            resp = requests.get(
                f"https://api.pwnedpasswords.com/range/{prefix}",
                timeout=3,
            )
            if suffix in resp.text:
                raise ValidationError(
                    "This password has been found in a data breach. Choose another."
                )
        except requests.RequestException:
            pass  # Fail open — don't block registration on API timeout

    def get_help_text(self) -> str:
        return "Password must not appear in known data breaches."
```

## Red Flags

- `AUTH_PASSWORD_VALIDATORS = []` — no password validation
- Minimum length below 8 characters
- Missing `CommonPasswordValidator`
- Breach check that fails closed (blocks registration on API error)

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
