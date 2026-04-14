---
agent: 'agent'
description: 'Generate a changelog entry from recent git changes, grouped by Added/Changed/Fixed/Removed/Security.'
tools: ['semantic_search', 'read_file', 'grep_search', 'list_dir', 'file_search', 'run_in_terminal']
---

# Changelog Entry

Generate a structured changelog entry from recent code changes, following Keep a Changelog format.

## Step 1 — Gather Recent Changes

1. Run `git log --oneline -30` to see recent commits.
2. Run `git diff --stat HEAD~10..HEAD` (or user-specified range) for a file-level summary.
3. If the user specifies a date range or tag, use that instead: `git log --oneline --since="YYYY-MM-DD"`.
4. Read commit messages to understand intent behind each change.

## Step 2 — Analyze Changes by File Type

For each changed file, classify the change:

- **Model changes** (`models.py`): New models = Added, modified fields = Changed.
- **New files**: Any new `.py`, `.html`, `.js`, `.css` = Added.
- **Bug fixes**: Commits with "fix", "bug", "patch", "hotfix" in message = Fixed.
- **Removed files/features**: Deletions, dissolved apps = Removed.
- **Security changes**: Auth, CSRF, XSS, rate limiting, sanitization = Security.
- **Dependency changes** (`requirements.txt`): Added/updated/removed packages.
- **Migration files**: Schema changes to note.

## Step 3 — Read Key Changed Files

For significant changes, read the actual files to understand what was added or modified:

- New models: list model names and their purpose.
- New views: list URL paths and what they serve.
- New templates: list page names and functionality.
- New services: list function names and what they do.
- New API endpoints: list routes and methods.

## Step 4 — Categorize into Changelog Groups

### Added
- New features, models, views, templates, API endpoints, management commands.
- New governance files (rules, skills, agents, commands).
- New dependencies.

### Changed
- Modified behavior, updated models, refactored services.
- Updated dependencies (version bumps).
- Configuration changes.

### Fixed
- Bug fixes with brief description of what was wrong and what was fixed.
- Performance improvements.
- Type safety fixes.

### Removed
- Deprecated features removed.
- Dead code cleaned up.
- Dissolved app remnants removed.
- Unused dependencies removed.

### Security
- Auth improvements.
- Input validation additions.
- Sanitization changes (nh3).
- Rate limiting updates.
- CSRF/XSS fixes.
- Dependency security patches.

## Step 5 — Output the Changelog Entry

```markdown
## [Unreleased] - YYYY-MM-DD

### Added
- **[App]**: [Description of new feature/functionality]
  - [Detail with file reference if helpful]
- **[App]**: [Another addition]

### Changed
- **[App]**: [Description of what changed and why]

### Fixed
- **[App]**: [Bug description] — [root cause and fix]

### Removed
- **[App]**: [What was removed and why]

### Security
- **[App]**: [Security improvement description]

---

**Files changed**: X | **Insertions**: +Y | **Deletions**: -Z
```

Include links to relevant files where helpful. Keep descriptions concise but informative — someone reading the changelog should understand what changed without reading the code.
