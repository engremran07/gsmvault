---
agent: 'agent'
description: 'Verify governance file completeness: count rules, hooks, commands, skills, agents and check format compliance.'
tools: ['semantic_search', 'read_file', 'grep_search', 'list_dir', 'file_search', 'run_in_terminal']
---

# Governance Check

Audit the AI governance system for completeness and format compliance. The platform uses rules, hooks, commands, skills, and agents to enforce code quality.

## Step 1 — Count Governance Files

Run an inventory of all governance components:

### Rules (`.claude/rules/`)
1. List all files in `.claude/rules/`.
2. Count total `.md` files. Target: 50+ rules.
3. For each rule, verify it has YAML frontmatter with `paths` or is always-active (no `applies_to`).

### Hooks (`.claude/hooks/`)
1. List all files in `.claude/hooks/`.
2. Count total hook files. Target: 30+ hooks.

### Commands (`.claude/commands/`)
1. List all files in `.claude/commands/`.
2. Count total `.md` files. Target: 50+ commands.

### Skills (`.github/skills/`)
1. List all directories in `.github/skills/`.
2. Count total skill directories. Each must contain a `SKILL.md` file.
3. Verify each skill directory has `SKILL.md` — flag any missing.

### Agents (`.github/agents/`)
1. List all files in `.github/agents/`.
2. Count total `.agent.md` files. Target: 44+ agents.

## Step 2 — Rule Format Compliance

For a sample of 10 rules, read each and verify:

- [ ] Has YAML frontmatter block (`---` delimiters).
- [ ] Frontmatter has `paths` array (or is always-active with no `applies_to`).
- [ ] Has a `# Title` heading.
- [ ] Contains actionable rules (not just descriptions).
- [ ] References actual codebase patterns (file paths, function names).
- [ ] Uses tables for structured information where appropriate.

## Step 3 — Skill Format Compliance

For a sample of 10 skills, read each `SKILL.md` and verify:

- [ ] Has proper heading structure.
- [ ] Contains Overview section explaining when to use.
- [ ] Contains Rules or Patterns section with specific guidance.
- [ ] Contains Code Examples with actual GSMFWs-style code.
- [ ] Contains Anti-Patterns section (what NOT to do).
- [ ] Contains Quality Gate section.
- [ ] References actual codebase patterns (apps, models, services).

## Step 4 — Agent Format Compliance

For a sample of 10 agents, read each `.agent.md` and verify:

- [ ] Has YAML frontmatter.
- [ ] Has Description section.
- [ ] Has Checklist or Steps section.
- [ ] Has Quality Gate section.
- [ ] References actual codebase conventions.

## Step 5 — Coverage Analysis

Check if governance files cover all critical areas:

### Must-Have Rule Coverage
- [ ] App boundaries (cross-app import rules).
- [ ] Security (CSRF, XSS, auth checks, sanitization).
- [ ] Database safety (no raw SQL, select_for_update, transactions).
- [ ] Type safety (type hints, ModelAdmin typing, no blanket ignore).
- [ ] Template safety (HTMX fragments, Alpine patterns, components).
- [ ] Financial safety (wallet, shop, marketplace, bounty).
- [ ] Frontend patterns (Tailwind tokens, theme variables, CDN fallback).

### Must-Have Skill Coverage
- [ ] Admin panel patterns.
- [ ] API design (DRF serializers, viewsets, permissions).
- [ ] Frontend templates (HTMX, Alpine, Tailwind).
- [ ] Testing patterns (pytest, factory_boy).
- [ ] Security patterns (auth, CSRF, XSS, CSP).
- [ ] SEO patterns (metadata, sitemaps, JSON-LD).
- [ ] Service layer patterns (transactions, caching, events).

## Step 6 — Output Report

```markdown
## Governance Audit Report

### Inventory
| Component | Location | Count | Target | Status |
|-----------|----------|-------|--------|--------|
| Rules | .claude/rules/ | X | 50+ | ✅/⚠️ |
| Hooks | .claude/hooks/ | X | 30+ | ✅/⚠️ |
| Commands | .claude/commands/ | X | 50+ | ✅/⚠️ |
| Skills | .github/skills/ | X | 27+ | ✅/⚠️ |
| Agents | .github/agents/ | X | 44+ | ✅/⚠️ |

### Format Compliance
- Rules: X/10 sampled pass format check
- Skills: X/10 sampled pass format check
- Agents: X/10 sampled pass format check

### Coverage Gaps
- [List of missing governance coverage areas]

### Recommendations
1. [Prioritized list of governance improvements]
```
