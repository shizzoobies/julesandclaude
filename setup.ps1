<#
.SYNOPSIS
One-time machine setup for the Jules and Claude orchestration system.

.DESCRIPTION
Sets KANDA_ORCH_PATH to the location of this orchestration repo and adds the
repo dir to the User PATH so jules-dispatch.ps1 can be invoked from anywhere.
Idempotent: safe to re-run.
#>

[CmdletBinding()]
param(
  [string]$OrchPath = (Split-Path -Parent $MyInvocation.MyCommand.Path)
)

$ErrorActionPreference = 'Stop'

$OrchPath = (Resolve-Path -LiteralPath $OrchPath).Path
Write-Host "Orchestration repo path: $OrchPath" -ForegroundColor Cyan

# 1. Set KANDA_ORCH_PATH env var (User scope, persists across sessions)
[System.Environment]::SetEnvironmentVariable('KANDA_ORCH_PATH', $OrchPath, 'User')
$env:KANDA_ORCH_PATH = $OrchPath
Write-Host "Set KANDA_ORCH_PATH = $OrchPath (User scope)" -ForegroundColor Green

# 2. Add orchestration repo dir to User PATH (idempotent)
$userPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
if ($null -eq $userPath) { $userPath = "" }
$pathParts = $userPath -split ';' | Where-Object { $_ -ne "" }
if ($pathParts -notcontains $OrchPath) {
  $newPath = (@($pathParts) + $OrchPath) -join ';'
  [System.Environment]::SetEnvironmentVariable('PATH', $newPath, 'User')
  $env:PATH = "$env:PATH;$OrchPath"
  Write-Host "Added $OrchPath to User PATH" -ForegroundColor Green
} else {
  Write-Host "$OrchPath already on User PATH" -ForegroundColor DarkGray
}

# 3. Check gh CLI status
$ghCmd = Get-Command gh -ErrorAction SilentlyContinue
if ($ghCmd) {
  Write-Host "gh CLI found: $($ghCmd.Source)" -ForegroundColor Green
  try { & gh auth status -ErrorAction Stop 2>&1 | Out-Null } catch {}
  if ($LASTEXITCODE -eq 0) {
    Write-Host "gh is authenticated" -ForegroundColor Green
  } else {
    Write-Host "gh is not authenticated. Run: gh auth login" -ForegroundColor Yellow
  }
} else {
  Write-Host "gh CLI not found. Install with: winget install GitHub.cli" -ForegroundColor Yellow
}

# 4. Print next steps
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. If gh is not authenticated, run: gh auth login"
Write-Host "  2. Open a fresh PowerShell session so the PATH change takes effect"
Write-Host "  3. Onboard each Phase 1 repo:"
Write-Host "       runbooks\onboard-repo.ps1 -RepoName shizzoobies/kandadesigners.com"
Write-Host "       runbooks\onboard-repo.ps1 -RepoName shizzoobies/daily-prompt-generator"
Write-Host "  4. Connect each repo at https://jules.google.com/ (see NEXT_SESSION.md)"
