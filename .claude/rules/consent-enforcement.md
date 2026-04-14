---
paths: ["apps/consent/**", "templates/consent/**"]
---

# Consent Enforcement

User consent is a legal requirement (GDPR, ePrivacy). Consent MUST be freely given, specific, informed, and revocable. Auto-granting consent or bypassing the consent flow is a compliance violation.

## Consent Scopes

- **functional** — required for site operation, always granted, cannot be rejected by the user.
- **analytics** — traffic and behaviour tracking, requires explicit opt-in.
- **seo** — SEO-related tracking and third-party schema embedding, requires explicit opt-in.
- **ads** — ad targeting, affiliate tracking, rewarded ad engagement, requires explicit opt-in.
- NEVER bundle non-functional scopes with functional — each scope MUST be independently controllable.
- NEVER pre-check analytics, seo, or ads checkboxes — consent must be affirmative action.

## Form View Pattern — CRITICAL

- Consent form views (`accept_all`, `reject_all`, `accept`) MUST return `HttpResponseRedirect` to `HTTP_REFERER` — NEVER return JSON.
- The consent cookie is set on the redirect `HttpResponse` object.
- `fetch()` callers follow the redirect automatically — their `.then()` handler fires regardless.
- This pattern eliminates the "raw JSON on blank screen" bug class entirely.
- See `apps/consent/views.py` `_consent_done()` for the canonical implementation.
- For programmatic consent queries: use `consent/api/status/` (GET) and `consent/api/update/` (POST) — these are separate DRF endpoints that DO return JSON.

## Middleware and Decorators

- `apps.consent.middleware` enforces consent checks at the request level — runs on every request.
- `@consent_required` decorator gates views that need specific consent scopes (e.g., `@consent_required("analytics")`).
- Middleware sets consent context for templates via `apps.consent.context_processors`.
- NEVER bypass consent middleware for authenticated users — consent is per-user, not per-authentication-state.

## Data Handling

- Consent records stored in `ConsentRecord` model (server-side) — the cookie is a signed reference, not the truth.
- `ConsentEvent` logs every consent change (grant, revoke, modify) with timestamp and IP hash.
- NEVER store raw IP addresses in consent logs — use `hash_ip()` from `apps.consent.utils`.
- NEVER store raw User-Agent strings — use `hash_ua()` from `apps.consent.utils`.
- Consent withdrawal MUST be as easy as consent granting — provide a clear revoke mechanism on every page.

## Third-Party Integration

- Analytics scripts (Google Analytics, Plausible, etc.) MUST check consent status before loading.
- Ad network scripts MUST check `ads` consent scope before initializing.
- SEO schema injection MUST check `seo` consent scope.
- Use `{% if consent.analytics %}` template guards — NEVER load tracking scripts unconditionally.
