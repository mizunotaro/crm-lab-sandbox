<#
set-ai-automation-mode.ps1 (v1.0.0)

Goal:
- Safely set AI_AUTOMATION_MODE repository variable
- Validates mode value before setting
- Provides verification step

Security:
- Does NOT print secret values
- Requires user confirmation before setting

Usage:
  pwsh -NoProfile -ExecutionPolicy Bypass -File ./set-ai-automation-mode.ps1 -Mode PAUSE
  pwsh -NoProfile -ExecutionPolicy Bypass -File ./set-ai-automation-mode.ps1 -Mode RUNNING -Repo owner/repo
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('RUNNING', 'PAUSE', IgnoreCase = $false)]
  [string]$Mode,

  [Parameter()]
  [string]$Repo = '',

  [Parameter()]
  [switch]$SkipConfirm
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ValidModes = @('RUNNING', 'PAUSE')

function Write-Info([string]$Message) {
  Write-Host ("[INFO] {0}" -f $Message) -ForegroundColor Cyan
}

function Write-Success([string]$Message) {
  Write-Host ("[OK] {0}" -f $Message) -ForegroundColor Green
}

function Write-Error-Message([string]$Message) {
  Write-Host ("[ERROR] {0}" -f $Message) -ForegroundColor Red
}

function Test-GhInstalled {
  if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error-Message "GitHub CLI (gh) is not installed or not in PATH"
    Write-Host "Install from: https://cli.github.com/" -ForegroundColor Yellow
    return $false
  }
  return $true
}

function Resolve-Repo([string]$RepoInput) {
  if ([string]::IsNullOrWhiteSpace($RepoInput)) {
    try {
      $gitRemote = git config --get remote.origin.url 2>$null
      if ([string]::IsNullOrWhiteSpace($gitRemote)) {
        throw "No git remote found"
      }

      $gitRemote = $gitRemote -replace '^(https?://|git@)github\.com[:/]', ''
      $gitRemote = $gitRemote -replace '\.git$', ''
      return $gitRemote.Trim()
    } catch {
      Write-Error-Message "Could not auto-detect repository. Please specify -Repo owner/repo"
      return ''
    }
  }
  return $RepoInput
}

function Get-CurrentMode([string]$Repo) {
  try {
    $current = gh variable get AI_AUTOMATION_MODE --repo $Repo 2>$null
    if ($LASTEXITCODE -eq 0) {
      return $current.Trim()
    }
    return '<not set>'
  } catch {
    return '<not set>'
  }
}

function Set-AutomationMode([string]$Repo, [string]$NewMode) {
  $confirm = $SkipConfirm -or $PSCmdlet.ShouldProcess(
    "Set AI_AUTOMATION_MODE to '{0}' in repository '{1}'" -f $NewMode, $Repo,
    "Set AI_AUTOMATION_MODE to {0}?" -f $NewMode
  )

  if (-not $confirm) {
    Write-Info "Operation cancelled by user"
    return $false
  }

  Write-Info "Setting AI_AUTOMATION_MODE to '{0}'..." -f $NewMode
  $output = gh variable set AI_AUTOMATION_MODE --body $NewMode --repo $Repo 2>&1

  if ($LASTEXITCODE -ne 0) {
    Write-Error-Message "Failed to set variable"
    Write-Host $output -ForegroundColor DarkGray
    return $false
  }

  return $true
}

function Verify-Mode([string]$Repo, [string]$ExpectedMode) {
  Write-Info "Verifying..."
  $current = Get-CurrentMode -Repo $Repo

  if ($current -eq $ExpectedMode) {
    Write-Success "AI_AUTOMATION_MODE is now set to: {0}" -f $current
    return $true
  } else {
    Write-Error-Message "Verification failed. Expected '{0}', got '{1}'" -f $ExpectedMode, $current
    return $false
  }
}

function Main {
  $startTime = Get-Date

  Write-Host ""
  Write-Host "=== AI Automation Mode Controller ===" -ForegroundColor Magenta
  Write-Host ""

  if (-not (Test-GhInstalled)) {
    exit 1
  }

  $resolvedRepo = Resolve-Repo -RepoInput $Repo
  if ([string]::IsNullOrWhiteSpace($resolvedRepo)) {
    exit 1
  }

  Write-Info "Repository: {0}" -f $resolvedRepo
  Write-Info "Target mode: {0}" -f $Mode

  $currentMode = Get-CurrentMode -Repo $resolvedRepo
  Write-Info "Current mode: {0}" -f $currentMode
  Write-Host ""

  if ($currentMode -eq $Mode) {
    Write-Success "AI_AUTOMATION_MODE is already set to '{0}'. No action needed." -f $Mode
    exit 0
  }

  if (-not (Set-AutomationMode -Repo $resolvedRepo -NewMode $Mode)) {
    exit 1
  }

  Write-Host ""

  if (-not (Verify-Mode -Repo $resolvedRepo -ExpectedMode $Mode)) {
    exit 1
  }

  $elapsed = ((Get-Date) - $startTime).TotalSeconds
  Write-Host ""
  Write-Success "Completed in {0:N2} seconds" -f $elapsed
  Write-Host ""

  if ($Mode -eq 'PAUSE') {
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Investigate the root cause (e.g., CI failures)" -ForegroundColor Yellow
    Write-Host "2. Resolve the issue" -ForegroundColor Yellow
    Write-Host "3. Set AI_AUTOMATION_MODE=RUNNING to resume automation" -ForegroundColor Yellow
  } else {
    Write-Host "AI automation will resume on next scheduled run (within 15 minutes)." -ForegroundColor Green
  }

  Write-Host ""
}

Main
