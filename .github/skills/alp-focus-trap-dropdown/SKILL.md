---
name: alp-focus-trap-dropdown
description: "Focus trapping in dropdowns. Use when: building accessible dropdown menus, ensuring arrow-key navigation within dropdown options, trapping focus in select-like widgets."
---

# Alpine Focus Trap — Dropdowns

## When to Use

- Custom dropdown menus with keyboard navigation
- Action menus (edit, delete, archive) needing arrow key support
- Select-like widgets that must be fully keyboard accessible

## Patterns

### Dropdown with x-trap and Arrow Keys

```html
<div x-data="{ open: false, activeIndex: -1, items: ['Edit', 'Duplicate', 'Archive', 'Delete'] }"
     class="relative">
  <button @click="open = !open; activeIndex = -1"
          @keydown.arrow-down.prevent="open = true; activeIndex = 0"
          :aria-expanded="open" aria-haspopup="true">
    Actions
  </button>

  <div x-show="open" x-cloak x-trap="open"
       @click.outside="open = false"
       @keydown.arrow-down.prevent="activeIndex = (activeIndex + 1) % items.length"
       @keydown.arrow-up.prevent="activeIndex = (activeIndex - 1 + items.length) % items.length"
       @keydown.escape.prevent="open = false"
       @keydown.enter.prevent="if(activeIndex >= 0) { /* handle selection */ open = false; }"
       x-transition:enter="transition ease-out duration-150"
       x-transition:leave="transition ease-in duration-100"
       role="menu" class="absolute mt-1 w-48 rounded shadow-lg bg-[var(--color-surface)] border border-[var(--color-border)]">
    <template x-for="(item, i) in items" :key="i">
      <button x-text="item" role="menuitem"
              :class="{ 'bg-[var(--color-accent)]/10': activeIndex === i }"
              @mouseenter="activeIndex = i"
              @click="/* handle */ open = false"
              class="block w-full text-left px-4 py-2 text-sm">
      </button>
    </template>
  </div>
</div>
```

### Simple Focus Trap Without Plugin

```html
<div x-data="{ open: false }" class="relative">
  <button @click="open = !open" @click.outside="open = false"
          @keydown.escape="open = false">
    Menu
  </button>
  <div x-show="open" x-cloak x-transition
       @keydown.tab.prevent="open = false"
       role="menu"
       class="absolute mt-1 rounded shadow bg-[var(--color-surface)]">
    <a href="#" role="menuitem" class="block px-4 py-2">Profile</a>
    <a href="#" role="menuitem" class="block px-4 py-2">Settings</a>
    <a href="#" role="menuitem" class="block px-4 py-2">Logout</a>
  </div>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| No arrow key navigation | Keyboard users can't navigate items | Add `@keydown.arrow-*` handlers |
| Missing `role="menu"` / `role="menuitem"` | Screen readers don't identify as menu | Add ARIA roles |
| Tab key exits to background | Focus escapes dropdown | Trap or close-on-tab |
| No `@click.outside` | Dropdown stays open forever | Add outside click dismiss |

## Red Flags

- Dropdown menu without keyboard support
- Missing `aria-haspopup`, `aria-expanded`, or `role="menu"`
- No escape key handler

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
