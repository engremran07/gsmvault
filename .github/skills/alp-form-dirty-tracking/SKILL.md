---
name: alp-form-dirty-tracking
description: "Form dirty state tracking: unsaved changes warning. Use when: warning users about unsaved changes, confirming navigation away from dirty forms, tracking which fields changed."
---

# Alpine Form Dirty State Tracking

## When to Use

- Warning users before navigating away from a form with unsaved changes
- Enabling/disabling the save button based on whether changes were made
- Highlighting changed fields visually

## Patterns

### Basic Dirty Tracking

```html
<form x-data="{
  original: {},
  formData: { title: '{{ post.title|escapejs }}', body: '{{ post.body|escapejs }}' },
  dirty: false,
  init() {
    this.original = { ...this.formData };
    this.$watch('formData', () => {
      this.dirty = JSON.stringify(this.formData) !== JSON.stringify(this.original);
    }, { deep: true });
  }
}" @submit="dirty = false" method="post">
  {% csrf_token %}
  <input x-model="formData.title" name="title" type="text"
         class="w-full px-3 py-2 rounded border border-[var(--color-border)]">
  <textarea x-model="formData.body" name="body" rows="5"
            class="w-full px-3 py-2 rounded border border-[var(--color-border)]"></textarea>

  <div class="flex items-center gap-3 mt-4">
    <button type="submit" :disabled="!dirty"
            :class="dirty ? 'bg-[var(--color-accent)] text-[var(--color-accent-text)]' : 'bg-gray-500 opacity-50 cursor-not-allowed'"
            class="px-4 py-2 rounded">Save</button>
    <span x-show="dirty" x-cloak class="text-sm text-yellow-400">Unsaved changes</span>
  </div>
</form>
```

### Beforeunload Warning

```html
<div x-data="{
  dirty: false,
  init() {
    window.addEventListener('beforeunload', (e) => {
      if (this.dirty) {
        e.preventDefault();
        e.returnValue = '';
      }
    });
  }
}">
  <input x-model="title" @input="dirty = true" type="text">
  <form @submit="dirty = false" method="post">
    {% csrf_token %}
    <button type="submit">Save</button>
  </form>
</div>
```

### Field-Level Change Highlight

```html
<form x-data="{
  original: { name: '{{ device.name|escapejs }}', brand: '{{ device.brand|escapejs }}' },
  formData: { name: '{{ device.name|escapejs }}', brand: '{{ device.brand|escapejs }}' },
  isChanged(field) { return this.formData[field] !== this.original[field]; }
}" method="post">
  {% csrf_token %}
  <label class="block mb-3">
    <span class="text-sm">Name</span>
    <input x-model="formData.name" name="name"
           :class="isChanged('name') ? 'border-yellow-400 bg-yellow-400/5' : 'border-[var(--color-border)]'"
           class="w-full px-3 py-2 rounded border">
  </label>
  <label class="block mb-3">
    <span class="text-sm">Brand</span>
    <input x-model="formData.brand" name="brand"
           :class="isChanged('brand') ? 'border-yellow-400 bg-yellow-400/5' : 'border-[var(--color-border)]'"
           class="w-full px-3 py-2 rounded border">
  </label>
</form>
```

### Reset / Discard Changes

```html
<div x-data="{
  original: { title: '{{ item.title|escapejs }}' },
  formData: { title: '{{ item.title|escapejs }}' },
  dirty: false,
  init() {
    this.$watch('formData', () => {
      this.dirty = JSON.stringify(this.formData) !== JSON.stringify(this.original);
    }, { deep: true });
  },
  discard() { this.formData = { ...this.original }; }
}">
  <input x-model="formData.title" type="text">
  <button x-show="dirty" x-cloak @click="discard()"
          class="text-sm text-red-400">Discard changes</button>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Comparing objects with `===` | Reference check always false after clone | Use `JSON.stringify` comparison |
| `beforeunload` not cleared on submit | Warning fires even after saving | Set `dirty = false` on `@submit` |
| Tracking dirty on `x-model` only | Misses programmatic changes | Use `$watch` on the data object |

## Red Flags

- No unsaved changes warning on forms that take significant effort to fill out
- `beforeunload` listener never removed (leaks across navigation)
- Save button enabled when no changes actually exist

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
