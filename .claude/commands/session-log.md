# /session-log â€” Create or update SESSION_LOG.md entry

Add a structured entry to SESSION_LOG.md documenting the current work session: tasks completed, files changed, decisions made, and follow-up items.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Gather Session Context

- [ ] Review git diff for files changed in this session: `git diff --stat`

- [ ] Review git log for commits made: `git log --oneline -20`

- [ ] Note any pending/uncommitted changes

- [ ] If $ARGUMENTS provides session description, use it as the entry title

### Step 2: Read Existing Log

- [ ] Read `SESSION_LOG.md` to understand current format and last entry

- [ ] Determine the next entry number/date

### Step 3: Compose Entry

- [ ] Date/time header (ISO 8601 format)

- [ ] Session title/description

- [ ] Tasks completed (bullet list)

- [ ] Files modified (grouped by app/area)

- [ ] Key decisions made and rationale

- [ ] Issues encountered and resolutions

- [ ] Follow-up items / TODOs for next session

### Step 4: Write Entry

- [ ] Prepend new entry to SESSION_LOG.md (newest first)

- [ ] Follow the existing format exactly

- [ ] Keep entries concise â€” bullet points, not paragraphs

### Step 5: Verify

- [ ] Confirm entry renders correctly in Markdown

- [ ] Verify no sensitive information (keys, passwords) in the log
