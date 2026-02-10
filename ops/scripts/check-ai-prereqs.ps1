<#
check-ai-prereqs.ps1 (v1.0.2)

Goal:
- Static + minimal dynamic preflight for AI automation.
- Always writes a JSON log (even on failure).
- Avoids PowerShell pitfalls: .Count on scalar, null pipeline, placeholders.

Outputs:
- Writes JSON log alongside this script: ai-prereqs-<timestamp>-<pid>.json
- Writes text log alongside this script: check-ai-prereqs-<timestamp>-<pid>.log
- Prints the log path to stdout (for workflow step parsing).
- Exit code 0 when PASS, 1 when FAIL.

Security:
- Does NOT print secret values.

Usage:
  pwsh -NoProfile -ExecutionPolicy Bypass -File ./check-ai-prereqs.ps1 -Repo owner/repo
  pwsh -NoProfile -ExecutionPolicy Bypass -File ./check-ai-prereqs.ps1 -Repo owner/repo -JsonOnly

Notes:
- We intentionally avoid '#requires -Version 7.0' so we can still produce a log on older PowerShell versions.
#>

[CmdletBinding(PositionalBinding = $false)]
param(
  [Parameter()]
  [string]$Repo = '',

  [Parameter()]
  [switch]$JsonOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Run identifier reused across all outputs for easy correlation
$script:RunId = Get-Date -Format 'yyyyMMdd_HHmmss_fff'
$script:TextLogPath = ''

function Append-TextLogLine([string]$Message) {
  try {
    if (-not [string]::IsNullOrWhiteSpace($script:TextLogPath)) {
      [System.IO.File]::AppendAllText(
        $script:TextLogPath,
        ($Message + "`r`n"),
        (New-Object System.Text.UTF8Encoding($false))
      )
    }
  } catch {
    # never fail the run due to logging
  }
}

function Write-Info([string]$Message) {
  Append-TextLogLine $Message
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
    # Avoid stale values if the scriptblock does not invoke an external process
    $global:LASTEXITCODE = 0

    # Capture stderr together; keep for diagnosis.
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

function Resolve-LogDir() {
  # Per user request: prefer the script directory (same folder as this .ps1).
  $candidates = New-Object System.Collections.Generic.List[string]

  try {
    if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
      $candidates.Add($PSScriptRoot)
    }
  } catch { }

  try { $candidates.Add((Get-Location).Path) } catch { }

  if (-not [string]::IsNullOrWhiteSpace($env:RUNNER_TEMP)) { $candidates.Add($env:RUNNER_TEMP) }
  if (-not [string]::IsNullOrWhiteSpace($env:TEMP)) { $candidates.Add($env:TEMP) }

  foreach ($dir in $candidates) {
    try {
      # sanity: verify we can write
      $probe = Join-Path $dir (".probe-{0}.tmp" -f ([Guid]::NewGuid().ToString('n')))
      [System.IO.File]::WriteAllText($probe, "ok", (New-Object System.Text.UTF8Encoding($false)))
      Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
      return $dir
    } catch {
      continue
    }
  }

  # absolute last resort
  return '.'
}

function Write-JsonLog([object]$Obj, [string]$LogDir) {
  $ts = $script:RunId
  if ([string]::IsNullOrWhiteSpace($ts)) { $ts = Get-Date -Format 'yyyyMMdd_HHmmss_fff' }
  $logPath = Join-Path $LogDir ("ai-prereqs-{0}-{1}.json" -f $ts, $PID)
  $json = $Obj | ConvertTo-Json -Depth 30
  # UTF8 without BOM
  [System.IO.File]::WriteAllText($logPath, $json, (New-Object System.Text.UTF8Encoding($false)))
  return $logPath
}

function Set-Fail([System.Collections.IDictionary]$Result, [string]$Summary) {
  $Result['status'] = 'fail'
  Append-TextLogLine ('FAIL: ' + $Summary)
  if ([string]::IsNullOrWhiteSpace([string]$Result['summary'])) {
    $Result['summary'] = $Summary
  } else {
    $Result['summary'] = ([string]$Result['summary'] + ' | ' + $Summary)
  }
}

# --- initialize result as early as possible ---
$result = [ordered]@{
  ts = (Get-Date).ToString('o')
  repo = $Repo
  status = 'pass'
  summary = ''
  outputs = [ordered]@{
    textLogPath = ''
  }
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
$logDir = Resolve-LogDir

# Create a plain text log in the same directory as the JSON (prefer script dir)
try {
  $script:TextLogPath = Join-Path $logDir ("check-ai-prereqs-{0}-{1}.log" -f $script:RunId, $PID)
  # Touch + header
  [System.IO.File]::WriteAllText($script:TextLogPath, ("startedAt=" + (Get-Date).ToString('o') + "`r`n"), (New-Object System.Text.UTF8Encoding($false)))
  $result.outputs.textLogPath = $script:TextLogPath
} catch {
  $script:TextLogPath = ''
}


try {
  # --- preflight (do not terminate before logging) ---
  if ($PSVersionTable.PSVersion.Major -lt 7) {
    Set-Fail -Result $result -Summary ("powershell: requires 7+ (found {0})" -f $PSVersionTable.PSVersion.ToString())
    $exitCode = 1
  }

  if ([string]::IsNullOrWhiteSpace($Repo)) {
    Set-Fail -Result $result -Summary 'repo: missing -Repo owner/repo'
    $exitCode = 1
  } else {
    $result.repo = $Repo
  }

  try {
    Assert-Command git
    Assert-Command gh
  } catch {
    Set-Fail -Result $result -Summary ("tools: {0}" -f $_.Exception.Message)
    $exitCode = 1
  }

  if ($exitCode -ne 0) {
    # Preflight failed; skip further checks but still log.
    throw "preflight failed"
  }

  # --- labels ---
  Write-Info "Checking labels..."
  $labelNames = Try-RunLines { gh label list --repo $Repo --limit 500 --json name --jq '.[].name' }
  $labelNames = @($labelNames | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

  if ($labelNames.Count -eq 0) {
    $result.checks.labels.note = $script:TryRunLastErrorText
    Set-Fail -Result $result -Summary 'labels: unable to list labels (auth/permissions or repo not found)'
    $exitCode = 1
  } else {
    $result.checks.labels.present = $labelNames
    $missing = @()
    $req = @($result.checks.labels.required)
    foreach ($r in $req) {
      if (-not ($labelNames -contains $r)) { $missing += $r }
    }
    $result.checks.labels.missing = $missing
    if ($missing.Count -gt 0) {
      Set-Fail -Result $result -Summary ("labels missing: {0}" -f ($missing -join ','))
      $exitCode = 1
    }
  }

  # --- default branch ---
  Write-Info "Detecting default branch..."
  $defaultBranchLines = Try-RunLines { gh api "repos/$Repo" --jq '.default_branch' }
  $defaultBranchLines = @($defaultBranchLines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
  if ($defaultBranchLines.Count -gt 0) {
    $result.checks.branch_protection.branch = ($defaultBranchLines[0]).Trim()
  } else {
    if (-not [string]::IsNullOrWhiteSpace($script:TryRunLastErrorText)) {
      $result.checks.branch_protection.note = ("default_branch lookup failed: {0}" -f $script:TryRunLastErrorText)
    }
  }

  # --- secrets (names only) ---
  Write-Info "Checking secrets..."
  $secretNames = Try-RunLines { gh secret list --repo $Repo --json name --jq '.[].name' }
  $secretNames = @($secretNames | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

  if ($secretNames.Count -eq 0) {
    $apiFailed = -not [string]::IsNullOrWhiteSpace($script:TryRunLastErrorText)

    # In GitHub Actions, GITHUB_TOKEN often can't list secrets: treat as SKIP (note only).
    if (Is-Integration403 $script:TryRunLastErrorText -or (($env:GITHUB_ACTIONS -eq 'true') -and $apiFailed)) {
      Write-Warning "SKIP: unable to list secrets (insufficient token permission)."
      $result.checks.secrets.note = 'SKIP: unable to list secrets (insufficient token permission).'
    } else {
      # outside Actions: record note and use env hint; if neither env exists, fail.
      $result.checks.secrets.note = 'unable to list secrets via gh (token permissions). Ensure at least one of ZAI_API_KEY or ZHIPU_API_KEY exists.'
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
    $apiFailed = -not [string]::IsNullOrWhiteSpace($script:TryRunLastErrorText)
    if ($apiFailed) {
      $result.checks.variables.note = 'unable to list variables via gh api (token permissions).'
      # do not hard-fail on inability to list
    } else {
      # listing succeeded but there are no variables: treat required vars as missing
      $missingVars = @($result.checks.variables.required)
      $result.checks.variables.missing = $missingVars
      Set-Fail -Result $result -Summary ("variables missing: {0}" -f ($missingVars -join ','))
      $exitCode = 1
    }
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

  # --- branch protection (default branch) ---
  $branch = $result.checks.branch_protection.branch
  Write-Info ("Checking branch protection ({0})..." -f $branch)
  $contexts = Try-RunLines { gh api ("repos/{0}/branches/{1}/protection" -f $Repo, $branch) --jq '.required_status_checks.contexts[]?' }
  $contexts = @($contexts | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

  if ($contexts.Count -gt 0) {
    $result.checks.branch_protection.enabled = $true
  } else {
    $apiFailed = -not [string]::IsNullOrWhiteSpace($script:TryRunLastErrorText)
    if ($apiFailed -and (Is-Integration403 $script:TryRunLastErrorText)) {
      # In Actions, protection might be readable, but if not, treat as note.
      $result.checks.branch_protection.note = 'unable to read branch protection (insufficient token permission).'
    } else {
      # 404 when not protected, or empty contexts
      $result.checks.branch_protection.enabled = $false
      Set-Fail -Result $result -Summary ("branch protection missing on {0} (required status checks not enforced)" -f $branch)
      $result.checks.branch_protection.note = ("repos/.../branches/{0}/protection returned empty/404." -f $branch)
      $exitCode = 1
    }
  }

} catch {
  # Catch-all: mark fail but still write log
  if ($_.Exception.Message -ne 'preflight failed') {
    Set-Fail -Result $result -Summary ("exception: {0}" -f $_.Exception.Message)
  }
  $exitCode = 1
} finally {
  $logPath = ''
  try {
    # Per user request: write alongside script first; fallback is handled by Resolve-LogDir.
    if ([string]::IsNullOrWhiteSpace($logDir)) { $logDir = Resolve-LogDir }
    $logPath = Write-JsonLog -Obj $result -LogDir $logDir
  } catch {
    # Last resort: emit JSON to stdout so CI has *something* actionable.
    Write-Warning ("FAILED to write JSON log to disk: {0}" -f $_.Exception.Message)
    Write-Output ($result | ConvertTo-Json -Depth 30)
  }

  if (-not [string]::IsNullOrWhiteSpace($logPath)) {
    # Print log path for workflow step parsing, even in JsonOnly mode
    Write-Output $logPath
  }
}

exit $exitCode
