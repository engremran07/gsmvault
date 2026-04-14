---
paths: ["static/js/**/*.js"]
---

# JavaScript Safety

Security and code quality rules for client-side JavaScript.

## Content Security Policy

- All inline `<script>` tags MUST include the CSP nonce: `<script nonce="{{ request.csp_nonce }}">`.
- The nonce is generated per-request by the `csp_nonce` middleware — never hardcode or reuse nonces.
- External scripts loaded from CDN MUST include Subresource Integrity (SRI) `integrity` attributes.
- NEVER add `'unsafe-inline'` or `'unsafe-eval'` to the CSP policy to work around nonce requirements.

## Forbidden APIs

- NEVER use `eval()`, `Function()` constructor, or `setTimeout`/`setInterval` with string arguments.
- NEVER use `innerHTML` with user-supplied or server-rendered untrusted data — use `textContent` for text-only updates.
- NEVER use `document.write()` — it blocks parsing and is incompatible with CSP.
- NEVER use `outerHTML` assignment with unsanitised content.
- NEVER expose sensitive data (tokens, API keys, user PII) in client-side JavaScript variables or data attributes.

## Code Standards

- Use `const` for values that don't change, `let` for variables — NEVER use `var`.
- Use `"use strict";` at the top of all non-module scripts.
- Wrap initialisation code in `document.addEventListener("DOMContentLoaded", () => { ... })`.
- Use `try/catch` for operations that may fail (network requests, JSON parsing, storage access).
- Use `async/await` over raw Promises for readability.

## Event Handling

- Use `addEventListener` — never inline event handlers (`onclick="..."`) except for CDN fallback `onerror`.
- Remove event listeners when elements are destroyed (especially in HTMX `htmx:beforeSwap`).
- Debounce high-frequency events (scroll, resize, input) with `requestAnimationFrame` or a debounce utility.

## Module Organisation

- Source files in `static/js/src/` — organised by feature (theme-switcher, notifications, ajax).
- Minified output in `static/js/dist/`.
- Shared utilities in `static/js/src/utils.js`.
- NEVER create global variables — use IIFE, modules, or Alpine stores for encapsulation.
