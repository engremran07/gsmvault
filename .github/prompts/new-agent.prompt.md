---
agent: 'agent'
description: 'Create a new .agent.md file with frontmatter, description, checklist, patterns, and quality gate.'
tools: ['semantic_search', 'read_file', 'grep_search', 'list_dir', 'file_search', 'run_in_terminal']
---

# New Agent

Create a new `.github/agents/<agent-name>.agent.md` file following the GSMFWs agent format. The user will provide the agent's purpose.

## Step 1 — Validate the Agent Need

1. Check `.github/agents/` to ensure no existing agent already covers this role.
2. If a similar agent exists, suggest extending its responsibilities instead.
3. Determine the agent's specialization: backend, frontend, security, testing, DevOps, content, etc.

## Step 2 — Research the Format

1. Read 2-3 existing agents in `.github/agents/` to understand the expected format and depth.
2. Read `.claude/rules/agent-format.md` if it exists, for format compliance rules.
3. Note the naming convention: `<role>.agent.md` (kebab-case).

## Step 3 — Create the Agent File

Create `.github/agents/<agent-name>.agent.md` with this structure:

```markdown
---
name: '<Agent Name>'
description: '<One-line description of the agent role>'
---

# <Agent Name>

## Role

One paragraph describing:
- What this agent specializes in.
- What types of tasks it handles.
- What apps/layers it operates on.

## Responsibilities

Bullet list of specific responsibilities:
- [Responsibility 1]
- [Responsibility 2]
- [Responsibility 3]

## Checklist

Ordered checklist the agent follows for every task:

1. [ ] **Understand the request**: Read the user's requirements fully before acting.
2. [ ] **Search first**: Check for existing implementations before creating anything new.
3. [ ] **[Domain-specific step]**: [What to check/do specific to this agent's domain].
4. [ ] **[Implementation step]**: [How to implement changes in this domain].
5. [ ] **Quality gate**: Run ruff check, ruff format, Django check — zero errors.
6. [ ] **Documentation**: Update README.md, AGENTS.md, copilot-instructions.md if needed.

## Patterns

### Pattern 1: [Name]

When to apply this pattern and how:

```python
# Example code following GSMFWs conventions
```

### Pattern 2: [Name]

When to apply and how:

```python
# Another example
```

## Anti-Patterns

Things this agent must NEVER do:

- ❌ [Anti-pattern 1 with explanation]
- ❌ [Anti-pattern 2 with explanation]
- ❌ [Anti-pattern 3 with explanation]

## Conventions

Platform conventions this agent must follow:

- **App boundaries**: Models/services don't cross app boundaries. Use `EventBus` for cross-app communication.
- **Type safety**: Full type hints on all public APIs. `ModelAdmin[MyModel]` generic typing.
- **Security**: Sanitize HTML with `apps.core.sanitizers.sanitize_html_content()`. Auth checks with `getattr(request.user, "is_staff", False)`.
- **Database**: No raw SQL. `select_for_update()` on financial mutations. `@transaction.atomic` on multi-model writes.
- **Templates**: Use components from `templates/components/`. HTMX fragments must NOT use `{% extends %}`. Alpine `x-show` elements need `x-cloak`.
- **Dissolved apps**: Never reference: `security_suite`, `security_events`, `crawler_guard`, `ai_behavior`, `device_registry`, `gsmarena_sync`, `fw_verification`, `fw_scraper`, `download_links`, `admin_audit`, `email_system`, `webhooks`.

## Skills

Skills this agent should load for relevant tasks:

- `<skill-name>` — [When to load this skill]
- `<skill-name>` — [When to load this skill]

## Quality Gate

After every task, this agent MUST run:

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

Zero tolerance: no lint warnings, no type errors, no Django check issues.
```

## Step 4 — Customize for the Domain

Replace all placeholder content with domain-specific details:

- **Backend agent**: Focus on models, services, migrations, ORM, transactions.
- **Frontend agent**: Focus on templates, Alpine.js, HTMX, Tailwind, components.
- **Security agent**: Focus on auth, CSRF, XSS, CSP, rate limiting, input validation.
- **Testing agent**: Focus on pytest, fixtures, factories, coverage, assertions.
- **Admin agent**: Focus on admin views, `_render_admin`, admin templates, KPI cards.
- **API agent**: Focus on DRF serializers, viewsets, permissions, throttling, pagination.
- **SEO agent**: Focus on metadata, sitemaps, JSON-LD, redirects, internal linking.
- **DevOps agent**: Focus on deployment, settings, requirements, Celery, Redis, PostgreSQL.

## Step 5 — Verify Quality

- Read the completed agent file to ensure it's comprehensive.
- Verify all code examples use GSMFWs conventions.
- Ensure the agent name follows kebab-case convention.
- Ensure frontmatter has `name` and `description` fields.
- Update governance counts in `AGENTS.md` and `GOVERNANCE.md` if they track agent counts.
