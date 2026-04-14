---
agent: 'agent'
description: 'Verify project documentation is current: README.md, AGENTS.md, copilot-instructions.md match actual app structure and features.'
tools: ['semantic_search', 'read_file', 'grep_search', 'list_dir', 'file_search', 'run_in_terminal']
---

# Documentation Check

Verify that all project documentation accurately reflects the current codebase state. Flag stale references, missing sections, and outdated information.

## Step 1 — Inventory Current State

1. List all apps in `apps/` directory to get the actual app count.
2. For each app, check `models.py` to get current model names.
3. Check `apps/admin/` view modules to verify admin coverage.
4. Count files in `templates/components/` to verify component count.
5. Count governance files: rules in `.claude/rules/`, hooks in `.claude/hooks/`, commands in `.claude/commands/`, skills in `.github/skills/`, agents in `.github/agents/`.

## Step 2 — Check README.md

Read `README.md` and verify:

- [ ] App count matches actual `apps/` directory count.
- [ ] Feature list matches implemented features (check models exist for claimed features).
- [ ] Technology versions are current (Django, Python, Tailwind, Alpine, HTMX, Lucide).
- [ ] Installation instructions work (commands are correct).
- [ ] No references to dissolved apps.
- [ ] Architecture description matches current structure.

## Step 3 — Check AGENTS.md

Read `AGENTS.md` and verify:

- [ ] App list in Architecture section matches actual apps (31 apps post-consolidation).
- [ ] `apps.core` module table matches actual exports — read `apps/core/` to verify.
- [ ] Dissolved apps reference table is complete and accurate.
- [ ] Model counts per app match reality.
- [ ] Frontend architecture section matches actual template/static structure.
- [ ] Forum section matches actual `apps/forum/models.py` model count (30+).
- [ ] Ads section matches actual `apps/ads/models.py` model count (18+).
- [ ] SEO section matches actual `apps/seo/models.py` features.
- [ ] Component list matches files in `templates/components/`.
- [ ] Governance counts match actual file counts.
- [ ] Quality gate commands are correct.
- [ ] Build/test commands work.
- [ ] No references to dissolved app names in import examples.

## Step 4 — Check copilot-instructions.md

Read `.github/copilot-instructions.md` and verify:

- [ ] Architecture snapshot matches AGENTS.md (should be consistent).
- [ ] Gotchas list is complete and accurate.
- [ ] Key references table links to existing files.
- [ ] Critical rules match current conventions.
- [ ] Environment details are correct (Python version, venv path, settings module).

## Step 5 — Cross-Reference Consistency

Check that all three docs agree on:

- Total app count.
- Component count in `templates/components/`.
- Governance file counts (rules, hooks, commands, skills, agents).
- Technology versions.
- Dissolved app list.
- App boundary rules.
- Quality gate commands.

## Step 6 — Check for Stale References

Search all documentation files for:

- References to non-existent files: `grep_search` for file paths mentioned in docs, verify they exist.
- References to dissolved apps: search for `security_suite`, `security_events`, `crawler_guard`, `ai_behavior`, `device_registry`, `gsmarena_sync`, `fw_verification`, `fw_scraper`, `download_links`, `admin_audit`, `email_system`, `webhooks` in docs.
- Dead links: internal file references that point to moved/deleted files.
- Outdated model names or field names.

## Step 7 — Output Findings

```markdown
## Documentation Audit

### Summary
- README.md: [UP TO DATE / NEEDS UPDATE]
- AGENTS.md: [UP TO DATE / NEEDS UPDATE]
- copilot-instructions.md: [UP TO DATE / NEEDS UPDATE]

### Stale References Found
| File | Line | Issue | Fix |
|------|------|-------|-----|
| ... | ... | ... | ... |

### Missing Documentation
- [Features implemented but not documented]

### Inconsistencies Between Docs
- [Where docs disagree with each other]

### Recommended Updates
1. [Prioritized list of documentation fixes]
```
