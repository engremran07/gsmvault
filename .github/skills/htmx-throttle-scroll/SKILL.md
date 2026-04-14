---
name: htmx-throttle-scroll
description: "Scroll throttling with hx-trigger='scroll throttle:200ms'. Use when: loading content on scroll, lazy loading sections, scroll-triggered animations with rate limiting."
---

# HTMX Scroll Throttling

## When to Use

- Loading more content as user scrolls (throttled, not every pixel)
- Lazy loading images or sections on scroll
- Scroll-triggered data fetching with rate limiting
- Parallax-like scroll effects with server data

## Rules

1. Use `hx-trigger="scroll throttle:200ms"` — limits requests to once per 200ms
2. `throttle` is different from `delay` — throttle sends immediately, then waits
3. Combine with a sentinel element for infinite scroll patterns
4. Always specify the scroll target: `from:window` or `from:closest .scrollable`

## Patterns

### Scroll-Triggered Lazy Load

```html
<div class="overflow-y-auto max-h-96" id="log-container">
  <div id="log-content">
    {% include "admin/fragments/log_rows.html" %}
  </div>
  <div hx-get="{% url 'admin:load_more_logs' %}"
       hx-trigger="intersect once"
       hx-target="#log-content"
       hx-swap="beforeend"
       hx-indicator="#log-spinner">
    <span id="log-spinner" class="htmx-indicator">
      {% include "components/_loading.html" %}
    </span>
  </div>
</div>
```

### Throttled Scroll Position Tracking

```html
<div hx-get="{% url 'analytics:track_scroll' %}"
     hx-trigger="scroll from:window throttle:5000ms"
     hx-swap="none"
     hx-vals='js:{"scroll_pct": Math.round(window.scrollY / document.body.scrollHeight * 100)}'>
</div>
```

### Scroll-to-Load in Scrollable Container

```html
<div class="overflow-y-auto h-[600px]" id="chat-messages">
  {% for msg in messages %}
  <div class="message">{{ msg.text }}</div>
  {% endfor %}

  {# Load older messages when scrolling to top #}
  <div hx-get="{% url 'forum:older_messages' topic.pk %}"
       hx-trigger="intersect once threshold:0.1"
       hx-target="this"
       hx-swap="outerHTML">
  </div>
</div>
```

## Anti-Patterns

```html
<!-- WRONG — no throttle (fires on every scroll pixel) -->
<div hx-get="/load/" hx-trigger="scroll from:window">

<!-- WRONG — throttle too aggressive for content loading -->
<div hx-trigger="scroll throttle:50ms">  {# 20 requests/second #}
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| `scroll` trigger without throttle | Floods server with requests | Add `throttle:200ms` minimum |
| Throttle under 100ms | Still too many requests | Use 200ms+ for scroll events |
| Missing `from:` target | Listens on wrong scroll container | Specify `from:window` or container |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
