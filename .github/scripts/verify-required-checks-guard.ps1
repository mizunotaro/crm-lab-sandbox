#requires -Version 7.0
<#
.SYNOPSIS
  Verifies .github/scripts/required-checks-guard.ps1 for:
   - PowerShell parser errors
   - PSScriptAnalyzer findings
   - Known risky string patterns that can trigger ParserError in CI
   - Optional smoke-run (requires gh/git + auth)

.DESCRIPTION
  Intended for Windows 11 + PowerShell 7.
  This script is read-only except for creating/using .github/scripts/_reports.

.EXAMPLE
  pwsh -NoProfile -File .\.github\scripts\verify-required-checks-guard.ps1 -RepoRoot 'C:\src\_sandbox\crm-lab-sandbox' -SmokeRun -Repo mizunotaro/crm-lab-sandbox -Branch main -PullRequestNumber 521
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$false)]
  [string]$RepoRoot = 'C:\src\_sandbox\crm-lab-sandbox',

  [Parameter(Mandatory=$false)]
  [string]$TargetScript = '.\.github\scripts\required-checks-guard.ps1',

  [Parameter(Mandatory=$false)]
  [switch]$SmokeRun,

  # Passed through to required-checks-guard.ps1 when -SmokeRun is specified
  [Parameter(Mandatory=$false)]
  [string]$Repo,

  [Parameter(Mandatory=$false)]
  [string]$Branch = 'main',

  [Parameter(Mandatory=$false)]
  [ValidateRange(0, 1000000000)]
  [int]$PullRequestNumber = 0,

  [Parameter(Mandatory=$false)]
  [switch]$PreferMergeCommit,

  [Parameter(Mandatory=$false)]
  [switch]$FailOnApiError,

  [Parameter(Mandatory=$false)]
  [switch]$FailOnUnknown,

  [Parameter(Mandatory=$false)]
  [switch]$FailOnMissingProtection
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

function Assert([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw $Message }
}

function Write-Section([string]$Title) {
  Write-Host ''
  Write-Host ('==== {0} ====' -f $Title)
}

Write-Section 'Location'
Set-Location -LiteralPath $RepoRoot
Write-Host ('RepoRoot: {0}' -f (Get-Location).Path)

Write-Section 'Versions'
$psv = $PSVersionTable.PSVersion
Write-Host ('PowerShell: {0}' -f $psv)

# Optional but recommended floor check (as per your requirement)
$minPs = [Version]'7.5.4'
if ($psv -lt $minPs) {
  Write-Warning ("PowerShell version is below {0}. Some CI-equivalent checks may differ." -f $minPs)
}

Write-Host ('gh: {0}' -f ((Get-Command gh -ErrorAction SilentlyContinue)?.Source ?? '<not found>'))
Write-Host ('git: {0}' -f ((Get-Command git -ErrorAction SilentlyContinue)?.Source ?? '<not found>'))

Write-Section 'Target file'
$targetPath = (Resolve-Path -LiteralPath $TargetScript).Path
Write-Host ('TargetScript: {0}' -f $targetPath)
Assert (Test-Path -LiteralPath $targetPath) ("Target script not found: {0}" -f $targetPath)

Write-Section 'Parser check (official PowerShell parser)'
$tokens = $null
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile(
  $targetPath,
  [ref]$tokens,
  [ref]$errors
) | Out-Null

if ($errors -and $errors.Count -gt 0) {
  $errors | Format-Table -AutoSize Extent, ErrorId, Message
  throw ('Parser errors found: {0}' -f $errors.Count)
}
Write-Host 'OK: parser clean'

Write-Section 'Known risky pattern scan'
# Pattern 1: backtick immediately before a double quote inside a double-quoted string can break parsing: `"
$hit = Select-String -Path $targetPath -Pattern '`"' -SimpleMatch -ErrorAction SilentlyContinue
if ($hit) {
  $hit | Select-Object LineNumber, Line | Format-Table -AutoSize
  throw "Found risky pattern (`" ) in script. Replace such markdown strings with single-quoted strings."
}
Write-Host 'OK: no `"` pattern found'

Write-Section 'PSScriptAnalyzer'
$minSa = [Version]'1.24.0'
$sa = Get-Module -ListAvailable PSScriptAnalyzer | Sort-Object Version -Descending | Select-Object -First 1
if (-not $sa) {
  throw 'PSScriptAnalyzer not found. Install-Module PSScriptAnalyzer -Scope CurrentUser'
}
Write-Host ('PSScriptAnalyzer: {0}' -f $sa.Version)
if ($sa.Version -lt $minSa) {
  Write-Warning ("PSScriptAnalyzer is below {0}. Results may differ." -f $minSa)
}

$saResults = Invoke-ScriptAnalyzer -Path $targetPath -Severity Error,Warning
if ($saResults -and $saResults.Count -gt 0) {
  $saResults | Sort-Object Severity, Line | Format-Table -AutoSize RuleName, Severity, Line, Column, Message
  throw ('ScriptAnalyzer findings: {0}' -f $saResults.Count)
}
Write-Host 'OK: ScriptAnalyzer clean (Error/Warning)'

if ($SmokeRun) {
  Write-Section 'Smoke run (executes required-checks-guard.ps1)'
  Assert (-not [string]::IsNullOrWhiteSpace($Repo)) 'SmokeRun requires -Repo <owner/repo>.'

  $cmd = @(
    'pwsh','-NoProfile','-File', $targetPath,
    '-Repo',$Repo,
    '-Branch',$Branch
  )

  if ($PullRequestNumber -gt 0) { $cmd += @('-PullRequestNumber', "$PullRequestNumber") }
  if ($PreferMergeCommit) { $cmd += '-PreferMergeCommit' }
  if ($FailOnApiError) { $cmd += '-FailOnApiError' }
  if ($FailOnUnknown) { $cmd += '-FailOnUnknown' }
  if ($FailOnMissingProtection) { $cmd += '-FailOnMissingProtection' }

  Write-Host ('Running: {0}' -f ($cmd -join ' '))
  & $cmd[0] @($cmd[1..($cmd.Count-1)])
  Write-Host ('ExitCode: {0}' -f $LASTEXITCODE)
  Assert ($LASTEXITCODE -eq 0) ('Smoke run failed: exit code {0}' -f $LASTEXITCODE)
  Write-Host 'OK: smoke run passed'
}

Write-Section 'DONE'
Write-Host 'ALL OK'
