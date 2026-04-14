---
name: sec-csp-report-uri
description: "CSP violation reporting: report-uri, report-to, CSPViolationReport model. Use when: monitoring CSP violations, configuring violation endpoints."
---

# CSP Violation Reporting

## When to Use

- Setting up CSP violation monitoring
- Debugging blocked scripts/styles in production
- Reviewing CSP violation patterns in admin

## Rules

| Directive | Purpose | Status |
|-----------|---------|--------|
| `report-uri` | Legacy reporting endpoint | Deprecated but widely supported |
| `report-to` | Modern Reporting API | Preferred — use alongside report-uri |
| Report-Only | Test CSP without blocking | `Content-Security-Policy-Report-Only` |

## Patterns

### CSP Header with Reporting
```python
# app/middleware/csp_nonce.py
def __call__(self, request: HttpRequest) -> HttpResponse:
    nonce = secrets.token_urlsafe(32)
    request.csp_nonce = nonce
    response = self.get_response(request)
    csp = (
        f"script-src 'nonce-{nonce}' 'strict-dynamic'; "
        "object-src 'none'; base-uri 'self'; "
        "report-uri /api/v1/csp-report/; "
        "report-to csp-endpoint;"
    )
    response["Content-Security-Policy"] = csp
    response["Report-To"] = '{"group":"csp-endpoint","max_age":86400,"endpoints":[{"url":"/api/v1/csp-report/"}]}'
    return response
```

### CSP Report Endpoint
```python
# apps/security/api.py
import json
from django.http import HttpRequest, HttpResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST

@csrf_exempt  # CSP reports are browser-generated, no CSRF token
@require_POST
def csp_report(request: HttpRequest) -> HttpResponse:
    try:
        data = json.loads(request.body)
        report = data.get("csp-report", data)
        CSPViolationReport.objects.create(
            document_uri=report.get("document-uri", "")[:500],
            violated_directive=report.get("violated-directive", "")[:200],
            blocked_uri=report.get("blocked-uri", "")[:500],
            source_file=report.get("source-file", "")[:500],
            line_number=report.get("line-number", 0),
        )
    except (json.JSONDecodeError, KeyError):
        pass  # Malformed reports are silently ignored
    return HttpResponse(status=204)
```

### Report-Only Mode for Testing
```python
# Test new CSP rules without breaking the site
response["Content-Security-Policy-Report-Only"] = new_csp_policy
```

## Red Flags

- No CSP reporting configured — violations go undetected
- `report-uri` pointing to external domain (data leak)
- Not using `Report-Only` to test policy changes
- CSP report endpoint accessible without rate limiting

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
