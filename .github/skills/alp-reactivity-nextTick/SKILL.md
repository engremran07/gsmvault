---
name: alp-reactivity-nextTick
description: "$nextTick for DOM-ready callbacks. Use when: accessing DOM after reactive update, scrolling to element after list change, focusing input after show, measuring element dimensions after render."
---

# Alpine $nextTick — DOM-Ready Callbacks

## When to Use

- Focusing an input after it becomes visible via `x-show`
- Scrolling to a newly appended item after list update
- Measuring element dimensions after a reactive DOM change
- Running code that depends on the DOM being fully updated

## Patterns

### Focus Input After Show

```html
<div x-data="{ editing: false }">
  <button @click="editing = true; $nextTick(() => $refs.input.focus())">
    Edit
  </button>
  <input x-show="editing" x-cloak x-ref="input" type="text"
         @keydown.escape="editing = false"
         class="px-3 py-2 rounded border border-[var(--color-border)]">
</div>
```

### Scroll to Bottom After New Message

```html
<div x-data="{
  messages: [],
  addMessage(text) {
    this.messages.push({ id: Date.now(), text });
    this.$nextTick(() => {
      this.$refs.list.scrollTop = this.$refs.list.scrollHeight;
    });
  }
}">
  <div x-ref="list" class="h-64 overflow-y-auto">
    <template x-for="msg in messages" :key="msg.id">
      <div x-text="msg.text" class="p-2 border-b border-[var(--color-border)]"></div>
    </template>
  </div>
  <button @click="addMessage('New message at ' + new Date().toLocaleTimeString())">
    Send
  </button>
</div>
```

### Measure Element After Render

```html
<div x-data="{
  items: ['A', 'B'],
  height: 0,
  addItem() {
    this.items.push('Item ' + (this.items.length + 1));
    this.$nextTick(() => {
      this.height = this.$refs.container.offsetHeight;
    });
  }
}">
  <div x-ref="container">
    <template x-for="item in items" :key="item">
      <div x-text="item" class="p-2"></div>
    </template>
  </div>
  <button @click="addItem()">Add</button>
  <p>Container height: <span x-text="height + 'px'"></span></p>
</div>
```

### Await $nextTick (Async)

```html
<div x-data="{
  async reveal() {
    this.show = true;
    await this.$nextTick();
    this.$refs.panel.querySelector('input')?.focus();
  },
  show: false
}">
  <button @click="reveal()">Show Panel</button>
  <div x-show="show" x-cloak x-ref="panel">
    <input type="text" placeholder="Auto-focused">
  </div>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `setTimeout(fn, 0)` as substitute | Unreliable timing, not guaranteed after Alpine update | Use `$nextTick()` |
| Chaining multiple `$nextTick` calls | Hard to reason about, usually unnecessary | One `$nextTick` after final state change |
| DOM reads without `$nextTick` after state change | Stale DOM values | Always `$nextTick` before measuring |

## Red Flags

- `setTimeout` used where `$nextTick` is appropriate
- `$refs` accessed immediately after `x-show` toggle without `$nextTick`
- Multiple nested `$nextTick` calls (simplify the flow)

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
