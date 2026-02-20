#requires -Version 7.0
<#
.SYNOPSIS
  Issue7: QC policy enforcement + optional ruff autofix with retry guard.

.DESCRIPTION
  - Runs on GitHub Actions (Windows runner) for internal PRs only.
  - Checks:
    * PowerShell: official parser (AST) + PSScriptAnalyzer (>=1.24.0) per policy.
    * Python: ruff via uvx per policy.
  - If findings exist and autofix is applicable:
    * Runs ruff --fix and pushes a commit to the PR head branch.
  - Guardrails:
    * Label gate (policy.labels.gate_any_of)
    * Attempt limit (policy.attempts.max_autofix_commits) with prefix counting
    * Fail-safe: if attempt count cannot be determined, block to avoid loops.
  - Token handling:
    * Prefers GH_TOKEN (PAT). Falls back to GITHUB_TOKEN.
    * Avoids embedding tokens in remote URLs; uses http.extraheader as fallback.

.NOTES
  Designed for Windows11 + PowerShell 7.5.4+ in local tests.
  In Actions, works with PowerShell 7+.
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string]$Repo,

  [Parameter(Mandatory)]
  [ValidateRange(1, 999999)]
  [int]$PullNumber,

  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string]$RunId,

  [Parameter(Mandatory = $false)]
  [ValidateRange(1, 1000)]
  [int]$MaxAttempts = 10,

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]$PolicyPath = ".github/ai/qc-policy.json"
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

function Invoke-Native {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Exe,
    [Parameter(Mandatory = $false)][string[]]$ExeArgs = @(),
    [Parameter(Mandatory = $false)][switch]$AllowNonZero,
    [Parameter(Mandatory = $false)][switch]$Quiet
  )

  $oldPref = $null
  $hasPref = $false
  try {
    $oldPref = $PSNativeCommandUseErrorActionPreference
    $hasPref = $true
    $PSNativeCommandUseErrorActionPreference = $false
  } catch { }

  try {
    if (-not $Quiet) { Write-LogLine -Level 'INFO' -Message ("Run: {0} {1}" -f $Exe, ($ExeArgs -join ' ')) }
    $out = & $Exe @ExeArgs 2>&1
    $code = $LASTEXITCODE
    $txt = (($out | Out-String).Trim())
    if (-not $AllowNonZero -and $code -ne 0) {
      throw ("Command failed (exit={0}): {1} {2}`n{3}" -f $code, $Exe, ($ExeArgs -join ' '), $txt)
    }
    return [pscustomobject]@{ ExitCode = $code; StdOut = $txt }
  } catch {
    $txt = (($_ | Out-String).Trim())
    $code = 1
    if ($_.Exception -is [System.Management.Automation.NativeCommandExitException]) {
      try { $code = [int]$_.Exception.ExitCode } catch { $code = 1 }
    } elseif ($LASTEXITCODE -ne $null) {
      try { $code = [int]$LASTEXITCODE } catch { $code = 1 }
    }
    if (-not $AllowNonZero) {
      throw ("Command threw (exit~={0}): {1} {2}`n{3}" -f $code, $Exe, ($ExeArgs -join ' '), $txt)
    }
    return [pscustomobject]@{ ExitCode = $code; StdOut = $txt }
  } finally {
    if ($hasPref) {
      try { $PSNativeCommandUseErrorActionPreference = $oldPref } catch { }
    }
  }
}

function Require-Command {
  param([Parameter(Mandatory)][string]$Name)
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if (-not $cmd) { throw "Required command not found: $Name" }
  return $cmd.Source
}

function Resolve-Token {
  if (-not $env:GH_TOKEN -and $env:GITHUB_TOKEN) { $env:GH_TOKEN = $env:GITHUB_TOKEN }
  if (-not $env:GH_TOKEN) { throw "Missing token. Set GH_TOKEN or GITHUB_TOKEN." }
}

function Read-Policy {
  param([Parameter(Mandatory)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { throw "Policy file not found: $Path" }
  Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 50
}

function Invoke-GhJson {
  param([Parameter(Mandatory)][string[]]$GhArgs)
  $r = Invoke-Native -Exe 'gh' -ExeArgs $GhArgs
  if (-not $r.StdOut) { throw "Expected JSON but got empty output from gh." }
  try {
    return ($r.StdOut | ConvertFrom-Json -Depth 100)
  } catch {
    throw "Failed to parse JSON output from gh. Output begins: $($r.StdOut.Substring(0, [Math]::Min(300, $r.StdOut.Length)))"
  }
}

function Try-Comment {
  param([string]$Body)
  try {
    [void](Invoke-Native -Exe 'gh' -ExeArgs @('pr', 'comment', "$PullNumber", '-R', $Repo, '-b', $Body) -Quiet)
  } catch {
    Write-LogLine -Level 'WARN' -Message ("Failed to comment: {0}" -f $_.Exception.Message)
  }
}

function Try-AddLabel {
  param([string]$Label)
  if (-not $Label) { return }
  try {
    [void](Invoke-Native -Exe 'gh' -ExeArgs @('pr', 'edit', "$PullNumber", '-R', $Repo, '--add-label', $Label) -Quiet)
  } catch {
    Write-LogLine -Level 'WARN' -Message ("Failed to add label '{0}': {1}" -f $Label, $_.Exception.Message)
  }
}

function Get-PrInfo {
  $fields = 'url,labels,isDraft,headRefName,headRefOid,headRepository,baseRefName'
  return Invoke-GhJson -ExeArgs @('pr', 'view', "$PullNumber", '-R', $Repo, '--json', $fields)
}

function Get-ChangedFiles {
  $r = Invoke-Native -Exe 'gh' -ExeArgs @('pr', 'diff', "$PullNumber", '-R', $Repo, '--name-only')
  ($r.StdOut -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

function Has-AnyGateLabel {
  param(
    [Parameter(Mandatory)][string[]]$GateAnyOf,
    [Parameter(Mandatory)][object[]]$Labels
  )
  $labelNames = @()
  foreach ($l in $Labels) {
    # gh returns objects with "name"
    try { $labelNames += [string]$l.name } catch { }
  }
  foreach ($g in $GateAnyOf) {
    if ($labelNames -contains $g) { return $true }
  }
  return $false
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
    # Prefer MinimumVersion to allow patch releases
    Install-Module -Name PSScriptAnalyzer -MinimumVersion $MinVersion -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
  } catch {
    # fallback: RequiredVersion
    Install-Module -Name PSScriptAnalyzer -RequiredVersion $MinVersion -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
  }
}

function Check-PowerShellFiles {
  param(
    [Parameter(Mandatory)][string[]]$Files,
    [Parameter(Mandatory)][object]$Policy
  )

  $parserErrors = New-Object System.Collections.Generic.List[string]
  $reportFindings = New-Object System.Collections.Generic.List[string]
  $failFindings = New-Object System.Collections.Generic.List[string]

  foreach ($f in $Files) {
    if (-not (Test-Path -LiteralPath $f)) { continue }
    $tokens = $null
    $errs = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path -LiteralPath $f).Path, [ref]$tokens, [ref]$errs)
    if ($errs) {
      foreach ($e in $errs) {
        $parserErrors.Add(("{0}:{1}:{2} {3}" -f $f, $e.Extent.StartLineNumber, $e.Extent.StartColumnNumber, $e.Message))
      }
    }
  }

  $sa = $Policy.powershell.script_analyzer
  if ($sa -and $sa.enabled -eq $true) {
    Ensure-PSScriptAnalyzer -MinVersion ([version]'1.24.0')
    Import-Module PSScriptAnalyzer -ErrorAction Stop

    $sevReport = @($sa.severity_report)
    $sevFail   = @($sa.severity_fail)

    foreach ($f in $Files) {
      if (-not (Test-Path -LiteralPath $f)) { continue }

      $findReport = Invoke-ScriptAnalyzer -Path $f -Severity $sevReport -ErrorAction Stop
      foreach ($x in ($findReport | Where-Object { $_ })) {
        $reportFindings.Add(("{0}:{1}:{2} [{3}] {4} {5}" -f $f, $x.Line, $x.Column, $x.Severity, $x.RuleName, $x.Message))
      }

      $findFail = Invoke-ScriptAnalyzer -Path $f -Severity $sevFail -ErrorAction Stop
      foreach ($x in ($findFail | Where-Object { $_ })) {
        $failFindings.Add(("{0}:{1}:{2} [{3}] {4} {5}" -f $f, $x.Line, $x.Column, $x.Severity, $x.RuleName, $x.Message))
      }
    }
  }

  [pscustomobject]@{
    ParserErrors    = @($parserErrors)
    AnalyzerReport  = @($reportFindings)
    AnalyzerFail    = @($failFindings)
  }
}

function Resolve-RuffRunner {
  $uvx = Get-Command uvx -ErrorAction SilentlyContinue
  if ($uvx) { return [pscustomobject]@{ Exe = 'uvx'; PrefixArgs = @('ruff') } }

  $ruff = Get-Command ruff -ErrorAction SilentlyContinue
  if ($ruff) { return [pscustomobject]@{ Exe = 'ruff'; PrefixArgs = @() } }

  $uv = Get-Command uv -ErrorAction SilentlyContinue
  if ($uv) { return [pscustomobject]@{ Exe = 'uv'; PrefixArgs = @('tool', 'run', 'ruff') } }

  throw "No ruff runner found. Expected 'uvx' (preferred), 'ruff', or 'uv'."
}

function Run-Ruff {
  param(
    [Parameter(Mandatory)][string[]]$Files,
    [Parameter(Mandatory)][string[]]$RuffArgs
  )
  if (-not $Files -or $Files.Count -eq 0) {
    return [pscustomobject]@{ Exit = 0; Out = "" }
  }

  $runner = Resolve-RuffRunner
  $allArgs = @()
  $allArgs += @($runner.PrefixArgs)
  $allArgs += @($RuffArgs)
  $allArgs += @($Files)

  $r = Invoke-Native -Exe $runner.Exe -ExeArgs $allArgs -AllowNonZero
  [pscustomobject]@{ Exit = $r.ExitCode; Out = $r.StdOut }
}

function Git-HasChanges {
  $r = Invoke-Native -Exe 'git' -ExeArgs @('status', '--porcelain')
  return ($r.StdOut.Trim().Length -gt 0)
}

function Git-Commit {
  param(
    [Parameter(Mandatory)][string]$Message,
    [Parameter(Mandatory)][object]$Policy
  )
  [void](Invoke-Native -Exe 'git' -ExeArgs @('config', 'user.name', [string]$Policy.bot.user) -Quiet)
  [void](Invoke-Native -Exe 'git' -ExeArgs @('config', 'user.email', [string]$Policy.bot.email) -Quiet)

  [void](Invoke-Native -Exe 'git' -ExeArgs @('add', '-A') -Quiet)
  # allow empty? no. If empty commit attempted, it will fail and be handled by caller.
  [void](Invoke-Native -Exe 'git' -ExeArgs @('commit', '-m', $Message) -Quiet)
}

function Git-PushWithExtraHeader {
  param(
    [Parameter(Mandatory)][string]$Repo,
    [Parameter(Mandatory)][string]$Branch,
    [Parameter(Mandatory)][string]$Token
  )
  # Avoid token in URL; use Authorization header (basic x-access-token:TOKEN)
  $pair = "x-access-token:$Token"
  $basic = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
  $extra = "http.https://github.com/.extraheader=AUTHORIZATION: basic $basic"

  $env:GIT_TERMINAL_PROMPT = '0'
  try {
    [void](Invoke-Native -Exe 'git' -ExeArgs @('-c', $extra, 'push', 'origin', "HEAD:$Branch") -Quiet)
  } finally {
    Remove-Item Env:GIT_TERMINAL_PROMPT -ErrorAction SilentlyContinue
  }
}

function Git-Push {
  param(
    [Parameter(Mandatory)][string]$Branch
  )
  # 1) Normal push using checkout credentials (preferred)
  $r = Invoke-Native -Exe 'git' -ExeArgs @('push', 'origin', "HEAD:$Branch") -AllowNonZero -Quiet
  if ($r.ExitCode -eq 0) { return }

  Write-LogLine -Level 'WARN' -Message "Normal git push failed; trying token header fallback."
  $token = $env:GH_TOKEN
  if (-not $token) { throw "Token missing for push fallback." }

  Git-PushWithExtraHeader -Repo $Repo -Branch $Branch -Token $token
}

function Count-AutofixCommitsSafe {
  param(
    [Parameter(Mandatory)][string]$Prefix
  )

  # Attempt 1: paginate with jq first-line extraction (line-based, safe)
  try {
    $jq = '.[].commit.message | split("\n")[0]'
    $r = Invoke-Native -Exe 'gh' -ExeArgs @('api', "repos/$Repo/pulls/$PullNumber/commits", '--paginate', '--jq', $jq) -Quiet
    $lines = @($r.StdOut -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    return ($lines | Where-Object { $_.StartsWith($Prefix) }).Count
  } catch {
    Write-LogLine -Level 'WARN' -Message ("Attempt count (paginate+jq) failed: {0}" -f $_.Exception.Message)
  }

  # Attempt 2: single page (per_page=100). Safe because attempts are small (< 100 commits expected)
  try {
    $commits = Invoke-GhJson -ExeArgs @('api', "repos/$Repo/pulls/$PullNumber/commits?per_page=100")
    $count = 0
    foreach ($c in $commits) {
      try {
        $msg = [string]$c.commit.message
        $subject = ($msg -split "`r?`n")[0]
        if ($subject.StartsWith($Prefix)) { $count++ }
      } catch { }
    }
    return $count
  } catch {
    Write-LogLine -Level 'WARN' -Message ("Attempt count (single page) failed: {0}" -f $_.Exception.Message)
  }

  return $null
}

function Trim-Lines {
  param([string[]]$Lines, [int]$Max = 120)
  if (-not $Lines) { return @() }
  if ($Lines.Count -le $Max) { return $Lines }
  return @($Lines[0..($Max-1)] + @("... (truncated)"))
}

try {
  Require-Command -Name 'git' | Out-Null
  Require-Command -Name 'gh'  | Out-Null

  Resolve-Token

  $policy = Read-Policy -Path $PolicyPath
  $pr = Get-PrInfo

  if ($pr.isDraft -eq $true) { Write-LogLine -Level 'INFO' -Message "PR is draft. Skip."; exit 0 }

  # Safety: internal PR only
  if ([string]$pr.headRepository.fullName -ne $Repo) { Write-LogLine -Level 'INFO' -Message "External PR. Skip."; exit 0 }

  $gate = @($policy.labels.gate_any_of)
  if ($gate.Count -gt 0 -and -not (Has-AnyGateLabel -GateAnyOf $gate -Labels @($pr.labels))) {
    Write-LogLine -Level 'INFO' -Message "Gate labels not present. Skip."
    exit 0
  }

  $files = Get-ChangedFiles
  if (-not $files -or $files.Count -eq 0) { Write-LogLine -Level 'INFO' -Message "No changed files. Skip."; exit 0 }

  $psExt = @($policy.powershell.extensions)
  $pyExt = @($policy.python.extensions)

  $psFiles = @()
  $pyFiles = @()
  foreach ($f in $files) {
    $ext = [System.IO.Path]::GetExtension($f).ToLowerInvariant()
    if ($policy.powershell.enabled -eq $true -and $psExt -contains $ext) { $psFiles += $f; continue }
    if ($policy.python.enabled -eq $true -and $pyExt -contains $ext) { $pyFiles += $f; continue }
  }

  $psFail = $false
  $psRes = [pscustomobject]@{ ParserErrors = @(); AnalyzerReport = @(); AnalyzerFail = @() }
  if ($psFiles.Count -gt 0) {
    $psRes = Check-PowerShellFiles -Files $psFiles -Policy $policy
    if ($psRes.ParserErrors.Count -gt 0 -or $psRes.AnalyzerFail.Count -gt 0) { $psFail = $true }
  }

  $ruffFail = $false
  $ruffOut = [pscustomobject]@{ Exit = 0; Out = "" }
  if ($pyFiles.Count -gt 0 -and $policy.python.ruff) {
    $ruffOut = Run-Ruff -Files $pyFiles -ExeArgs @($policy.python.ruff.check_args)
    if ($policy.python.ruff.fail_on_findings -eq $true -and $ruffOut.Exit -ne 0) { $ruffFail = $true }
  }

  if (-not $psFail -and -not $ruffFail) { Write-LogLine -Level 'INFO' -Message "QC passed. Done."; exit 0 }

  $summary = New-Object System.Collections.Generic.List[string]
  $summary.Add("AI QC AutoFix report (run_id=$RunId)")
  $summary.Add("repo=$Repo pr=$PullNumber")
  if ($psFail) {
    $summary.Add("")
    $summary.Add("PowerShell: FAIL")
    $summary.AddRange((Trim-Lines -Lines @($psRes.ParserErrors + $psRes.AnalyzerFail) -Max 80))
  } elseif ($psFiles.Count -gt 0) {
    $summary.Add("")
    $summary.Add("PowerShell: OK (with report findings)")
    $summary.AddRange((Trim-Lines -Lines @($psRes.AnalyzerReport) -Max 40))
  }

  if ($ruffFail) {
    $summary.Add("")
    $summary.Add("Python ruff: FAIL")
    $summary.AddRange((Trim-Lines -Lines @($ruffOut.Out -split "`r?`n") -Max 120))
  }

  $prefix = [string]$policy.attempts.autofix_commit_prefix
  if (-not $prefix) { $prefix = "[autofix]" }

  $attemptNow = Count-AutofixCommitsSafe -Prefix $prefix
  if ($null -eq $attemptNow) {
    Try-Comment -Body (($summary + @("", "Autofix attempt count could not be determined. Failsafe: blocking to avoid loops.")) -join "`n")
    Try-AddLabel -Label ([string]$policy.labels.blocked)
    exit 1
  }

  # Attempt limit: prefer policy; also respect workflow param MaxAttempts (min of both)
  $policyMax = [int]$policy.attempts.max_autofix_commits
  $effectiveMax = [Math]::Min([int]$MaxAttempts, $policyMax)
  if ($attemptNow -ge $effectiveMax) {
    Try-Comment -Body (($summary + @("", "Autofix attempts exceeded ($attemptNow/$effectiveMax). Please review manually.")) -join "`n")
    Try-AddLabel -Label ([string]$policy.labels.blocked)
    exit 1
  }

  $canAutofix = ($policy.autofix.enabled -eq $true -and $policy.autofix.push_changes -eq $true -and $pyFiles.Count -gt 0)
  if (-not $canAutofix) {
    Try-Comment -Body (($summary + @("", "Autofix disabled or not applicable. Please review manually.")) -join "`n")
    Try-AddLabel -Label ([string]$policy.labels.blocked)
    exit 1
  }

  $fix = Run-Ruff -Files $pyFiles -ExeArgs @($policy.python.ruff.autofix_args)
  if ($fix.Exit -ne 0) {
    Try-Comment -Body (($summary + @("", "Autofix (ruff --fix) failed. Please review manually.")) -join "`n")
    Try-AddLabel -Label ([string]$policy.labels.blocked)
    exit 1
  }

  if (-not (Git-HasChanges)) {
    Try-Comment -Body (($summary + @("", "Autofix ran but produced no changes. Please review manually.")) -join "`n")
    Try-AddLabel -Label ([string]$policy.labels.blocked)
    exit 1
  }

  $next = $attemptNow + 1
  $headBranch = [string]$pr.headRefName
  if (-not $headBranch) { throw "Missing headRefName from PR info." }

  $commitMsg = "{0} ruff fix (attempt {1})" -f $prefix, $next

  Git-Commit -Message $commitMsg -Policy $policy
  Git-Push -Branch $headBranch

  Try-Comment -Body (($summary + @("", "Autofix pushed: $commitMsg")) -join "`n")
  exit 0

} catch {
  $msg = $_.Exception.Message
  Write-LogLine -Level 'ERROR' -Message $msg
  Try-Comment -Body ("Exception: {0} (run_id={1})" -f $msg, $RunId)
  Try-AddLabel -Label 'ai:blocked'
  throw
}
