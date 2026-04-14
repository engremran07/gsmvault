---
paths: ["templates/**/fragments/*.html"]
---

# HTMX Fragment Patterns

Rules for HTMX HTML-over-the-wire fragments used throughout the Django-served frontend.

## Fragment Structure

- Fragments MUST NOT use `{% extends %}` — they are standalone HTML snippets injected into existing pages.
- Fragments MUST NOT include `{% load static %}` unless they reference static assets directly.
- Fragments MUST be placed in `templates/<app>/fragments/` — never alongside full-page templates.
- Each fragment MUST be a self-contained, valid HTML snippet (no `<html>`, `<head>`, or `<body>` tags).

## Targeting & Swapping

- ALWAYS use `hx-target` with stable DOM IDs (`#result-list`, `#user-table-body`), never fragile CSS selectors.
- Default swap is `hx-swap="innerHTML"` — use it for content replacement inside a container.
- Use `hx-swap="outerHTML"` when replacing the target element itself (e.g., updating a single row).
- Use `hx-swap="beforeend"` for append patterns (infinite scroll, chat messages).
- For multi-target updates, use `hx-swap-oob="true"` on additional elements in the response.
- NEVER use `hx-swap="delete"` without a confirmation step.

## CSRF & Headers

- CSRF is handled globally via `<body hx-headers='{"X-CSRFToken": "{{ csrf_token }}"}'>` in `base.html`.
- NEVER add per-request `hx-headers` for CSRF — the global handler covers all HTMX requests.
- NEVER add `{% csrf_token %}` inside HTMX fragment forms — CSRF is in the header, not the body.

## Prohibited Patterns

- NEVER use `hx-boost` on forms or action buttons — it causes double-submission and redirect issues.
- NEVER use `hx-push-url` on fragments that update partial content — only on full navigation actions.
- NEVER return JSON from an HTMX endpoint — always return rendered HTML fragments.

## Loading & Error States

- Use `htmx-indicator` class on loading spinners: `<div class="htmx-indicator">Loading...</div>`.
- Pair with `hx-indicator="#my-spinner"` on the triggering element.
- Handle errors with the `htmx:responseError` event — show a toast or inline error message.
- Return appropriate HTTP status codes: 200 for success, 422 for validation errors with error HTML.

## View Pattern

- Views serving HTMX fragments MUST check `request.headers.get("HX-Request")` to decide response type.
- Full-page requests render the complete template; HTMX requests render only the fragment.
- Use `HX-Trigger` response header to fire client-side events after successful mutations.
