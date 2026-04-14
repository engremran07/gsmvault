# Skill Sources â€” External Attribution

## Overview

This project's governance system draws inspiration from multiple sources.
Patterns have been studied, adapted for Django 5.2, and re-implemented as
original work. No code has been copied â€” only structural patterns and
organizational strategies have been adopted.

---

## Referenced Projects

### AcTechs (Flutter/Firebase)

A Flutter/Firebase project with 14 governance files. Key patterns adopted:

| Pattern | Source | Adaptation |
| --------- | -------- | ------------ |
| Regression Registry | `REGRESSION_REGISTRY.md` | CSV-style bug tracker with guards, adapted for Django model/view/template regressions |
| Session Log | `SESSION_LOG.md` | Dated work ledger format, adopted directly |
| Multi-Subagent Audit | 7-agent concurrent audit prompt | Adapted for Django: security, frontend, architecture, quality, regression agents |
| Post-Implementation Checklist | 22 sequential gates | Expanded to cover Django-specific checks (migrations, ORM, templates, HTMX) |
| Weekly Governance Audit | Scheduled Monday 5am workflow | Adapted as GitHub Actions workflow for governance file validation |
| Breakage Chain Documentation | Coupling chain format | Expanded from 5 chains to 10 Django-specific chains |

### Footwear (Flutter/Firebase ERP)

A Flutter/Firebase ERP with 46 governance files â€” the most comprehensive
governance system studied. Key patterns adopted:

| Pattern | Source | Adaptation |
| --------- | -------- | ------------ |
| Band-Aid Loop Reversal | Candidate ledger for ambiguous fixes | Adapted as regression detection agents that flag potential band-aids |
| Inline Audit Skill | 7-layer audit on every fix | Adapted as `repo-audit` skill with Django-specific audit layers |
| Chartered Accountant Skill | Double-entry ledger integrity | Adapted for `apps.wallet` financial transaction patterns |
| Domain-Specific Skills | 21 skills in `.claude/skills/` | Expanded to 27 skills covering Django, frontend, security, testing |
| Breakage Chain Patterns | 5 documented coupling chains | Template adopted, content rewritten for Django dependencies |
| Multi-Agent Orchestration | 20-agent audit roster | Expanded to 44 agents covering all Django domains |

### Blogs-main (Next.js/TypeScript)

A Next.js 16 TypeScript project with 30+ governance files. Primary reference
for SEO, Ads, and Distribution feature parity:

| Feature Area | Reference Capabilities | Django Adaptation |
| -------------- | ---------------------- | ------------------- |
| SEO Engine | 21 audit checks, TF-IDF keywords, knowledge graph, auto-interlinking | `apps.seo` with Django ORM models, Celery tasks for async processing |
| Ads Management | 11 network types, 21 ad positions, 14 format components | `apps.ads` with 18+ models, rotation/targeting engines, affiliate pipeline |
| Distribution | 7 platforms, circuit breaker, 5 message styles | `apps.distribution` with Django service layer, Celery for async syndication |
| Content Pipeline | Automated publishing workflow | `apps.blog` with approval workflow, AI-assisted editing |

---

## Open Source Influences

### Claude Code Documentation

The governance file structure (rules, hooks, commands, agents) follows
patterns documented in the Claude Code official documentation. File formats,
YAML frontmatter conventions, and lifecycle hook points are based on the
Claude Code specification.

### Django Coding Style

Code conventions follow the Django project's official coding style guide:

- PEP 8 compliance (enforced via Ruff)
- Django model conventions (`__str__`, `Meta`, `verbose_name`)
- URL namespace patterns
- Template block naming conventions
- Management command structure

### OWASP Guidelines

Security rules and audit checks are based on the OWASP Top 10 (2021 edition):

- A01:2021 â€” Broken Access Control â†’ `auth-checks.md`, `regression-auth-checks`
- A02:2021 â€” Cryptographic Failures â†’ `secret-management.md`, `cookie-security.md`
- A03:2021 â€” Injection â†’ `xss-prevention.md`, `security-always.md` (no raw SQL)
- A04:2021 â€” Insecure Design â†’ `financial-safety.md`, `services-layer.md`
- A05:2021 â€” Security Misconfiguration â†’ `settings-safety.md`, `cors-policy.md`
- A06:2021 â€” Vulnerable Components â†’ `requirements-drift.md`, `dependency-check.ps1`
- A07:2021 â€” Auth Failures â†’ `consent-enforcement.md`, `rate-limit-enforcement.md`
- A08:2021 â€” Software/Data Integrity â†’ `migrations-safety.md`, `backup-safety.md`
- A09:2021 â€” Logging Failures â†’ `logging-safety.md`
- A10:2021 â€” SSRF â†’ `upload-validation.md`, `storage-patterns.md`

### Python Type Checking

Type annotation patterns follow Pyright strict mode conventions with
Django-specific adaptations from `django-stubs` and `djangorestframework-stubs`.

---

## License Compliance

All governance files in this project are **original work**. Patterns and
organizational strategies have been studied from the referenced projects,
but no source code, configuration files, or documentation text has been
copied verbatim.

- Rule files: Original content based on project-specific requirements
- Hook scripts: Original PowerShell scripts for this project's toolchain
- Agent definitions: Original role descriptions for this project's architecture
- Skill documents: Original procedures written for Django 5.2 + the project stack
- Breakage chains: Original analysis of this project's dependency graph

The referenced projects are credited here as sources of **inspiration for
governance patterns**, not as sources of code or content.

---

*Last updated: 2026-04-14.*
