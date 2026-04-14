---
applyTo: 'README.md, AGENTS.md, .github/copilot-instructions.md'
---

# Release Surface Sync Instructions

## The Three-File Rule

Every new feature, app, model, service, or significant change **MUST** be documented in ALL THREE files before the task is considered complete:

| File | Audience | Depth |
|---|---|---|
| `README.md` | Public / developers / contributors | High-level: what it does, how to use it |
| `AGENTS.md` | AI agents / full architecture reference | Full depth: models, services, patterns, gotchas |
| `.github/copilot-instructions.md` | VS Code Copilot quick reference | Concise: identity, key patterns, critical gotchas |

## What Triggers a Sync

- New Django app added to `apps/`
- New model class created
- New service module or function added
- New URL namespace or endpoint group
- New reusable template component in `templates/components/`
- Dissolved app migration (app merged into another)
- New management command
- Architecture pattern change (e.g., new event type, new middleware)
- New Celery task or scheduled job
- New frontend library or CDN dependency
- Static architecture changes (new static files, major CSS/JS split, asset budget updates)

## README.md Updates

Public-facing documentation. Keep professional and organized:

```markdown
## Feature Name

Brief description of what it does and why it exists.

### Quick Start

How to use it — commands, configuration, examples.

### Key Points

- Bullet points of important behavior
- Configuration options
- Dependencies or prerequisites
```

## AGENTS.md Updates

Full architecture reference for AI agents. Include:

1. **App section**: Add to the Architecture tree if new app
2. **Model table**: All models with purpose column
3. **Service layer**: Key functions and their responsibilities
4. **URL patterns**: Namespace and key routes
5. **Celery tasks**: Task names, schedules, purpose
6. **Common Mistakes**: Add to the "Lessons Learned" section if applicable
7. **Dissolved apps**: Update the table if app was merged

Example model table format:

```markdown
| Model | Purpose |
| --- | --- |
| `NewModel` | Brief description of what it stores |
```

## .github/copilot-instructions.md Updates

Quick-reference card. Keep entries concise:

1. **Architecture table**: Add one-line app description
2. **Critical Gotchas**: Add numbered entry if applicable
3. **Key References**: Update if new reference doc created

## Validation Checklist

Before marking a task complete, verify:

- [ ] `README.md` has a section for the new feature/change
- [ ] `AGENTS.md` has full architectural details (models, services, patterns)
- [ ] `.github/copilot-instructions.md` has concise quick-reference entry
- [ ] All three files are internally consistent (no contradictions)
- [ ] Dissolved app references removed from all three files
- [ ] Model counts updated if models were added/removed
- [ ] App counts updated if apps were added/removed (currently 31)
- [ ] Static file changes are documented with rationale: why extension was insufficient and why split/new file was required
- [ ] Reusable component decisions are documented when UI patterns changed
- [ ] No-regression/operational readiness notes are reflected for significant changes (performance, observability, rollback)

## Forbidden Practices

- Never consider a feature "done" without updating all three files
- Never add an app to one file but not the others
- Never leave stale references to dissolved apps in any file
- Never document features differently across the three files (e.g., different model names)
- Never remove documentation for existing features without explicit request
- Never update `AGENTS.md` model tables without verifying against actual `models.py`
- Never add static files silently; document the split/new-file rationale when static surface changes
