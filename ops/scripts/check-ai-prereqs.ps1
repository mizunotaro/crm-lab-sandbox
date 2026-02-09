#requires -Version 7.0
<#
check-ai-prereqs.ps1 (fixed)

Goal:
- Static + minimal dynamic preflight for AI automation.
- Never crashes before writing a JSON log.
- Avoids PowerShell pitfalls: .Count on scalar, null pipeline, placeholders.

Outputs:
- Writes JSON log to ops/logs/ai-prereqs-<timestamp>.json
- Exit code 0 when PASS, 1 when FAIL.

Security:
- Does NOT print secret values.

Usage:
  pwsh -NoProfile -ExecutionPolicy Bypass -File ./ops/scripts/check-ai-prereqs.ps1 -Repo owner/repo
  pwsh -NoProfile -ExecutionPolicy Bypass -File ./ops/scripts/check-ai-prereqs.ps1 -Repo owner/repo -JsonOnly
#>

[CmdletBinding(PositionalBinding = $false)]
param(
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string]$Repo,

  [Parameter()]
  [switch]$JsonOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info([string]$Message) {
  if (-not $JsonOnly) { Write-Host $Message }
}

$script:TryRunLastErrorText = ''


function Assert-Command([string]$Name) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Required command not found: $Name"
  }
}

function Try-RunLines([scriptblock]$Sb) {
  # Always returns string[]
  try {
    $script:TryRunLastErrorText = ''
    # Capture stderr to keep Actions logs clean; keep for diagnosis.
    $out = & $Sb 2>&1
    if ($LASTEXITCODE -ne 0) {
      $script:TryRunLastErrorText = (@($out) -join "`n").Trim()
      throw "Command failed (exit=$LASTEXITCODE)"
    }
    return @($out)
  } catch {
    if ([string]::IsNullOrWhiteSpace($script:TryRunLastErrorText)) {
      $script:TryRunLastErrorText = ($_.ToString()).Trim()
    }
    return @()
  }
}

function Is-Integration403([string]$Text) {
  if ([string]::IsNullOrWhiteSpace($Text)) { return $false }
  return ($Text -match 'HTTP 403') -and ($Text -match 'Resource not accessible by integration')
}


function Get-LogDir() {
  # script path: ops/scripts; log dir: ops/logs
  $opsDir = Split-Path -Parent $PSScriptRoot
  $logDir = Join-Path $opsDir 'logs'
  if (-not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
  }
  return $logDir
}

function Write-JsonLog([object]$Obj, [string]$LogDir) {
  $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
  $logPath = Join-Path $LogDir ("ai-prereqs-{0}.json" -f $ts)
  $json = $Obj | ConvertTo-Json -Depth 20
  # UTF8 without BOM
  [System.IO.File]::WriteAllText($logPath, $json, (New-Object System.Text.UTF8Encoding($false)))
  return $logPath
}

function Set-Fail([hashtable]$Result, [string]$Summary) {
  $Result.status = 'fail'
  if ([string]::IsNullOrWhiteSpace($Result.summary)) {
    $Result.summary = $Summary
  } else {
    $Result.summary = ($Result.summary + ' | ' + $Summary)
  }
}

Assert-Command git
Assert-Command gh

$logDir = Get-LogDir

# --- initialize result ---
$result = [ordered]@{
  ts = (Get-Date).ToString('o')
  repo = $Repo
  status = 'pass'
  summary = ''
  checks = [ordered]@{
    labels = [ordered]@{
      required = @(
        # queue / state
        'ai:ready', 'ai:in-progress', 'ai:blocked', 'ai:triage', 'ai:pr-open',
        # control
        'ai:deps', 'ai:risky-change'
      )
      optional = @('ai:approved', 'ai:pause')
      present = @()
      missing = @()
      note = ''
    }
    secrets = [ordered]@{
      required_any = @('ZAI_API_KEY','ZHIPU_API_KEY')
      present = @()
      missing = @()
      note = ''
    }
    variables = [ordered]@{
      required = @('AI_AUTOMATION_MODE','AI_MAX_OPEN_AI_PRS','AI_MAX_ATTEMPTS_PER_ISSUE')
      present = @()
      missing = @()
      note = ''
    }
    branch_protection = [ordered]@{
      branch = 'main'
      enabled = $false
      note = ''
    }
  }
}

$exitCode = 0

try {
  # --- labels ---
  Write-Info "Checking labels..."
  $labelNames = Try-RunLines { gh label list --repo $Repo --limit 500 --json name --jq '.[].name' }
  $labelNames = @($labelNames | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

  if ($labelNames.Count -eq 0) {
    Set-Fail -Result $result -Summary 'labels: unable to list labels (auth/permissions or repo not found)'
    $result.checks.labels.note = 'gh label list returned empty.'
    $exitCode = 1
  } else {
    $result.checks.labels.present = $labelNames
    $req = @($result.checks.labels.required)
    $missing = @()
    foreach ($r in $req) {
      if (-not ($labelNames -contains $r)) { $missing += $r }
    }
    $result.checks.labels.missing = $missing
    if ($missing.Count -gt 0) {
      Set-Fail -Result $result -Summary ("labels missing: {0}" -f ($missing -join ','))
      $exitCode = 1
    }
  }

  # --- secrets (names only) ---
  Write-Info "Checking secrets..."
  $secretNames = Try-RunLines { gh secret list --repo $Repo --json name --jq '.[].name' }
  $secretNames = @($secretNames | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

  if ($secretNames.Count -eq 0) {
    if (Is-Integration403 $script:TryRunLastErrorText) {
      Write-Warning "SKIP: unable to list secrets in GitHub Actions (HTTP 403 integration token)."
      $result.checks.secrets.note = 'SKIP: unable to list secrets in GitHub Actions (HTTP 403 integration token).'
    } else {
      # do not hard-fail just because list is not permitted; record note, and use env hint
      $result.checks.secrets.note = 'unable to list secrets via gh (token permissions). Ensure at least one of ZAI_API_KEY or ZHIPU_API_KEY exists.'
      # If neither env exists during the run, fail.
      $hasEnv = (-not [string]::IsNullOrWhiteSpace($env:ZAI_API_KEY)) -or (-not [string]::IsNullOrWhiteSpace($env:ZHIPU_API_KEY))
      if (-not $hasEnv) {
        Set-Fail -Result $result -Summary 'secrets: cannot verify via API and no env key present in this run'
        $result.checks.secrets.missing = @($result.checks.secrets.required_any)
        $exitCode = 1
      }
    }
  } else {
    $result.checks.secrets.present = $secretNames
    $hasAny = $false
    foreach ($s in @($result.checks.secrets.required_any)) {
      if ($secretNames -contains $s) { $hasAny = $true }
    }
    if (-not $hasAny) {
      Set-Fail -Result $result -Summary 'secrets missing: set either ZAI_API_KEY or ZHIPU_API_KEY'
      $result.checks.secrets.missing = @($result.checks.secrets.required_any)
      $exitCode = 1
    }
  }

  # --- variables ---
  Write-Info "Checking variables..."
  $varNames = Try-RunLines { gh api "repos/$Repo/actions/variables" --jq '.variables[].name' }
  $varNames = @($varNames | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

  if ($varNames.Count -eq 0) {
    $result.checks.variables.note = 'unable to list variables via gh api (token permissions).'
    # If we cannot list, do not hard-fail (avoid false negatives), but record it.
  } else {
    $result.checks.variables.present = $varNames
    $missingVars = @()
    foreach ($v in @($result.checks.variables.required)) {
      if (-not ($varNames -contains $v)) { $missingVars += $v }
    }
    $result.checks.variables.missing = $missingVars
    if ($missingVars.Count -gt 0) {
      Set-Fail -Result $result -Summary ("variables missing: {0}" -f ($missingVars -join ','))
      $exitCode = 1
    }
  }

  # --- branch protection (main) ---
  Write-Info "Checking branch protection (main)..."
  $contexts = Try-RunLines { gh api "repos/$Repo/branches/main/protection" --jq '.required_status_checks.contexts[]?' }
  if ($contexts.Count -gt 0) {
    $result.checks.branch_protection.enabled = $true
  } else {
    if (Is-Integration403 $script:TryRunLastErrorText) {
      Write-Warning "SKIP: cannot read branch protection in GitHub Actions (HTTP 403 integration token)."
      $result.checks.branch_protection.enabled = $false
      $result.checks.branch_protection.note = 'SKIP: cannot read branch protection in GitHub Actions (HTTP 403 integration token).'
    } else {
      # API returns 404 when not protected. We treat as fail because policy requires CI green gating.
      $result.checks.branch_protection.enabled = $false
      Set-Fail -Result $result -Summary 'branch protection missing on main (required status checks not enforced)'
      $result.checks.branch_protection.note = 'repos/.../branches/main/protection returned empty/404.'
      $exitCode = 1
    }
  }

} catch {
  # Catch-all: mark fail but still write log
  Set-Fail -Result $result -Summary ("exception: {0}" -f $_.Exception.Message)
  $exitCode = 1
} finally {
  $logPath = Write-JsonLog -Obj $result -LogDir $logDir
  # Print log path for workflow step parsing, even in JsonOnly mode
  Write-Output $logPath
}

exit $exitCode

