---
paths: [".github/agents/*.agent.md", ".claude/agents/*.md"]
---

# Agent File Format Rules

Rules for creating and maintaining agent definition files.

## Two Agent Locations

| Location | Format | Purpose |
|----------|--------|---------|
| `.github/agents/<name>.agent.md` | VS Code / Copilot agent | Available in VS Code agent picker |
| `.claude/agents/<name>.md` | Claude Code agent | Used by Claude Code CLI |

## .github Agent Format

```yaml
---
name: agent-name
description: >-
  One-line description. Use when: trigger phrases.
---
```

Body contains: Role description, scope/checklist, detection methods, output format.

## .claude Agent Format

```yaml
---
model: sonnet
tools:
  - grep_search
  - read_file
  - run_in_terminal
---
```

- `model` MUST be `haiku` (fast/cheap) or `sonnet` (capable).
- `tools` array restricts which tools the agent can use.
- Read-only agents: `grep_search`, `read_file`, `list_dir`, `semantic_search`.
- Write agents: add `replace_string_in_file`, `create_file`, `run_in_terminal`.

## Naming Conventions

- Agent names MUST be lowercase kebab-case.
- Name pattern: `<domain>-<action>` (e.g., `security-auditor`, `frontend-builder`).
- Regression agents: `regression-<domain>` (e.g., `regression-security`).
- Orchestrator agents: `<domain>-orchestrator` or `<domain>-guardian`.

## Required Content

Every agent definition MUST include:

1. **Role** — what the agent does (one paragraph).
2. **Scope** — what files/areas the agent operates on.
3. **Procedure** — step-by-step workflow the agent follows.
4. **Output** — what the agent reports back.

## Anti-Patterns

- NEVER create agents that duplicate existing agent capabilities.
- NEVER create write agents for audit-only tasks — use read-only tool sets.
- NEVER create agents without a quality gate reference.
