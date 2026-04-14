---
name: alp-keyboard-shortcuts
description: "Keyboard shortcut bindings. Use when: adding global keyboard shortcuts, command palette triggers, quick-action hotkeys like Ctrl+K for search."
---

# Alpine Keyboard Shortcuts

## When to Use

- Global search shortcut (Ctrl+K or /)
- Quick navigation shortcuts (g then d = go to dashboard)
- Action shortcuts (Ctrl+S to save form, Ctrl+Enter to submit)

## Patterns

### Global Search Shortcut (Ctrl+K)

```html
<div x-data="{ searchOpen: false }"
     @keydown.window="
       if ((event.ctrlKey || event.metaKey) && event.key === 'k') {
         event.preventDefault();
         searchOpen = !searchOpen;
       }
     ">
  <div x-show="searchOpen" x-cloak x-trap="searchOpen"
       @keydown.escape="searchOpen = false"
       class="fixed inset-0 z-50 flex items-start justify-center pt-20">
    <div class="absolute inset-0 bg-black/50" @click="searchOpen = false"></div>
    <div class="relative w-full max-w-lg bg-[var(--color-surface)] rounded-lg shadow-xl">
      <input type="text" placeholder="Search... (Esc to close)"
             x-ref="searchInput"
             x-init="$watch('searchOpen', v => v && $nextTick(() => $refs.searchInput.focus()))"
             class="w-full px-4 py-3 rounded-t-lg border-b border-[var(--color-border)] bg-transparent">
      <div class="p-4 text-[var(--color-text-muted)] text-sm">
        Type to search firmwares, devices, topics...
      </div>
    </div>
  </div>
</div>
```

### Navigation Shortcuts

```html
<div x-data
     @keydown.window="
       if (event.target.tagName === 'INPUT' || event.target.tagName === 'TEXTAREA') return;
       if (event.key === '?' && event.shiftKey) $dispatch('show-shortcuts');
     ">
</div>

<!-- Shortcuts help modal -->
<div x-data="{ show: false }" @show-shortcuts.window="show = true">
  <div x-show="show" x-cloak x-trap="show" @keydown.escape="show = false"
       class="fixed inset-0 z-50 flex items-center justify-center">
    <div class="bg-[var(--color-surface)] rounded-lg p-6 max-w-md shadow-xl">
      <h3 class="text-lg font-semibold mb-4">Keyboard Shortcuts</h3>
      <table class="w-full text-sm">
        <tr><td class="py-1"><kbd class="px-2 py-0.5 rounded bg-[var(--color-surface-alt)] text-xs">Ctrl+K</kbd></td><td>Search</td></tr>
        <tr><td class="py-1"><kbd class="px-2 py-0.5 rounded bg-[var(--color-surface-alt)] text-xs">?</kbd></td><td>This help</td></tr>
        <tr><td class="py-1"><kbd class="px-2 py-0.5 rounded bg-[var(--color-surface-alt)] text-xs">Esc</kbd></td><td>Close dialog</td></tr>
      </table>
      <button @click="show = false" class="mt-4 px-4 py-2 rounded bg-[var(--color-accent)] text-[var(--color-accent-text)]">Close</button>
    </div>
  </div>
</div>
```

### Form Submit Shortcut (Ctrl+Enter)

```html
<form x-data @keydown.ctrl.enter="$el.submit()" method="post">
  {% csrf_token %}
  <textarea name="content" rows="5"
            class="w-full px-3 py-2 rounded border border-[var(--color-border)]"></textarea>
  <p class="text-xs text-[var(--color-text-muted)] mt-1">Ctrl+Enter to submit</p>
  <button type="submit">Submit</button>
</form>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Shortcuts fire inside text inputs | User can't type normally | Guard: `if (event.target.tagName === 'INPUT') return` |
| Overriding browser shortcuts | Breaks expected behavior | Avoid Ctrl+T, Ctrl+W, Ctrl+N etc. |
| No shortcut discoverability | Users never find them | Add `?` help modal |

## Red Flags

- Keyboard shortcut that fires while user is typing in a form field
- Overriding browser-native shortcuts (Ctrl+C, Ctrl+V, Ctrl+T)
- Shortcuts without discoverable documentation (no `?` help)

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
