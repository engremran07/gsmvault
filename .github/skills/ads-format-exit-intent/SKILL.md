---
name: ads-format-exit-intent
description: "Exit-intent ads: mouse tracking, popup trigger. Use when: showing ads when user moves cursor to close/leave, implementing exit popups, bounce reduction."
---

# Exit-Intent Ad Format

## When to Use
- Displaying an ad/offer when user moves cursor towards browser close
- Implementing exit-intent popups for promotions or newsletter signup
- Reducing bounce rate with last-chance offers
- Desktop-only — exit intent not reliable on mobile

## Rules
- Exit-intent ONLY on desktop — mobile has no reliable cursor tracking
- Show once per session maximum — stored in `sessionStorage`
- Must have a clear close button and respect consent
- Never trigger on internal navigation — only on actual page exit intent
- Combine with `ads-consent-gating` — check consent before showing

## Patterns

### Exit-Intent Detection
```javascript
// static/js/src/ads/exit-intent.js
function initExitIntent(callback, { sensitivity = 20, cooldownMs = 5000 } = {}) {
  if (sessionStorage.getItem('exit_intent_shown')) return;

  let lastY = 0;
  const handler = (e) => {
    if (e.clientY <= sensitivity && e.clientY < lastY) {
      sessionStorage.setItem('exit_intent_shown', 'true');
      document.removeEventListener('mousemove', handler);
      callback();
    }
    lastY = e.clientY;
  };

  // Delay activation to avoid false triggers on page load
  setTimeout(() => {
    document.addEventListener('mousemove', handler);
  }, cooldownMs);
}
```

### Exit-Intent Ad Template
```html
{# templates/ads/fragments/exit_intent.html #}
<div x-data="{ showExitAd: false }" x-cloak
     x-init="initExitIntent(() => { showExitAd = true })"
     x-show="showExitAd"
     class="fixed inset-0 z-50 flex items-center justify-center bg-black/70">

  <div class="relative bg-[var(--color-bg-primary)] rounded-xl max-w-lg w-full mx-4 p-8">
    <button @click="showExitAd = false"
            class="absolute top-3 right-3"
            aria-label="Close">
      <i data-lucide="x" class="w-5 h-5"></i>
    </button>

    <h3 class="text-xl font-bold mb-4">Before you go...</h3>
    <div class="ad-content" data-slot="exit-intent">
      {{ placement.render_code|safe }}
    </div>
  </div>
</div>
```

## Anti-Patterns
- Attempting exit-intent on mobile/touch devices — unreliable
- Showing exit-intent every page visit — must be once per session
- Blocking the entire page without a close button
- Triggering on scroll-up — that's not exit intent, that's scroll direction

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
