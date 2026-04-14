# /changelog-update â€” Add CHANGELOG.md entry

Add a new entry to CHANGELOG.md following the Keep a Changelog format (keepachangelog.com).

## Scope

$ARGUMENTS

## Checklist

### Step 1: Determine Change Type

- [ ] Categorize the change using Keep a Changelog sections:
  - **Added** â€” new features
  - **Changed** â€” changes in existing functionality
  - **Deprecated** â€” soon-to-be removed features
  - **Removed** â€” removed features
  - **Fixed** â€” bug fixes
  - **Security** â€” vulnerability fixes

- [ ] If $ARGUMENTS specifies the type, use it; otherwise infer from recent commits

### Step 2: Gather Change Details

- [ ] Review recent git commits: `git log --oneline -20`

- [ ] Review changed files: `git diff --stat HEAD~5`

- [ ] Group changes by type (Added, Changed, Fixed, etc.)

- [ ] Write clear, user-facing descriptions (not implementation details)

### Step 3: Read Existing Changelog

- [ ] Read `CHANGELOG.md` to understand format and last version

- [ ] Identify current `[Unreleased]` section (create if missing)

### Step 4: Write Entry

- [ ] Add items under `[Unreleased]` section with appropriate type headers

- [ ] Each entry: single line starting with `-`, concise description

- [ ] Include ticket/issue references if applicable

- [ ] Group related changes together

### Step 5: Format Validation

- [ ] Verify entries follow Keep a Changelog format

- [ ] Verify date format: `[version] - YYYY-MM-DD`

- [ ] Verify `[Unreleased]` section exists at top

- [ ] Verify Markdown renders correctly
