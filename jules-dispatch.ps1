<#
.SYNOPSIS
File a GitHub issue tagged for Jules pickup and log it to the orchestration repo.

.DESCRIPTION
PowerShell port of jules-dispatch.sh for the Kanda Designers Jules and Claude
orchestration system. Builds a standardized issue body (Task, Definition of Done,
Rules, Priority), enforces a 5-active-task cap per repo, and appends to STATUS.md
when KANDA_ORCH_PATH is set.

.PARAMETER Repo
GitHub repo in owner/name form, for example shizzoobies/kandadesigners.com.

.PARAMETER Title
Issue title.

.PARAMETER Body
Issue body text. Mutually exclusive with -BodyFile.

.PARAMETER BodyFile
Path to a file containing the issue body. Mutually exclusive with -Body.

.PARAMETER Priority
high, normal, or low. Defaults to normal.

.PARAMETER Dod
Definition of Done items, semicolon-separated. Optional; a default checklist is
used if omitted.

.EXAMPLE
jules-dispatch.ps1 -Repo shizzoobies/kandadesigners.com -Title "Refresh README" -Body "Update tech stack section." -Priority normal

.EXAMPLE
jules-dispatch.ps1 -Repo shizzoobies/daily-prompt-generator -Title "Add Vitest coverage for prompt engine" -BodyFile .\specs\coverage.md -Dod "Coverage above 80%; New tests pass; No em dashes"
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$Repo,

  [Parameter(Mandatory = $true)]
  [string]$Title,

  [string]$Body = "",

  [string]$BodyFile = "",

  [ValidateSet('high', 'normal', 'low')]
  [string]$Priority = "normal",

  [string]$Dod = ""
)

$ErrorActionPreference = 'Stop'

# Resolve body source
if ($BodyFile) {
  if (-not (Test-Path -LiteralPath $BodyFile)) {
    Write-Error "Body file not found: $BodyFile"
    exit 1
  }
  $Body = Get-Content -LiteralPath $BodyFile -Raw
}

# Verify gh is available and authenticated
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  Write-Error "gh CLI not found on PATH. Install with: winget install GitHub.cli"
  exit 1
}

& gh auth status 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Error "gh is not authenticated. Run: gh auth login"
  exit 1
}

# Build Definition of Done block
$dodLines = @()
if ($Dod) {
  foreach ($item in ($Dod -split ';')) {
    $trimmed = $item.Trim()
    if ($trimmed) {
      $dodLines += "- [ ] $trimmed"
    }
  }
} else {
  $dodLines = @(
    "- [ ] Changes match the spec above",
    "- [ ] No em dashes anywhere (see AGENTS.md)",
    "- [ ] Existing tests pass",
    "- [ ] PR description explains what changed and how to verify"
  )
}
$dodBlock = $dodLines -join "`n"

# Compose full issue body
$fullBody = @"
## Task

$Body

## Definition of Done

$dodBlock

## Rules

Read AGENTS.md in the repo root before planning. Locked style rules apply.

## Priority

$Priority

---
*Dispatched by Claude Code via jules-dispatch*
"@

# Check active Jules tasks (cap at 5)
$activeRaw = & gh issue list --repo $Repo --label "jules:in-progress" --json number --jq 'length' 2>$null
$active = 0
if ($LASTEXITCODE -eq 0 -and $activeRaw) {
  $active = [int]$activeRaw
}

if ($active -ge 5) {
  Write-Host "Warning: $active active Jules tasks in $Repo already. Cap is 5." -ForegroundColor Yellow
  Write-Host "Either wait for completion or raise the cap intentionally."
  exit 1
}

# File the issue
$issueUrl = & gh issue create --repo $Repo --title $Title --body $fullBody --label "jules:ready"
if ($LASTEXITCODE -ne 0) {
  Write-Error "Failed to create issue"
  exit 1
}

Write-Host "Dispatched: $issueUrl" -ForegroundColor Green

# Log to orchestration repo if configured
$orchPath = $env:KANDA_ORCH_PATH
if ($orchPath -and (Test-Path -LiteralPath $orchPath)) {
  $statusFile = Join-Path $orchPath 'STATUS.md'
  if (Test-Path -LiteralPath $statusFile) {
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm 'UTC'")
    $entry = "- [$timestamp] **$Repo**: [$Title]($issueUrl) -- *$Priority*"

    $lines = Get-Content -LiteralPath $statusFile
    $newLines = New-Object System.Collections.Generic.List[string]
    $inserted = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
      $newLines.Add($lines[$i])
      if (-not $inserted -and $lines[$i] -eq '## Active Dispatches') {
        if ($i + 1 -lt $lines.Count) {
          $i++
          $newLines.Add($lines[$i])
        }
        $newLines.Add($entry)
        $inserted = $true
      }
    }
    if (-not $inserted) {
      $newLines.Add("")
      $newLines.Add("## Active Dispatches")
      $newLines.Add("")
      $newLines.Add($entry)
    }
    Set-Content -LiteralPath $statusFile -Value $newLines -Encoding utf8

    Push-Location $orchPath
    try {
      git add STATUS.md 2>&1 | Out-Null
      git commit -m "Log dispatch: $Title" 2>&1 | Out-Null
      if ($LASTEXITCODE -eq 0) {
        git push 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
          Write-Host "Logged to orchestration repo" -ForegroundColor DarkGray
        } else {
          Write-Host "Note: STATUS.md committed locally but push failed" -ForegroundColor DarkYellow
        }
      } else {
        Write-Host "Note: could not auto-commit STATUS.md" -ForegroundColor DarkYellow
      }
    } finally {
      Pop-Location
    }
  }
}
