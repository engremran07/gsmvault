---
name: alp-keyboard-navigation
description: "Keyboard navigation: arrow keys, tab. Use when: building accessible lists with arrow key navigation, tab panels, tree views, roving tabindex patterns."
---

# Alpine Keyboard Navigation

## When to Use

- Arrow key navigation through a list of options (menus, autocomplete)
- Tab panels with arrow key switching
- Roving tabindex pattern for widget accessibility
- Any interactive list requiring keyboard support

## Patterns

### Arrow Key List Navigation

```html
<div x-data="{
  items: ['Dashboard', 'Firmwares', 'Devices', 'Users', 'Settings'],
  activeIndex: 0,
  next() { this.activeIndex = (this.activeIndex + 1) % this.items.length; },
  prev() { this.activeIndex = (this.activeIndex - 1 + this.items.length) % this.items.length; },
}" @keydown.arrow-down.prevent="next()"
   @keydown.arrow-up.prevent="prev()"
   tabindex="0" role="listbox"
   class="focus:outline-none">
  <template x-for="(item, i) in items" :key="i">
    <div role="option" :aria-selected="activeIndex === i"
         :class="activeIndex === i ? 'bg-[var(--color-accent)]/10 text-[var(--color-accent)]' : ''"
         @click="activeIndex = i"
         class="px-4 py-2 cursor-pointer rounded">
      <span x-text="item"></span>
    </div>
  </template>
</div>
```

### Tab Panel with Arrow Keys

```html
<div x-data="{ activeTab: 0, tabs: ['Overview', 'Specs', 'Downloads'] }">
  <div role="tablist" @keydown.arrow-right.prevent="activeTab = (activeTab + 1) % tabs.length"
       @keydown.arrow-left.prevent="activeTab = (activeTab - 1 + tabs.length) % tabs.length">
    <template x-for="(tab, i) in tabs" :key="i">
      <button role="tab" :aria-selected="activeTab === i"
              :tabindex="activeTab === i ? 0 : -1"
              @click="activeTab = i"
              :class="activeTab === i ? 'border-b-2 border-[var(--color-accent)] text-[var(--color-accent)]' : 'text-[var(--color-text-muted)]'"
              class="px-4 py-2" x-text="tab">
      </button>
    </template>
  </div>
  <div role="tabpanel">
    <div x-show="activeTab === 0" x-cloak>Overview content</div>
    <div x-show="activeTab === 1" x-cloak>Specs content</div>
    <div x-show="activeTab === 2" x-cloak>Downloads content</div>
  </div>
</div>
```

### Roving Tabindex

```html
<div x-data="{ focused: 0, buttons: 3 }"
     @keydown.arrow-right.prevent="focused = (focused + 1) % buttons"
     @keydown.arrow-left.prevent="focused = (focused - 1 + buttons) % buttons"
     role="toolbar">
  <template x-for="i in buttons" :key="i">
    <button :tabindex="focused === i - 1 ? 0 : -1"
            x-effect="if (focused === i - 1) $el.focus()"
            class="px-3 py-1 rounded border border-[var(--color-border)]"
            x-text="'Action ' + i">
    </button>
  </template>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| No `role` attributes | Screen readers can't identify widget type | Add `role="listbox"`, `role="tab"` etc. |
| All items with `tabindex="0"` | User must tab through every item | Use roving tabindex |
| Arrow keys without `.prevent` | Page scrolls while navigating | Add `.prevent` modifier |

## Red Flags

- Arrow key navigation without ARIA roles
- Missing `.prevent` on arrow key handlers (causes scroll)
- No visual focus indicator on active item

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
