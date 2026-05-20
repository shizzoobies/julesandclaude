<#
.SYNOPSIS
Sync the master AGENTS.md from the orchestration repo to every connected Kanda repo.

.DESCRIPTION
Reads runbooks/connected-repos.txt (one owner/repo per line, lines starting with
# are comments), clones each repo if missing under the orchestration repo's
parent dir, copies agents/AGENTS.md over the local AGENTS.md, commits the
change if different, and pushes.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$orchPath = $env:KANDA_ORCH_PATH
if (-not $orchPath -or -not (Test-Path -LiteralPath $orchPath)) {
  Write-Error "KANDA_ORCH_PATH not set. Run setup.ps1 first."
  exit 1
}

$listPath = Join-Path $orchPath 'runbooks\connected-repos.txt'
$masterAgents = Join-Path $orchPath 'agents\AGENTS.md'
$parent = Split-Path -Parent $orchPath

if (-not (Test-Path -LiteralPath $listPath)) {
  Write-Error "connected-repos.txt not found at $listPath"
  exit 1
}

$repos = Get-Content -LiteralPath $listPath | Where-Object {
  $_ -and ($_.Trim() -ne '') -and -not $_.Trim().StartsWith('#')
}

foreach ($repoName in $repos) {
  $repoName = $repoName.Trim()
  $bareName = $repoName -replace '^.+/', ''
  $localPath = Join-Path $parent $bareName

  if (-not (Test-Path -LiteralPath $localPath)) {
    Write-Host "Cloning $repoName ..." -ForegroundColor Cyan
    git clone "https://github.com/$repoName.git" $localPath
    if ($LASTEXITCODE -ne 0) {
      Write-Host "  clone failed, skipping" -ForegroundColor Red
      continue
    }
  }

  Copy-Item -LiteralPath $masterAgents -Destination (Join-Path $localPath 'AGENTS.md') -Force
  Push-Location $localPath
  try {
    git add AGENTS.md 2>&1 | Out-Null
    git diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
      git commit -m "Sync AGENTS.md from orchestration repo" 2>&1 | Out-Null
      git push 2>&1 | Out-Null
      Write-Host "$repoName : updated" -ForegroundColor Green
    } else {
      Write-Host "$repoName : no change" -ForegroundColor DarkGray
    }
  } finally {
    Pop-Location
  }
}
