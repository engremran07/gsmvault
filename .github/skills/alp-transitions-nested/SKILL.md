---
name: alp-transitions-nested
description: "Nested transition patterns. Use when: animating parent container and child items separately, staggered children inside an animated parent, sequential reveal."
---

# Alpine Nested Transitions

## When to Use

- Modal overlay (fade) with modal content (scale) as separate animations
- Dropdown container animates, then items within animate sequentially
- Parent panel slides in, child elements fade in after

## Patterns

### Modal with Backdrop + Content Transitions

```html
<div x-show="showModal" x-cloak class="fixed inset-0 z-50">
  <!-- Backdrop -->
  <div x-show="showModal"
       x-transition:enter="transition ease-out duration-300"
       x-transition:enter-start="opacity-0"
       x-transition:enter-end="opacity-100"
       x-transition:leave="transition ease-in duration-200"
       x-transition:leave-start="opacity-100"
       x-transition:leave-end="opacity-0"
       class="absolute inset-0 bg-black/50"
       @click="showModal = false">
  </div>
  <!-- Content -->
  <div x-show="showModal"
       x-transition:enter="transition ease-out duration-300 delay-75"
       x-transition:enter-start="opacity-0 scale-95"
       x-transition:enter-end="opacity-100 scale-100"
       x-transition:leave="transition ease-in duration-150"
       x-transition:leave-start="opacity-100 scale-100"
       x-transition:leave-end="opacity-0 scale-95"
       class="relative mx-auto mt-20 max-w-lg bg-[var(--color-surface)] rounded-lg p-6">
    <h2>Modal Title</h2>
    <button @click="showModal = false">Close</button>
  </div>
</div>
```

### Menu with Header + Items

```html
<div x-data="{ open: false }" class="relative">
  <button @click="open = !open">Menu</button>
  <div x-show="open" x-cloak @click.outside="open = false"
       x-transition:enter="transition ease-out duration-200"
       x-transition:enter-start="opacity-0 scale-95"
       x-transition:enter-end="opacity-100 scale-100"
       x-transition:leave="transition ease-in duration-100"
       x-transition:leave-start="opacity-100 scale-100"
       x-transition:leave-end="opacity-0 scale-95"
       class="absolute mt-2 w-48 rounded shadow-lg bg-[var(--color-surface)]">
    <div class="px-3 py-2 text-xs text-[var(--color-text-muted)]">Actions</div>
    <a href="#" class="block px-3 py-2">Edit</a>
    <a href="#" class="block px-3 py-2">Archive</a>
    <a href="#" class="block px-3 py-2 text-red-500">Delete</a>
  </div>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Same transition on parent and children | Children inherit parent timing, looks janky | Give children their own transition or delay |
| Missing `x-cloak` on nested elements | Inner elements flash before parent hides | Add `x-cloak` to outermost `x-show` |
| Very long delays on inner elements | User waits too long | Keep total animation under 400ms |

## Red Flags

- Nested `x-show` without `x-cloak` on the outermost wrapper
- Duplicate `x-transition` definitions (same enter/leave on parent + child)
- CSS `animate-*` mixed with `x-transition` in the same subtree

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
