---
name: alp-morph-dom-diff
description: "DOM diffing with Alpine morph. Use when: updating DOM efficiently from server HTML, HTMX swap alternatives, preserving Alpine state during DOM updates."
---

# Alpine Morph — DOM Diffing

## When to Use

- Updating a section of the page from server HTML without losing Alpine state
- HTMX `morph` swap strategy for seamless partial updates
- Re-rendering component HTML while keeping reactive state intact

## Patterns

### Alpine.morph for Manual DOM Update

```html
<script>
async function refreshSection(el) {
  const res = await fetch(el.dataset.url);
  const html = await res.text();
  const template = document.createElement('template');
  template.innerHTML = html.trim();
  Alpine.morph(el, template.content.firstElementChild);
}
</script>

<div x-data="{ count: 0 }" data-url="/fragments/stats/"
     @refresh-stats.window="refreshSection($el)">
  <p>Count: <span x-text="count"></span></p>
  <!-- Server HTML updates structure, but Alpine state (count) persists -->
</div>
```

### HTMX with Morph Swap

Configure HTMX to use morph swap for Alpine-compatible updates:

```html
<div hx-get="/firmwares/fragments/list/"
     hx-trigger="filter-changed from:body"
     hx-swap="morph:innerHTML"
     hx-target="this">
  {% for fw in firmwares %}
    <div x-data="{ expanded: false }">
      <button @click="expanded = !expanded" x-text="'{{ fw.name|escapejs }}'"></button>
      <div x-show="expanded" x-cloak x-transition>Details...</div>
    </div>
  {% endfor %}
</div>
```

### Morph with Key Preservation

Use `id` attributes to help morph identify matching elements:

```html
<ul id="notification-list">
  <template x-for="n in $store.notifications.items" :key="n.id">
    <li :id="'notif-' + n.id" :class="{ 'font-bold': !n.read }">
      <span x-text="n.message"></span>
    </li>
  </template>
</ul>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `innerHTML =` to replace Alpine-managed DOM | Destroys reactive state | Use `Alpine.morph()` |
| Morph without stable `id` attributes | Morph can't match elements, causes flicker | Add `id` to key elements |
| Using morph for tiny updates | Overkill, worse perf than targeted update | Use reactive `x-text`/`x-bind` for simple changes |

## Red Flags

- `el.innerHTML = html` inside an Alpine component — destroys state
- HTMX `hx-swap="innerHTML"` on Alpine-reactive elements — should use `morph`
- Alpine.morph called on elements without stable identifiers

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
