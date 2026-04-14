# .claude/hooks/secrets-scan.ps1
# PreToolUse hook — scans staged files and command strings for credential patterns.
# Blocks git commit if credentials are detected. Exit 1 to block, exit 0 to allow.
#
# CLAUDE_TOOL_INPUT env var contains the tool input JSON (for Bash tool).

$ErrorActionPreference = "SilentlyContinue"

$toolName = $env:CLAUDE_TOOL_NAME
$toolInput = $env:CLAUDE_TOOL_INPUT

# Only run on Bash tool calls that look like git commit
if ($toolName -ne "Bash") { exit 0 }
if ($toolInput -notmatch "git\s+commit") { exit 0 }

$projectRoot = $PSScriptRoot | Split-Path | Split-Path

# Patterns that indicate credential exposure
$credentialPatterns = @(
    "sk-ant-",               # Anthropic API key
    "AKIA[0-9A-Z]{16}",     # AWS Access Key ID
    "sk_live_",              # Stripe live key
    "sk_test_",              # Stripe test key
    "ghp_",                  # GitHub personal access token
    "gho_",                  # GitHub OAuth token
    "ghs_",                  # GitHub Actions token
    "glpat-",                # GitLab PAT
    "BEGIN PRIVATE KEY",     # PEM private key
    "BEGIN RSA PRIVATE KEY", # RSA private key
    "-----BEGIN EC",         # EC private key
    "eyJhbGciOiJIUzI1NiJ9", # HS256 JWT (hardcoded secret risk)
    "DATABASE_URL\s*=\s*postgresql://[^@]+:[^@]+@",  # DB URL with password
    "SECRET_KEY\s*=\s*['\"][^'\"]{20,}",             # Hardcoded Django secret key
    "password\s*=\s*['\"][^'\"]{8,}",               # Hardcoded password
    "OPENAI_API_KEY\s*=",   # OpenAI key
    "GCS_CREDENTIALS",       # GCS credentials
    "service_account"        # Service account files
)

# Get staged file content
Push-Location $projectRoot
$stagedContent = & git diff --cached --unified=0 2>$null
Pop-Location

if ([string]::IsNullOrEmpty($stagedContent)) { exit 0 }

$found = @()
foreach ($pattern in $credentialPatterns) {
    $matches = $stagedContent | Select-String -Pattern $pattern -AllMatches
    if ($matches) {
        $found += "  - Pattern detected: $pattern"
    }
}

if ($found.Count -gt 0) {
    Write-Host ""
    Write-Host "SECRETS SCAN BLOCKED GIT COMMIT" -ForegroundColor Red
    Write-Host "Potential credentials detected in staged changes:" -ForegroundColor Red
    $found | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
    Write-Host ""
    Write-Host "Review staged changes: git diff --cached" -ForegroundColor Cyan
    Write-Host "Unstage: git reset HEAD <file>" -ForegroundColor Cyan
    Write-Host "Add to .gitignore if intentional and use env vars instead." -ForegroundColor Cyan
    exit 1
}

exit 0
