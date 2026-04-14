---
name: ads-compliance-adstxt
description: "ads.txt compliance: authorized sellers. Use when: generating ads.txt, managing authorized ad network sellers, preventing domain spoofing."
---

# ads.txt Compliance

## When to Use
- Generating the `/ads.txt` file for authorized digital sellers
- Adding new ad networks and their seller IDs
- Preventing unauthorized reselling of ad inventory
- IAB Tech Lab ads.txt specification compliance

## Rules
- `ads.txt` served at site root: `https://example.com/ads.txt`
- Each line: `<domain>, <publisher_id>, <relationship>, <cert_authority_id>`
- Relationship: `DIRECT` (own inventory) or `RESELLER` (authorized reseller)
- Auto-generated from enabled `AdNetwork` records
- Must include `contact` and `subdomain` directives if applicable
- Regenerate whenever networks are added/removed

## Patterns

### Dynamic ads.txt View
```python
# apps/ads/views.py
from django.http import HttpResponse
from apps.ads.models import AdNetwork

ADS_TXT_DOMAINS = {
    "adsense": "google.com",
    "admanager": "google.com",
    "medianet": "media.net",
    "amazon": "amazon-adsystem.com",
    "taboola": "taboola.com",
    "outbrain": "outbrain.com",
    "propellerads": "propellerads.com",
}

def ads_txt(request) -> HttpResponse:
    """Generate ads.txt from active ad network records."""
    lines = ["# ads.txt — Auto-generated from active ad networks", ""]

    networks = AdNetwork.objects.filter(is_enabled=True, is_deleted=False)
    for network in networks:
        domain = ADS_TXT_DOMAINS.get(network.network_type, "")
        if domain and network.publisher_id:
            lines.append(
                f"{domain}, {network.publisher_id}, DIRECT"
            )

    lines.append("")
    lines.append("# Contact")
    lines.append("contact=ads@example.com")

    return HttpResponse("\n".join(lines), content_type="text/plain; charset=utf-8")
```

### URL Configuration
```python
# app/urls.py
from apps.ads.views import ads_txt

urlpatterns = [
    path("ads.txt", ads_txt, name="ads-txt"),
    ...
]
```

## Anti-Patterns
- Static `ads.txt` that drifts from actual network configuration
- Missing `ads.txt` when running ad networks — revenue loss from spoofing
- Including disabled networks in `ads.txt`
- Forgetting to update `ads.txt` when adding/removing networks

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
