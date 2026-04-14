---
name: ads-analytics-impressions
description: "Impression tracking: viewability, AdEvent creation. Use when: recording ad impressions, tracking viewable impressions, building ad analytics."
---

# Impression Tracking

## When to Use
- Recording when an ad is rendered on page
- Tracking viewable impressions (IAB standard: 50% visible for 1 second)
- Creating `AdEvent` records for analytics
- Building impression dashboards and reporting

## Rules
- Impression = ad rendered in DOM; Viewable impression = ad seen by user
- Store in `AdEvent(event_type="impression")` with placement and creative FKs
- Batch impressions — don't create DB records on every page load in real-time
- Use Celery task `aggregate_events` for periodic aggregation
- Include metadata: `page_url`, `viewport_zone`, `user_agent`

## Patterns

### Client-Side Impression Beacon
```javascript
// static/js/src/ads/tracking.js
function trackImpression(slotId, creativeId) {
  const data = {
    slot_id: slotId,
    creative_id: creativeId,
    event_type: 'impression',
    page_url: window.location.pathname,
    timestamp: Date.now(),
  };

  // Use sendBeacon for reliable delivery
  navigator.sendBeacon('/api/v1/ads/events/', JSON.stringify(data));
}

// Fire when ad slot enters viewport
function observeAdSlots() {
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const slot = entry.target;
        trackImpression(slot.dataset.slot, slot.dataset.creativeId);
        observer.unobserve(slot);
      }
    });
  }, { threshold: 0.5 });

  document.querySelectorAll('.ad-slot[data-slot]').forEach(el => observer.observe(el));
}
```

### Server-Side Event Recording
```python
# apps/ads/api.py
from rest_framework.decorators import api_view, throttle_classes
from apps.core.throttling import APIRateThrottle

@api_view(["POST"])
@throttle_classes([APIRateThrottle])
def record_ad_event(request):
    """Record ad impression/click event."""
    AdEvent.objects.create(
        event_type=request.data.get("event_type", "impression"),
        placement_id=request.data.get("slot_id"),
        creative_id=request.data.get("creative_id"),
        user=request.user if request.user.is_authenticated else None,
        ip_address=get_client_ip(request),
        page_url=request.data.get("page_url", ""),
    )
    return Response(status=204)
```

## Anti-Patterns
- Creating `AdEvent` synchronously on every page load — performance bottleneck
- Counting DOM render as viewable impression — must use IntersectionObserver
- No deduplication — counting same impression multiple times per session
- Impression tracking without consent check (see `ads-consent-gating`)

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
