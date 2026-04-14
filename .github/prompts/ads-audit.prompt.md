---
agent: 'agent'
description: 'Audit the ads management system including placements, consent gating, affiliate pipeline, and revenue tracking'
tools: ['semantic_search', 'read_file', 'grep_search', 'list_dir', 'file_search']
---

# Ads System Audit

Comprehensive audit of the `apps/ads/` system covering ad serving, affiliate marketing, consent compliance, and revenue integrity.

## 1 — Ad Placement Configuration

### Placement Records
Read `apps/ads/models.py` `AdPlacement` model. Verify placement records exist for all template ad slots:
- Header banner
- Sidebar (upper, lower)
- In-content (after paragraph N)
- Footer
- Interstitial (between pages)
- Sticky (bottom/top anchor)

### Placement-Assignment Wiring
Verify `PlacementAssignment` connects `AdCreative` to `AdPlacement` with proper weights, priority, and lock controls.

### Orphaned Placements
Check for `AdPlacement` records referenced in templates but missing from the database, or database records with no template integration.

## 2 — Ad Format Templates

Verify template support for all ad formats:

| Format | Template Location | Required Elements |
|--------|------------------|-------------------|
| Banner | `templates/ads/banner.html` | Responsive sizing, close button |
| Interstitial | `templates/ads/interstitial.html` | Full-screen overlay, dismiss after N seconds |
| Native | `templates/ads/native.html` | Content-blended styling, "Sponsored" label |
| Video | `templates/ads/video.html` | Player integration, completion tracking |
| Rewarded | `templates/ads/rewarded.html` | Watch-verify-credit flow |
| Sticky | `templates/ads/sticky.html` | Fixed position, close button |

## 3 — Consent-Gated Rendering

Verify ads check consent status before serving:
1. Check for consent scope `ads` in cookie/session before rendering personalized ads
2. Non-personalized ads can show without consent (contextual only)
3. Templates use `{% if consent_ads %}` or equivalent before loading ad network scripts
4. `apps/consent/` integration: `@consent_required` decorator or manual `check_consent()` in ad views

## 4 — ads.txt Compliance

Verify:
1. `ads.txt` URL endpoint exists and is accessible
2. Content lists all authorized seller entries per `AdNetwork` records
3. Format follows IAB specification: `domain, seller_id, relationship_type, cert_authority`
4. No duplicate or contradictory entries

## 5 — Impression Tracking

### AdEvent Creation
Verify `AdEvent` records are created on:
- `impression` — ad rendered in viewport
- `viewable` — ad visible for 1+ second (IAB standard)
- `click` — user click on ad
- `conversion` — tracked action after click

### Deduplication
Check that duplicate impressions within the same session/page are prevented. Verify impression counting logic in `apps/ads/services/analytics.py`.

### Fraud Detection
Check for basic fraud signals: impossible click rates, bot user agents, suspicious IP patterns.

## 6 — Revenue Analytics

Verify analytics pipeline in `apps/ads/services/analytics.py`:
1. eCPM calculation (effective cost per mille)
2. Fill rate tracking (requests vs. filled slots)
3. Revenue aggregation by network, placement, time period
4. ARPU (average revenue per user) computation
5. Network comparison for optimization

Check Celery tasks `aggregate_events` and `cleanup_old_events` schedules.

## 7 — Rewarded Ad Workflow

Verify `RewardedAdConfig` enforcement:
1. **Credits** — Reward amount per completed view
2. **Cooldown** — Minimum time between rewarded views
3. **Daily Limit** — Maximum rewarded views per day per user
4. **Completion Verification** — Ad must play to completion before reward
5. **Premium Hours** — Optional access to premium features duration
6. **Ad-Free Hours** — Optional ad-free period after watching

Check `RewardedAdView` model tracks completion status and prevents re-reward.

## 8 — Concurrency Policy

Verify ad density controls from `AdsSettings`:
1. **Max Ads Per Page** — Total ad unit limit per page load
2. **aggressiveness** setting — Controls ad density level (low/medium/high)
3. **Priority Rules** — Higher-priority placements fill first
4. **Slot Allocation** — When demand exceeds supply, lower-priority slots are empty, not duplicated

## 9 — Responsive Ad Slots

Verify ad containers handle responsive sizing:
1. Mobile: collapse or hide non-essential ad slots
2. Tablet: adjust ad sizes appropriately
3. Desktop: full-size ad units
4. Ad container CSS uses responsive breakpoints, not fixed widths

Check for ad layout shift issues (CLS) — ad containers should have reserved height.

## 10 — Affiliate Pipeline

### Provider Configuration
Verify `AffiliateProvider` records for configured networks (Amazon, AliExpress, Banggood, CJ, ShareASale, etc.) have:
- Valid API credentials
- Cookie duration configured
- Commission rates set

### Click Tracking
Verify `AffiliateLink` → `AffiliateClick` pipeline:
1. Click recorded with UTM parameters
2. IP/user agent captured for attribution
3. Redirect to merchant with proper affiliate parameters

### Product Matching
Check `AffiliateProductMatch` auto-matching logic connects firmware devices to relevant products.

## Report

```
[SEVERITY] Category — Finding
  File: apps/ads/path/to/file.py:LINE
  Impact: Revenue loss / compliance risk / abuse vector
  Fix: Specific remediation
```
