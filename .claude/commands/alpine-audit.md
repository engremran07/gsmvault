# /alpine-audit â€” Alpine.js pattern compliance audit

Audit Alpine.js usage: x-cloak on conditionals, x-data structure, animation+x-show conflict prevention, and store pattern compliance.

## Scope

$ARGUMENTS

## Checklist

### Step 1: x-cloak on Conditionals

- [ ] Find all elements with `x-show` â€” verify each has `x-cloak` attribute

- [ ] Find all elements with `x-if` â€” verify each has `x-cloak` attribute

- [ ] Missing `x-cloak` causes FOUC (flash of unstyled content) â€” flag as critical

### Step 2: Animation + x-show Conflict

- [ ] Find elements with both `x-show` and CSS animation/transition classes

- [ ] Specifically check for `animate-*`, `transition-*` classes on `x-show` elements

- [ ] Animation classes override `display:none`, causing flicker â€” flag as critical

- [ ] Fix: remove animation classes from `x-show` elements, use `x-transition` instead

### Step 3: x-data Structure

- [ ] Verify `x-data` attributes use valid JavaScript object syntax

- [ ] Check for overly complex inline `x-data` â€” should be extracted to Alpine component

- [ ] Verify no `x-data` duplicates on nested elements (unexpected scope)

- [ ] Check Alpine component registration in `static/js/src/`

### Step 4: Alpine Store Patterns

- [ ] Check `Alpine.store()` usage for shared state

- [ ] Verify stores are initialized before use (script order in base.html)

- [ ] Check for direct DOM manipulation that should use Alpine reactivity instead

### Step 5: Event Handling

- [ ] Verify `@click`, `@submit`, `@keydown` handlers reference defined methods

- [ ] Check `$dispatch` usage follows event bus patterns

- [ ] Verify `x-on:` long-form matches `@` shorthand consistently

### Step 6: Theme Switcher

- [ ] Verify theme switcher in `_theme_switcher.html` stores preference in `localStorage`

- [ ] Check `data-theme` attribute updates on `<html>` element

- [ ] Verify all 3 themes (dark, light, contrast) are selectable

- [ ] Check `--color-accent-text` works correctly in all themes

### Step 7: Report

- [ ] List all non-compliant patterns with file:line references

- [ ] Categorize: Critical (FOUC/flicker), Major (broken interaction), Minor (style)

- [ ] Provide specific fix for each finding
