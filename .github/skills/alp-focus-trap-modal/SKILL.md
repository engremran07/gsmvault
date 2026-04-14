---
name: alp-focus-trap-modal
description: "Focus trapping in modals. Use when: building accessible modals, preventing tab from escaping modal dialog, ensuring keyboard users stay within modal bounds."
---

# Alpine Focus Trap — Modals

## When to Use

- Modal dialogs that must trap keyboard focus for accessibility
- Confirmation dialogs, form modals, detail overlays
- Any overlay that should prevent interaction with background content

## Patterns

### Focus Trap with x-trap (Alpine Focus Plugin)

Requires `@alpinejs/focus` plugin (loaded via CDN fallback chain):

```html
<div x-data="{ showModal: false }">
  <button @click="showModal = true">Open Modal</button>

  <div x-show="showModal" x-cloak
       x-trap.noscroll="showModal"
       @keydown.escape.window="showModal = false"
       class="fixed inset-0 z-50 flex items-center justify-center">
    <!-- Backdrop -->
    <div class="absolute inset-0 bg-black/50" @click="showModal = false"></div>
    <!-- Content -->
    <div class="relative bg-[var(--color-surface)] rounded-lg p-6 max-w-md w-full shadow-xl"
         role="dialog" aria-modal="true" aria-labelledby="modal-title">
      <h2 id="modal-title">Confirm Action</h2>
      <p>Are you sure you want to proceed?</p>
      <div class="flex gap-3 mt-4">
        <button @click="showModal = false"
                class="px-4 py-2 rounded bg-[var(--color-surface-alt)]">Cancel</button>
        <button @click="/* action */; showModal = false"
                class="px-4 py-2 rounded bg-[var(--color-accent)] text-[var(--color-accent-text)]">
          Confirm
        </button>
      </div>
    </div>
  </div>
</div>
```

### Manual Focus Trap (No Plugin)

```html
<div x-data="{ showModal: false }"
     @keydown.tab.prevent="
       const focusable = $refs.modal.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex=-1])');
       const first = focusable[0];
       const last = focusable[focusable.length - 1];
       if ($event.shiftKey && document.activeElement === first) { last.focus(); }
       else if (!$event.shiftKey && document.activeElement === last) { first.focus(); }
     ">
  <button @click="showModal = true; $nextTick(() => $refs.modal.querySelector('button')?.focus())">
    Open
  </button>
  <div x-show="showModal" x-cloak x-ref="modal" role="dialog" aria-modal="true"
       class="fixed inset-0 z-50 flex items-center justify-center">
    <div class="bg-[var(--color-surface)] rounded-lg p-6 max-w-md">
      <button @click="showModal = false">Close</button>
      <input type="text" placeholder="Name">
      <button>Submit</button>
    </div>
  </div>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Modal without focus trap | Keyboard user tabs into background | Use `x-trap` or manual trap |
| Missing `role="dialog"` and `aria-modal` | Screen readers don't announce modal | Add ARIA attributes |
| No escape key handler | User can't dismiss with keyboard | Add `@keydown.escape` |
| Scroll not locked | Background scrolls behind modal | Use `x-trap.noscroll` |

## Red Flags

- Interactive modal without `x-trap` or manual tab trapping
- Missing `aria-modal="true"` and `role="dialog"`
- No mechanism to close via keyboard (Escape)

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
