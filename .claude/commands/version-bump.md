# /version-bump â€” Bump version and update changelog

Bump the version number in pyproject.toml and move CHANGELOG.md Unreleased entries to a new versioned section with release date.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Determine Version Bump

- [ ] Read current version from `pyproject.toml` (`[project]` or `[tool.poetry]` section)

- [ ] If $ARGUMENTS specifies version type (major, minor, patch), use it

- [ ] If $ARGUMENTS specifies exact version, use it

- [ ] Default to patch bump if unspecified

- [ ] Calculate new version (semver: MAJOR.MINOR.PATCH)

### Step 2: Update pyproject.toml

- [ ] Update `version = "X.Y.Z"` in `pyproject.toml`

- [ ] Verify no other version references need updating

### Step 3: Update CHANGELOG.md

- [ ] Read `CHANGELOG.md` and find `[Unreleased]` section

- [ ] Create new version header: `## [X.Y.Z] - YYYY-MM-DD`

- [ ] Move all `[Unreleased]` entries under the new version header

- [ ] Keep empty `[Unreleased]` section at top for future changes

- [ ] Add comparison link at bottom if using GitHub-style links

### Step 4: Release Notes

- [ ] Compile release notes from changelog entries

- [ ] Highlight breaking changes (if major bump)

- [ ] Note migration steps if applicable

### Step 5: Verify

- [ ] Confirm version in pyproject.toml matches changelog header

- [ ] Run `& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev`

- [ ] Verify Markdown renders correctly

### Step 6: Summary

- [ ] Print: Previous version â†’ New version

- [ ] Print: Changes included in this release

- [ ] Remind: commit with message `chore: bump version to X.Y.Z`
