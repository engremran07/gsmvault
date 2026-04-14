---
name: htmx-confirm-sweetalert
description: "Confirmation dialogs with SweetAlert pattern. Use when: enhanced confirmation UX for destructive actions, rich HTML confirm dialogs, replacing browser confirm()."
---

# HTMX Confirmation — SweetAlert Pattern

## When to Use

- Replacing the native `hx-confirm` browser dialog with a styled modal
- Destructive actions requiring explicit user confirmation
- Enhanced confirm UX with icons, descriptions, and styled buttons

## Rules

1. Use `hx-confirm` for simple text prompts (quick and native)
2. For rich UX, use `htmx:confirm` event + Alpine modal or `$store.confirm`
3. Call `event.detail.issueRequest(true)` after user confirms
4. Never skip confirmation on destructive operations (delete, revoke, block)

## Patterns

### Using htmx:confirm Event + Alpine Store

```html
<button hx-delete="{% url 'firmwares:delete' fw.pk %}"
        hx-target="#fw-row-{{ fw.pk }}"
        hx-swap="outerHTML"
        hx-confirm="Are you sure you want to delete this firmware?"
        class="text-red-500">
  <i data-lucide="trash-2" class="w-4 h-4"></i> Delete
</button>
```

### Custom Confirm with Alpine Modal

```html
<script nonce="{{ request.csp_nonce }}">
document.addEventListener('htmx:confirm', function(event) {
  // Intercept the default confirm dialog
  event.preventDefault();

  Alpine.store('confirm').ask(
    event.detail.question || 'Are you sure?',
    function() {
      // User confirmed — issue the request
      event.detail.issueRequest(true);
    }
  );
});
</script>
```

### Contextual Confirm Message

```html
{# Use data attributes for dynamic confirm text #}
<button hx-delete="{% url 'admin:block_ip' ip.pk %}"
        hx-target="#ip-row-{{ ip.pk }}"
        hx-swap="outerHTML"
        hx-confirm="Block IP {{ ip.address }}? All requests from this IP will be refused."
        class="btn btn-danger">
  <i data-lucide="shield-x" class="w-4 h-4"></i> Block
</button>
```

### Selective Interception (Only for Deletes)

```html
<script nonce="{{ request.csp_nonce }}">
document.addEventListener('htmx:confirm', function(event) {
  // Only intercept DELETE requests
  const verb = event.detail.elt.getAttribute('hx-delete');
  if (!verb) return; // Let non-delete confirms use native dialog

  event.preventDefault();
  Alpine.store('confirm').ask(
    event.detail.question,
    function() { event.detail.issueRequest(true); }
  );
});
</script>
```

## Anti-Patterns

```html
<!-- WRONG — destructive action without any confirmation -->
<button hx-delete="/firmware/5/" hx-target="#row-5" hx-swap="outerHTML">
  Delete
</button>

<!-- WRONG — blocking JavaScript confirm() -->
<button onclick="if(!confirm('Sure?')) return false;"
        hx-delete="/firmware/5/">Delete</button>
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| Delete without `hx-confirm` | Accidental deletion | Add `hx-confirm` message |
| `window.confirm()` in JS | Blocks thread, ugly UI | Use `htmx:confirm` event |
| Missing `issueRequest(true)` | Confirm succeeds but request never fires | Call `event.detail.issueRequest(true)` |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
