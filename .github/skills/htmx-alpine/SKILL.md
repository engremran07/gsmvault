---
name: htmx-alpine
description: "HTMX and Alpine.js interactive patterns for Django. Use when: adding AJAX behavior, live search, partial page updates, SPA-like interactions, modals, dropdowns, tabs, infinite scroll, form submissions without page reload, client-side state management."
---

# HTMX + Alpine.js Patterns

## When to Use

- Adding dynamic behavior to Django templates without full SPA
- Live search, filtering, pagination without page reload
- Modal dialogs, dropdowns, tabs, accordions
- Form submission with inline validation
- Infinite scroll, lazy loading
- Toast notifications, confirmation dialogs
- Any interaction that would traditionally require jQuery/React

## Rules

1. **HTMX for server communication** — fetches HTML fragments from Django views
2. **Alpine.js for client-side state** — toggles, animations, form validation, theme switching
3. **Never mix concerns** — HTMX talks to server, Alpine handles UI state
4. **CSRF token on all HTMX requests** — `hx-headers='{"X-CSRFToken": "{{ csrf_token }}"}'` on `<body>` tag
5. **HTMX fragments are plain HTML** — no JSON, no JavaScript in responses
6. **Views detect HTMX** — `request.headers.get("HX-Request")` to return fragment vs full page
7. **Alpine stores for global state** — `$store.theme`, `$store.notify`, `$store.confirm`
8. **Alpine `x-data` for local state** — modals, forms, toggles
9. **Loading indicators required** — `hx-indicator` on every HTMX trigger
10. **Graceful degradation** — pages work without JavaScript (basic HTML forms)
11. **Use `x-show` not `<template x-if>` when toggling Lucide icons** — Lucide renders SVG once at DOMContentLoaded. If `x-if` destroys/recreates DOM, new icon elements never render. Use `x-show` to toggle visibility of pre-rendered icons.

## CRITICAL: x-cloak Anti-FOUC Pattern

**Every Alpine.js conditional element MUST have `x-cloak`** to prevent flash of content before Alpine initializes.

### How it works
1. CSS rule `[x-cloak] { display: none !important; }` is loaded in `_head.html` as an inline `<style>` (before any scripts)
2. Elements with `x-cloak` are hidden immediately by CSS
3. Alpine.js automatically removes `x-cloak` when it initializes the element
4. The element then follows its `x-show` / `x-if` directive

### Where x-cloak is required
```html
{# Search results dropdown — hidden until user focuses input #}
<div id="search-results" x-show="focused" x-cloak class="...">

{# Mobile menu — hidden until hamburger clicked #}
<div x-show="mobileOpen" x-cloak class="...">

{# Modal — hidden until triggered #}
<div x-show="open" x-cloak class="...">

{# Filter panel — toggled by button #}
<div x-show="filtersOpen" x-cloak class="...">

{# Any element with x-show or x-if — ALWAYS add x-cloak #}
```

### Common mistake
```html
{# WRONG — visible flash before Alpine hides it #}
<div x-show="open" class="...">

{# CORRECT — hidden by CSS until Alpine manages it #}
<div x-show="open" x-cloak class="...">
```

## CRITICAL: Centralized Notification System

the platform uses two Alpine.js stores (defined in `static/js/src/notifications.js`) — **never use browser `alert()` or `confirm()`**.

### Toast Notifications (`$store.notify`)
```javascript
// Show a toast — auto-dismisses after duration (ms)
$store.notify.show('File uploaded successfully', 'success', 5000)
$store.notify.show('Network error', 'error', 8000)
$store.notify.show('Processing...', 'warning', 5000)
$store.notify.show('New firmware available', 'info', 5000)
```
Types: `success`, `error`, `warning`, `info`. Rendered by `_messages.html`.

### Confirmation Dialog (`$store.confirm`)
```javascript
// Returns a Promise — resolved when user clicks confirm/cancel
const confirmed = await $store.confirm.ask('Delete firmware?', 'This cannot be undone.')
if (confirmed) { /* proceed */ }
```
Rendered by `_confirm_dialog.html` (included in `_base.html`).

### Django Messages Integration
`_messages.html` automatically converts Django messages framework messages into `$store.notify` toasts on page load:
```html
{% for message in messages %}
<script nonce="{{ request.csp_nonce }}">
  document.addEventListener('alpine:init', () => {
    Alpine.store('notify').show('{{ message|escapejs }}', '{{ message.tags }}');
  });
</script>
{% endfor %}
```

## HTMX Patterns

### Live Search

```html
<div class="relative w-full max-w-xl" x-data="{ focused: false }">
  <input type="search"
         name="q"
         placeholder="Search firmware, devices, brands..."
         hx-get="{% url 'firmwares:search' %}"
         hx-trigger="keyup changed delay:300ms, search"
         hx-target="#search-results"
         hx-indicator="#search-spinner"
         @focus="focused = true"
         @blur="setTimeout(() => focused = false, 200)"
         autocomplete="off"
         class="w-full px-4 py-2 bg-[var(--color-input)] border border-[var(--color-input-border)] rounded-[var(--radius-md)]">

  <div id="search-spinner" class="htmx-indicator absolute right-3 top-2.5">
    {% include "components/_loading.html" %}
  </div>

  {# x-cloak REQUIRED — prevents visible empty box before Alpine init #}
  <div id="search-results" x-show="focused" x-cloak
       class="absolute top-full left-0 right-0 mt-1 bg-[var(--color-bg-secondary)] border border-[var(--color-border)] rounded-lg shadow-xl z-50 max-h-80 overflow-y-auto">
  </div>
</div>
```

### Infinite Scroll

```html
{% for firmware in page_obj %}
  {% include "components/_card.html" %}
  {% if forloop.last and page_obj.has_next %}
    <div hx-get="?page={{ page_obj.next_page_number }}"
         hx-trigger="revealed"
         hx-swap="afterend"
         hx-indicator="#load-more-spinner">
    </div>
  {% endif %}
{% endfor %}
<div id="load-more-spinner" class="htmx-indicator text-center py-4">
  {% include "components/_loading.html" %}
</div>
```

### Form Submission

```html
<form hx-post="{% url 'comments:create' %}"
      hx-target="#comment-list"
      hx-swap="afterbegin"
      hx-on::after-request="this.reset()">
  {% csrf_token %}
  <textarea name="body" required
            class="w-full p-3 bg-[var(--color-input)] border border-[var(--color-input-border)] rounded-[var(--radius-md)]"
            placeholder="Write a comment..."></textarea>
  <button type="submit" class="mt-2 px-4 py-2 bg-[var(--color-accent)] text-[var(--color-accent-text)] rounded-[var(--radius-md)]">
    Post Comment
  </button>
</form>
```

### Delete with Confirmation (using $store.confirm)

```html
<button @click="
  if (await $store.confirm.ask('Delete comment?', 'This cannot be undone.')) {
    htmx.ajax('DELETE', '{% url 'comments:delete' pk=comment.pk %}', { target: closest('.comment-item'), swap: 'outerHTML' });
  }
" class="text-[var(--color-error)] hover:underline text-sm">
  Delete
</button>
```

### Tab Navigation

```html
<div class="border-b border-[var(--color-border)]">
  <nav class="flex gap-4" role="tablist">
    <button hx-get="{% url 'user:tab' tab='overview' %}"
            hx-target="#tab-content"
            class="tab-btn {% if active_tab == 'overview' %}active{% endif %}">
      Overview
    </button>
    <button hx-get="{% url 'user:tab' tab='downloads' %}"
            hx-target="#tab-content"
            class="tab-btn">
      Downloads
    </button>
  </nav>
</div>
<div id="tab-content">
  {% include "user/_tab_overview.html" %}
</div>
```

## Alpine.js Patterns

### Modal Dialog

```html
<div x-data="{ open: false }">
  <button @click="open = true" class="btn-primary">Open Modal</button>

  <div x-show="open" x-cloak class="fixed inset-0 z-50 flex items-center justify-center"
       @keydown.escape.window="open = false">
    <div class="absolute inset-0 bg-black/50" @click="open = false"></div>
    <div class="relative bg-[var(--color-card)] rounded-[var(--radius-lg)] shadow-[var(--shadow-lg)] p-6 max-w-lg w-full mx-4"
         @click.stop>
      <h2 class="text-xl font-semibold mb-4">Title</h2>
      <div class="mt-6 flex justify-end gap-3">
        <button @click="open = false" class="btn-secondary">Cancel</button>
        <button class="btn-primary">Confirm</button>
      </div>
    </div>
  </div>
</div>
```

### Dropdown Menu

```html
<div x-data="{ open: false }" class="relative">
  <button @click="open = !open" @click.outside="open = false">
    <span>{{ user.username }}</span>
    <i data-lucide="chevron-down" class="w-4 h-4 transition-transform"
       :class="open && 'rotate-180'"></i>
  </button>

  <div x-show="open" x-cloak x-transition
       class="absolute right-0 mt-2 w-48 bg-[var(--color-card)] border border-[var(--color-border)] rounded-[var(--radius-md)] shadow-[var(--shadow-lg)] py-1 z-50">
    <a href="{% url 'users:profile' %}" class="block px-4 py-2 hover:bg-[var(--color-bg-tertiary)]">Profile</a>
    <a href="{% url 'users:settings' %}" class="block px-4 py-2 hover:bg-[var(--color-bg-tertiary)]">Settings</a>
    <hr class="border-[var(--color-border)] my-1">
    <a href="{% url 'account_logout' %}" class="block px-4 py-2 text-[var(--color-error)]">Logout</a>
  </div>
</div>
```

### Form Validation

```html
<form x-data="{ email: '', password: '', errors: {} }"
      @submit.prevent="
        errors = {};
        if (!email) errors.email = 'Email required';
        if (password.length < 8) errors.password = 'Min 8 characters';
        if (Object.keys(errors).length === 0) $el.submit();
      ">
  <div class="mb-4">
    <input type="email" x-model="email"
           :class="errors.email && 'border-[var(--color-error)]'"
           class="w-full px-3 py-2 bg-[var(--color-input)] border border-[var(--color-input-border)] rounded-[var(--radius-md)]">
    <p x-show="errors.email" x-text="errors.email"
       class="text-[var(--color-error)] text-sm mt-1"></p>
  </div>
</form>
```

### Alpine Store Registration

All global stores are registered in `static/js/src/*.js` using the `alpine:init` event:

```javascript
// static/js/src/theme-switcher.js
document.addEventListener('alpine:init', () => {
  Alpine.store('theme', {
    current: localStorage.getItem('theme') || 'dark',
    set(name) {
      this.current = name;
      document.documentElement.setAttribute('data-theme', name);
      localStorage.setItem('theme', name);
    }
  });
});

// static/js/src/notifications.js
document.addEventListener('alpine:init', () => {
  Alpine.store('notify', { /* toast methods */ });
  Alpine.store('confirm', { /* dialog methods */ });
});
```

## Django View Pattern

```python
from django.http import HttpRequest, HttpResponse
from django.shortcuts import render

def firmware_list(request: HttpRequest) -> HttpResponse:
    """Return full page or HTMX fragment based on request type."""
    firmwares = Firmware.objects.select_related("device").all()

    q = request.GET.get("q")
    if q:
        firmwares = firmwares.filter(name__icontains=q)

    if request.headers.get("HX-Request"):
        return render(request, "firmwares/fragments/list.html", {"firmwares": firmwares})
    return render(request, "firmwares/list.html", {"firmwares": firmwares})
```

## Admin Sidebar Collapse

The admin sidebar uses Alpine.js for collapse/expand with localStorage persistence:

```html
<div x-data="{
  sidebarOpen: JSON.parse(localStorage.getItem('admin-sidebar-open') ?? 'true'),
  toggle() {
    this.sidebarOpen = !this.sidebarOpen;
    localStorage.setItem('admin-sidebar-open', JSON.stringify(this.sidebarOpen));
  }
}">
  {# Desktop sidebar — collapsible #}
  <aside :class="sidebarOpen ? 'w-64' : 'w-16'" class="transition-all duration-300 hidden lg:block">
    <button @click="toggle()" class="p-2 hover:bg-[var(--color-bg-tertiary)] rounded-[var(--radius-md)]">
      <i data-lucide="panel-left-close" class="w-5 h-5" x-show="sidebarOpen" x-cloak></i>
      <i data-lucide="panel-left-open" class="w-5 h-5" x-show="!sidebarOpen" x-cloak></i>
    </button>
    {# Nav links — labels hidden when collapsed #}
    <span x-show="sidebarOpen" x-cloak class="ml-3">Dashboard</span>
  </aside>

  {# Mobile overlay — separate toggle #}
  <div x-show="mobileMenuOpen" x-cloak @click.self="mobileMenuOpen = false"
       class="fixed inset-0 z-40 bg-black/50 lg:hidden">
    <aside class="w-64 h-full bg-[var(--color-bg-secondary)] shadow-xl">
      {# Full sidebar content #}
    </aside>
  </div>
</div>
```

## Admin Tab Switching

Alpine.js tabs combined with HTMX lazy-loading for admin detail pages:

```html
<div x-data="{ activeTab: 'overview' }">
  <nav class="flex gap-1 border-b border-[var(--color-border)] mb-4" role="tablist">
    <button @click="activeTab = 'overview'"
            :class="activeTab === 'overview' ? 'border-[var(--color-accent)] text-[var(--color-accent)]' : 'border-transparent text-[var(--color-text-secondary)]'"
            class="px-4 py-2 border-b-2 font-medium transition-colors">
      Overview
    </button>
    <button @click="activeTab = 'activity'; $refs.activityTab.getAttribute('data-loaded') || htmx.trigger($refs.activityTab, 'load-tab')"
            :class="activeTab === 'activity' ? 'border-[var(--color-accent)] text-[var(--color-accent)]' : 'border-transparent text-[var(--color-text-secondary)]'"
            class="px-4 py-2 border-b-2 font-medium transition-colors">
      Activity
    </button>
  </nav>

  <div x-show="activeTab === 'overview'" x-cloak>
    {# Inline content — already rendered #}
    {% include "admin_suite/fragments/tab_overview.html" %}
  </div>

  <div x-show="activeTab === 'activity'" x-cloak
       x-ref="activityTab"
       hx-get="{% url 'admin_suite:tab_activity' pk=obj.pk %}"
       hx-trigger="load-tab"
       hx-swap="innerHTML"
       @htmx:after-swap="$el.setAttribute('data-loaded', 'true')">
    <div class="text-center py-8 text-[var(--color-text-muted)]">Loading...</div>
  </div>
</div>
```

## Inline Editing

HTMX `hx-put` pattern for editing fields inline in admin tables:

```html
{# Display mode — double-click to edit #}
<td class="editable-cell" hx-get="{% url 'admin_suite:inline_edit_form' pk=obj.pk field='status' %}"
    hx-trigger="dblclick" hx-swap="outerHTML">
  {{ obj.status }}
</td>

{# Edit mode fragment (returned by server) #}
<td>
  <form hx-put="{% url 'admin_suite:inline_edit_save' pk=obj.pk field='status' %}"
        hx-swap="outerHTML"
        hx-target="closest td"
        @keydown.escape="htmx.ajax('GET', '{% url 'admin_suite:inline_edit_cancel' pk=obj.pk field='status' %}', {target: closest('td'), swap: 'outerHTML'})">
    <select name="status" class="admin-input text-sm" autofocus>
      {% for choice in status_choices %}
        <option value="{{ choice.0 }}" {% if choice.0 == obj.status %}selected{% endif %}>{{ choice.1 }}</option>
      {% endfor %}
    </select>
    <button type="submit" class="text-[var(--color-success)] ml-1">
      <i data-lucide="check" class="w-4 h-4"></i>
    </button>
  </form>
</td>
```

## Bulk Actions

Select-all checkbox pattern for admin tables with Alpine.js state management:

```html
<div x-data="{
  selectedIds: [],
  allSelected: false,
  toggleAll(checked) {
    this.allSelected = checked;
    this.selectedIds = checked
      ? [...document.querySelectorAll('[data-select-row]')].map(el => el.value)
      : [];
  },
  toggleRow(id, checked) {
    if (checked) { this.selectedIds.push(id); }
    else { this.selectedIds = this.selectedIds.filter(i => i !== id); }
    this.allSelected = this.selectedIds.length === document.querySelectorAll('[data-select-row]').length;
  }
}">
  {# Bulk action bar — shown when items selected #}
  <div x-show="selectedIds.length > 0" x-cloak
       class="flex items-center gap-4 p-3 bg-[var(--color-accent-soft)] rounded-[var(--radius-md)] mb-4">
    <span x-text="selectedIds.length + ' selected'" class="text-sm font-medium"></span>
    <button @click="$store.confirm.ask('Delete selected?', 'This cannot be undone.').then(ok => {
              if (ok) htmx.ajax('POST', '{% url 'admin_suite:bulk_delete' %}', {
                values: {ids: selectedIds.join(',')}, target: '#table-body', swap: 'innerHTML'
              });
            })"
            class="text-sm text-[var(--color-error)] hover:underline">Delete</button>
    <button class="text-sm text-[var(--color-accent)] hover:underline"
            hx-post="{% url 'admin_suite:bulk_export' %}"
            :hx-vals="JSON.stringify({ids: selectedIds})">
      Export
    </button>
  </div>

  <table class="admin-table w-full">
    <thead>
      <tr>
        <th class="w-10">
          <input type="checkbox" data-select-all
                 :checked="allSelected"
                 @change="toggleAll($event.target.checked)">
        </th>
        <th>Name</th>
      </tr>
    </thead>
    <tbody>
      {% for obj in objects %}
      <tr>
        <td>
          <input type="checkbox" data-select-row value="{{ obj.pk }}"
                 :checked="selectedIds.includes('{{ obj.pk }}')"
                 @change="toggleRow('{{ obj.pk }}', $event.target.checked)">
        </td>
        <td>{{ obj.name }}</td>
      </tr>
      {% endfor %}
    </tbody>
  </table>
</div>
```

## Procedure

1. Decide: server interaction (HTMX) or client-side only (Alpine)
2. For HTMX: create fragment template + view that detects `HX-Request`
3. For Alpine: use `x-data` for local state or `Alpine.store()` for global
4. **Add `x-cloak` to EVERY element with `x-show` or `x-if`** — no exceptions
5. Use `$store.notify` for toasts, `$store.confirm` for confirmations — never `alert()`/`confirm()`
6. Add loading indicators on HTMX triggers (`hx-indicator`)
7. Ensure CSRF token is sent with all HTMX requests (via `hx-headers` on `<body>`)
8. Test without JavaScript (graceful degradation)
9. Run quality gate

## CRITICAL: JSON-on-POST Anti-Pattern

**Any view that returns `JsonResponse` for AJAX `fetch()` calls MUST also handle non-AJAX POST gracefully.**

### The Problem

When a form uses `@submit.prevent` with `fetch()` to POST data, Alpine.js intercepts the form submission and sends an AJAX request. The view returns `JsonResponse({"ok": True, "message": "..."})`. This works perfectly — UNTIL Alpine.js fails to initialize (CSP blocks it, script error, slow load, etc.). When that happens, the form falls through to a regular HTML POST, and the user sees raw JSON on a blank screen:

```
{"ok": true, "message": "Preferences saved"}
```

### The Fix

1. **Client side**: Always include `'X-Requested-With': 'XMLHttpRequest'` in fetch headers:
```javascript
fetch(url, {
  method: 'POST',
  headers: {'X-CSRFToken': csrfToken, 'X-Requested-With': 'XMLHttpRequest'},
})
```

2. **Server side**: Detect AJAX vs regular POST and redirect for non-AJAX:
```python
def _is_ajax(request: HttpRequest) -> bool:
    if request.headers.get("X-Requested-With") == "XMLHttpRequest":
        return True
    if request.headers.get("HX-Request"):
        return True
    accept = request.headers.get("Accept", "")
    return "application/json" in accept and "text/html" not in accept

def my_view(request):
    # ... process the form ...
    resp = JsonResponse({"ok": True, "message": "Done"})
    if _is_ajax(request):
        return resp
    # Non-AJAX fallback — redirect to referrer
    redirect = HttpResponseRedirect(request.META.get("HTTP_REFERER", "/"))
    # Copy any cookies set on the JSON response
    for header_value in resp.cookies.values():
        redirect.cookies[header_value.key] = header_value
    return redirect
```

### Rule
**NEVER return bare `JsonResponse` from a POST endpoint that could be reached by a regular HTML form submission.** Always check for AJAX and provide a redirect fallback.
