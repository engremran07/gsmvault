---
paths: ["CHANGELOG.md", "apps/changelog/**"]
---

# Changelog Format Rules

Rules for maintaining changelogs and version release documentation.

## Changelog Entry Format

Follow [Keep a Changelog](https://keepachangelog.com/) convention:

```markdown
## [version] — YYYY-MM-DD

### Added
- New feature description.

### Changed
- Modification to existing functionality.

### Fixed
- Bug fix description.

### Removed
- Removed feature or deprecated item.

### Security
- Security fix or improvement.
```

## Version Numbering

- Use Semantic Versioning: `MAJOR.MINOR.PATCH`.
- MAJOR: breaking changes to API or DB schema.
- MINOR: new features, backward-compatible.
- PATCH: bug fixes, documentation, governance updates.
- Pre-release: `1.0.0-alpha.1`, `1.0.0-beta.2`.

## Rules

- ALWAYS add changelog entries for user-facing changes.
- NEVER modify entries for released versions — append corrections.
- Group changes by category (Added/Changed/Fixed/Removed/Security).
- Link to relevant issues or PRs where applicable.
- Include migration notes for breaking changes.
- Keep descriptions concise — one line per item.
- Governance-only changes (rules, agents, skills) go under PATCH with "### Changed".

## Apps Changelog Model

The `apps.changelog` app tracks version releases programmatically:
- `ChangelogEntry` model: version, date, category, description.
- Management command: `manage.py changelog_update` to sync from CHANGELOG.md.
- API endpoint for version history.
