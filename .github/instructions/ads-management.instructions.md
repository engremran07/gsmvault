---
applyTo: 'apps/ads/**'
---

# Ads Management Instructions

## System Overview

`apps.ads` is a full autonomous ads management system with 18+ models covering ad serving, campaigns, rewarded ads, auto-ads scanning, and a multi-network affiliate pipeline.

## Core Ad Serving Pipeline

```
Campaign → AdCreative → PlacementAssignment → AdPlacement → Template Slot
```

1. **Campaign**: Budget, targeting rules, scheduling (`start_at`/`end_at`), status
2. **AdCreative**: Title, body, image, CTA URL, click/impression counts
3. **PlacementAssignment**: Weighted creative ↔ placement binding with lock/priority
4. **AdPlacement**: Named slot in template (header, sidebar, in-content, footer)
5. **Template Slot**: `{% include %}` tag that calls the ad serving logic

## Key Models

| Model | Purpose |
|---|---|
| `AdsSettings` | Singleton: `ads_enabled`, `ad_networks_enabled`, `affiliate_enabled`, `aggressiveness` |
| `AdNetwork` | 18 network types with priority/status |
| `AdUnit` | Unit config per network (format: banner/interstitial/native/video/rewarded/sticky) |
| `AdPlacement` | Named placement slots in templates |
| `Campaign` | Budget, caps, targeting, scheduling, status |
| `AdCreative` | Creative assets with click/impression counters |
| `PlacementAssignment` | Weighted creative ↔ placement binding |
| `AdEvent` | Analytics events (impression, click, viewable, conversion) |
| `RewardedAdConfig` | Reward rules (credits, premium_hours, cooldown, daily_limit) |
| `RewardedAdView` | Per-user reward tracking |
| `AutoAdsScanResult` | AI template scan: discovered placements, confidence scores |

## Rewarded Ads

Users watch ads to earn credits or premium time:

```python
# RewardedAdConfig fields:
# - credits_earned: Decimal
# - premium_hours_earned: int
# - ad_free_hours_earned: int
# - cooldown_minutes: int
# - daily_limit: int

# Enforcement:
# 1. Check daily_limit (RewardedAdView count for today)
# 2. Check cooldown (last RewardedAdView.created_at + cooldown_minutes)
# 3. Record RewardedAdView on completion
# 4. Credit user wallet or grant premium time
```

## Affiliate Pipeline

```
AffiliateProvider → AffiliateProduct → AffiliateLink → AffiliateClick
```

| Model | Purpose |
|---|---|
| `AffiliateProvider` | Network config (Amazon, AliExpress, CJ, etc.), API keys, cookie duration |
| `AffiliateProductCategory` | Product taxonomy |
| `AffiliateProduct` | Product listings with commission rates and deep links |
| `AffiliateSource` | Traffic source tracking |
| `AffiliateLink` | Tracked outbound links with UTM parameters |
| `AffiliateClick` | Every click recorded for commission attribution |
| `AffiliateProductMatch` | Auto-matching device models to products |

## Service Layer (`apps/ads/services/`)

| Service | Purpose |
|---|---|
| `rotation.py` | Weighted creative rotation per placement |
| `targeting.py` | Campaign targeting (geo, device, user segment, time-of-day) |
| `analytics.py` | Event tracking and aggregation |
| `affiliate.py` | Link resolution and click attribution |
| `ai_optimizer.py` | AI placement optimization and creative scoring |

## Consent-Gated Ad Serving — MANDATORY

All personalized ad serving MUST check user consent first:

```python
from apps.consent.utils import check_consent

def serve_ad(request, placement_slug):
    # Functional ads always shown; personalized ads require consent
    has_ads_consent = check_consent(request, "ads")
    if has_ads_consent:
        # Serve personalized/targeted ad
        return get_targeted_ad(request.user, placement_slug)
    else:
        # Serve generic/non-personalized ad
        return get_generic_ad(placement_slug)
```

## Template Integration

Ads are placed in templates via named placement slots:

```html
{% load ads_tags %}
{% render_ad_placement "sidebar_top" %}
{% render_ad_placement "in_content_1" %}
{% render_ad_placement "footer_banner" %}
```

## Celery Tasks

| Task | Schedule | Purpose |
|---|---|---|
| `aggregate_events` | Periodic | Aggregate AdEvent data for dashboards |
| `cleanup_old_events` | Daily | Remove stale events past retention |
| `scan_templates_for_ad_placements` | On demand | AI scan templates for optimal slots |
| `ai_optimize_ad_placements` | Weekly | AI analysis with optimization suggestions |

## API Endpoints

Under `/api/v1/ads/`:
- Ad serving endpoints (GET)
- Click tracking (POST)
- Affiliate link resolution (GET/POST)
- Rewarded ad completion callback (POST)

## Forbidden Practices

- Never serve personalized ads without consent check
- Never hardcode ad network credentials in source code
- Never bypass campaign budget/daily caps
- Never auto-approve affiliate products without admin review
- Never track users who have opted out of analytics consent
