#requires -Version 7.0
<#
RUN_probe-opencode.safe.ps1 (v6)
Goal:
- Safely run ops/scripts/probe-opencode.ps1 with minimal friction under strict ExecutionPolicy.
- Avoid PowerShell cross-process array binding pitfalls.

IMPORTANT (PowerShell behavior):
- When you run a script via `pwsh -File ...`, do NOT pass array expressions like:
    -ModelCandidates @('a','b')
  because the outer PowerShell expands the array into:
    -ModelCandidates a b
  and PowerShell binds ONLY the first value, making `b` an unbound positional argument.

Stable pattern (recommended):
- Use -ModelCandidatesCsv (single string argument), e.g.
    -ModelCandidatesCsv "a,b"
    -ModelCandidatesCsv "'a','b'"
    -ModelCandidatesCsv "a b"

Alternative (same-process invocation):
- Call the script directly:
    & .\ops\scripts\RUN_probe-opencode.safe.ps1 -RepoRoot ... -ModelCandidates @('a','b') ...

Safety:
- Does NOT change machine/user execution policy.
- Best-effort Unblock-File (Mark-of-the-Web removal) to support RemoteSigned.
- Detects GPO-enforced AllSigned/Restricted and fails fast (Bypass can't override).
#>

[CmdletBinding(PositionalBinding=$false)]
param(
  [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$RepoRoot,
  [Parameter()][ValidateNotNullOrEmpty()][string]$ProbeScriptRelPath = 'ops/scripts/probe-opencode.ps1',
  [Parameter()][string]$OutDir = '',

  # Use this when invoking via `pwsh -File` (single argument; script will split)
  [Parameter()][string]$ModelCandidatesCsv = 'zai-coding-plan/glm-4.7,zai-coding-plan/glm-4.6',

  # Use this only when invoking in the same PowerShell process (call operator `&`)
  [Parameter()][string[]]$ModelCandidates = @(),

  [Parameter()][ValidateRange(10,1800)][int]$TimeoutSeconds = 60,
  [Parameter()][ValidateSet('None','Npm')][string]$InstallIfMissing = 'Npm',
  [Parameter()][string]$OpenCodeNpmVersion = '1.1.44',
  [Parameter()][ValidateSet('INFO','DEBUG','WARN','ERROR')][string]$LogLevel = 'INFO',

  # Optional: prompt for API key locally (session-scoped; not persisted)
  [Parameter()][switch]$PromptForApiKey,
  [Parameter()][ValidateSet('ZAI','ZHIPU','Both')][string]$ApiKeyTarget = 'Both',

  [Parameter()][switch]$ForceBypass
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-SecretPlainText([string]$Prompt) {
  $sec = Read-Host -Prompt $Prompt -AsSecureString
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
  try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
  finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

function Ensure-ApiKeysLocal([switch]$PromptForApiKey, [string]$ApiKeyTarget) {
  $hasZai = -not [string]::IsNullOrWhiteSpace($env:ZAI_API_KEY)
  $hasZhipu = -not [string]::IsNullOrWhiteSpace($env:ZHIPU_API_KEY)

  if ($hasZai -or $hasZhipu) { return }

  if (-not $PromptForApiKey) { return }

  $key = Read-SecretPlainText -Prompt 'Enter API key (will be set to env vars for THIS session only)'
  if ([string]::IsNullOrWhiteSpace($key)) { throw 'API key input was empty.' }

  if ($ApiKeyTarget -in @('ZAI','Both'))   { $env:ZAI_API_KEY = $key }
  if ($ApiKeyTarget -in @('ZHIPU','Both')) { $env:ZHIPU_API_KEY = $key }
}


function New-Dir([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
}

function Ensure-Unblocked([string]$Path) {
  try { Unblock-File -LiteralPath $Path -ErrorAction Stop; return $true } catch { return $false }
}

function Get-EffectivePolicy {
  try { return (Get-ExecutionPolicy) } catch { return $null }
}

function Get-PolicyMap {
  try { $raw = (Get-ExecutionPolicy -List) } catch { return @{} }
  if ($null -eq $raw) { return @{} }

  if ($raw -is [System.Collections.IDictionary]) {
    $m = @{}
    foreach ($k in $raw.Keys) { $m[[string]$k] = [string]$raw[$k] }
    return $m
  }

  $map = @{}
  foreach ($item in @($raw)) {
    $scopeProp = $item.PSObject.Properties['Scope']
    $polProp   = $item.PSObject.Properties['ExecutionPolicy']
    if ($scopeProp -and $polProp) {
      $map[[string]$scopeProp.Value] = [string]$polProp.Value
    }
  }
  return $map
}

function Get-MapValue([hashtable]$Map, [string]$Key) {
  if ($null -eq $Map) { return $null }
  if ($Map.ContainsKey($Key)) { return $Map[$Key] }
  return $null
}

function Has-GpoOverrideAllSignedOrRestricted([hashtable]$PolicyMap) {
  $mp = Get-MapValue -Map $PolicyMap -Key 'MachinePolicy'
  $up = Get-MapValue -Map $PolicyMap -Key 'UserPolicy'
  return ($mp -in @('AllSigned','Restricted')) -or ($up -in @('AllSigned','Restricted'))
}

if (-not (Test-Path -LiteralPath $RepoRoot)) { throw "RepoRoot not found: $RepoRoot" }

# Repo sanity check (avoid passing C:\Users\... by mistake)
if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot '.git'))) {
  throw "RepoRoot does not look like a git repo (missing .git): $RepoRoot"
}

Set-Location -LiteralPath $RepoRoot
Ensure-ApiKeysLocal -PromptForApiKey:$PromptForApiKey -ApiKeyTarget $ApiKeyTarget

$probePath = Join-Path $RepoRoot $ProbeScriptRelPath
if (-not (Test-Path -LiteralPath $probePath)) { throw "Probe script not found: $probePath" }

if ([string]::IsNullOrWhiteSpace($OutDir)) {
  $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
  $OutDir = Join-Path $RepoRoot ("_probe\probe_{0}" -f $ts)
}
New-Dir $OutDir

[void](Ensure-Unblocked $probePath)

$effective  = Get-EffectivePolicy
$policyMap  = Get-PolicyMap
$gpoLocks   = Has-GpoOverrideAllSignedOrRestricted $policyMap

$argsPath = Join-Path $OutDir 'wrapper_args.txt'
Set-Content -LiteralPath $argsPath -Encoding utf8NoBOM -Value @(
  ("RepoRoot={0}" -f $RepoRoot)
  ("ProbeScriptRelPath={0}" -f $ProbeScriptRelPath)
  ("OutDir={0}" -f $OutDir)
  ("ModelCandidatesCsv={0}" -f $ModelCandidatesCsv)
  ("ModelCandidates(in-process)={0}" -f (@($ModelCandidates) -join '|'))
  ("TimeoutSeconds={0}" -f $TimeoutSeconds)
  ("InstallIfMissing={0}" -f $InstallIfMissing)
  ("OpenCodeNpmVersion={0}" -f $OpenCodeNpmVersion)
  ("LogLevel={0}" -f $LogLevel)
  ("ExecutionPolicy(effective)={0}" -f $effective)
  ("ExecutionPolicy(MachinePolicy)={0}" -f (Get-MapValue -Map $policyMap -Key 'MachinePolicy'))
  ("ExecutionPolicy(UserPolicy)={0}" -f (Get-MapValue -Map $policyMap -Key 'UserPolicy'))
  ("gpo_override_allSignedOrRestricted={0}" -f $gpoLocks)
)

$needBypass = $ForceBypass -or ($effective -in @('AllSigned','Restricted'))

if ($needBypass -and $gpoLocks) {
  throw "ExecutionPolicy is enforced by Group Policy (MachinePolicy/UserPolicy=AllSigned/Restricted). '-ExecutionPolicy Bypass' cannot override. Sign scripts with a trusted code-signing cert (or adjust policy per your org rules). See $argsPath for details."
}

# Build args for the probe (use ModelCandidatesCsv to avoid cross-process array binding issues)
$probeArgs = @('-NoProfile','-File', $probePath)
$probeArgs += @(
  '-ModelCandidatesCsv', $ModelCandidatesCsv,
  '-TimeoutSeconds', $TimeoutSeconds,
  '-OutDir', $OutDir,
  '-InstallIfMissing', $InstallIfMissing,
  '-OpenCodeNpmVersion', $OpenCodeNpmVersion,
  '-LogLevel', $LogLevel
)

$pwsh = (Get-Command pwsh -ErrorAction Stop).Source

if ($needBypass) {
  & $pwsh -NoProfile -ExecutionPolicy Bypass -File $probePath `
    -ModelCandidatesCsv $ModelCandidatesCsv `
    -TimeoutSeconds $TimeoutSeconds `
    -OutDir $OutDir `
    -InstallIfMissing $InstallIfMissing `
    -OpenCodeNpmVersion $OpenCodeNpmVersion `
    -LogLevel $LogLevel
} else {
  & $pwsh @probeArgs
}

$sum = Join-Path $OutDir 'summary.json'
if (Test-Path -LiteralPath $sum) {
  "OK: summary.json -> $sum"
  Get-Content -LiteralPath $sum
} else {
  $fe = Join-Path $OutDir 'fatal_error.txt'
  if (Test-Path -LiteralPath $fe) {
    'ERROR: summary.json not found; probe crashed. Showing fatal_error.txt:'
    Get-Content -LiteralPath $fe
  } else {
    'ERROR: summary.json not found; probe may have crashed before writing outputs.'
  }
  throw "summary.json not found at: $sum"
}