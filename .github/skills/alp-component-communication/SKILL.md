---
name: alp-component-communication
description: "Component communication: $dispatch, events. Use when: sibling components need to communicate, parent-child event bubbling, cross-component coordination without global stores."
---

# Alpine Component Communication

## When to Use

- A child component needs to notify its parent (e.g., "item selected")
- Sibling components need to react to each other's state changes
- Decoupled communication without polluting global stores

## Patterns

### Child → Parent with $dispatch

```html
<div x-data="{ selectedId: null }" @item-selected.camel="selectedId = $event.detail.id">
  <p>Selected: <span x-text="selectedId || 'None'"></span></p>

  <!-- Child component dispatches event -->
  <div x-data="{ items: [{ id: 1, name: 'Alpha' }, { id: 2, name: 'Beta' }] }">
    <template x-for="item in items" :key="item.id">
      <button @click="$dispatch('item-selected', { id: item.id })" x-text="item.name"></button>
    </template>
  </div>
</div>
```

### Sibling Communication via Window Events

```html
<!-- Component A: dispatches to window -->
<div x-data>
  <button @click="$dispatch('filter-changed', { category: 'firmware' })">
    Show Firmware
  </button>
</div>

<!-- Component B: listens on window -->
<div x-data="{ filter: 'all' }" @filter-changed.window="filter = $event.detail.category">
  <p>Current filter: <span x-text="filter"></span></p>
</div>
```

### Modal Trigger via Custom Event

```html
<!-- Trigger button (anywhere on page) -->
<button x-data @click="$dispatch('open-modal', { title: 'Confirm Delete', id: {{ obj.pk }} })">
  Delete
</button>

<!-- Modal component (in layout) -->
<div x-data="{ show: false, title: '', itemId: null }"
     @open-modal.window="show = true; title = $event.detail.title; itemId = $event.detail.id"
     @keydown.escape.window="show = false">
  <div x-show="show" x-cloak x-transition class="fixed inset-0 z-50 flex items-center justify-center">
    <div class="bg-[var(--color-surface)] rounded-lg p-6 shadow-xl">
      <h3 x-text="title"></h3>
      <button @click="show = false">Cancel</button>
    </div>
  </div>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `document.querySelector` to read sibling state | Breaks reactivity, fragile | Use `$dispatch` or `Alpine.store` |
| Event names without namespace | Collision with native events | Use descriptive names: `item-selected`, `modal-open` |
| Overusing window events for local communication | Hard to trace, global noise | Use DOM bubbling (no `.window`) when parent/child |
| Passing large objects in `$event.detail` | Memory/serialization issues | Pass IDs, look up data in store |

## Red Flags

- `document.getElementById` or `querySelector` inside Alpine components
- Event names matching native DOM events (`click`, `submit`, `change`)
- Communication patterns that should be a global store (used by 3+ unrelated components)

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
