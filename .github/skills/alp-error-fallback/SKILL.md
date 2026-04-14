---
name: alp-error-fallback
description: "Fallback UI for Alpine failures. Use when: showing alternative content when Alpine fails to load, progressive enhancement, no-JS fallback patterns."
---

# Alpine Error Fallback UI

## When to Use

- Providing usable content when JavaScript is disabled or Alpine fails
- Progressive enhancement — content works without JS, enhanced with Alpine
- Showing fallback UI when a component's data fetch fails

## Patterns

### No-JS Fallback with x-cloak Inversion

```html
<style>[x-cloak] { display: none !important; }</style>

<!-- Shown only when Alpine is active -->
<div x-data="{ open: false }" x-cloak>
  <button @click="open = !open">Toggle (JS)</button>
  <div x-show="open" x-cloak x-transition>Interactive content</div>
</div>

<!-- Shown only when JS is disabled -->
<noscript>
  <div class="p-4 rounded bg-yellow-500/10 border border-yellow-500/30">
    <p>Enable JavaScript for the full interactive experience.</p>
  </div>
</noscript>
```

### Component-Level Fallback

```html
<div x-data="{
  items: [],
  loaded: false,
  error: false,
  async init() {
    try {
      const res = await fetch('/api/v1/stats/');
      if (!res.ok) throw new Error();
      this.items = await res.json();
      this.loaded = true;
    } catch {
      this.error = true;
    }
  }
}">
  <!-- Loading state -->
  <div x-show="!loaded && !error">
    {% include "components/_loading.html" with size="md" %}
  </div>

  <!-- Error fallback -->
  <div x-show="error" x-cloak>
    {% include "components/_empty_state.html" with icon="alert-triangle" message="Could not load stats" cta_text="Retry" %}
  </div>

  <!-- Success content -->
  <div x-show="loaded" x-cloak>
    <template x-for="item in items" :key="item.id">
      <div x-text="item.label" class="p-2"></div>
    </template>
  </div>
</div>
```

### Server-Rendered Default + Alpine Enhancement

```html
<!-- Server provides initial HTML, Alpine enhances -->
<div x-data="{ enhanced: true }">
  <!-- Server-rendered static content (always visible) -->
  <table>
    {% for fw in firmwares %}
    <tr><td>{{ fw.name }}</td><td>{{ fw.version }}</td></tr>
    {% endfor %}
  </table>

  <!-- Alpine-only enhancement: sort controls -->
  <div x-show="enhanced" x-cloak class="mt-2">
    <button @click="/* client-side sort */">Sort by Name</button>
  </div>
</div>
```

### Graceful Feature Detection

```html
<div x-data="{
  clipboardSupported: !!navigator.clipboard,
}">
  <button x-show="clipboardSupported" x-cloak @click="/* copy */">
    Copy to Clipboard
  </button>
  <span x-show="!clipboardSupported" x-cloak class="text-[var(--color-text-muted)] text-sm">
    Select and copy manually
  </span>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Entire page depends on Alpine | Nothing renders without JS | Server-render critical content |
| No loading state between init and data | Blank flash | Show skeleton/spinner |
| Error state without retry option | Dead end for user | Add retry button |

## Red Flags

- Critical content (phone numbers, addresses, forms) only rendered via Alpine
- No `<noscript>` fallback for essential functionality
- Error states that show technical messages to end users

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
