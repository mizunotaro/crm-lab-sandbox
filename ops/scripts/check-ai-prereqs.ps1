#requires -Version 7.0
<#
.SYNOPSIS
  AI prerequisites preflight checker for GitHub repos.

.DESCRIPTION
  Checks required labels / Actions secrets / Actions variables on a repository using GitHub CLI (gh),
  writes a JSON report under ops/logs/, and exits with a non-zero code only when prerequisites are missing
  or a non-soft permission/API error occurs.

  IMPORTANT:
    - When running under GitHub Actions with the default GITHUB_TOKEN, listing secrets/variables can return:
        HTTP 403: Resource not accessible by integration
      In that specific case, this script records a WARN and does NOT fail the workflow.

.PARAMETER Repo
  Repository in the form "owner/name".

.PARAMETER JsonOnly
  If set, suppresses the human-readable summary block (the checks still print their PASS/FAIL/WARN lines).

.PARAMETER ConfigPath
  Optional path to a JSON config file with keys: labels, secrets, variables (arrays of strings).

.OUTPUTS
  Writes JSON report to ops/logs/ai-prereqs-<timestamp>.json

.EXITCODES
  0: pass, or pass-with-warnings (soft 403 on secrets/variables)
  1: missing prerequisites (fail) or hard errors (error)
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$Repo,

  [switch]$JsonOnly,

  [string]$ConfigPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-RepoRoot {
  try {
    $root = (& git rev-parse --show-toplevel 2>$null).Trim()
    if ($root) { return $root }
  } catch { }
  # Fallback: assume this script is at <repo>/ops/scripts
  return (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
}

function Resolve-ConfigPath {
  param([string]$ExplicitPath)

  if ($ExplicitPath) {
    $p = Resolve-Path -LiteralPath $ExplicitPath -ErrorAction Stop
    return $p.Path
  }

  $candidates = @(
    (Join-Path $PSScriptRoot 'ai-prereqs-config.json'),
    (Join-Path $PSScriptRoot 'ai-prereqs.json'),
    (Join-Path (Join-Path $PSScriptRoot '..') 'ai-prereqs-config.json'),
    (Join-Path (Join-Path $PSScriptRoot '..') 'ai-prereqs.json'),
    (Join-Path (Join-Path $PSScriptRoot '..\config') 'ai-prereqs-config.json'),
    (Join-Path (Join-Path $PSScriptRoot '..\config') 'ai-prereqs.json')
  )

  foreach ($c in $candidates) {
    if (Test-Path -LiteralPath $c) { return (Resolve-Path -LiteralPath $c).Path }
  }

  return $null
}

function Load-Config {
  param([string]$Path)

  $cfg = [ordered]@{ labels = @(); secrets = @(); variables = @() }

  if (-not $Path) { return $cfg }

  try {
    $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
    $obj = $raw | ConvertFrom-Json -ErrorAction Stop

    foreach ($k in @('labels','secrets','variables')) {
      $val = $null
      if ($obj -is [System.Collections.IDictionary] -and $obj.Contains($k)) {
        $val = $obj[$k]
      } else {
        $p = $obj.PSObject.Properties.Match($k)
        if ($p.Count -gt 0) { $val = $p[0].Value }
      }

      if ($null -eq $val) {
        $cfg[$k] = @()
      } elseif ($val -is [System.Collections.IEnumerable] -and $val -isnot [string]) {
        $cfg[$k] = @($val)
      } else {
        $cfg[$k] = @("$val")
      }
    }
  } catch {
    Write-Host ("WARN: Failed to load config JSON ({0}): {1}" -f $Path, $_.Exception.Message) -ForegroundColor Yellow
  }

  return $cfg
}

function Test-ItemMatch {
  param(
    [string[]]$required,
    [string[]]$existing
  )

  $req = @($required | Where-Object { $_ -and $_.Trim() -ne '' } | ForEach-Object { $_.Trim() })
  $ex  = @($existing | Where-Object { $_ -and $_.Trim() -ne '' } | ForEach-Object { $_.Trim() })

  $missing = @()
  foreach ($r in $req) {
    if ($r -notin $ex) { $missing += $r }
  }
  return @($missing)
}

function Is-Soft403 {
  param([string]$Text)

  if (-not $Text) { return $false }
  # Match common gh/HTTP messages for the integration-limited token
  if ($Text -match '(?i)\bHTTP\s*403\b') { return $true }
  if ($Text -match '(?i)Resource not accessible by integration') { return $true }
  if ($Text -match '(?i)\bforbidden\b') { return $true }
  return $false
}

function Parse-GhFirstColumn {
  param([string]$GhOutput)

  if (-not $GhOutput) { return @() }
  $lines = $GhOutput -split "`n" | ForEach-Object { $_.TrimEnd("`r") } | Where-Object { $_ -ne '' }

  # Drop header lines if present
  $lines = $lines | Where-Object { $_ -notmatch '^(?i)NAME(\s+|$)' }

  $names = @()
  foreach ($l in $lines) {
    $first = ($l -split '\s+')[0]
    if ($first -and $first -ne 'NAME') { $names += $first }
  }
  return @($names)
}

# ===== Main =====

$repoRoot = Resolve-RepoRoot
$logsDir = Join-Path $repoRoot 'ops\logs'
New-Item -ItemType Directory -Force -Path $logsDir 1>$null

$configResolved = Resolve-ConfigPath -ExplicitPath $ConfigPath
$config = Load-Config -Path $configResolved

$result = [ordered]@{
  repo        = $Repo
  generatedAt = (Get-Date).ToString('o')
  status      = 'pass'
  summary     = ''
  checks      = [ordered]@{}
}

$exitCode = 0

# Check labels
Write-Host "Checking labels..." -ForegroundColor Cyan
$labelCheck = & gh label list --repo $Repo 2>&1
if ($LASTEXITCODE -eq 0) {
  $existingLabels = Parse-GhFirstColumn -GhOutput $labelCheck
  $missingLabels = Test-ItemMatch -required $config.labels -existing $existingLabels

  $result.checks.labels = @{
    required = @($config.labels)
    existing = @($existingLabels)
    missing  = @($missingLabels)
    status   = if ($missingLabels.Count -gt 0) { 'fail' } else { 'pass' }
  }

  if ($missingLabels.Count -gt 0) {
    Write-Host ("  FAIL: Missing labels: {0}" -f ($missingLabels -join ', ')) -ForegroundColor Red
  } else {
    Write-Host "  PASS: All required labels exist" -ForegroundColor Green
  }
} else {
  $result.checks.labels = @{
    required = @($config.labels)
    existing = @()
    missing  = @($config.labels)
    status   = 'error'
    error    = "$labelCheck"
  }
  Write-Host ("  ERROR: Failed to list labels: {0}" -f $labelCheck) -ForegroundColor Yellow
}

# Check secrets
Write-Host "`nChecking secrets (names only)..." -ForegroundColor Cyan
$secretCheck = & gh secret list --repo $Repo 2>&1
if ($LASTEXITCODE -eq 0) {
  $existingSecrets = Parse-GhFirstColumn -GhOutput $secretCheck
  $missingSecrets = Test-ItemMatch -required $config.secrets -existing $existingSecrets

  $result.checks.secrets = @{
    required = @($config.secrets)
    existing = @($existingSecrets)
    missing  = @($missingSecrets)
    status   = if ($missingSecrets.Count -gt 0) { 'fail' } else { 'pass' }
  }

  if ($missingSecrets.Count -gt 0) {
    Write-Host ("  FAIL: Missing secrets: {0}" -f ($missingSecrets -join ', ')) -ForegroundColor Red
  } else {
    Write-Host "  PASS: All required secrets exist" -ForegroundColor Green
  }
} else {
  $is403 = Is-Soft403 -Text "$secretCheck"
  $level = if ($is403) { 'WARN' } else { 'ERROR' }

  $result.checks.secrets = @{
    required = @($config.secrets)
    existing = @()
    missing  = if ($is403) { @() } else { @($config.secrets) }
    status   = if ($is403) { 'warn' } else { 'error' }
    error    = "$secretCheck"
  }

  Write-Host ("  {0}: Failed to list secrets (may need additional permissions): {1}" -f $level, $secretCheck) -ForegroundColor Yellow
}

# Check variables
Write-Host "`nChecking variables..." -ForegroundColor Cyan
$variableCheck = & gh variable list --repo $Repo 2>&1
if ($LASTEXITCODE -eq 0) {
  $existingVariables = Parse-GhFirstColumn -GhOutput $variableCheck
  $missingVariables = Test-ItemMatch -required $config.variables -existing $existingVariables

  $result.checks.variables = @{
    required = @($config.variables)
    existing = @($existingVariables)
    missing  = @($missingVariables)
    status   = if ($missingVariables.Count -gt 0) { 'fail' } else { 'pass' }
  }

  if ($missingVariables.Count -gt 0) {
    Write-Host ("  FAIL: Missing variables: {0}" -f ($missingVariables -join ', ')) -ForegroundColor Red
  } else {
    Write-Host "  PASS: All required variables exist" -ForegroundColor Green
  }
} else {
  $is403 = Is-Soft403 -Text "$variableCheck"
  $level = if ($is403) { 'WARN' } else { 'ERROR' }

  $result.checks.variables = @{
    required = @($config.variables)
    existing = @()
    missing  = if ($is403) { @() } else { @($config.variables) }
    status   = if ($is403) { 'warn' } else { 'error' }
    error    = "$variableCheck"
  }

  Write-Host ("  {0}: Failed to list variables (may need additional permissions): {1}" -f $level, $variableCheck) -ForegroundColor Yellow
}

# Determine overall status
$hasErrors   = @($result.checks.Values | Where-Object { $_.status -eq 'error' })
$hasFailures = @($result.checks.Values | Where-Object { $_.status -eq 'fail' })
$hasWarns    = @($result.checks.Values | Where-Object { $_.status -eq 'warn' })

if ($hasErrors.Count -gt 0) {
  $result.status = 'error'
  $result.summary = 'Preflight check completed with errors (permission issues or API errors)'
  $exitCode = 1
} elseif ($hasFailures.Count -gt 0) {
  $result.status = 'fail'
  $result.summary = 'Preflight check failed: missing required prerequisites'
  $exitCode = 1
} elseif ($hasWarns.Count -gt 0) {
  $result.status = 'warn'
  $result.summary = 'Preflight check completed with warnings (could not verify secrets/variables due to token permissions)'
  $exitCode = 0
} else {
  $result.status = 'pass'
  $result.summary = 'Preflight check passed'
  $exitCode = 0
}

# Write JSON report
$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
$outPath = Join-Path $logsDir ("ai-prereqs-{0}.json" -f $ts)
($result | ConvertTo-Json -Depth 8) | Set-Content -LiteralPath $outPath -Encoding UTF8

Write-Host ("`nJSON report written to: {0}" -f $outPath) -ForegroundColor Cyan

if (-not $JsonOnly) {
  Write-Host "`n==== Summary ====" -ForegroundColor Cyan
  Write-Host ("Status : {0}" -f $result.status)
  Write-Host ("Summary: {0}" -f $result.summary)
}

exit $exitCode
