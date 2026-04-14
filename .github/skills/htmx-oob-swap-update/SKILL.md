---
name: htmx-oob-swap-update
description: "Out-of-band swap for updating multiple page sections. Use when: a single HTMX response needs to update multiple disconnected DOM elements, sidebar + content + header updates."
---

# HTMX Out-of-Band Swap — Update

## When to Use

- A single server response needs to update multiple page sections
- Updating a notification badge AND a content area simultaneously
- Refreshing a sidebar counter when the main content changes
- Any response that affects multiple disconnected DOM elements

## Rules

1. Use `hx-swap-oob="true"` on elements in the response that should swap by ID
2. OOB elements MUST have a matching `id` attribute on the existing page
3. The primary swap target works normally; OOB elements are extra updates
4. OOB elements default to `innerHTML` swap — use `hx-swap-oob="outerHTML"` if needed

## Patterns

### Updating Content + Counter

```html
{# templates/forum/fragments/like_response.html #}

{# Primary response — replaces the hx-target #}
<button id="like-btn-{{ topic.pk }}"
        hx-post="{% url 'forum:toggle_like' topic.pk %}"
        hx-target="this"
        hx-swap="outerHTML"
        class="{% if liked %}text-red-500{% endif %}">
  <i data-lucide="heart"></i> {{ like_count }}
</button>

{# OOB update — updates the stats sidebar independently #}
<span id="topic-like-total" hx-swap-oob="true">
  {{ total_likes }} total likes
</span>
```

### Updating Multiple Sections

```python
# views.py
def approve_firmware(request, pk):
    firmware = get_object_or_404(Firmware, pk=pk)
    firmware.status = "approved"
    firmware.save()

    pending_count = Firmware.objects.filter(status="pending").count()
    return render(request, "admin/fragments/approve_response.html", {
        "firmware": firmware,
        "pending_count": pending_count,
    })
```

```html
{# templates/admin/fragments/approve_response.html #}

{# Primary — replaces the firmware row #}
<tr id="fw-row-{{ firmware.pk }}">
  <td>{{ firmware.name }}</td>
  <td><span class="badge badge-success">Approved</span></td>
</tr>

{# OOB — update the pending count badge in sidebar #}
<span id="pending-badge" hx-swap-oob="true"
      class="badge">{{ pending_count }}</span>

{# OOB — update the page title count #}
<span id="pending-title-count" hx-swap-oob="true">
  ({{ pending_count }} pending)
</span>
```

### OOB with outerHTML Swap

```html
{# Replace the entire element, not just innerHTML #}
<div id="notification-bell" hx-swap-oob="outerHTML">
  <i data-lucide="bell" class="w-5 h-5"></i>
  {% if unread_count %}<span class="badge-dot"></span>{% endif %}
</div>
```

## Anti-Patterns

```html
<!-- WRONG — OOB element without matching ID on page -->
<div id="nonexistent-element" hx-swap-oob="true">Updated!</div>

<!-- WRONG — using OOB for the primary target (confusing) -->
<!-- Use normal hx-target for the main content, OOB for extras -->
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| OOB element ID not on page | Silently ignored, no update | Ensure matching `id` exists |
| Everything via OOB | Overcomplicating simple swaps | Use OOB only for secondary updates |
| Missing `hx-swap-oob` attribute | Element rendered but not swapped | Add `hx-swap-oob="true"` |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
