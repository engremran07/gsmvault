# /test-forum â€” Run forum app test suite

Execute all tests for the community forum app covering topics, replies, polls, reactions, trust levels, wiki headers, and search.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Run Forum Tests

- [ ] Full suite: `& .\.venv\Scripts\python.exe -m pytest apps/forum/ -v --settings=app.settings_dev`

- [ ] Specific test: `& .\.venv\Scripts\python.exe -m pytest apps/forum/ -v -k "$ARGUMENTS" --settings=app.settings_dev`

- [ ] With coverage: `& .\.venv\Scripts\python.exe -m pytest apps/forum/ -v --cov=apps/forum --cov-report=term-missing`

### Step 2: Verify Feature Coverage

- [ ] Topic CRUD: create, edit, delete, pin, lock, close, move, merge

- [ ] Reply CRUD: create, edit, delete, quote, @mentions

- [ ] Polls: create poll, cast vote, single/multiple choice, secret ballot

- [ ] Reactions: toggle like, configurable reaction types, reply reactions

- [ ] Trust levels: auto-promotion criteria, level checks, permission gates

- [ ] Wiki headers: create, edit, history tracking

- [ ] Search: topic search, inline HTMX search, category filtering

- [ ] 4PDA features: useful posts, FAQ entries, changelogs, device linking

- [ ] Private messages: create, reply, user access control

- [ ] Moderation: flags, warnings, IP bans, move/merge logs

### Step 3: Check Results

- [ ] All tests pass (zero failures)

- [ ] No deprecation warnings from Django 5.2

- [ ] Coverage above project threshold

- [ ] Run quality gate: `& .\.venv\Scripts\python.exe -m ruff check apps/forum/`
