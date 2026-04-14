# /governance-status â€” Report governance file inventory and compliance

Report counts and health of governance files: rules, hooks, commands, agents, skills, and overall compliance metrics.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Rules Inventory

- [ ] Count files in `.claude/rules/`

- [ ] List each rule file with its `applyTo` glob pattern

- [ ] Check for rules without `applyTo` (always-active rules)

- [ ] Verify no duplicate or conflicting rules

### Step 2: Commands Inventory

- [ ] Count files in `.claude/commands/`

- [ ] List each command with its one-line description

- [ ] Check for commands without clear checklists

- [ ] Verify no duplicate command names

### Step 3: Agents Inventory

- [ ] Count files in `.claude/agents/` (if exists)

- [ ] Count files in `.github/agents/` (if exists)

- [ ] List each agent with its specialty

- [ ] Verify agent files follow the agent format rules

### Step 4: Skills Inventory

- [ ] Count skill directories in `.github/skills/`

- [ ] List each skill with its description

- [ ] Verify each skill has a `SKILL.md` file

- [ ] Check for skills referenced in code but missing SKILL.md

### Step 5: Hooks Inventory

- [ ] Count hook files in `.claude/hooks/` (if exists)

- [ ] List each hook with its trigger and matcher

### Step 6: Key Documentation

- [ ] Verify `AGENTS.md` exists and is up to date

- [ ] Verify `CLAUDE.md` exists and is up to date

- [ ] Verify `.github/copilot-instructions.md` exists and is up to date

- [ ] Verify `CONTRIBUTING.md` exists

- [ ] Verify `README.md` exists

### Step 7: Compliance Metrics

- [ ] Total governance files count

- [ ] Coverage: which app areas have dedicated rules

- [ ] Gaps: app areas without governance coverage

- [ ] Print summary table: Category | Count | Status
