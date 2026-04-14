---
name: sec-penetration-testing
description: "Penetration testing checklist: OWASP methodology. Use when: running security tests, OWASP Top 10 audit, pre-launch security review."
---

# Penetration Testing Checklist

## When to Use

- Pre-launch security review
- Periodic security assessment
- After major feature additions
- OWASP Top 10 compliance audit

## Rules

| OWASP Category | Test Area | Django Check |
|----------------|-----------|--------------|
| A01 Broken Access Control | Auth/authz bypass | `@login_required`, ownership checks |
| A02 Cryptographic Failures | Weak hashing, HTTPS | Argon2, `SECURE_SSL_REDIRECT` |
| A03 Injection | SQL, XSS, command | ORM-only, nh3 sanitization |
| A04 Insecure Design | Logic flaws | Business logic review |
| A05 Security Misconfiguration | Debug mode, defaults | `manage.py check --deploy` |
| A06 Vulnerable Components | Outdated deps | `pip-audit`, `pip check` |
| A07 Auth Failures | Brute force, weak creds | Rate limiting, password policy |
| A08 Data Integrity Failures | Unsigned data, deserialization | HMAC tokens, no pickle |
| A09 Logging Failures | Missing audit trail | SecurityEvent, AuditLog |
| A10 SSRF | Server-side requests | URL allowlisting |

## Patterns

### Automated Django Security Check
```powershell
# Built-in deployment checks
& .\.venv\Scripts\python.exe manage.py check --deploy --settings=app.settings_production
```

### Access Control Tests
```python
class AccessControlTests(TestCase):
    def test_unauthenticated_redirects(self):
        """All protected views redirect to login."""
        protected_urls = ["/admin/", "/profile/", "/firmware/upload/"]
        for url in protected_urls:
            response = self.client.get(url)
            assert response.status_code in (301, 302, 403)

    def test_non_owner_cannot_access(self):
        """Users cannot access other users' resources."""
        other_user = User.objects.create_user("other", password="test")
        firmware = Firmware.objects.create(uploaded_by=other_user)
        self.client.login(username="attacker", password="test")
        response = self.client.get(f"/firmware/{firmware.pk}/edit/")
        assert response.status_code in (403, 404)

    def test_horizontal_privilege_escalation(self):
        """User A cannot modify User B's data."""
        response = self.client.post(
            f"/api/v1/users/{other_user.pk}/", {"email": "hacked@evil.com"}
        )
        assert response.status_code in (403, 404)
```

### Injection Tests
```python
class InjectionTests(TestCase):
    def test_xss_in_search(self):
        response = self.client.get("/search/?q=<script>alert(1)</script>")
        assert b"<script>" not in response.content

    def test_sql_injection_in_filter(self):
        response = self.client.get("/firmware/?brand='; DROP TABLE--")
        assert response.status_code == 200  # Should handle gracefully
```

### Security Header Verification
```python
class SecurityHeaderTests(TestCase):
    def test_security_headers(self):
        response = self.client.get("/")
        assert response["X-Frame-Options"] == "DENY"
        assert response["X-Content-Type-Options"] == "nosniff"
        assert "Content-Security-Policy" in response
```

### SSRF Prevention Pattern
```python
import ipaddress
from urllib.parse import urlparse

ALLOWED_SCHEMES = {"http", "https"}

def validate_external_url(url: str) -> None:
    parsed = urlparse(url)
    if parsed.scheme not in ALLOWED_SCHEMES:
        raise ValidationError("Invalid URL scheme.")
    # Block internal IPs
    try:
        ip = ipaddress.ip_address(parsed.hostname or "")
        if ip.is_private or ip.is_loopback:
            raise ValidationError("Internal URLs are not allowed.")
    except ValueError:
        pass  # Hostname, not IP — OK
```

## Red Flags

- No `manage.py check --deploy` in deployment pipeline
- Missing security tests in test suite
- No periodic dependency audit
- Debug mode in production
- No rate limiting on authentication endpoints
- No audit logging for security events

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
