---
name: alp-polling-refresh
description: "Polling/auto-refresh with Alpine.js. Use when: live dashboards, real-time stats, notification badge updates, auto-refreshing data without WebSocket."
---

# Alpine Polling & Auto-Refresh

## When to Use

- Live dashboard stats that update every N seconds
- Notification badge count polling
- Download progress or job status polling
- Any real-time-ish data without WebSocket complexity

## Patterns

### Basic Interval Polling

```html
<div x-data="{
  count: 0,
  init() {
    this.fetchCount();
    this._interval = setInterval(() => this.fetchCount(), 30000);
  },
  async fetchCount() {
    try {
      const res = await fetch('/api/v1/notifications/unread-count/');
      if (res.ok) { const data = await res.json(); this.count = data.count; }
    } catch { /* network error — keep last value */ }
  },
  destroy() { clearInterval(this._interval); }
}">
  <span class="relative">
    {% include 'components/_icon.html' with name='bell' size='20' %}
    <span x-show="count > 0" x-cloak x-text="count"
          class="absolute -top-1 -right-1 w-5 h-5 flex items-center justify-center text-xs rounded-full bg-red-500 text-white">
    </span>
  </span>
</div>
```

### Polling with Visibility API (Pause When Hidden)

```html
<div x-data="{
  stats: { users: 0, downloads: 0 },
  polling: true,
  init() {
    this.poll();
    document.addEventListener('visibilitychange', () => {
      this.polling = !document.hidden;
      if (this.polling) this.poll();
    });
  },
  async poll() {
    if (!this.polling) return;
    try {
      const res = await fetch('/api/v1/admin/stats/');
      if (res.ok) this.stats = await res.json();
    } catch { /* ignore */ }
    setTimeout(() => this.poll(), 15000);
  }
}">
  <div class="grid grid-cols-2 gap-4">
    <div class="p-4 rounded bg-[var(--color-surface-alt)]">
      <p class="text-sm text-[var(--color-text-muted)]">Active Users</p>
      <p class="text-2xl font-bold" x-text="stats.users"></p>
    </div>
    <div class="p-4 rounded bg-[var(--color-surface-alt)]">
      <p class="text-sm text-[var(--color-text-muted)]">Downloads Today</p>
      <p class="text-2xl font-bold" x-text="stats.downloads"></p>
    </div>
  </div>
</div>
```

### HTMX Polling Alternative

```html
<!-- For HTML fragment polling, HTMX is simpler -->
<div hx-get="/admin/fragments/stats/"
     hx-trigger="every 30s"
     hx-swap="innerHTML">
  {% include "admin/fragments/stats.html" %}
</div>
```

### Conditional Polling (Stop When Done)

```html
<div x-data="{
  jobId: '{{ job.id }}',
  status: 'processing',
  progress: 0,
  init() { this.checkStatus(); },
  async checkStatus() {
    try {
      const res = await fetch(`/api/v1/jobs/${this.jobId}/status/`);
      if (res.ok) {
        const data = await res.json();
        this.status = data.status;
        this.progress = data.progress;
      }
    } catch { /* retry */ }
    if (this.status === 'processing') {
      setTimeout(() => this.checkStatus(), 3000);
    }
  }
}">
  <div class="w-full bg-[var(--color-border)] rounded h-3">
    <div class="h-3 rounded bg-[var(--color-accent)] transition-all"
         :style="`width: ${progress}%`"></div>
  </div>
  <p class="text-sm mt-2 text-[var(--color-text-muted)]">
    <span x-show="status === 'processing'">Processing... <span x-text="progress + '%'"></span></span>
    <span x-show="status === 'done'" x-cloak class="text-green-400">Complete!</span>
    <span x-show="status === 'failed'" x-cloak class="text-red-400">Failed</span>
  </p>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Polling when tab is hidden | Wasted bandwidth, server load | Use `document.visibilitychange` to pause |
| Fixed `setInterval` for job status | Still polling after job completes | Use `setTimeout` + stop condition |
| No `clearInterval` in `destroy()` | Memory leak on component removal | Always clean up in `destroy()` |
| Polling every 1 second | Server DDoS by own users | Use 15–60s intervals for dashboards |

## Red Flags

- `setInterval` without corresponding `clearInterval` cleanup
- Polling that continues after the component is removed from DOM
- Very short polling intervals (< 5s) without server-side rate limiting
- Polling when HTMX `hx-trigger="every Ns"` would be simpler

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
