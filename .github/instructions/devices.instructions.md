---
applyTo: 'apps/devices/**'
---

# Devices App Instructions

## Scope

`apps.devices` handles the device catalog, trust scoring, behaviour analytics, and download quota tiers. It absorbed `device_registry` and `ai_behavior`.

## Core Models

| Model | Purpose |
|---|---|
| `DeviceConfig` | Singleton: global fingerprinting policy, quotas, MFA rules, AI risk scoring |
| `Device` | Registered device record (user FK, OS, browser, last_seen) |
| `DeviceEvent` | Activity log (login, download_attempt, policy_violation, etc.) |
| `DeviceFingerprint` | OS, browser, device type, trust level, bot detection |
| `TrustScore` | Computed trust score with signal tracking |
| `QuotaTier` | Per-tier download limits and capabilities |
| `BehaviorInsight` | AI-flagged anomalies with severity levels |

## Device Fingerprinting

```python
class DeviceFingerprint(TimestampedModel):
    # Identification
    user = models.ForeignKey(settings.AUTH_USER_MODEL, ...)
    fingerprint_hash = models.CharField(max_length=64, unique=True)

    # Attributes
    os_name = models.CharField(max_length=50)
    os_version = models.CharField(max_length=20)
    browser_name = models.CharField(max_length=50)
    browser_version = models.CharField(max_length=20)
    device_type = models.CharField(choices=DeviceType.choices)  # desktop, mobile, tablet, bot

    # Trust
    trust_level = models.CharField(choices=TrustLevel.choices)  # new, low, medium, high, verified
    is_bot = models.BooleanField(default=False)
    is_suspicious = models.BooleanField(default=False)
```

## Trust Score System

`TrustScore` is a computed score based on multiple signals:

```python
class TrustScore(TimestampedModel):
    device = models.OneToOneField(DeviceFingerprint, ...)
    score = models.IntegerField(default=50)  # 0-100

    # Individual signal scores
    age_score = models.IntegerField(default=0)       # How old is the device registration
    activity_score = models.IntegerField(default=0)   # Regular usage pattern
    violation_score = models.IntegerField(default=0)   # Negative: policy violations
    verification_score = models.IntegerField(default=0) # Positive: verified actions

    def compute(self):
        self.score = max(0, min(100,
            self.age_score + self.activity_score -
            self.violation_score + self.verification_score
        ))
        self.save(update_fields=["score"])
```

## Behaviour Insights (AI-Flagged)

```python
class BehaviorInsight(TimestampedModel):
    device = models.ForeignKey(DeviceFingerprint, ...)
    insight_type = models.CharField(max_length=50)  # rapid_downloads, credential_stuffing, etc.
    severity = models.CharField(choices=[
        ("low", "Low"),
        ("medium", "Medium"),
        ("high", "High"),
        ("critical", "Critical"),
    ])
    details = models.JSONField(default=dict)
    is_resolved = models.BooleanField(default=False)
```

Severity levels trigger different responses:
- **Low**: Log only
- **Medium**: Flag for review, increase captcha frequency
- **High**: Temporary download restriction, admin notification
- **Critical**: Immediate block, security event created in `apps.security`

## Quota Tier System

```python
class QuotaTier(TimestampedModel):
    name = models.CharField(max_length=50)          # "Free", "Registered", "Subscriber", "Premium"
    slug = models.SlugField(unique=True)
    daily_download_limit = models.IntegerField()     # Max downloads per 24h
    hourly_download_limit = models.IntegerField()    # Max downloads per hour
    max_file_size_mb = models.IntegerField()         # Max single file size
    requires_ad = models.BooleanField(default=True)  # Must watch ad before download
    can_bypass_captcha = models.BooleanField(default=False)
    priority_queue = models.BooleanField(default=False)  # Priority download queue
```

| Tier | Daily | Hourly | Ad Required | Captcha Bypass |
|---|---|---|---|---|
| Free | 3 | 1 | Yes | No |
| Registered | 10 | 3 | Yes | No |
| Subscriber | 50 | 15 | No | Yes |
| Premium | Unlimited | Unlimited | No | Yes |

## Critical Distinction: Quotas vs WAF Rate Limits

**Download quotas** (this app + `apps.firmwares`):
- Per-user, per-tier limits
- Business logic (freemium model)
- Enforced at download time in `apps.firmwares.download_service`

**WAF rate limits** (`apps.security`):
- Per-IP, per-path limits
- Security/DDoS protection
- Enforced at middleware level

**FORBIDDEN**: Importing `RateLimitRule` or `BlockedIP` from `apps.security` into this app. These are independent systems.

## Dissolved App Table References

```python
class DeviceFingerprint(TimestampedModel):
    class Meta:
        db_table = "device_registry_devicefingerprint"

class TrustScore(TimestampedModel):
    class Meta:
        db_table = "device_registry_trustscore"

class QuotaTier(TimestampedModel):
    class Meta:
        db_table = "device_registry_quotatier"

class BehaviorInsight(TimestampedModel):
    class Meta:
        db_table = "ai_behavior_behaviorinsight"
```

## Device Event Logging

```python
from apps.devices.models import DeviceEvent

DeviceEvent.objects.create(
    device=device,
    event_type="download_attempt",
    details={"firmware_id": fw.pk, "result": "quota_exceeded"},
    ip_address=get_client_ip(request),
)
```

Event types: `login`, `download_attempt`, `download_complete`, `policy_violation`, `trust_level_change`, `bot_detected`, `mfa_challenge`.
