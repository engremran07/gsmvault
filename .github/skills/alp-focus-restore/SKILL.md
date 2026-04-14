---
name: alp-focus-restore
description: "Focus restoration after modal/dialog close. Use when: returning focus to the trigger button after closing a modal, maintaining focus context for accessibility."
---

# Alpine Focus Restoration

## When to Use

- Restoring focus to the button that opened a modal after it closes
- Returning focus to context after a dropdown or popover dismisses
- Ensuring screen reader users don't lose their place in the page

## Patterns

### Focus Restore with x-ref

```html
<div x-data="{ showModal: false }">
  <button x-ref="trigger" @click="showModal = true">Open Modal</button>

  <div x-show="showModal" x-cloak
       x-trap="showModal"
       @keydown.escape.window="showModal = false"
       x-transition
       class="fixed inset-0 z-50 flex items-center justify-center">
    <div class="absolute inset-0 bg-black/50" @click="showModal = false"></div>
    <div class="relative bg-[var(--color-surface)] rounded-lg p-6 max-w-md"
         role="dialog" aria-modal="true">
      <p>Modal content</p>
      <button @click="showModal = false">Close</button>
    </div>
  </div>

  <!-- Restore focus when modal closes -->
  <template x-effect="if (!showModal) $refs.trigger?.focus()"></template>
</div>
```

### Using $watch for Focus Restore

```html
<div x-data="{
  showModal: false,
  triggerEl: null,
  open(event) {
    this.triggerEl = event.currentTarget;
    this.showModal = true;
  },
  close() {
    this.showModal = false;
    this.$nextTick(() => this.triggerEl?.focus());
  }
}">
  <button @click="open($event)">Edit Item</button>

  <div x-show="showModal" x-cloak x-trap="showModal"
       @keydown.escape.window="close()"
       class="fixed inset-0 z-50 flex items-center justify-center">
    <div class="bg-[var(--color-surface)] rounded-lg p-6">
      <button @click="close()">Done</button>
    </div>
  </div>
</div>
```

### Dropdown with Focus Return

```html
<div x-data="{ open: false }" class="relative">
  <button x-ref="menuBtn" @click="open = !open"
          @keydown.escape="open = false; $refs.menuBtn.focus()">
    Menu
  </button>
  <div x-show="open" x-cloak x-transition
       @click.outside="open = false; $refs.menuBtn.focus()"
       @keydown.escape="open = false; $refs.menuBtn.focus()">
    <a href="#">Option 1</a>
    <a href="#">Option 2</a>
  </div>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| No focus restore after modal close | Screen reader user lost in page | Store trigger ref, restore on close |
| `document.querySelector` for trigger | Fragile, breaks with multiple instances | Use `x-ref` or event.currentTarget |
| Focus restore without `$nextTick` | Element not yet in DOM / visible | Wrap in `$nextTick()` |

## Red Flags

- Modal closes without returning focus to trigger element
- Dropdown dismiss leaves focus on the now-hidden element
- Focus moves to `<body>` after dialog close (accessibility failure)

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
