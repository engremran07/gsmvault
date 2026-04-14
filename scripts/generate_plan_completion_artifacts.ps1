Set-Location D:\GSMFWs
$ErrorActionPreference = 'Stop'

# Governance-aligned completion artifact generator
# NOTE:
# - This script intentionally does NOT create agents/skills/rules files.
# - It only reports roadmap and governance completion metrics.

function Get-Count($path, $filter) {
    if (-not (Test-Path $path)) { return 0 }
    return (Get-ChildItem $path -Recurse -File -Filter $filter | Measure-Object).Count
}

$rules = Get-Count '.claude/rules' '*.md'
$hooks = Get-Count '.claude/hooks' '*.ps1'
$commands = Get-Count '.claude/commands' '*.md'
$githubAgents = Get-Count '.github/agents' '*.agent.md'
$claudeAgents = Get-Count '.claude/agents' '*.md'
$githubSkills = Get-Count '.github/skills' 'SKILL.md'
$claudeSkills = Get-Count '.claude/skills' 'SKILL.md'

$masterPlan = Get-Content '.\MASTER_PLAN.md' -Raw
$phaseMatches = [regex]::Matches($masterPlan, '### Phase\s+\d+:\s+.*✅')
$monthsSectionComplete = $masterPlan -match '## 12\. 12-Month Roadmap Closure \(Completed\)'

$summary = [ordered]@{
    generated_at = (Get-Date).ToString('s')
    rules = $rules
    hooks = $hooks
    commands = $commands
    github_agents = $githubAgents
    claude_agents = $claudeAgents
    github_skills = $githubSkills
    claude_skills = $claudeSkills
    roadmap_phases_marked_complete = $phaseMatches.Count
    has_12_month_closure_section = $monthsSectionComplete
    governance_mode = 'strict-no-auto-generation'
}

$summary | ConvertTo-Json -Depth 4 | Set-Content '.\output\plan_completion_summary.json' -Encoding utf8

Write-Output 'plan_completion_summary=output/plan_completion_summary.json'
Write-Output "rules=$rules"
Write-Output "hooks=$hooks"
Write-Output "commands=$commands"
Write-Output "github_agents=$githubAgents"
Write-Output "claude_agents=$claudeAgents"
Write-Output "github_skills=$githubSkills"
Write-Output "claude_skills=$claudeSkills"
Write-Output "roadmap_phases_marked_complete=$($phaseMatches.Count)"
Write-Output "has_12_month_closure_section=$monthsSectionComplete"
