---
name: sec-auth-social
description: "Social auth security: django-allauth, OAuth state validation. Use when: configuring social login, OAuth provider setup, callback security."
---

# Social Authentication Security

## When to Use

- Configuring django-allauth social providers
- Setting up OAuth callback URLs
- Auditing social login security

## Rules

| Rule | Implementation |
|------|----------------|
| State parameter | Always validate OAuth state (allauth handles this) |
| HTTPS callbacks | All callback URLs must be HTTPS in production |
| Email verification | Require email verification after social signup |
| Provider secrets | Store in environment variables, never in code |

## Patterns

### django-allauth Configuration
```python
# settings.py
INSTALLED_APPS = [
    "allauth",
    "allauth.account",
    "allauth.socialaccount",
    "allauth.socialaccount.providers.google",
    "allauth.socialaccount.providers.github",
]

SOCIALACCOUNT_PROVIDERS = {
    "google": {
        "SCOPE": ["profile", "email"],
        "AUTH_PARAMS": {"access_type": "online"},
        "VERIFIED_EMAIL": True,
    },
    "github": {
        "SCOPE": ["user:email"],
        "VERIFIED_EMAIL": True,
    },
}

# Security settings
ACCOUNT_EMAIL_VERIFICATION = "mandatory"
ACCOUNT_EMAIL_REQUIRED = True
ACCOUNT_UNIQUE_EMAIL = True
SOCIALACCOUNT_AUTO_SIGNUP = True
SOCIALACCOUNT_EMAIL_AUTHENTICATION = True
SOCIALACCOUNT_EMAIL_AUTHENTICATION_AUTO_CONNECT = True
```

### Provider Credentials via Environment
```python
# Never hardcode provider secrets
SOCIALACCOUNT_PROVIDERS["google"]["APP"] = {
    "client_id": os.environ.get("GOOGLE_CLIENT_ID", ""),
    "secret": os.environ.get("GOOGLE_CLIENT_SECRET", ""),
}
```

### Custom Social Account Adapter
```python
from allauth.socialaccount.adapter import DefaultSocialAccountAdapter

class CustomSocialAccountAdapter(DefaultSocialAccountAdapter):
    def is_auto_signup_allowed(self, request, sociallogin):
        email = sociallogin.user.email
        if not email:
            return False
        # Block disposable email domains
        domain = email.split("@")[1]
        blocked = {"tempmail.com", "guerrillamail.com", "mailinator.com"}
        return domain not in blocked
```

## Red Flags

- OAuth client secrets in source code or settings files
- `ACCOUNT_EMAIL_VERIFICATION = "none"` — allows unverified signups
- HTTP callback URLs in production
- Missing state parameter validation (allauth handles this, don't override)
- `SOCIALACCOUNT_AUTO_SIGNUP = True` without email verification

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
