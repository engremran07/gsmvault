# /new-feature â€” Plan and Scaffold New Feature

Plan and scaffold a new feature described in $ARGUMENTS following full project architecture.

## Phase 1: Clarify and Plan (ask before writing code)

Ask 3 clarifying questions:
1. Which existing app(s) does this feature belong to, or does it need a new app?
2. Does it need a new API endpoint, or is it view-only?
3. What is the primary user flow (who initiates, what data is created/changed)?

## Phase 2: Technical Design

Produce a feature design document covering:

### Data Layer

- New or modified models (with field names and types)
- Migrations needed
- Relationships to existing models (with `related_name`)

### Service Layer

- New service functions in `services.py` with signatures and purpose
- Transaction requirements (`@transaction.atomic` needed?)
- Cross-app event bus emissions if other apps need to react

### API Layer (if needed)

- Endpoint URL, method, request/response schema
- Permission class
- Serializer fields (explicit, no `"__all__"`)

### View/Template Layer (if needed)

- URL pattern
- Template file(s) and fragments
- Alpine.js or HTMX interactions

### Async Tasks (if needed)

- Celery tasks, schedule, retry policy

## Phase 3: Scaffold

After user approval of the design, create all files:

1. Create/modify models â€” run `makemigrations`
2. Create service functions
3. Create API endpoints (if needed)
4. Create views and URL patterns
5. Create templates and fragments
6. Create tests with happy path and at least one edge case

## Phase 4: Quality Gate

Run `/qa` â€” must pass before marking complete.

## Phase 5: Documentation

Update `README.md`, `AGENTS.md`, and `.github/copilot-instructions.md` with the new feature.
