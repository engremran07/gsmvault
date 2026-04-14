# /pr â€” Pull Request Preparation

Prepare a complete pull request summary for the current branch's changes.

## Steps

1. **Get branch diff**:
   ```powershell
   git diff main...HEAD --stat
   git log main...HEAD --oneline
   ```

2. **Run quality gate** (same as `/qa`):
   - ruff check, ruff format, manage.py check â€” all must pass.

3. **Generate PR summary** in this structure:

---

### Summary

[1-3 sentence description of what this PR does and why]

### Type of Change

- [ ] Bug fix

- [ ] New feature

- [ ] Breaking change

- [ ] Refactor / cleanup

- [ ] Documentation

- [ ] Dependency update

### Changes

**Modified apps / files:**
- `apps/<app>/`: [brief description of changes]
- `templates/<app>/`: [brief description]

**New models / migrations:**
- [model name] in `apps/<app>/` â€” [purpose]

**API changes:**
- [endpoint] â€” [what changed]

### Breaking Changes

[List any breaking changes, or "None"]

### Test Coverage

- [ ] New/updated tests in `apps/<app>/tests.py`

- [ ] All existing tests pass: `pytest --cov=apps`

### Documentation Updated

- [ ] `README.md` updated

- [ ] `AGENTS.md` updated (if architecture changed)

- [ ] `.github/copilot-instructions.md` updated (if critical conventions changed)

### Quality Gate

- [ ] `ruff check . --fix` â€” 0 issues

- [ ] `ruff format .` â€” no changes

- [ ] `manage.py check --settings=app.settings_dev` â€” 0 silenced

- [ ] `get_errors()` â€” clean

---

4. **Suggested commit message** (conventional commits format):
   ```
   feat(app): description
   
   - Bullet 1
   - Bullet 2
   
   Closes #<issue>
   ```
