---
name: affiliate-tracker
description: "Affiliate marketing tracker. Use when: affiliate links, click tracking, commission attribution, AffiliateProvider, AffiliateProduct, AffiliateClick, apps.ads affiliate models."
---

# Affiliate Tracker

You manage the affiliate marketing system in this platform using `apps.ads`.

## Architecture

All affiliate models live in `apps.ads`:

| Model | Purpose |
| --- | --- |
| `AffiliateProvider` | Network config (Amazon, AliExpress, Banggood, CJ, ShareASale), API keys, cookie duration |
| `AffiliateProductCategory` | Product taxonomy |
| `AffiliateProduct` | Product listings with commission rates and deep links |
| `AffiliateSource` | Traffic source tracking |
| `AffiliateLink` | Tracked outbound links with UTM parameters |
| `AffiliateClick` | Every click recorded for commission attribution |
| `AffiliateProductMatch` | Auto-matching firmware device models to relevant affiliate products |

## Rules

1. Every outbound affiliate link goes through `/api/v1/ads/affiliate/redirect/<link_id>/` for tracking
2. Record click with: IP (hashed), user agent, referrer, UTM params, timestamp
3. Cookie duration per provider config — attribute commission within window
4. Auto-match products to devices using `AffiliateProductMatch` (firmware model → relevant accessories)
5. Revenue events emitted to `apps.analytics` for attribution reporting
6. Never expose raw API keys in responses — keys stored encrypted in `AffiliateProvider`
7. UTM parameters: `utm_source`, `utm_medium`, `utm_campaign`, `utm_content`

## API Endpoints

| Endpoint | Method | Purpose |
| --- | --- | --- |
| `/api/v1/ads/affiliate/links/` | GET | List affiliate links for current page/device |
| `/api/v1/ads/affiliate/redirect/<id>/` | GET | Track click and redirect to affiliate URL |
| `/api/v1/ads/affiliate/products/` | GET | Matched products for a device |
| `/api/v1/ads/affiliate/stats/` | GET | Commission stats (admin/affiliate) |

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
