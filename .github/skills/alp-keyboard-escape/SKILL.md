---
name: alp-keyboard-escape
description: "Escape key handling for modals/dropdowns. Use when: closing overlays on Escape, nested escape handling, global escape listener patterns."
---

# Alpine Escape Key Handling

## When to Use

- Closing modals, dropdowns, and sidebars on Escape press
- Nested overlays where Escape should close the topmost only
- Dismissing alerts or tooltips with keyboard

## Patterns

### Basic Escape to Close

```html
<div x-data="{ open: false }">
  <button @click="open = true">Open Menu</button>
  <div x-show="open" x-cloak
       @keydown.escape.window="open = false"
       x-transition
       class="absolute z-40 mt-2 w-48 rounded-lg shadow-lg bg-[var(--color-surface)] border border-[var(--color-border)]">
    <a href="#" class="block px-4 py-2 hover:bg-[var(--color-surface-alt)]">Option 1</a>
    <a href="#" class="block px-4 py-2 hover:bg-[var(--color-surface-alt)]">Option 2</a>
  </div>
  <div x-show="open" x-cloak @click="open = false" class="fixed inset-0 z-30"></div>
</div>
```

### Scoped Escape (Prevents Bubbling)

```html
<div x-data="{ modalOpen: false }">
  <button @click="modalOpen = true">Open Modal</button>
  <div x-show="modalOpen" x-cloak
       @keydown.escape.stop="modalOpen = false"
       x-trap.noscroll="modalOpen"
       class="fixed inset-0 z-50 flex items-center justify-center">
    <div class="absolute inset-0 bg-black/50" @click="modalOpen = false"></div>
    <div class="relative bg-[var(--color-surface)] rounded-lg p-6 max-w-md w-full shadow-xl"
         @click.stop>
      <h2 class="text-lg font-semibold mb-4">Modal Title</h2>
      <p>Press Escape to close</p>
      <button @click="modalOpen = false"
              class="mt-4 px-4 py-2 rounded bg-[var(--color-accent)] text-[var(--color-accent-text)]">
        Close
      </button>
    </div>
  </div>
</div>
```

### Nested Escape — Inner Closes First

```html
<div x-data="{ sidebar: false }">
  <button @click="sidebar = true">Open Sidebar</button>
  <div x-show="sidebar" x-cloak @keydown.escape.window="sidebar = false"
       class="fixed inset-y-0 right-0 w-80 z-40 bg-[var(--color-surface)] shadow-xl">

    <div x-data="{ confirm: false }">
      <button @click="confirm = true">Delete</button>
      <!-- Inner escape stops propagation — sidebar stays open -->
      <div x-show="confirm" x-cloak
           @keydown.escape.stop="confirm = false"
           class="absolute inset-0 bg-black/30 flex items-center justify-center z-50">
        <div class="bg-[var(--color-surface)] rounded p-4">
          <p>Are you sure? Press Escape to cancel.</p>
          <button @click="confirm = false">Cancel</button>
        </div>
      </div>
    </div>
  </div>
</div>
```

### Escape Only When Visible

```html
<div x-data="{ isOpen: false }"
     @keydown.escape.window="if (isOpen) { isOpen = false; }">
  <button @click="isOpen = true">Open</button>
  <div x-show="isOpen" x-cloak x-transition
       class="p-4 rounded shadow-lg bg-[var(--color-surface)]">
    Content
  </div>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `@keydown.escape.window` on nested overlay | Closes all overlays at once | Use `.stop` on inner overlay |
| Escape handler without visibility check | Runs even when component is hidden | Guard with `if (isOpen)` |
| Missing backdrop click-to-close alongside Escape | Inconsistent UX | Always pair Escape + backdrop click |

## Red Flags

- Nested modals where Escape closes everything instead of topmost
- Escape handler active when the target element is already hidden
- No Escape support on overlays that have backdrop click-to-close

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
