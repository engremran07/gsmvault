---
name: ads-format-video
description: "Video ad format: pre-roll, mid-roll, rewarded. Use when: implementing video ad units, configuring video player integration, rewarded video ads."
---

# Video Ad Format

## When to Use
- Implementing video ad slots (pre-roll, mid-roll, outstream)
- Rewarded video ads (watch to earn credits/downloads)
- `AdUnit.ad_format = "video"` or `"rewarded"` units
- Networks with `supports_video = True`

## Rules
- Video ads MUST have muted autoplay or click-to-play — never unmuted autoplay
- Rewarded videos must complete before granting reward (verified server-side)
- `RewardedAdConfig.min_watch_seconds` enforced — can't skip before threshold
- Video completion tracked via `RewardedAdView.status`
- Outstream video ads pause when scrolled out of viewport

## Patterns

### Video Ad Player Container
```html
{# templates/ads/fragments/video_ad.html #}
<div x-data="videoAd('{{ placement.slot_id }}')" x-cloak
     class="relative w-full max-w-[640px] mx-auto aspect-video
            bg-black rounded-lg overflow-hidden">

  <video x-ref="player" muted playsinline
         @ended="onComplete()"
         @timeupdate="onProgress($event)"
         class="w-full h-full object-contain">
    <source src="{{ creative.video_url }}" type="video/mp4">
  </video>

  {# Progress bar #}
  <div class="absolute bottom-0 left-0 right-0 h-1 bg-gray-700">
    <div class="h-full bg-[var(--color-accent)]"
         :style="`width: ${progress}%`"></div>
  </div>

  {# Skip button — appears after min seconds #}
  <button x-show="canSkip" x-transition
          @click="skip()"
          class="absolute top-3 right-3 px-3 py-1 text-xs text-white bg-black/60 rounded">
    Skip
  </button>
</div>
```

### Server-Side Reward Verification
```python
# apps/ads/services.py
from django.db import transaction

@transaction.atomic
def verify_rewarded_view(*, view_id: int) -> bool:
    """Verify video was watched and grant reward."""
    view = RewardedAdView.objects.select_for_update().get(pk=view_id)
    config = view.config
    if not config or view.reward_granted:
        return False

    min_seconds = config.min_watch_seconds or 30
    if view.watch_duration_seconds < min_seconds:
        return False

    view.status = "completed"
    view.reward_granted = True
    view.reward_type = config.reward_type
    view.reward_amount = config.reward_amount
    view.completed_at = timezone.now()
    view.save()
    return True
```

## Anti-Patterns
- Unmuted autoplay video ads — browsers block and users leave
- Granting rewards client-side without server verification — exploitable
- Video ads without viewport intersection pausing — wastes bandwidth

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
