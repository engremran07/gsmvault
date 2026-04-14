---
paths: ["**"]
---

# Repository Hygiene and Artifact Elimination

This rule is always active and applies to every workflow, file type, and tooling surface.

## Goal

Keep the workspace and repository enterprise-clean with zero stale temporary artifacts, zero stale references, and zero avoidable diagnostics in the Problems tab.

## Always-Required Behavior

1. Remove transient artifacts created during work once they are no longer required.
2. Never leave references to removed temporary files in code, docs, prompts, workflows, scripts, or tests.
3. Treat diagnostics from real source files as blocking across all filetypes:
   - Python, Markdown, HTML, CSS, SCSS, JavaScript, TypeScript
   - JSON, YAML, TOML, INI, shell scripts, PowerShell
4. Keep generated output directories curated. Persist only intentional, versioned outputs.
5. Ensure governance files do not point to deleted paths.

## Temporary Artifact Policy

The following are temporary by default unless explicitly documented as permanent project assets:

- one-off scratch scripts
- ad-hoc output dumps in output/ used only for a single audit pass
- local benchmark logs not required for regression history
- stale temporary markdowns used for draft planning
- local caches and transient working files created by tools

## Forbidden Patterns

- Referencing deleted local artifacts in any committed file.
- Keeping stale links to temporary reports in prompts/agents/skills.
- Leaving renamed or moved files with dangling references.
- Completing a task without checking for temporary artifact residue.

## Required End-of-Task Checks

1. Verify Problems tab has no real source-file diagnostics.
2. Verify no stale artifact references remain.
3. Verify no temporary local files are accidentally tracked.
4. Verify governance references resolve to existing files.

## Cleanup Standard

When an artifact is needed for an audit session, keep it scoped and delete it after findings are integrated into canonical docs.

Canonical docs include:
- GOVERNANCE.md
- AGENTS.md
- REGRESSION_REGISTRY.md
- SESSION_LOG.md
- CHANGELOG.md
