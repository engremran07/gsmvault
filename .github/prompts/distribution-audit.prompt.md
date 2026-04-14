---
agent: 'agent'
description: 'Audit the content distribution system including social connectors, circuit breakers, and retry logic'
tools: ['semantic_search', 'read_file', 'grep_search', 'list_dir', 'file_search']
---

# Distribution System Audit

Audit the `apps/distribution/` social content syndication system for reliability, correctness, and completeness.

## 1 — Connector Health

Scan `apps/distribution/` for all social platform connectors:

| Platform | Expected Connector | Status Check |
|----------|--------------------|--------------|
| Twitter/X | OAuth credentials, API v2 | Token validity, rate limit status |
| LinkedIn | Share API credentials | Token expiry, refresh capability |
| Facebook | Graph API, Page token | Long-lived token, page permissions |
| Telegram | Bot API token | Bot alive check, channel access |
| Discord | Webhook URL | Webhook validity |
| Reddit | OAuth app credentials | Token refresh, karma checks |
| Pinterest | API token | Pin creation permissions |
| WhatsApp | Business API | Template approval status |
| Email Newsletter | SMTP / Mailchimp / SendGrid | Delivery credentials |
| RSS/Atom | Feed endpoint | Feed generation health |
| WebSub | Hub configuration | Hub subscription status |

Verify each connector has:
- Credential storage (encrypted or env-var based)
- Connection test method
- Error handling for expired/invalid credentials

## 2 — Credential Validation

For each configured connector:
1. API tokens are not hardcoded in source
2. Token refresh logic exists for OAuth-based platforms
3. Expired tokens are detected before distribution attempt
4. Failed credential validation logs a `SecurityEvent` or equivalent

## 3 — Circuit Breaker State

Verify circuit breaker pattern implementation:

```
CLOSED → OPEN (after N consecutive failures)
OPEN → HALF-OPEN (after cooldown period)
HALF-OPEN → CLOSED (on successful probe) or OPEN (on failure)
```

Check:
1. Circuit breaker exists per platform connector
2. Failure threshold is configurable
3. Cooldown period is appropriate (not too short/long)
4. Half-open state sends a single probe request
5. Circuit state persists across process restarts (Redis/DB)

## 4 — Rate Limits Per Platform

Verify per-platform rate limiting respects each API's limits:

| Platform | Rate Limit | Window |
|----------|-----------|--------|
| Twitter | 300 tweets/3h | Per app |
| LinkedIn | 100 shares/day | Per member |
| Facebook | 200 posts/hour | Per page |
| Telegram | 30 messages/second | Per bot |
| Reddit | 1 post/10 minutes | Per account |

Check that:
1. Rate limit tracking exists per platform
2. Exceeded limits queue instead of drop
3. Rate limit headers from API responses are parsed and respected
4. No burst sending that triggers platform bans

## 5 — Message Builder

Verify `ShareTemplate` / message builder produces platform-appropriate content:

1. **Twitter** — Character limit (280), hashtag extraction, URL shortening
2. **LinkedIn** — Professional tone, article format, image sizing
3. **Facebook** — Open Graph preview, link sharing, image dimensions
4. **Telegram** — Markdown formatting, inline keyboard buttons
5. **Discord** — Rich embed format, webhook payload structure
6. **Email** — HTML template with plain text fallback

Check `ContentVariant` model for per-platform variations of the same content.

## 6 — UTM Injection

Verify all outbound links include UTM parameters:
```
utm_source=platform_name
utm_medium=social
utm_campaign=auto_publish (or specific campaign name)
utm_content=post_id (for A/B tracking)
```

Check that UTM parameters are:
1. Appended to all links in distributed content
2. Not duplicated if already present
3. Properly URL-encoded
4. Tracked back in `apps/analytics/`

## 7 — Deduplication

Verify duplicate distribution prevention:
1. Same content cannot be posted to same channel within N hours
2. Content hash or ID tracked per platform per post
3. Retry of failed posts does not create duplicates on partial success
4. Idempotent job execution — re-running same job produces no new posts

## 8 — Auto-Publish Configuration

Verify signal-driven auto-publish:
1. Blog post `post_save` signal triggers distribution
2. Only `status=published` posts trigger (not drafts)
3. Auto-publish respects `SharePlan` configuration
4. Distribution jobs are queued via Celery (not synchronous)
5. Auto-publish can be disabled globally via settings

## 9 — Retry Logic

Verify failed distribution job handling:
1. Exponential backoff: 1s → 2s → 4s → 8s → ... up to max
2. Maximum retry count configured (e.g., 5 attempts)
3. Dead letter handling — permanently failed jobs logged with error
4. Retry does not duplicate content (idempotency)
5. Different error types get different retry strategies (transient vs. permanent)

## 10 — WebSub Integration

Verify WebSub (PubSubHubbub) implementation:
1. Hub notification on content publish
2. Subscriber verification (intent verification callback)
3. Hub URL configured in feed `<link rel="hub">`
4. Lease renewal handling for subscriptions
5. Content delivery to subscribers with proper `Content-Type`

## Report

```
[SEVERITY] Category — Finding
  File: apps/distribution/path.py:LINE
  Risk: Distribution failure / duplicate posting / credential leak
  Fix: Remediation steps
```

Summary with per-connector health status and overall distribution reliability score.
