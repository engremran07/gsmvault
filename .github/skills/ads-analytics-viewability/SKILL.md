---
name: ads-analytics-viewability
description: "Ad viewability measurement: viewport intersection. Use when: measuring if ads are actually seen, IAB viewability standards, Intersection Observer tracking."
---

# Ad Viewability Measurement

## When to Use
- Measuring whether ads are actually viewed by users (not just loaded)
- Implementing IAB viewability standard (50% pixels, 1 second continuous)
- Distinguishing rendered impressions from viewable impressions
- Optimizing placement positions based on viewability scores

## Rules
- IAB standard: display ad = 50% pixels visible for ≥1 continuous second
- Video ad = 50% pixels visible for ≥2 continuous seconds
- Use `IntersectionObserver` at `threshold: 0.5` + duration timer
- Record `AdEvent(event_type="viewable")` separately from `"impression"`
- Viewability rate = viewable_impressions / total_impressions × 100

## Patterns

### Viewability Observer
```javascript
// static/js/src/ads/viewability.js
function trackViewability(adSlots) {
  const timers = new Map();

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      const slotId = entry.target.dataset.slot;

      if (entry.isIntersecting && entry.intersectionRatio >= 0.5) {
        // Start timing — need 1 second continuous visibility
        if (!timers.has(slotId)) {
          timers.set(slotId, setTimeout(() => {
            recordViewable(slotId);
            observer.unobserve(entry.target);
            timers.delete(slotId);
          }, 1000));
        }
      } else {
        // Left viewport before 1 second — cancel
        if (timers.has(slotId)) {
          clearTimeout(timers.get(slotId));
          timers.delete(slotId);
        }
      }
    });
  }, { threshold: 0.5 });

  adSlots.forEach(slot => observer.observe(slot));
}

function recordViewable(slotId) {
  navigator.sendBeacon('/api/v1/ads/events/', JSON.stringify({
    slot_id: slotId,
    event_type: 'viewable',
    timestamp: Date.now(),
  }));
}
```

### Viewability Rate Calculation
```python
# apps/ads/services/analytics.py
def get_viewability_rate(*, placement_id: int, days: int = 30) -> Decimal:
    cutoff = timezone.now() - timedelta(days=days)
    events = AdEvent.objects.filter(
        placement_id=placement_id, created_at__gte=cutoff,
    )
    impressions = events.filter(event_type="impression").count()
    viewable = events.filter(event_type="viewable").count()
    if impressions == 0:
        return Decimal("0")
    return Decimal(viewable) / Decimal(impressions) * 100
```

## Anti-Patterns
- Counting DOM insertion as viewable — must verify viewport + duration
- No minimum time threshold — brief scroll-past is not a view
- Using `getBoundingClientRect` polling instead of `IntersectionObserver`

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
