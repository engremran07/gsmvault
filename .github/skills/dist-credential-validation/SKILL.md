---
name: dist-credential-validation
description: "Credential validation for social accounts. Use when: testing API tokens, verifying account connectivity, detecting expired tokens, pre-flight checks."
---

# Credential Validation

## When to Use
- Testing `SocialAccount` credentials before scheduling distribution
- Detecting expired tokens via `SocialAccount.is_expired` property
- Pre-flight validation before creating `SharePlan`
- Admin UI "Test Connection" button for social accounts

## Rules
- `SocialAccount.is_expired` checks `token_expires_at < now()`
- `SocialAccount.last_tested_at` records the last validation timestamp
- Each connector has a lightweight "verify" API call (profile fetch)
- Failed validation → `SocialAccount.is_active = False` until re-auth
- Tokens refreshed automatically if `refresh_token` is available

## Patterns

### Validation Service
```python
# apps/distribution/services.py
import httpx
from apps.distribution.models import SocialAccount

VERIFY_ENDPOINTS = {
    "twitter": ("GET", "https://api.twitter.com/2/users/me"),
    "facebook": ("GET", "https://graph.facebook.com/v18.0/me"),
    "linkedin": ("GET", "https://api.linkedin.com/v2/me"),
    "telegram": ("GET", "https://api.telegram.org/bot{token}/getMe"),
}

def validate_account(account: SocialAccount) -> tuple[bool, str]:
    """Validate credentials with a lightweight API call."""
    if account.is_expired:
        if account.refresh_token:
            try:
                refresh_account_token(account)
            except Exception as e:
                return False, f"Token refresh failed: {e}"
        else:
            return False, "Token expired, no refresh token available"

    endpoint = VERIFY_ENDPOINTS.get(account.channel)
    if not endpoint:
        return True, "No verification endpoint — assumed valid"

    method, url = endpoint
    if "{token}" in url:
        url = url.replace("{token}", account.access_token)
        headers = {}
    else:
        headers = {"Authorization": f"Bearer {account.access_token}"}

    try:
        resp = httpx.request(method, url, headers=headers, timeout=10)
        if resp.status_code == 200:
            account.last_tested_at = timezone.now()
            account.save(update_fields=["last_tested_at"])
            return True, "Connection verified"
        return False, f"API returned {resp.status_code}"
    except httpx.RequestError as e:
        return False, f"Connection error: {e}"
```

### Admin Test Connection View
```python
# apps/admin/views_distribution.py
def test_social_account(request, pk: int):
    account = SocialAccount.objects.get(pk=pk)
    is_valid, message = validate_account(account)
    return JsonResponse({"valid": is_valid, "message": message})
```

## Anti-Patterns
- Scheduling jobs without verifying credentials — jobs fail silently
- Not checking `is_expired` before every API call
- Storing tokens in `config` JSON without encryption
- No automatic deactivation on repeated auth failures

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
