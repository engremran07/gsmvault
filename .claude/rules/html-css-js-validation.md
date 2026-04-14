---
paths: ["templates/**/*.html", "static/css/**", "static/js/**/*.js"]
---

# HTML / CSS / JS Validation

All frontend files MUST pass their respective validation checks with zero errors.

## HTML Rules

| Rule | Applies To | Fix |
|------|-----------|-----|
| All tags must be properly closed | `*.html` | Close all tags or use self-closing |
| Attributes must use valid HTML5 names | `*.html` | Remove non-standard attributes (except `x-`, `hx-`, `data-`) |
| No duplicate `id` attributes on a page | `*.html` | Use unique IDs per template scope |
| `alt` attribute required on `<img>` tags | `*.html` | Add descriptive alt text |
| `<table>` needs proper structure | `*.html` | Use `<thead>`, `<tbody>`, `<th>` |
| All `{% block %}` have matching `{% endblock %}` | `*.html` | Pair all template tags |
| No unclosed Django template tags | `*.html` | Close `{% if %}`, `{% for %}`, `{% with %}` |
| Boolean attributes don't need values | `*.html` | Use `disabled` not `disabled="disabled"` |

### Django Template Exceptions
- `x-data`, `x-show`, `x-cloak`, `x-text`, `x-html`, `x-bind`, `x-on`, `x-ref`, `x-if`, `x-for`, `x-transition`, `x-effect`, `x-init`, `x-model`, `x-modelable`, `x-teleport`, `x-intersect`, `x-trap`, `x-mask`, `@click`, `@submit`, `:class`, `:style` — Alpine.js directives, valid
- `hx-get`, `hx-post`, `hx-put`, `hx-delete`, `hx-patch`, `hx-target`, `hx-swap`, `hx-trigger`, `hx-push-url`, `hx-replace-url`, `hx-select`, `hx-select-oob`, `hx-indicator`, `hx-boost`, `hx-confirm`, `hx-headers`, `hx-vals`, `hx-encoding`, `hx-ext`, `hx-on` — HTMX attributes, valid
- `data-*` attributes — HTML5 standard, valid
- `{% ... %}` and `{{ ... }}` — Django template tags, valid in `.html`

## CSS / SCSS Rules

| Rule | Applies To | Fix |
|------|-----------|-----|
| Valid CSS property names | `*.css`, `*.scss` | Use only valid CSS3+ properties |
| No duplicate property declarations | `*.css`, `*.scss` | Remove duplicates |
| Selector specificity should be reasonable | `*.css`, `*.scss` | Avoid over-nesting (max 3 levels in SCSS) |
| CSS custom properties must be defined | `*.css`, `*.scss` | Define `--var-name` before using `var(--var-name)` |
| No `!important` unless overriding third-party | `*.css`, `*.scss` | Restructure specificity instead |
| Color values should use theme tokens | `*.css`, `*.scss` | Use `var(--color-*)` not hex/rgb |
| Units should be consistent | `*.css`, `*.scss` | Use `rem` for sizing, `px` for borders |
| No empty rulesets | `*.css`, `*.scss` | Remove or fill with properties |

## JavaScript Rules

| Rule | Applies To | Fix |
|------|-----------|-----|
| No `var` declarations | `*.js` | Use `const` or `let` |
| No `eval()` or `Function()` constructor | `*.js` | Use safe alternatives |
| No `document.write()` | `*.js` | Use DOM manipulation |
| No `innerHTML` with user input | `*.js` | Use `textContent` or sanitize first |
| Functions should use proper error handling | `*.js` | Add try/catch for async, check return values |
| No console.log in production code | `*.js` | Remove or use conditional logging |
| Event listeners should be cleaned up | `*.js` | Remove listeners in destroy/cleanup |
| No global variable pollution | `*.js` | Use Alpine stores or module pattern |
| Strict equality (`===`) over loose (`==`) | `*.js` | Use `===` and `!==` |

## JSON Rules

| Rule | Applies To | Fix |
|------|-----------|-----|
| Valid JSON syntax | `*.json` | Fix commas, quotes, brackets |
| No trailing commas | `*.json` | Remove trailing commas |
| No comments in JSON | `*.json` | Remove comments (use JSONC for config files) |
| Consistent indentation (2 spaces) | `*.json` | Reformat with 2-space indent |

## YAML Rules

| Rule | Applies To | Fix |
|------|-----------|-----|
| Consistent indentation (2 spaces) | `*.yml`, `*.yaml` | Use 2-space indent |
| No tab characters | `*.yml`, `*.yaml` | Replace tabs with spaces |
| Proper quoting for special characters | `*.yml`, `*.yaml` | Quote strings with `:`, `#`, `{` |
