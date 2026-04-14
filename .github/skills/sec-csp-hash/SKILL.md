---
name: sec-csp-hash
description: "CSP hash-based allowlisting for known inline scripts. Use when: allowing specific inline scripts without nonce, static script allowlisting."
---

# CSP Hash-Based Allowlisting

## When to Use

- Allowing specific, known inline scripts that cannot use nonces
- Third-party widgets requiring inline script approval
- Static scripts that never change between deployments

## Rules

| Rule | Detail |
|------|--------|
| Hash algorithm | SHA-256 minimum (SHA-384 or SHA-512 preferred) |
| Hash target | Exact script content including whitespace |
| When to use | Only for truly static scripts — prefer nonce for dynamic |
| Regenerate | Must regenerate hash if script content changes at all |

## Patterns

### Generating a Hash
```bash
# Generate SHA-256 hash of inline script content
echo -n "console.log('hello');" | openssl dgst -sha256 -binary | openssl base64
# Output: abc123def456...
```

### CSP Header with Hash
```python
# In CSP middleware or settings
CSP_SCRIPT_SRC = [
    "'self'",
    "'sha256-abc123def456...'",  # Known inline script
    "'strict-dynamic'",
]
```

### Python Hash Generation
```python
import base64
import hashlib

def compute_csp_hash(script_content: str) -> str:
    """Generate CSP-compatible SHA-256 hash of script content."""
    digest = hashlib.sha256(script_content.encode("utf-8")).digest()
    b64 = base64.b64encode(digest).decode("ascii")
    return f"'sha256-{b64}'"

# Usage
script = "document.documentElement.dataset.theme = localStorage.getItem('theme') || 'dark';"
csp_hash = compute_csp_hash(script)
# Add to CSP header: script-src {csp_hash}
```

### Template with Hashed Script
```html
<!-- This exact script content is hashed in CSP policy -->
<script>document.documentElement.dataset.theme = localStorage.getItem('theme') || 'dark';</script>
<!-- Changing even one character requires regenerating the hash -->
```

## Red Flags

- Using SHA-1 for CSP hashes (insecure — use SHA-256+)
- Hashing dynamic script content (use nonce instead)
- Forgetting to update hash when script content changes
- Mixing hash and nonce for same script (unnecessary)

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
