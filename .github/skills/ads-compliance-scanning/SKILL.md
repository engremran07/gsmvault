---
name: ads-compliance-scanning
description: "Ad content scanning: malvertising prevention. Use when: validating ad creatives, scanning for malicious scripts, blocking harmful ad content."
---

# Ad Content Scanning

## When to Use
- Validating `AdCreative` content before serving
- Scanning `AdUnit.render_code` for malicious JavaScript
- Blocking creatives that redirect or inject unwanted content
- Preventing supply-chain attacks via third-party ad code

## Rules
- All `render_code` and `AdCreative` HTML sanitized with `sanitize_ad_code()` from `apps.core.sanitizers`
- Block ad code containing: `document.write`, `eval()`, `window.location`, crypto miners
- Direct sale creatives (`network_type = "direct"`) MUST pass content scan
- Auto-rejecting creatives with external scripts not on allow-list
- Log blocked creatives to `AdEvent(event_type="blocked")`

## Patterns

### Creative Content Validation
```python
# apps/ads/services.py
import re
from apps.core.sanitizers import sanitize_ad_code

BLOCKED_PATTERNS = [
    r"document\.write",
    r"\beval\s*\(",
    r"window\.location\s*=",
    r"crypto\.subtle",
    r"WebAssembly",
    r"<script[^>]*src=[\"'][^\"']*miner",
]

def validate_creative_content(html: str) -> tuple[bool, list[str]]:
    """Validate ad creative content. Returns (is_safe, violations)."""
    violations = []
    for pattern in BLOCKED_PATTERNS:
        if re.search(pattern, html, re.IGNORECASE):
            violations.append(f"Blocked pattern: {pattern}")

    sanitized = sanitize_ad_code(html)
    if sanitized != html:
        violations.append("Content modified by sanitizer — suspicious elements found")

    return (len(violations) == 0, violations)
```

### Pre-Serve Scan in Rotation
```python
# apps/ads/services/rotation.py
def get_safe_creative(*, placement: AdPlacement) -> AdCreative | None:
    """Return a creative that passes content scanning."""
    creatives = placement.get_weighted_creatives()
    for creative in creatives:
        is_safe, _ = validate_creative_content(creative.html_content)
        if is_safe:
            return creative
        else:
            AdEvent.objects.create(
                creative=creative,
                event_type="blocked",
                metadata={"reason": "content_scan_failed"},
            )
    return None
```

## Anti-Patterns
- Serving `render_code` without sanitization — XSS vector
- Allowing `document.write` in ad scripts — breaks page rendering
- No logging of blocked creatives — can't identify malvertising sources
- Trusting all network-provided ad code without scanning

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
