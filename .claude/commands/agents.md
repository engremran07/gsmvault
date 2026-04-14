# /agents â€” Spawn Parallel Agent Team

Spawn a coordinated team of specialist agents to work on the current task in parallel.

## When to Use This Command

Use `/agents` when the task involves independent work across multiple domains simultaneously:
- New feature requiring backend models + API + frontend templates + tests
- Large refactor spanning multiple apps
- Full audit + fix cycle across the entire codebase

## Agent Team Structure

### Tier 1 â€” Orchestrator (runs first, plans the work)

- Agent: `orchestrator`
- Reads: CLAUDE.md + AGENTS.md + task description
- Produces: A numbered task list with clear assignments for each specialist

### Tier 2 â€” Specialists (run in parallel via git worktrees)

| Agent | Worktree | Owns |
|-------|----------|------|
| `django-backend` | `..\GSMFWs-backend` | `apps/` models, services, migrations |
| `frontend-builder` | `..\GSMFWs-frontend` | `templates/`, `static/` |
| `api-builder` | `..\GSMFWs-api` | `apps/*/api.py`, serializers |
| `test-writer` | `..\GSMFWs-tests` | `tests.py`, `conftest.py` |

### Tier 3 â€” Quality Gate (runs last, merges and validates)

- Agent: `quality-enforcer`
- Runs: `ruff check . --fix`, `ruff format .`, `manage.py check`
- Blocks: Does not complete until gate is green

## Setup Commands

```powershell
# Create worktrees for parallel agents
git worktree add ..\GSMFWs-backend feature/backend-work
git worktree add ..\GSMFWs-frontend feature/frontend-work
git worktree add ..\GSMFWs-tests feature/test-coverage

# Each Claude instance runs in its worktree directory
# VS Code: open a split terminal for each
```

## Coordination Protocol

1. Orchestrator produces task assignments (this session).
2. Spawn specialist agents via subagent calls with worktree isolation.
3. Each specialist completes its slice and reports back.
4. Orchestrator merges the work (manual `git merge` or cherry-pick).
5. Quality-enforcer runs the full gate on the merged result.

## Relevant Agents Available

See `.claude/agents/` for all 8 configured Claude Code agents.
See `.github/agents/` for all 39 VS Code Copilot specialist agents.
