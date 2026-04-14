---
name: alp-component-encapsulation
description: "Component encapsulation with x-data. Use when: creating self-contained UI components, scoping state to a single element tree, defining component-local methods."
---

# Alpine Component Encapsulation

## When to Use

- Building self-contained interactive widgets (dropdowns, accordions, tabs)
- Scoping state so it doesn't leak to siblings or parent components
- Defining methods and data that only one component needs

## Patterns

### Self-Contained Dropdown Component

```html
<div x-data="{ open: false }" class="relative">
  <button @click="open = !open" @click.outside="open = false"
          :aria-expanded="open">
    Options
  </button>
  <div x-show="open" x-cloak
       x-transition:enter="transition ease-out duration-150"
       x-transition:leave="transition ease-in duration-100"
       class="absolute mt-1 bg-[var(--color-surface)] border border-[var(--color-border)] rounded shadow-lg">
    <a href="#" class="block px-4 py-2">Edit</a>
    <a href="#" class="block px-4 py-2">Delete</a>
  </div>
</div>
```

### Extracted Component Function

For complex components, extract `x-data` into a reusable function:

```html
<script>
document.addEventListener('alpine:init', () => {
  Alpine.data('accordion', () => ({
    activeIndex: null,
    toggle(index) {
      this.activeIndex = this.activeIndex === index ? null : index;
    },
    isOpen(index) {
      return this.activeIndex === index;
    }
  }));
});
</script>

<div x-data="accordion">
  <template x-for="(item, i) in ['FAQ 1', 'FAQ 2', 'FAQ 3']">
    <div>
      <button @click="toggle(i)" x-text="item"></button>
      <div x-show="isOpen(i)" x-cloak x-transition>
        <p>Answer content here.</p>
      </div>
    </div>
  </template>
</div>
```

### Component with Props via `x-data`

```html
<div x-data="{ maxLength: {{ max_length|default:200 }}, text: '', get remaining() { return this.maxLength - this.text.length; } }">
  <textarea x-model="text" :maxlength="maxLength"></textarea>
  <span x-text="remaining" :class="{ 'text-red-500': remaining < 20 }"></span>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Global variable in `x-data` | State leaks across components | Keep data local to each `x-data` |
| `document.querySelector` inside `x-data` | Breaks encapsulation | Use `x-ref` and `this.$refs` |
| Giant inline `x-data="{...100+ chars...}"` | Unreadable | Extract to `Alpine.data()` function |
| Nested `x-data` sharing parent state | Confusing scope chain | Use `$dispatch` or stores for cross-scope |

## Red Flags

- `x-data` objects exceeding 3 properties without extraction to `Alpine.data()`
- Components reaching outside their DOM subtree
- Missing `x-cloak` on conditional elements

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
