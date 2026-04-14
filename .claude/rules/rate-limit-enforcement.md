---
paths: ["apps/security/**", "apps/firmwares/**", "apps/devices/**"]
---

# Rate Limit Enforcement

The platform has TWO separate, non-overlapping rate-limiting systems. Conflating them is a critical architecture violation that creates security gaps.

## System Separation — MANDATORY

- **WAF rate limits** (`apps.security`): IP/path-based DDoS and bot protection, enforced at middleware level via `RateLimitRule`, `BlockedIP`, `CrawlerRule`.
- **Download quotas** (`apps.firmwares` + `apps.devices`): Per-user/tier download limits, enforced at firmware download time via `DownloadToken`, `DownloadSession`, `QuotaTier`.
- NEVER import `RateLimitRule`, `BlockedIP`, or `CrawlerRule` in firmware code.
- NEVER import `DownloadToken`, `DownloadSession`, or `AdGateLog` in security code.
- NEVER reference WAF models in download service functions or vice versa.

## WAF Rate Limiting (`apps.security`)

- `RateLimitRule` defines per-path rules: `limit`, `window_seconds`, `action` (throttle/block/log).
- `BlockedIP` provides permanent or timed IP blocks — used for identified attackers.
- `CrawlerRule` handles bot-specific rate limiting with `requests_per_minute` and `action` (allow/throttle/block/challenge).
- Configuration via `SecurityConfig` singleton: `crawler_guard_enabled`, `crawler_default_action`.
- All WAF events logged to `SecurityEvent` with type: `rate_limited`, `ip_blocked`, `crawler_blocked`.
- NEVER bypass WAF for internal services without explicit allowlisting.

## Download Quota System (`apps.firmwares` + `apps.devices`)

- `QuotaTier` defines tier limits: daily/hourly caps, `requires_ad`, `can_bypass_captcha`.
- `DownloadToken` is a single-use, per-firmware, per-user token with HMAC signature, ad-gate requirement, and expiry.
- Tiers: Free (ad-gated) → Registered → Subscriber → Premium — each with increasing limits.
- Download enforcement functions live in `apps.firmwares.download_service` — `create_download_token()`, `validate_download_token()`, `check_rate_limit()`.
- `AdGateLog` tracks ad completion for ad-gated downloads — credits earned, watched seconds.
- NEVER grant unlimited downloads — even Premium tier has generous but finite daily limits.

## DRF API Throttling

- 6 throttle classes in `apps.core.throttling`: `UploadRateThrottle`, `DownloadRateThrottle`, `APIRateThrottle`, and 3 others.
- EVERY API endpoint MUST have a `throttle_classes` declaration — NEVER rely solely on global defaults.
- Anonymous endpoints: stricter throttle rates than authenticated endpoints.
- Throttle responses MUST include `Retry-After` header (DRF handles this automatically).
