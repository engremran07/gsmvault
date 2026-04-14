---
applyTo: 'templates/**/*.html, static/js/**/*.js'
---

# Alpine.js Component Conventions

## Component Encapsulation

Use `x-data` for component-local state:

```html
<div x-data="{ isOpen: false, search: '' }">
    <button @click="isOpen = !isOpen">Toggle</button>
    <div x-show="isOpen" x-cloak x-transition>
        <input x-model="search" placeholder="Search...">
    </div>
</div>
```

## x-cloak — MANDATORY

ALL elements with `x-show` or `x-if` MUST have `x-cloak` to prevent FOUC:

```html
<!-- CORRECT -->
<div x-show="isOpen" x-cloak>Content</div>
<template x-if="condition"><div x-cloak>Content</div></template>

<!-- WRONG — causes flash of unstyled content -->
<div x-show="isOpen">Content</div>
```

Ensure `[x-cloak] { display: none !important; }` exists in the CSS.

## Animation Conflict — CRITICAL

NEVER combine CSS animation classes with `x-show`. The animation overrides `display: none`:

```html
<!-- WRONG — animate-fade-in conflicts with x-show -->
<div x-show="isOpen" class="animate-fade-in">Content</div>

<!-- CORRECT — use x-transition for show/hide animations -->
<div x-show="isOpen" x-cloak
     x-transition:enter="transition ease-out duration-200"
     x-transition:enter-start="opacity-0 -translate-y-1"
     x-transition:enter-end="opacity-100 translate-y-0"
     x-transition:leave="transition ease-in duration-150"
     x-transition:leave-start="opacity-100 translate-y-0"
     x-transition:leave-end="opacity-0 -translate-y-1">
    Content
</div>
```

## Global Store

Use `Alpine.store()` for shared state across components:

```html
<script>
    document.addEventListener('alpine:init', () => {
        Alpine.store('notifications', {
            count: 0,
            items: [],
            add(message) {
                this.items.push({ message, id: Date.now() });
                this.count++;
            },
            dismiss(id) {
                this.items = this.items.filter(n => n.id !== id);
                this.count = Math.max(0, this.count - 1);
            }
        });
    });
</script>

<!-- Access store from any component -->
<span x-text="$store.notifications.count"></span>
```

## XSS Prevention — CRITICAL

NEVER use `x-html` with user-generated content:

```html
<!-- DANGER — XSS vulnerability -->
<div x-html="userComment"></div>

<!-- SAFE — auto-escaped by Alpine -->
<span x-text="userComment"></span>
```

If you must render HTML, ensure it has been sanitized server-side with
`apps.core.sanitizers.sanitize_html_content()` before embedding in the template.

## Theme Switching

Use `data-theme` attribute with CSS custom properties:

```html
<div x-data="{
    theme: localStorage.getItem('theme') || 'dark',
    setTheme(t) {
        this.theme = t;
        document.documentElement.setAttribute('data-theme', t);
        localStorage.setItem('theme', t);
    }
}">
    <button @click="setTheme('dark')">Dark</button>
    <button @click="setTheme('light')">Light</button>
    <button @click="setTheme('contrast')">Contrast</button>
</div>
```

## Component Communication

Use `$dispatch` for sibling/parent communication:

```html
<!-- Child dispatches event -->
<button @click="$dispatch('item-selected', { id: itemId })">Select</button>

<!-- Parent listens -->
<div @item-selected.window="handleSelection($event.detail)">
    ...
</div>
```

## Lifecycle Hooks

Use `x-init` for component initialization:

```html
<div x-data="{ items: [] }" x-init="items = await (await fetch('/api/v1/items/')).json()">
    <template x-for="item in items" :key="item.id">
        <div x-text="item.name"></div>
    </template>
</div>
```

## localStorage Safety

Always wrap localStorage in try/catch for private browsing compatibility:

```javascript
function safeGetStorage(key, fallback) {
    try { return localStorage.getItem(key) || fallback; }
    catch { return fallback; }
}
```
