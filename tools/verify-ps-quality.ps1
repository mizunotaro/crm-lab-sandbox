#requires -Version 7.0
<#
.SYNOPSIS
  Local verification for PowerShell scripts:
  - Official PowerShell parser (AST) for ParserError detection
  - PSScriptAnalyzer (>= 1.24.0)

.DESCRIPTION
  Designed for Windows11 + PowerShell 7.5.4+.
  Exits non-zero on:
    - Parser errors
    - ScriptAnalyzer findings in severity_fail (from qc-policy.json if available)
    - Module install/import failures (fail-safe)
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]$Root = (Get-Location).Path,

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]$PolicyPath = ".github/ai/qc-policy.json",

  [Parameter(Mandatory = $false)]
  [switch]$Recurse = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
try { $PSNativeCommandUseErrorActionPreference = $false } catch { }

function Write-LogLine {
  param([Parameter(Mandatory)][string]$Level, [Parameter(Mandatory)][string]$Message)
  $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
  Write-Host ("[{0}][{1}] {2}" -f $ts, $Level.ToUpperInvariant(), $Message)
}

function Assert-MinPwsh {
  param([Parameter(Mandatory)][version]$MinVersion)
  $v = $PSVersionTable.PSVersion
  if ($v -lt $MinVersion) {
    throw "PowerShell version too old: $v (required >= $MinVersion)"
  }
}

function Read-PolicyOrDefault {
  param([Parameter(Mandatory)][string]$Path)

  $defaults = [pscustomobject]@{
    powershell = [pscustomobject]@{
      extensions = @('.ps1', '.psm1', '.psd1')
      script_analyzer = [pscustomobject]@{
        enabled = $true
        severity_fail = @('Error')
        severity_report = @('Error', 'Warning', 'Information')
      }
    }
  }

  try {
    if (-not (Test-Path -LiteralPath $Path)) {
      Write-LogLine -Level 'WARN' -Message "Policy file not found: $Path (using defaults)"
      return $defaults
    }
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $p = $raw | ConvertFrom-Json -Depth 50
    return $p
  } catch {
    Write-LogLine -Level 'WARN' -Message "Failed to parse policy file; using defaults."
    return $defaults
  }
}

function Ensure-PSScriptAnalyzer {
  param([Parameter(Mandatory)][version]$MinVersion)

  $found = Get-Module -ListAvailable -Name PSScriptAnalyzer |
    Sort-Object Version -Descending |
    Select-Object -First 1

  if ($found -and $found.Version -ge $MinVersion) { return }

  Write-LogLine -Level 'INFO' -Message "Installing PSScriptAnalyzer >= $MinVersion (CurrentUser scope)..."
  $ProgressPreference = 'SilentlyContinue'
  try {
    Install-Module -Name PSScriptAnalyzer -MinimumVersion $MinVersion -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
  } catch {
    Install-Module -Name PSScriptAnalyzer -RequiredVersion $MinVersion -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
  }
}

function Get-Targets {
  param(
    [Parameter(Mandatory)][string]$Root,
    [Parameter(Mandatory)][string[]]$Extensions,
    [Parameter(Mandatory)][switch]$Recurse
  )

  if (-not (Test-Path -LiteralPath $Root)) { throw "Root path not found: $Root" }
  Push-Location $Root
  try {
    $opts = @{ File = $true; ErrorAction = 'Stop' }
    if ($Recurse) { $opts.Recurse = $true }
    $files = Get-ChildItem @opts | Where-Object { $Extensions -contains $_.Extension.ToLowerInvariant() }
    return @($files.FullName | Sort-Object -Unique)
  } finally {
    Pop-Location
  }
}

function Parse-File {
  param([Parameter(Mandatory)][string]$Path)
  $tokens = $null
  $errs = $null
  [void][System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errs)
  return @($errs)
}

# --- Main ---
try {
  Assert-MinPwsh -MinVersion ([version]'7.5.4')

  $policy = Read-PolicyOrDefault -Path (Join-Path $Root $PolicyPath)
  $ps = $policy.powershell
  $ext = @($ps.extensions | ForEach-Object { [string]$_ } | ForEach-Object { $_.ToLowerInvariant() })

  $targets = Get-Targets -Root $Root -Extensions $ext -Recurse:$Recurse
  if (-not $targets -or $targets.Count -eq 0) {
    Write-LogLine -Level 'INFO' -Message "No PowerShell files found under: $Root"
    exit 0
  }

  $parserProblems = New-Object System.Collections.Generic.List[string]
  foreach ($f in $targets) {
    $errs = Parse-File -Path $f
    foreach ($e in $errs) {
      $parserProblems.Add(("{0}:{1}:{2} {3}" -f $f, $e.Extent.StartLineNumber, $e.Extent.StartColumnNumber, $e.Message))
    }
  }

  if ($parserProblems.Count -gt 0) {
    Write-LogLine -Level 'ERROR' -Message "Parser errors detected:"
    $parserProblems | ForEach-Object { Write-Host $_ }
    exit 1
  }

  $sa = $ps.script_analyzer
  if ($sa.enabled -ne $true) {
    Write-LogLine -Level 'INFO' -Message "ScriptAnalyzer disabled by policy."
    exit 0
  }

  Ensure-PSScriptAnalyzer -MinVersion ([version]'1.24.0')
  Import-Module PSScriptAnalyzer -ErrorAction Stop

  $sevReport = @($sa.severity_report)
  $sevFail   = @($sa.severity_fail)

  $report = New-Object System.Collections.Generic.List[string]
  $fail   = New-Object System.Collections.Generic.List[string]

  foreach ($f in $targets) {
    $findReport = Invoke-ScriptAnalyzer -Path $f -Severity $sevReport -ErrorAction Stop
    foreach ($x in ($findReport | Where-Object { $_ })) {
      $report.Add(("{0}:{1}:{2} [{3}] {4} {5}" -f $f, $x.Line, $x.Column, $x.Severity, $x.RuleName, $x.Message))
    }

    $findFail = Invoke-ScriptAnalyzer -Path $f -Severity $sevFail -ErrorAction Stop
    foreach ($x in ($findFail | Where-Object { $_ })) {
      $fail.Add(("{0}:{1}:{2} [{3}] {4} {5}" -f $f, $x.Line, $x.Column, $x.Severity, $x.RuleName, $x.Message))
    }
  }

  if ($report.Count -gt 0) {
    Write-LogLine -Level 'INFO' -Message "ScriptAnalyzer findings (report):"
    $report | ForEach-Object { Write-Host $_ }
  }

  if ($fail.Count -gt 0) {
    Write-LogLine -Level 'ERROR' -Message "ScriptAnalyzer findings (fail):"
    $fail | ForEach-Object { Write-Host $_ }
    exit 1
  }

  Write-LogLine -Level 'INFO' -Message "OK: Parser + ScriptAnalyzer passed."
  exit 0

} catch {
  Write-LogLine -Level 'ERROR' -Message $_.Exception.Message
  Write-LogLine -Level 'ERROR' -Message $_.ScriptStackTrace
  exit 1
}
