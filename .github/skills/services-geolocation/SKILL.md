---
name: services-geolocation
description: "IP geolocation for analytics and targeting. Use when: determining user location from IP, geo-targeted ads, regional analytics, location-based access control."
---

# IP Geolocation Patterns

## When to Use
- Determining user country/region for analytics
- Geo-targeted ad campaigns
- Regional content restrictions
- Download CDN selection based on location

## Rules
- Use MaxMind GeoLite2 database (free tier) — not API calls per request
- Cache geolocation results per IP — same IP yields same location
- Use `apps.core.utils.get_client_ip()` to extract IP from request
- Never store raw IP addresses without consent — hash with `apps.consent.utils.hash_ip()`
- GeoIP database stored in `storage_credentials/` (gitignored)
- Gracefully handle missing/corrupt GeoIP databases

## Patterns

### GeoIP Service
```python
import logging
from functools import lru_cache
from django.contrib.gis.geoip2 import GeoIP2
from django.conf import settings

logger = logging.getLogger(__name__)

@lru_cache(maxsize=1)
def _get_geoip() -> GeoIP2 | None:
    """Lazy-load GeoIP2 database."""
    try:
        return GeoIP2()
    except Exception:
        logger.warning("GeoIP2 database not available")
        return None

def get_location_from_ip(ip_address: str) -> dict | None:
    """Get country/city from IP address."""
    geoip = _get_geoip()
    if geoip is None:
        return None
    try:
        return geoip.city(ip_address)
    except Exception:
        logger.debug("GeoIP lookup failed for %s", ip_address)
        return None

def get_country_code(ip_address: str) -> str:
    """Get ISO country code from IP. Returns 'XX' if unknown."""
    location = get_location_from_ip(ip_address)
    if location and location.get("country_code"):
        return location["country_code"]
    return "XX"
```

### Cached Geolocation
```python
from django.core.cache import cache

GEOIP_CACHE_TTL = 60 * 60 * 24  # 24 hours

def get_country_cached(ip_address: str) -> str:
    """Get country code with cache layer."""
    cache_key = f"geoip:country:{ip_address}"
    country = cache.get(cache_key)
    if country is None:
        country = get_country_code(ip_address)
        cache.set(cache_key, country, GEOIP_CACHE_TTL)
    return country
```

### Using in Views
```python
from apps.core.utils import get_client_ip

def firmware_list(request):
    ip = get_client_ip(request)
    country = get_country_cached(ip)
    firmwares = Firmware.objects.filter(is_active=True)
    if country != "XX":
        # Prioritize region-specific firmware
        firmwares = firmwares.order_by(
            models.Case(
                models.When(region=country, then=0),
                default=1,
            ),
            "-created_at",
        )
    return render(request, "firmwares/list.html", {"firmwares": firmwares})
```

### Analytics Tracking with Geo
```python
def track_download_with_geo(*, user_id: int, firmware_id: int, ip: str) -> None:
    """Track download event with geographic context."""
    country = get_country_cached(ip)
    AnalyticsEvent.objects.create(
        event_type="download",
        user_id=user_id,
        firmware_id=firmware_id,
        country_code=country,
    )
```

## Anti-Patterns
- Making API calls to GeoIP services per request — use local database
- Storing raw IPs without consent — privacy violation
- No fallback when GeoIP database is missing — crashes in production
- Assuming all IPs resolve to a location — handle `None` gracefully

## Red Flags
- `requests.get("https://ipapi.co/...")` on every request → use local DB
- Raw IP stored in analytics without `hash_ip()` → consent violation
- No `try/except` around GeoIP lookups → crashes on bad IPs

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
