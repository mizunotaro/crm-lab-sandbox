#requires -Version 7.0
<#
RUN_probe-opencode.local.ps1
Purpose:
  - Local runner wrapper for ops/scripts/probe-opencode.ps1
  - Prompts for API key (ephemeral) and runs probe in a new pwsh process with ExecutionPolicy Bypass
  - Attempts to isolate OpenCode config/data directories under OutDir to avoid persistent writes (best-effort)

Security:
  - Never prints API key values
  - Does NOT persist secrets (no setx, no files). Only process env vars for the child pwsh.
#>

param(
  [Parameter()][string]$RepoRoot = (Get-Location).Path,
  [Parameter()][string]$OutRoot = '',
  [Parameter()][string]$OpenCodeNpmVersion = 'latest',

  # Recommended order: coding-plan -> plain -> fallback
  [Parameter()][string]$ModelCandidatesCsv = 'zai-coding-plan/glm-4.7,zai/glm-4.7,zai-coding-plan/glm-4.6,zai/glm-4.6',

  [Parameter()][switch]$InstallOpenCodeIfMissing,
  [Parameter()][switch]$NonInteractive,

  # Optional: pass SecureString to avoid prompt (still becomes plaintext in-process to set env vars)
  [Parameter()][securestring]$ApiKey
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-Dir {
  param([Parameter(Mandatory)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

function Get-PlainText {
  param([Parameter()][AllowNull()][securestring]$Secure)
  if (-not $Secure) { return '' }
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
  try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
  finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

function Get-EnvValue {
  param([Parameter(Mandatory)][string]$Name)
  return [System.Environment]::GetEnvironmentVariable($Name)
}

function Set-EnvValue {
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter()][AllowNull()][string]$Value
  )
  [System.Environment]::SetEnvironmentVariable($Name, $Value)
}

function Get-Timestamp {
  return (Get-Date).ToString('yyyyMMdd_HHmmss')
}

# Resolve paths
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path

$probePath = Join-Path $RepoRoot 'ops/scripts/probe-opencode.ps1'
if (-not (Test-Path -LiteralPath $probePath)) {
  throw "probe script not found: $probePath (apply patch that adds ops/scripts/probe-opencode.ps1)"
}

$outBase = $OutRoot
if ([string]::IsNullOrWhiteSpace($outBase)) {
  $outBase = Join-Path $RepoRoot '_probe'
}
New-Dir -Path $outBase

$outDir = Join-Path $outBase ("probe_{0}" -f (Get-Timestamp))
New-Dir -Path $outDir

# Best-effort isolation of OpenCode config/data under OutDir
$isoDir = Join-Path $outDir 'opencode_isolated'
New-Dir -Path $isoDir

# Capture whether env vars were pre-set in this session
$hadZai   = -not [string]::IsNullOrWhiteSpace((Get-EnvValue -Name 'ZAI_API_KEY'))
$hadZhipu = -not [string]::IsNullOrWhiteSpace((Get-EnvValue -Name 'ZHIPU_API_KEY'))

try {
  # Acquire API key
  $key = ''
  if (-not $hadZai -and -not $hadZhipu) {
    if (-not $ApiKey) {
      if ($NonInteractive) { throw "API key is not set in env (ZAI_API_KEY/ZHIPU_API_KEY) and -NonInteractive was specified." }
      $ApiKey = Read-Host -Prompt 'Enter Z.AI/GLM API Key (will NOT be saved)' -AsSecureString
    }
    $key = Get-PlainText -Secure $ApiKey
    if ([string]::IsNullOrWhiteSpace($key)) { throw "API key is empty." }

    # Set both (some providers/tools read either)
    Set-EnvValue -Name 'ZAI_API_KEY' -Value $key
    Set-EnvValue -Name 'ZHIPU_API_KEY' -Value $key
  }

  # Isolation env vars (best-effort; depends on OpenCode)
  Set-EnvValue -Name 'OPENCODE_CONFIG_DIR' -Value $isoDir
  Set-EnvValue -Name 'XDG_CONFIG_HOME' -Value $isoDir
  Set-EnvValue -Name 'XDG_DATA_HOME' -Value $isoDir

  $install = if ($InstallOpenCodeIfMissing) { 'Npm' } else { 'None' }

  $pwsh = (Get-Command pwsh -ErrorAction Stop).Source

  $argList = @(
    '-NoLogo',
    '-NoProfile',
    '-ExecutionPolicy','Bypass',
    '-File', $probePath,
    '-OutDir', $outDir,
    '-ModelCandidatesCsv', $ModelCandidatesCsv,
    '-InstallIfMissing', $install,
    '-OpenCodeNpmVersion', $OpenCodeNpmVersion,
    '-TimeoutSeconds', '60',
    '-LogLevel', 'INFO'
  )

  Write-Host ("Running probe: {0}" -f $probePath)
  Write-Host ("OutDir: {0}" -f $outDir)
  Write-Host ("InstallIfMissing: {0} / OpenCodeNpmVersion: {1}" -f $install, $OpenCodeNpmVersion)
  Write-Host ("ModelCandidatesCsv: {0}" -f $ModelCandidatesCsv)

  & $pwsh @argList

  $sumPath = Join-Path $outDir 'summary.json'
  if (Test-Path -LiteralPath $sumPath) {
    $sum = Get-Content -LiteralPath $sumPath -Raw | ConvertFrom-Json
    Write-Host ("Probe status: {0} / reason: {1}" -f $sum.status, $sum.reason)
    if ($sum.status -ne 'PASS') { exit 1 }
  } else {
    throw "summary.json not found: $sumPath"
  }
}
finally {
  # Cleanup secrets from current process env if we set them
  if (-not $hadZai)   { Set-EnvValue -Name 'ZAI_API_KEY' -Value $null }
  if (-not $hadZhipu) { Set-EnvValue -Name 'ZHIPU_API_KEY' -Value $null }

  # Best-effort cleanup isolation env vars
  Set-EnvValue -Name 'OPENCODE_CONFIG_DIR' -Value $null
  Set-EnvValue -Name 'XDG_CONFIG_HOME' -Value $null
  Set-EnvValue -Name 'XDG_DATA_HOME' -Value $null
}
