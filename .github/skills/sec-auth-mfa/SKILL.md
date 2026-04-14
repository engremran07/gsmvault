---
name: sec-auth-mfa
description: "MFA implementation: TOTP, backup codes, enforcement rules. Use when: adding MFA, enforcing MFA for staff, generating backup codes."
---

# Multi-Factor Authentication

## When to Use

- Adding TOTP-based MFA to user accounts
- Enforcing MFA for staff/admin users
- Generating and validating backup codes

## Rules

| Rule | Implementation |
|------|----------------|
| TOTP algorithm | SHA-1, 6 digits, 30-second period (RFC 6238) |
| Backup codes | 10 single-use codes, hashed before storage |
| Staff enforcement | All `is_staff` users must have MFA enabled |
| Secret storage | Encrypted in database, never logged |

## Patterns

### TOTP Secret Generation
```python
import pyotp
import secrets

def enable_mfa(user: User) -> str:
    """Generate TOTP secret and return provisioning URI."""
    secret = pyotp.random_base32()
    user.mfa_secret = secret  # Store encrypted
    user.mfa_enabled = True
    user.save(update_fields=["mfa_secret", "mfa_enabled"])
    return pyotp.totp.TOTP(secret).provisioning_uri(
        name=user.email, issuer_name="GSMFWs"
    )
```

### TOTP Verification
```python
def verify_totp(user: User, code: str) -> bool:
    """Verify TOTP code with ±1 window for clock drift."""
    if not user.mfa_enabled or not user.mfa_secret:
        return False
    totp = pyotp.TOTP(user.mfa_secret)
    return totp.verify(code, valid_window=1)
```

### Backup Code Generation
```python
from django.contrib.auth.hashers import make_password, check_password

def generate_backup_codes(user: User) -> list[str]:
    """Generate 10 backup codes, store hashed."""
    codes = [secrets.token_hex(4).upper() for _ in range(10)]
    # Store hashed versions
    user.mfa_backup_codes = [make_password(code) for code in codes]
    user.save(update_fields=["mfa_backup_codes"])
    return codes  # Show once, never again

def verify_backup_code(user: User, code: str) -> bool:
    for i, hashed in enumerate(user.mfa_backup_codes):
        if check_password(code, hashed):
            user.mfa_backup_codes.pop(i)  # Single-use
            user.save(update_fields=["mfa_backup_codes"])
            return True
    return False
```

### Staff MFA Enforcement
```python
class MFAEnforcementMiddleware:
    EXEMPT_PATHS = ["/accounts/mfa/setup/", "/accounts/logout/"]

    def __call__(self, request):
        if (request.user.is_authenticated
            and getattr(request.user, "is_staff", False)
            and not getattr(request.user, "mfa_enabled", False)
            and request.path not in self.EXEMPT_PATHS):
            return redirect("/accounts/mfa/setup/")
        return self.get_response(request)
```

## Red Flags

- TOTP secret stored in plaintext logs
- Backup codes not hashed before storage
- MFA bypass for admin users
- No rate limiting on TOTP verification attempts

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
