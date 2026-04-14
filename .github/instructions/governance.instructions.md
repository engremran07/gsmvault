---
applyTo: '.claude/**, .github/agents/**, .github/skills/**, .github/prompts/**, .github/instructions/**'
---

# Governance System Instructions

## Overview

The GSMFWs platform uses a comprehensive AI governance system with 6 artefact types across two toolchains (Claude Code in `.claude/` and GitHub Copilot in `.github/`).

## Artefact Types

### 1. Rules (`.claude/rules/*.md`)

Context-specific coding rules with YAML frontmatter. Auto-injected when working in matched file paths.

```markdown
---
paths: ["apps/*/models.py"]
---

# Rule Title

Rule content with MUST/NEVER/ALWAYS language.
```

- `paths` array uses glob patterns for file matching
- Some rules use `paths: ["**"]` for universal enforcement (e.g., `security-always.md`, `no-versioned-files.md`, `no-duplicate-patterns.md`)
- Rules without `paths` key (using `---` only) are always active
- Keep rules focused: one concern per file

### 2. Hooks (`.claude/hooks/*.ps1`)

PowerShell scripts triggered by Claude Code lifecycle events (pre-commit, post-edit, etc.). Used for automated quality enforcement.

- All hooks are `.ps1` (PowerShell) — this is a Windows project
- Hooks should be idempotent and fast
- Exit code 0 = success, non-zero = block the action

### 3. Commands (`.claude/commands/*.md`)

Reusable command templates invoked by name. Define multi-step workflows.

```markdown
---
description: Brief description of what this command does
---

# Command Name

Step-by-step instructions for the agent to follow.
```

### 4. Agents (`.github/agents/*.agent.md`)

Specialist agent definitions with YAML frontmatter for VS Code Copilot Chat.

```markdown
---
name: agent-name
description: What this agent specializes in
tools: [tool1, tool2]
---

# Agent Name

System prompt and instructions for the agent.
```

- Agent names should be kebab-case
- Description should be one concise sentence
- Tools array lists the VS Code tools the agent can use

### 5. Skills (`.github/skills/<name>/SKILL.md`)

Domain-specific knowledge documents organized in subdirectories. Each skill has its own folder containing a `SKILL.md` file.

```text
.github/skills/
  admin-components/
    SKILL.md
  api-design/
    SKILL.md
  testing/
    SKILL.md
```

- Skill folder names use kebab-case
- `SKILL.md` is the canonical filename (uppercase)
- Skills are loaded on-demand when a matching task is detected
- Skills contain actionable patterns, code examples, and forbidden practices
- Skills reference actual GSMFWs models, services, and patterns

### 6. Instructions (`.github/instructions/*.instructions.md`)

VS Code Copilot instructions with YAML frontmatter specifying `applyTo` glob patterns.

```markdown
---
applyTo: 'apps/*/models.py'
---

# Title

Contextual coding instructions applied when editing matched files.
```

- `applyTo` uses glob patterns matching workspace-relative paths
- Multiple patterns separated by commas: `'apps/*/views.py, apps/*/views_*.py'`
- Content should be actionable: patterns, examples, forbidden practices

## Naming Conventions

| Type | Location | Convention | Example |
|---|---|---|---|
| Rules | `.claude/rules/` | `kebab-case.md` | `django-models.md` |
| Hooks | `.claude/hooks/` | `kebab-case.ps1` | `pre-commit-lint.ps1` |
| Commands | `.claude/commands/` | `kebab-case.md` | `quality-gate.md` |
| Agents | `.github/agents/` | `kebab-case.agent.md` | `security-auditor.agent.md` |
| Skills | `.github/skills/<name>/` | `SKILL.md` (uppercase) | `testing/SKILL.md` |
| Instructions | `.github/instructions/` | `kebab-case.instructions.md` | `models.instructions.md` |

## Forbidden Practices

- **Never create versioned governance files** — no `rule_v2.md`, `SKILL_new.md`, `command_backup.md`
- **Never duplicate rules** — check existing rules before creating new ones
- **Never create rules without `paths`** unless they are truly universal
- **Never put business logic in hooks** — hooks enforce quality gates, not features
- **Never create agents without a clear specialization** — each agent has one domain
- **Never create skills that duplicate existing instruction content** — skills go deeper than instructions
- **Never create instructions that contradict rules** — instructions provide context, rules enforce constraints
- **Never hardcode project paths in governance files** — use relative paths and glob patterns

## When to Create Each Type

| Need | Create |
|---|---|
| Enforce coding constraint on specific files | Rule |
| Automate quality check on save/commit | Hook |
| Define reusable multi-step workflow | Command |
| Specialist AI persona for specific domain | Agent |
| Deep domain knowledge with examples | Skill |
| Contextual guidance for file editing | Instruction |

## Quality Standards

- Every governance file must be production-quality — no stubs, no TODOs
- Every file must reference actual GSMFWs patterns (real model names, real imports)
- Every rule must have at least one concrete example
- Every skill must have code examples that compile against the actual codebase
- Check for existing coverage before creating — prefer extending over creating new

## Global Hard Rules (Non-Negotiable)

These rules are global and strict across `.claude/**`, `.github/**`, backend, frontend, static, and database workflows.

1. **No extra files by default**
  - Never create a new file if an existing canonical file can be extended safely.
  - New files are permitted only when architecture requires them (new app boundary, mandatory migration file, or proven file-size split).
2. **Reusable components first**
  - Always check `templates/components/` before introducing template markup patterns.
  - Duplicating card/modal/table/search/pagination structures inline is forbidden when a reusable component exists.
3. **Static assets stay minimal and structured**
  - Keep static layout coherent (`static/css/src`, `static/js`, `static/vendor`, `static/img`).
  - Do not create additional static files without clear need.
  - Split oversized static files only when they become operationally heavy (lag/perf), and keep split boundaries domain-based.
4. **Clean architecture and data integrity**
  - Keep backend/frontend/static/database changes synchronized and coherent.
  - No temporary forks, shadow implementations, or duplicated business logic across layers.
5. **No regression closure gate**
  - A task is not complete until quality gate checks pass and affected contracts/UI remain behaviorally consistent.

## Enterprise Guardrails (Recommended Defaults)

- **Performance budgets**: enforce practical limits for static asset sizes and template payload growth.
- **Observability**: require structured logs and meaningful error context for non-trivial flows.
- **Safe rollout**: prefer feature-flagged activation for high-impact behavior changes.
- **Backward compatibility**: preserve API and migration safety for rolling deployments.
- **Operational readiness**: every significant change should have a rollback path and verification checklist.
