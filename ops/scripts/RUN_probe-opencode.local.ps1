#requires -Version 7.0
<#
RUN_probe-opencode.local.ps1

Purpose:
- Local-only runner that injects API key into the current process ENV *ephemerally* (no persistence),
  then invokes the repo's safe wrapper: ops/scripts/RUN_probe-opencode.safe.ps1

Security:
- Never echoes the key.
- Does not write the key to disk.
- Clears ENV vars after execution.

Usage example (from repo root):
pwsh -NoProfile -ExecutionPolicy Bypass -File .\ops\scripts\RUN_probe-opencode.local.ps1 `
  -RepoRoot (Get-Location).Path `
  -ApiKeyTarget Both `
  -ModelCandidatesCsv "zai-coding-plan/glm-4.7,zai-coding-plan/glm-4.6" `
  -TimeoutSeconds 60 `
  -InstallIfMissing Npm `
  -OpenCodeNpmVersion "1.1.44" `
  -LogLevel INFO
#>

[CmdletBinding(PositionalBinding=$false)]
param(
  [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$RepoRoot,

  # Which env vars to set (compat)
  [Parameter()][ValidateSet('ZAI','ZHIPU','Both')][string]$ApiKeyTarget = 'Both',

  # Model candidates passed as ONE argument (CSV) to avoid cross-process array binding issues
  [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$ModelCandidatesCsv,

  [Parameter()][ValidateRange(10,1800)][int]$TimeoutSeconds = 60,
  [Parameter()][ValidateSet('None','Npm')][string]$InstallIfMissing = 'Npm',
  [Parameter()][string]$OpenCodeNpmVersion = '1.1.44',
  [Parameter()][ValidateSet('INFO','DEBUG','WARN','ERROR')][string]$LogLevel = 'INFO',

  # Optional: if provided, passed through to safe wrapper
  [Parameter()][string]$ProbeScriptRelPath = 'ops/scripts/probe-opencode.ps1'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Throw-IfNotFound([string]$Path, [string]$Label) {
  if (-not (Test-Path -LiteralPath $Path)) { throw "$Label not found: $Path" }
}

# Resolve paths
Throw-IfNotFound -Path $RepoRoot -Label 'RepoRoot'
Set-Location -LiteralPath $RepoRoot

$safe = Join-Path $RepoRoot 'ops/scripts/RUN_probe-opencode.safe.ps1'
Throw-IfNotFound -Path $safe -Label 'Safe wrapper'

# Prompt (hidden)
$sec  = Read-Host -Prompt 'Enter API key (input hidden)' -AsSecureString
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)

try {
  $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)

  if ($ApiKeyTarget -eq 'ZAI' -or $ApiKeyTarget -eq 'Both')   { $env:ZAI_API_KEY   = $plain }
  if ($ApiKeyTarget -eq 'ZHIPU' -or $ApiKeyTarget -eq 'Both') { $env:ZHIPU_API_KEY = $plain }

  $pwsh = (Get-Command pwsh -ErrorAction Stop).Source

  & $pwsh -NoProfile -ExecutionPolicy Bypass -File $safe `
    -RepoRoot $RepoRoot `
    -ProbeScriptRelPath $ProbeScriptRelPath `
    -ModelCandidatesCsv $ModelCandidatesCsv `
    -TimeoutSeconds $TimeoutSeconds `
    -InstallIfMissing $InstallIfMissing `
    -OpenCodeNpmVersion $OpenCodeNpmVersion `
    -LogLevel $LogLevel
}
finally {
  try { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) } catch {}
  Remove-Item Env:ZAI_API_KEY, Env:ZHIPU_API_KEY -ErrorAction SilentlyContinue
  $plain = $null; $sec = $null
  [GC]::Collect()
}
