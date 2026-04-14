---
paths: ["templates/base/base.html"]
---

# CDN Fallback Chain

Rules for the multi-CDN fallback strategy used in the base template.

## Fallback Order

- Primary: **jsDelivr** — fastest, most reliable global CDN.
- Fallback 1: **cdnjs** — Cloudflare-backed, high availability.
- Fallback 2: **unpkg** — npm-based CDN, last remote option.
- Fallback 3: **Local vendor** — bundled in `static/vendor/`, always available offline.
- This order MUST be maintained for all vendor libraries (Tailwind, Alpine, HTMX, Lucide).

## Version Pinning

- ALWAYS pin exact versions in CDN URLs — never use `@latest`, `@^4`, or version ranges.
- Example: `cdn.jsdelivr.net/npm/alpinejs@3.14.9/dist/cdn.min.js` — not `@3` or `@latest`.
- When updating a library version, update ALL four CDN URLs and the local vendor copy simultaneously.
- Document the current version of each vendor library in `static/vendor/README.md` or equivalent.

## Integrity & Security

- All CDN `<script>` and `<link>` tags MUST include `integrity` (SRI hash) and `crossorigin="anonymous"`.
- Generate SRI hashes with `shasum` or the SRI Hash Generator — never skip integrity checks.
- If an SRI hash fails, the fallback chain activates — this is the expected recovery path.
- NEVER add CDN domains to CSP `script-src` without SRI — use `script-src 'strict-dynamic'` with nonces instead.

## Fallback Implementation

- Use `onerror` attribute on `<script>` tags to trigger the next fallback in the chain.
- For CSS, use a JavaScript check (e.g., test if a class exists) to detect failed stylesheet loads.
- The local vendor fallback MUST be tested periodically — serve the page with network disabled.
- Local vendor files live in `static/vendor/<library>/` with the exact same version as CDN.

## Maintenance

- NEVER remove local vendor fallbacks — they are the offline safety net.
- When adding a new vendor library, add entries for all 4 levels of the fallback chain.
- Test the fallback chain by temporarily blocking CDN domains in browser DevTools.
- Log fallback activations in the browser console for debugging: `console.warn("CDN fallback activated for <lib>")`.
