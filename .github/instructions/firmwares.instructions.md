---
applyTo: 'apps/firmwares/**'
---

# Firmwares App Instructions

## Scope

`apps.firmwares` is the firmware mega-app handling: firmware catalog, OEM scraping, download gating, GSMArena sync, and firmware verification. It absorbed `fw_verification`, `fw_scraper`, `download_links`, and `gsmarena_sync`.

## Firmware Types

```python
class FirmwareType(models.TextChoices):
    OFFICIAL = "official", "Official"
    ENGINEERING = "engineering", "Engineering"
    READBACK = "readback", "Readback"
    MODIFIED = "modified", "Modified"
    OTHER = "other", "Other"
```

## Catalog Hierarchy

```
Brand → Model → Variant → FirmwareFile
```

- **Brand**: Samsung, Xiaomi, Huawei, etc. (with logo, slug)
- **Model**: Galaxy S24, Redmi Note 13, etc. (FK to Brand)
- **Variant**: Regional/carrier variants (FK to Model)
- **FirmwareFile**: Actual firmware file record (FK to Model/Variant, file_type, version, size)

## OEM Scraper Pipeline

```
OEMSource → ScraperConfig → ScraperRun → IngestionJob → [Admin Approval] → FirmwareFile
```

| Model | Purpose |
|---|---|
| `OEMSource` | OEM firmware source URL/API endpoint |
| `ScraperConfig` | Scraping rules (selectors, schedule, rate limits) |
| `ScraperRun` | Execution record (start/end, items found, errors) |
| `IngestionJob` | Individual scraped item awaiting review |

### CRITICAL: Scraped Data NEVER Auto-Inserts

All scraped items go through admin approval:

```
IngestionJob.status flow:
  pending → approved → processing → done
  pending → rejected (stops here)
  processing → failed (can retry)
  pending → skipped (duplicate detected)
```

**FORBIDDEN**: Writing scraped data directly to `FirmwareFile` or related models. Every scraped item MUST create an `IngestionJob` with `status="pending"` for admin review.

## Download Gating

| Model | Purpose |
|---|---|
| `DownloadToken` | Single-use, HMAC-signed, per-firmware per-user token |
| `DownloadSession` | Tracks download lifecycle (bytes delivered, duration) |
| `AdGateLog` | Ad watch tracking (video/banner, watched_seconds, credits) |
| `HotlinkBlock` | Domain-level hotlinking protection |

### Download Token Flow

```python
from apps.firmwares.download_service import (
    create_download_token,
    validate_download_token,
    complete_ad_gate,
    start_download_session,
    complete_download_session,
)

# 1. Create token (checks quota, generates HMAC)
token = create_download_token(user=user, firmware=firmware)

# 2. If ad-gated, user watches ad
if token.ad_gate_required:
    complete_ad_gate(token, ad_type="video", watched_seconds=30)

# 3. Validate token on download request
is_valid = validate_download_token(token_string)

# 4. Start tracked download session
session = start_download_session(token)

# 5. Complete download
complete_download_session(session, bytes_delivered=file_size)
```

Token properties:
- HMAC-signed with server secret
- Single-use (status changes to "used" on download)
- Expiry (configurable, default 24 hours)
- Statuses: `active` → `used` | `expired` | `revoked`

## Download Quotas

Quotas are defined in `apps.devices.QuotaTier` and enforced here:

| Tier | Daily Limit | Ad Required | Captcha Bypass |
|---|---|---|---|
| Free | 3 | Yes | No |
| Registered | 10 | Yes | No |
| Subscriber | 50 | No | Yes |
| Premium | Unlimited | No | Yes |

**These are NOT WAF rate limits.** WAF rate limits are in `apps.security`. Download quotas are per-user business rules.

## GSMArena Sync

| Model | Purpose |
|---|---|
| `GSMArenaDevice` | Synced device spec data from GSMArena |
| `SyncRun` | Sync execution record |
| `SyncConflict` | Data conflicts requiring manual resolution |

## Verification Programme

| Model | Purpose |
|---|---|
| `TrustedTester` | Verified tester profile (reputation, level) |
| `VerificationReport` | Firmware test report (boot, flash, features) |
| `TestResult` | Individual test outcomes within a report |
| `VerificationCredit` | Credits earned for verification work |

## Dissolved App db_table References

Models from dissolved apps use their original table names:

```python
# From fw_scraper
class OEMSource(TimestampedModel):
    class Meta:
        db_table = "fw_scraper_oemsource"

# From download_links
class DownloadToken(TimestampedModel):
    class Meta:
        db_table = "download_links_downloadtoken"

# From gsmarena_sync
class GSMArenaDevice(TimestampedModel):
    class Meta:
        db_table = "gsmarena_sync_gsmarenadevice"

# From fw_verification
class TrustedTester(TimestampedModel):
    class Meta:
        db_table = "fw_verification_trustedtester"
```

## Forbidden Practices

- Never auto-insert scraped data — always `IngestionJob` → admin approval
- Never import `RateLimitRule` from `apps.security` — download quotas are separate
- Never serve firmware files without token validation
- Never skip HMAC verification on download tokens
- Never allow hotlinked downloads without referrer check
