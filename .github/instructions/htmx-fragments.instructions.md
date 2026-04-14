---
applyTo: 'templates/*/fragments/*.html'
---

# HTMX Fragment Conventions

## Core Rule: No Extends

HTMX fragments are injected into existing pages. They MUST be standalone HTML snippets:

```html
<!-- CORRECT — standalone fragment -->
<div id="search-results">
  {% for item in results %}
    <div class="result-item">
      <h3>{{ item.name }}</h3>
      <p>{{ item.description }}</p>
    </div>
  {% empty %}
    {% include "components/_empty_state.html" with icon="search" message="No results found" %}
  {% endfor %}
</div>

<!-- FORBIDDEN — fragments must NOT extend templates -->
{% extends "layouts/default.html" %}
{% block content %}...{% endblock %}
```

## CSRF in Fragment Forms

Forms inside fragments must include CSRF token. The global `hx-headers` on `<body>` handles
HTMX AJAX requests, but fragment forms rendered via swap still need the token:

```html
<form hx-post="{% url 'firmwares:create' %}" hx-target="#firmware-list" hx-swap="innerHTML">
    {% csrf_token %}
    {{ form.as_p }}
    <button type="submit">Submit</button>
</form>
```

## Target and Swap

Always specify `hx-target` for precise DOM replacement:

```html
<!-- Trigger element -->
<input
    type="search"
    name="q"
    hx-get="{% url 'firmwares:search' %}"
    hx-target="#search-results"
    hx-swap="innerHTML"
    hx-trigger="keyup changed delay:300ms"
    hx-indicator="#search-spinner"
    placeholder="Search firmwares..."
>

<!-- Target container -->
<div id="search-results">
    {% include "firmwares/fragments/search_results.html" %}
</div>

<!-- Loading indicator -->
<div id="search-spinner" class="htmx-indicator">
    {% include "components/_loading.html" %}
</div>
```

## Loading Indicators

Use `htmx-indicator` class for loading states:

```html
<button
    hx-post="{% url 'firmwares:approve' pk=fw.pk %}"
    hx-target="#firmware-{{ fw.pk }}"
    hx-swap="outerHTML"
    hx-indicator="#spinner-{{ fw.pk }}"
>
    Approve
</button>
<span id="spinner-{{ fw.pk }}" class="htmx-indicator">
    {% include "components/_loading.html" %}
</span>
```

## Out-of-Band Swaps

Update multiple page sections with a single response:

```html
<!-- Primary content swap -->
<div id="firmware-list">
    {% for fw in firmwares %}...{% endfor %}
</div>

<!-- OOB: update counter -->
<span id="firmware-count" hx-swap-oob="innerHTML">{{ total_count }}</span>

<!-- OOB: toast notification -->
<div id="toast-container" hx-swap-oob="beforeend">
    {% include "components/_alert.html" with type="success" message="Firmware approved!" %}
</div>
```

## Pagination Fragment

```html
<div id="firmware-list">
    {% for fw in page_obj %}
        <div class="firmware-card">{{ fw.name }}</div>
    {% endfor %}

    {% if page_obj.has_next %}
        <div
            hx-get="{% url 'firmwares:list' %}?page={{ page_obj.next_page_number }}"
            hx-target="#firmware-list"
            hx-swap="innerHTML"
            hx-trigger="revealed"
        >
            {% include "components/_loading.html" %}
        </div>
    {% endif %}
</div>
```

## Alpine.js in Fragments

Alpine.js components inside fragments work after swap — no special init needed.
Always add `x-cloak` on conditional elements:

```html
<div x-data="{ expanded: false }">
    <button @click="expanded = !expanded">Toggle</button>
    <div x-show="expanded" x-cloak x-transition>
        Expanded content
    </div>
</div>
```
