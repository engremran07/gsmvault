# Governance System Documentation

## Overview

This project uses a comprehensive AI governance system to guide autonomous
agents, enforce code quality, prevent regressions, and maintain architectural
consistency across 31 Django apps. Governance files are machine-readable
documents â€” rules, hooks, commands, agents, and skills â€” that shape how AI
assistants interact with the codebase.

Governance is not bureaucracy. Every file exists to prevent a class of errors
that has occurred (or will occur) during AI-assisted development. The system
is additive: new patterns are encoded as they're discovered.

---

## File Types

| Type | Location | Count | Format | Purpose |
| ------ | ---------- | ------- | -------- | --------- |
| Rules | `.claude/rules/` | 58 | Markdown + YAML frontmatter | Enforce constraints when editing specific file types |
| Hooks | `.claude/hooks/` | 36 | PowerShell (.ps1) | Automated checks at lifecycle points |
| Commands | `.claude/commands/` | 50 | Markdown | User-invoked workflows via slash commands |
| Agents | `.github/agents/` | 44 | Markdown + YAML frontmatter | Specialist AI agents for domain tasks |
| Skills | `.github/skills/` | 27 | Markdown (SKILL.md) | Domain knowledge packages loaded on demand |

### Supporting Documents

| File | Purpose |
| ------ | --------- |
| `AGENTS.md` | Full architecture reference (31 apps, conventions, patterns) |
| `CLAUDE.md` | Quick-reference card for AI agents |
| `CONTRIBUTING.md` | Developer workflow, commit format, PR process |
| `MASTER_PLAN.md` | Strategy, roadmap, implementation phases |
| `REGRESSION_REGISTRY.md` | Tracked regression entries with guards |
| `SESSION_LOG.md` | Dated work ledger across sessions |
| `BREAKAGE_CHAINS.md` | Known coupling chains that cause cascade failures |
| `AUDIT_CHECKLIST.md` | Post-implementation verification gates |
| `DEPLOYMENT_CHECKLIST.md` | Pre-deploy production verification |
| `SECURITY_POLICY.md` | Vulnerability reporting procedures |

---

## Rules (`.claude/rules/`)

Rules are constraint files that activate when an agent edits files matching
specific glob patterns. They use YAML frontmatter with a `paths:` array.

### Format

```yaml
---
paths: ["apps/*/models.py"]
---

# Rule Title

MUST do X. NEVER do Y. ALWAYS check Z.
```

- **Path-scoped rules**: Activate only when editing matching files
- **Global rules**: No `paths:` field â€” always active (e.g., `security-always.md`)
- **Keywords**: `MUST`, `NEVER`, `ALWAYS`, `FORBIDDEN`, `REQUIRED`
- **Length**: 20â€“150 lines (concise, prescriptive)
- **No Quality Gate block** â€” rules are constraints, not workflows

### Rule Categories (62 files)

#### Django Layer Rules (15)

| Rule | Scope | Purpose |
| ------ | ------- | --------- |
| `views-layer.md` | `apps/*/views.py` | View patterns, thin views, HTMX detection |
| `admin-views.md` | `apps/admin/views*.py` | Admin view patterns, `_render_admin` usage |
| `forms-layer.md` | `apps/*/forms.py` | Form validation, widget patterns |
| `urls-layer.md` | `apps/*/urls.py` | URL namespaces, pattern conventions |
| `tasks-layer.md` | `apps/*/tasks.py` | Celery task patterns |
| `signals-layer.md` | `apps/*/signals.py` | Signal handler patterns |
| `managers-layer.md` | `apps/*/managers.py` | Custom manager/queryset patterns |
| `migrations-safety.md` | `apps/*/migrations/*.py` | Migration safety rules |
| `apps-config.md` | `apps/*/apps.py` | App config conventions |
| `tests-layer.md` | `apps/*/tests*.py` | Test patterns |
| `middleware-layer.md` | `app/middleware/*.py` | Middleware patterns |
| `context-processors.md` | `apps/*/context_processors.py` | Context processor rules |
| `templatetags-layer.md` | `apps/*/templatetags/*.py` | Template tag patterns |
| `management-commands.md` | `apps/*/management/commands/*.py` | Management command patterns |
| `fixtures-layer.md` | `apps/*/fixtures/*.json` | Fixture conventions |

#### Frontend Rules (10)

| Rule | Scope | Purpose |
| ------ | ------- | --------- |
| `htmx-patterns.md` | `templates/**/fragments/*.html` | HTMX fragment rules |
| `alpine-patterns.md` | `templates/**/*.html` | Alpine.js x-cloak, x-show rules |
| `tailwind-tokens.md` | `templates/**/*.html` | CSS custom property usage |
| `scss-architecture.md` | `static/css/src/**` | SCSS file organization |
| `javascript-safety.md` | `static/js/**/*.js` | JS security and CSP |
| `lucide-icons.md` | `templates/**/*.html` | Icon usage patterns |
| `cdn-fallback.md` | `templates/base/base.html` | Multi-CDN fallback chain |
| `theme-variables.md` | `static/css/src/_themes.scss` | Theme variable rules |
| `responsive-design.md` | `templates/**/*.html` | Responsive patterns |
| `print-stylesheet.md` | `static/css/src/_print.scss` | Print media rules |

#### Security Rules (10)

| Rule | Scope | Purpose |
| ------ | ------- | --------- |
| `security-always.md` | `**` (global) | Always-active security constraints |
| `xss-prevention.md` | Models, services, views, templates | XSS sanitization rules |
| `auth-checks.md` | Views, API | Authentication guard patterns |
| `financial-safety.md` | Wallet, shop, marketplace, bounty | Financial transaction safety |
| `upload-validation.md` | Services, views | File upload validation |
| `cookie-security.md` | Settings, consent | Cookie security flags |
| `csp-enforcement.md` | Middleware, base template | CSP header rules |
| `cors-policy.md` | Settings | CORS configuration |
| `rate-limit-enforcement.md` | Security, firmwares, devices | Rate limiting rules |
| `consent-enforcement.md` | Consent app, templates | Privacy consent rules |
| `secret-management.md` | Settings, .env | Credential handling |

#### Infrastructure Rules (10)

| Rule | Scope | Purpose |
| ------ | ------- | --------- |
| `celery-tasks.md` | `apps/*/tasks.py` | Celery task patterns |
| `cache-patterns.md` | Services, views | Caching strategy |
| `logging-safety.md` | `apps/**/*.py` | Logging PII prevention |
| `queryset-optimization.md` | Services, views, managers | N+1, select_related |
| `settings-safety.md` | `app/settings*.py` | Settings configuration |
| `requirements-drift.md` | `requirements.txt` | Dependency management |
| `database-indexes.md` | `apps/*/models.py` | Index optimization |
| `connection-pooling.md` | `app/settings*.py` | DB connection pooling |
| `storage-patterns.md` | `apps/storage/**` | File storage rules |
| `backup-safety.md` | `apps/backup/**` | Backup/restore safety |

#### Governance Rules (5)

| Rule | Scope | Purpose |
| ------ | ------- | --------- |
| `skill-format.md` | `.github/skills/**/SKILL.md` | Skill file format |
| `agent-format.md` | `.github/agents/*.agent.md` | Agent file format |
| `regression-registry-format.md` | `REGRESSION_REGISTRY.md` | Registry entry format |
| `session-log-format.md` | `SESSION_LOG.md` | Session log format |
| `changelog-format.md` | `CHANGELOG.md` | Changelog entry format |

#### Quality Enforcement Rules (4)

| Rule | Scope | Purpose |
| ------ | ------- | --------- |
| `zero-tolerance-problems-tab.md` | `**` (global) | Master zero-tolerance policy for VS Code Problems tab |
| `markdown-lint.md` | `**/*.md` | Markdown lint compliance (MD001–MD050) |
| `html-css-js-validation.md` | `templates/**`, `static/**` | HTML/CSS/JS/JSON/YAML validation |
| `pyright-strict.md` | `**/*.py` | Pyright/Pylance strict type checking |

#### Foundation Rules (8)

| Rule | Scope | Purpose |
| ------ | ------- | --------- |
| `no-duplicate-patterns.md` | `**` (global) | Prevent infrastructure duplication |
| `no-versioned-files.md` | `**` (global) | Prevent `_v2.py` file copies |
| `unification-over-creation.md` | `**` (global) | Edit existing files, don't create new |
| `django-models.md` | `apps/*/models.py` | Model meta, \_\_str\_\_, related_name |
| `services-layer.md` | `apps/*/services*.py` | Service layer patterns |
| `api-layer.md` | `apps/*/api.py` | DRF API patterns |
| `frontend-templates.md` | `templates/**` | Template hierarchy rules |
| `views-layer.md` | `apps/*/views.py` | View layer patterns |

---

## Hooks (`.claude/hooks/`)

Hooks are PowerShell scripts triggered at specific lifecycle points during
AI-assisted editing. They run automatically â€” no user action required.

### Lifecycle Points

| Point | When | Use Case |
| ------- | ------ | ---------- |
| `PreToolUse` | Before a tool executes | Block dangerous operations, scan for secrets |
| `PostToolUse` | After a tool executes | Quality checks after file edits |
| `PreStop` | Before agent session ends | Final quality gate, session summary |
| `UserPromptSubmit` | When user submits a prompt | Session initialization, context loading |

### Blocking vs Non-Blocking

- **Exit code 0**: Success â€” proceed normally
- **Exit code 1**: Block â€” prevent the action (blocking hook)
- **Exit code 2**: Warning â€” continue but flag the issue (non-blocking)

### Hook Inventory (36 files)

| Hook | Lifecycle | Purpose |
| ------ | ----------- | --------- |
| `post-edit-quality.ps1` | PostToolUse | Ruff check after every file edit |
| `post-edit-no-versioned.ps1` | PostToolUse | Block `_v2.py` file creation |
| `pre-commit-quality.ps1` | PreToolUse | Full quality gate before commits |
| `pre-commit-no-duplicates.ps1` | PreToolUse | Block duplicate infrastructure |
| `pre-push-governance.ps1` | PreToolUse | Governance validation before push |
| `pre-stop-quality.ps1` | PreStop | Final quality check at session end |
| `session-start.ps1` | UserPromptSubmit | Initialize session context |
| `session-end-summary.ps1` | PreStop | Generate session summary |
| `secrets-scan.ps1` | PreToolUse | Scan for exposed secrets |
| `secrets-scan-enhanced.ps1` | PreToolUse | Deep secrets scan |
| `migration-safety.ps1` | PostToolUse | Verify migration safety |
| `template-audit.ps1` | PostToolUse | Template correctness check |
| `template-extends-check.ps1` | PostToolUse | Fragment isolation check |
| `import-boundary.ps1` | PostToolUse | Cross-app import detection |
| `test-coverage-gate.ps1` | PreStop | Test coverage threshold |
| `dependency-check.ps1` | PostToolUse | Dependency drift detection |
| `type-check-changed.ps1` | PostToolUse | Type check edited files |
| `regression-check.ps1` | PostToolUse | Regression pattern scan |
| `xss-audit-hook.ps1` | PostToolUse | XSS vulnerability scan |
| `csrf-audit-hook.ps1` | PostToolUse | CSRF protection check |
| `model-completeness.ps1` | PostToolUse | Model meta enforcement |
| `admin-registration-check.ps1` | PostToolUse | Admin model registration |
| `url-namespace-check.ps1` | PostToolUse | URL namespace validation |
| `related-name-check.ps1` | PostToolUse | FK related_name enforcement |
| `docstring-check.ps1` | PostToolUse | Docstring presence check |
| `unused-import-check.ps1` | PostToolUse | Unused import detection |
| `dead-code-check.ps1` | PostToolUse | Dead code detection |
| `god-file-check.ps1` | PostToolUse | Large file detection |
| `fragment-isolation-check.ps1` | PostToolUse | HTMX fragment isolation |
| `alpine-cloak-check.ps1` | PostToolUse | Alpine x-cloak enforcement |
| `htmx-csrf-check.ps1` | PostToolUse | HTMX CSRF header check |
| `tailwind-token-check.ps1` | PostToolUse | Tailwind token usage |
| `z-index-scale-check.ps1` | PostToolUse | Z-index scale compliance |
| `print-style-check.ps1` | PostToolUse | Print stylesheet check |
| `accessibility-hook.ps1` | PostToolUse | Accessibility check |
| `performance-hook.ps1` | PostToolUse | Performance pattern check |

---

## Commands (`.claude/commands/`)

Commands are user-invoked workflows accessible via slash commands (e.g.,
`/health`, `/audit`, `/deploy-check`). They are plain Markdown with checklists.

### Command Format

```text
# /command-name - Full Command Title

One-line description.

## Steps

### Step 1: First Action

<PowerShell command here>

### Step 2: Second Action

<Explanation>

## Output Format

<Expected deliverables>
```

### Command Inventory (50 files)

**Quality & Linting**: `health`, `lint-fix`, `format-all`, `type-check`,
`coverage-report`, `fix-all`, `qa`

**Testing**: `test-security`, `test-wallet`, `test-coverage`, `test-forum`,
`test-ads`, `test-seo`, `test-distribution`, `test-firmwares`, `test-devices`,
`test-admin`, `test-api`

**Auditing**: `audit`, `xss-audit`, `htmx-audit`, `alpine-audit`,
`seo-audit`, `template-check`, `dependency-audit`, `rtl-audit`,
`accessibility`, `performance`

**Infrastructure**: `celery-status`, `db-status`, `env-check`,
`cache-clear`, `static-build`, `migration-check`

**Governance**: `governance-status`, `regression-status`, `session-log`,
`changelog-update`, `version-bump`

**Workflow**: `deploy-check`, `security`, `seed-data`, `fixture-generate`,
`split-godfile`, `new-app`, `new-feature`, `review`, `pr`, `debug`, `agents`

### Repository Hygiene Workflow

- `/repo-hygiene-audit` performs temporary artifact discovery, stale-reference cleanup,
  and final quality re-verification.

---

## Agents (`.github/agents/`)

Agents are specialist AI assistants with domain expertise. Each agent file
defines a focused role with checklist rules, code patterns, and a quality gate.

### Agent Format

```yaml
---
name: kebab-case-agent-name
description: "One-line description. Use when: scenario1, scenario2."
---
```

Body includes: role description, checklist/rules, code patterns, quality gate.

### Agent Inventory (44 files)

**Architecture**: `backend-architect`, `frontend-architect`, `django-app-builder`,
`master-planner`

**Security**: `security-audit`, `security-commander`, `waf-configurator`,
`auth-specialist`

**Django**: `model-migration`, `service-builder`, `serializer-designer`,
`middleware-builder`, `celery-task-writer`, `signal-handler`

**Frontend**: `template-builder`, `htmx-developer`, `alpine-developer`,
`tailwind-styler`, `scss-architect`, `responsive-designer`, `theme-designer`,
`icon-manager`

**Testing & Quality**: `test-writer`, `integration-tester`, `code-reviewer`,
`quality-gatekeeper`, `linter-fixer`, `type-checker`

**Regression**: `regression-guardian`, `regression-security`,
`regression-frontend`, `regression-architecture`, `regression-quality`

**Domain**: `seo-optimizer`, `shop-builder`, `wallet-manager`,
`affiliate-tracker`, `content-strategist`, `email-designer`,
`i18n-translator`, `automation-pilot`

**DevOps**: `deployment-manager`, `api-endpoint`

### Repository Hygiene Governance Extension

The governance pack now includes dedicated hygiene enforcement assets:

- Rule: `.claude/rules/repo-hygiene-artifacts.md`
- Instruction: `.github/instructions/repo-hygiene.instructions.md`
- Skill: `.github/skills/repo-hygiene/SKILL.md`
- Agent: `.github/agents/repo-hygiene-enforcer.agent.md`
- Command workflow: `.claude/commands/repo-hygiene-audit.md`

These assets enforce multi-filetype Problems-tab cleanliness and strict temporary artifact lifecycle control.

---

## Skills (`.github/skills/`)

Skills are domain knowledge packages that agents load on demand. Each skill
directory contains a `SKILL.md` file with procedures, patterns, and examples.

### Skill Format

```yaml
---
name: skill-folder-name
description: "One-line description. Use when: scenarios."
---
```

Body includes: When to Use, Rules, Step-by-Step Procedure, Component
Inventory, Common Issues, Quality Gate.

### Skill Inventory (27 directories)

**Admin & UI**: `admin-components`, `admin-panel`, `enduser-components`,
`frontend-templates`

**Frontend**: `htmx-alpine`, `tailwind-theming`, `static-assets`,
`static-cdn-registry`

**Django**: `django-app-scaffold`, `api-design`, `data-pipeline`,
`requirements-management`

**Security**: `security-check`

**Testing**: `testing`

**Quality**: `quality-gate`

**Regression Detection**: `regression-detection`, `regression-app-boundaries`,
`regression-auth-checks`, `regression-csp-enforcement`,
`regression-csrf-protection`, `regression-database-safety`,
`regression-template-safety`, `regression-test-coverage`,
`regression-type-safety`, `regression-xss-prevention`

**Content**: `repo-audit`, `web-scraping`

---

## Quality Gate â€” Mandatory

Every agent, every task, every session â€” before and after:

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

**Zero tolerance**: No ruff warnings, no Pyright/Pylance errors, no Django
check issues, no VS Code Problems tab errors. Fix everything before marking
a task complete.

---

## Adding New Governance Files

### Adding a Rule

1. Create `.claude/rules/<rule-name>.md`
2. Add YAML frontmatter with `paths:` array (or omit for global rules)
3. Write prescriptive constraints using MUST/NEVER/ALWAYS language
4. Keep under 150 lines â€” rules are concise
5. Reference the rule in `GOVERNANCE.md` under the appropriate category

### Adding a Hook

1. Create `.claude/hooks/<hook-name>.ps1`
2. Add 3-line header comment (path, lifecycle point, description)
3. Set `$ErrorActionPreference` and derive `$projectRoot`
4. Use `Write-Host` with color coding for output
5. Exit with code 0 (pass), 1 (block), or 2 (warn)
6. Register in `.claude/settings.json` under the appropriate lifecycle point

### Adding a Command

1. Create `.claude/commands/<command-name>.md`
2. Use `# /command-name â€” Title` heading format
3. Write numbered steps with PowerShell code blocks
4. Include Output Format and Common Issues sections
5. Keep procedural and actionable

### Adding an Agent

1. Create `.github/agents/<agent-name>.agent.md`
2. Add YAML frontmatter: `name`, `description`
3. Write role description, checklist rules, code patterns
4. Include Quality Gate section
5. Keep between 60â€“150 lines

### Adding a Skill

1. Create `.github/skills/<skill-name>/SKILL.md`
2. Add YAML frontmatter: `name`, `description`
3. Write When to Use, Rules, Procedure, Examples
4. Include Component Inventory tables if applicable
5. Add Quality Gate section

---

## File Count Dashboard

| Category | Current | Target | Status |
| ---------- | --------- | -------- | -------- |
| Rules (`.claude/rules/`) | 58 | 50+ | Exceeded |
| Hooks (`.claude/hooks/`) | 36 | 30+ | Exceeded |
| Commands (`.claude/commands/`) | 50 | 50+ | Met |
| Agents (`.github/agents/`) | 44 | 500 | In progress |
| Skills (`.github/skills/`) | 27 | 1,000 | In progress |
| Root governance docs | 12 | 15+ | In progress |
| **Total governance files** | **~227** | **1,700+** | **Phase 1 complete** |

---

*Last updated: 2026-04-14. See `MASTER_PLAN.md` for the 12-month roadmap.*
