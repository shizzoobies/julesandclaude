<#
.SYNOPSIS
Onboard a Kanda repo into the Jules and Claude orchestration system.

.DESCRIPTION
Clones the repo if needed, copies AGENTS.md from the orchestration repo into
the target repo root, writes .jules/config.yml from the template, creates the
7 GitHub labels from labels.json, and commits + pushes the scaffold.

.PARAMETER RepoName
GitHub repo in owner/name form, for example shizzoobies/kandadesigners.com.

.PARAMETER LocalPath
Where to clone or find the repo locally. Defaults to <parent-of-orch>/<repo-name-only>.

.PARAMETER BaseBranch
Branch the repo treats as its default. Defaults to main.

.EXAMPLE
.\runbooks\onboard-repo.ps1 -RepoName shizzoobies/kandadesigners.com

.EXAMPLE
.\runbooks\onboard-repo.ps1 -RepoName shizzoobies/legacy-site -BaseBranch master
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$RepoName,

  [string]$LocalPath = "",

  [string]$BaseBranch = "main"
)

$ErrorActionPreference = 'Stop'

$orchPath = $env:KANDA_ORCH_PATH
if (-not $orchPath -or -not (Test-Path -LiteralPath $orchPath)) {
  Write-Error "KANDA_ORCH_PATH is not set or invalid. Run setup.ps1 from the orchestration repo first."
  exit 1
}

# Default local path: sibling of the orchestration repo
if (-not $LocalPath) {
  $bareName = $RepoName -replace '^.+/', ''
  $parent = Split-Path -Parent $orchPath
  $LocalPath = Join-Path $parent $bareName
}

# Clone if needed
if (-not (Test-Path -LiteralPath $LocalPath)) {
  Write-Host "Cloning $RepoName to $LocalPath ..." -ForegroundColor Cyan
  git clone "https://github.com/$RepoName.git" $LocalPath
  if ($LASTEXITCODE -ne 0) {
    Write-Error "git clone failed"
    exit 1
  }
} else {
  Write-Host "Local path exists: $LocalPath" -ForegroundColor DarkGray
}

# Copy AGENTS.md
$agentsSrc = Join-Path $orchPath 'agents\AGENTS.md'
$agentsDst = Join-Path $LocalPath 'AGENTS.md'
Copy-Item -LiteralPath $agentsSrc -Destination $agentsDst -Force
Write-Host "Copied AGENTS.md" -ForegroundColor Green

# Render .jules/config.yml from template
$cfgSrc = Join-Path $orchPath '.jules\config.template.yml'
$cfgDir = Join-Path $LocalPath '.jules'
if (-not (Test-Path -LiteralPath $cfgDir)) {
  New-Item -ItemType Directory -Path $cfgDir | Out-Null
}
$cfgDst = Join-Path $cfgDir 'config.yml'

$tpl = Get-Content -LiteralPath $cfgSrc -Raw
$tpl = $tpl -replace '\{\{BASE_BRANCH\}\}', $BaseBranch
Set-Content -LiteralPath $cfgDst -Value $tpl -Encoding utf8
Write-Host "Wrote .jules/config.yml (base: $BaseBranch)" -ForegroundColor Green

# Create labels
$labelsPath = Join-Path $orchPath 'labels.json'
$labels = Get-Content -LiteralPath $labelsPath -Raw | ConvertFrom-Json
foreach ($label in $labels) {
  & gh label create $label.name --color $label.color --description $label.description --repo $RepoName 2>$null
  if ($LASTEXITCODE -eq 0) {
    Write-Host "  label created: $($label.name)" -ForegroundColor DarkGray
  } else {
    Write-Host "  label exists or failed: $($label.name)" -ForegroundColor DarkYellow
  }
}

# Commit and push the scaffold
Push-Location $LocalPath
try {
  git add AGENTS.md .jules/ 2>&1 | Out-Null
  git diff --cached --quiet
  if ($LASTEXITCODE -ne 0) {
    git commit -m "Add Jules orchestration scaffold"
    git push
    Write-Host "Pushed scaffold to $RepoName" -ForegroundColor Green
  } else {
    Write-Host "Nothing to commit, scaffold already present" -ForegroundColor DarkGray
  }
} finally {
  Pop-Location
}

Write-Host ""
Write-Host "Next: connect $RepoName at https://jules.google.com/" -ForegroundColor Cyan
Write-Host "  Trigger: issues labeled jules:ready"
Write-Host "  Branch prefix: jules/"
Write-Host "  Default reviewer: shizzoobies"
