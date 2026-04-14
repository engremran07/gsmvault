---
name: htmx-history-replaceUrl
description: "URL replace with hx-replace-url. Use when: updating the URL without adding to browser history, replacing current history entry, sort/filter changes."
---

# HTMX History Replace URL

## When to Use

- Updating the URL to reflect current state without growing history stack
- Sort order changes, filter toggles where back button should skip intermediates
- Search-as-you-type where each keystroke shouldn't create a history entry

## Rules

1. Use `hx-replace-url="true"` to replace (not push) the current URL
2. Use `hx-replace-url="/custom/"` to replace with a specific URL
3. Back button goes to the page BEFORE the series of replaces
4. Prefer replace over push for rapid-fire URL updates (search, sort, filter)

## Patterns

### Live Search with URL Replace

```html
<input type="search" name="q"
       hx-get="{% url 'forum:search' %}"
       hx-target="#search-results"
       hx-trigger="keyup changed delay:300ms"
       hx-replace-url="true"
       placeholder="Search topics...">
<div id="search-results"></div>
```

### Sort Column without History Pollution

```html
<th>
  <a hx-get="{% url 'admin:firmware_list' %}?sort=name&order=asc"
     hx-target="#firmware-table"
     hx-replace-url="true">
    Name ↑
  </a>
</th>
```

### Filter Panel

```html
<form hx-get="{% url 'firmwares:list' %}"
      hx-target="#firmware-grid"
      hx-replace-url="true"
      hx-trigger="change">
  <select name="brand">
    <option value="">All Brands</option>
    {% for brand in brands %}
    <option value="{{ brand.slug }}">{{ brand.name }}</option>
    {% endfor %}
  </select>
  <select name="type">
    <option value="">All Types</option>
    <option value="official">Official</option>
    <option value="modified">Modified</option>
  </select>
</form>
```

## Anti-Patterns

```html
<!-- WRONG — push URL on search (creates entry per keystroke) -->
<input hx-get="/search/" hx-trigger="keyup delay:300ms" hx-push-url="true">

<!-- WRONG — replace URL on major navigation (user can't go back) -->
<a hx-get="/other-page/" hx-replace-url="true">Go to other page</a>
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| `hx-push-url` on search input | History flooded with search entries | Use `hx-replace-url` |
| `hx-replace-url` on navigation | Can't use back button | Use `hx-push-url` for navigation |
| No URL update at all on filters | State not bookmarkable | Add `hx-replace-url="true"` |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
