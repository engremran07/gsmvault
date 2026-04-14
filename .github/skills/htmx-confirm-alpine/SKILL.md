---
name: htmx-confirm-alpine
description: "Confirmation with Alpine.js modal. Use when: styled confirmation dialogs, multi-step confirmations, inline confirm/cancel buttons, non-blocking confirmations."
---

# HTMX Confirmation — Alpine.js Modal

## When to Use

- Styled confirmation dialogs that match the theme
- Multi-step confirmation (type to confirm, checkbox agreement)
- Inline confirm/cancel button patterns
- Non-blocking UI confirmations

## Rules

1. Use `$store.confirm.ask()` for global confirm dialogs
2. Use inline Alpine `x-data` for per-element confirm state
3. Always restore focus after modal closes
4. Destructive actions must have clear visual warning (red button, warning icon)

## Patterns

### Inline Confirm/Cancel Pattern

```html
{# Replaces the action button with confirm/cancel on click #}
<div x-data="{ confirming: false }">
  <button x-show="!confirming"
          @click="confirming = true"
          class="text-red-500 hover:text-red-700">
    <i data-lucide="trash-2" class="w-4 h-4"></i> Delete
  </button>

  <div x-show="confirming" x-cloak class="flex gap-2">
    <button hx-delete="{% url 'firmwares:delete' fw.pk %}"
            hx-target="#fw-row-{{ fw.pk }}"
            hx-swap="outerHTML"
            @click="confirming = false"
            class="btn btn-sm btn-danger">
      Confirm
    </button>
    <button @click="confirming = false"
            class="btn btn-sm btn-secondary">
      Cancel
    </button>
  </div>
</div>
```

### Global Confirm Store

```html
<script nonce="{{ request.csp_nonce }}">
document.addEventListener('alpine:init', () => {
  Alpine.store('confirm', {
    open: false,
    message: '',
    callback: null,

    ask(message, onConfirm) {
      this.message = message;
      this.callback = onConfirm;
      this.open = true;
    },
    accept() {
      if (this.callback) this.callback();
      this.close();
    },
    close() {
      this.open = false;
      this.message = '';
      this.callback = null;
    }
  });
});
</script>

{# Modal component — include once in base.html #}
<div x-data x-show="$store.confirm.open" x-cloak
     class="fixed inset-0 z-50 flex items-center justify-center"
     @keydown.escape.window="$store.confirm.close()">
  <div class="fixed inset-0 bg-black/50" @click="$store.confirm.close()"></div>
  <div class="relative bg-[var(--color-bg-secondary)] rounded-lg p-6 max-w-md shadow-xl">
    <p class="text-[var(--color-text-primary)]" x-text="$store.confirm.message"></p>
    <div class="flex justify-end gap-3 mt-4">
      <button @click="$store.confirm.close()"
              class="btn btn-secondary">Cancel</button>
      <button @click="$store.confirm.accept()"
              class="btn btn-danger">Confirm</button>
    </div>
  </div>
</div>
```

### HTMX + Alpine Confirm Integration

```html
<script nonce="{{ request.csp_nonce }}">
document.addEventListener('htmx:confirm', function(event) {
  event.preventDefault();
  Alpine.store('confirm').ask(
    event.detail.question,
    () => event.detail.issueRequest(true)
  );
});
</script>
```

## Anti-Patterns

```html
<!-- WRONG — confirm with no visual distinction from regular actions -->
<button @click="$store.confirm.ask('Sure?', () => doThing())">
  Do Thing  <!-- should clearly indicate the severity -->
</button>
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| No escape key handler | Can't dismiss with keyboard | Add `@keydown.escape` |
| No backdrop click close | Trapped in confirm | Add `@click` on backdrop |
| Missing `x-cloak` on modal | FOUC on page load | Add `x-cloak` to container |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
