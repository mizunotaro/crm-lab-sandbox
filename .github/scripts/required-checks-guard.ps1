#requires -Version 7.0
<#
.SYNOPSIS
  required-checks-guard: Validate that GitHub branch protection "required checks"
  are satisfied on the target commit (preferably PR HEAD / merge commit), based on
  observed facts from GitHub APIs (Checks API + Status API). YAML analysis is used
  only as an optional diagnostic aid.

.DESCRIPTION
  What this guard ultimately answers is one question:
    "Are ALL required checks configured in branch protection satisfied (successful)
     on the target commit (or the PR's HEAD / merge commit)?"

  Source-of-truth design (high stability / reproducibility):
    1) Required side: branch protection required_status_checks (contexts + checks[].context + strict)
    2) Observed side: per-commit check-runs (name + status + conclusion) AND status contexts (context + state)
    3) Diff & verdict: missing / failing / pending / unknown, with evidence pointers (API endpoints, URLs, timestamps)

  YAML workflow scanning:
    - Runs ONLY if online observation cannot conclusively PASS, or if explicitly requested.
    - It is *diagnostic* and must never override an online PASS.

.NOTES
  - Windows 11 + PowerShell 7 intended.
  - No -Command nesting; execute via pwsh -File.
  - Native commands are invoked via Start-Process with ArgumentList (string[]), with stdout/stderr redirected to files.
  - Logs are plain text (no Write-Error/Write-Warning) to avoid "Write-X: path:line" noise.

.PARAMETER Repo
  GitHub repository in OWNER/REPO. If omitted, uses env GITHUB_REPOSITORY, then git remote origin.

.PARAMETER Branch
  Target protected branch. If omitted, uses env GITHUB_BASE_REF, env GITHUB_REF_NAME, else 'main'.

.PARAMETER PullRequestNumber
  Target PR number. Strongly recommended for local runs (best reproducibility).

.PARAMETER TargetSha
  Explicit commit SHA to evaluate. If provided, PR resolution may be skipped.

.PARAMETER PreferMergeCommit
  If set (and PR is available), evaluate merge_commit_sha first when strict=true, otherwise evaluate head.sha.
  (If merge_commit_sha is unavailable, falls back to head.sha.)

.PARAMETER ReportsDir
  Output directory for reports (JSON + MD + optional dumps). Default: .github/scripts/_reports

.PARAMETER WorkflowsDir
  Workflow directory for optional YAML diagnostics. Default: .github/workflows

.PARAMETER SkipOnlineObservation
  Force skip online observation. Not recommended.

.PARAMETER AlsoRunYamlAnalysis
  Force YAML diagnostics even if online observation PASSed.

.PARAMETER FailOnApiError
  If set, any GitHub API failure results in non-zero exit.

.PARAMETER FailOnUnknown
  If set, "unknown" results in non-zero exit.

.PARAMETER FailOnMissingProtection
  If set, missing protection (404) results in non-zero exit.

.PARAMETER AcceptedCheckConclusions
  Check-run conclusions treated as PASS. Default: success

.PARAMETER ObservationPollAttempts / ObservationPollIntervalSec
  Polling for checks completion (handles eventual consistency / in-progress checks).

.PARAMETER GhTimeoutSec / GhApiRetries
  gh api execution timeout and retries.

.PARAMETER DumpGhIo
  Save redacted stdout/stderr dumps for gh calls to ReportsDir.

.EXAMPLE
  pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\required-checks-guard.v10.1.11.0.ps1 -Branch main -PullRequestNumber 521 -FailOnApiError -FailOnUnknown
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $false)]
  [string]$Repo,

  [Parameter(Mandatory = $false)]
  [string]$Branch,

  [Parameter(Mandatory = $false)]
  [ValidateRange(0, 1000000000)]
  [int]$PullRequestNumber = 0,

  [Parameter(Mandatory = $false)]
  [ValidatePattern('^[0-9a-fA-F]{7,40}$')]
  [string]$TargetSha,

  [Parameter(Mandatory = $false)]
  [switch]$PreferMergeCommit,

  [Parameter(Mandatory = $false)]
  [string]$ReportsDir = '.github/scripts/_reports',

  [Parameter(Mandatory = $false)]
  [string]$WorkflowsDir = '.github/workflows',

  [Parameter(Mandatory = $false)]
  [switch]$RecurseWorkflows,

  [Parameter(Mandatory = $false)]
  [switch]$SkipOnlineObservation,

  [Parameter(Mandatory = $false)]
  [switch]$AlsoRunYamlAnalysis,

  [Parameter(Mandatory = $false)]
  [switch]$FailOnApiError,

  [Parameter(Mandatory = $false)]
  [switch]$FailOnUnknown,

  [Parameter(Mandatory = $false)]
  [switch]$FailOnMissingProtection,

  [Parameter(Mandatory = $false)]
  [switch]$VerboseGhApi,

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]$GhExe = 'gh',

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]$GitExe = 'git',

  [Parameter(Mandatory = $false)]
  [ValidateRange(1, 10)]
  [int]$GhApiRetries = 3,

  [Parameter(Mandatory = $false)]
  [ValidateRange(5, 600)]
  [int]$GhTimeoutSec = 60,

  [Parameter(Mandatory = $false)]
  [ValidateRange(0, 60)]
  [int]$ObservationPollIntervalSec = 5,

  [Parameter(Mandatory = $false)]
  [ValidateRange(1, 20)]
  [int]$ObservationPollAttempts = 3,

  [Parameter(Mandatory = $false)]
  [ValidateRange(1, 100)]
  [int]$CheckRunsPerPage = 100,

  [Parameter(Mandatory = $false)]
  [string[]]$AcceptedCheckConclusions = @('success'),

  [Parameter(Mandatory = $false)]
  [switch]$DumpGhIo
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

$script:RcgVerboseGhApi = [bool]$VerboseGhApi

function Write-RcgLog {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Message,
    [Parameter(Mandatory = $false)][ValidateSet('INFO','WARN','ERROR')][string]$Level = 'INFO'
  )

  $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
  $line = '[{0}][{1}] {2}' -f $ts, $Level, $Message

  switch ($Level) {
    'ERROR' { [System.Console]::Error.WriteLine($line) }
    'WARN'  { [System.Console]::Error.WriteLine($line) }
    default { [System.Console]::Out.WriteLine($line) }
  }
}

function New-RcgStringSet {
  [CmdletBinding()]
  [OutputType([System.Collections.Generic.HashSet[string]])]
  param()
  return [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
}

function ConvertTo-RcgRedactedText {
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)][AllowNull()][string]$Text
  )

  if ($null -eq $Text) { return '' }
  $t = [string]$Text

  $patterns = @(
    '(?i)authorization:\s*bearer\s+[^ \r\n]+',
    '(?i)authorization:\s*token\s+[^ \r\n]+',
    '(?i)ghp_[A-Za-z0-9_]+',
    '(?i)github_pat_[A-Za-z0-9_]+',
    '(?i)x-oauth-basic',
    '(?i)cookie:\s*[^ \r\n]+'
  )

  foreach ($p in $patterns) {
    $t = [System.Text.RegularExpressions.Regex]::Replace($t, $p, '[REDACTED]')
  }
  return $t
}

function Resolve-RcgCommandPath {
  [CmdletBinding()]
  [OutputType([string])]
  param([Parameter(Mandatory)][string]$NameOrPath)

  if ([string]::IsNullOrWhiteSpace($NameOrPath)) { return $null }

  if ($NameOrPath -match '[\\/]' -or $NameOrPath -match '^\w:') {
    if (Test-Path -LiteralPath $NameOrPath) { return (Resolve-Path -LiteralPath $NameOrPath).Path }
    return $null
  }

  try {
    $cmd = Get-Command -Name $NameOrPath -ErrorAction Stop
    return [string]$cmd.Source
  } catch {
    return $null
  }
}

function Invoke-RcgProcess {
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param(
    [Parameter(Mandatory)][string]$ExePath,
    [Parameter(Mandatory = $false)][string[]]$Arguments = @(),
    [Parameter(Mandatory = $false)][ValidateRange(1, 3600)][int]$TimeoutSec = 60,
    [Parameter(Mandatory = $false)][string]$WorkingDirectory = (Get-Location).Path
  )

  if ([string]::IsNullOrWhiteSpace($ExePath)) {
    return [pscustomobject]@{ ExitCode = 127; TimedOut = $false; Stdout = ''; Stderr = 'Executable path is null/empty'; Exe = $ExePath; Arguments = @($Arguments) }
  }

  $tmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('rcg_' + [guid]::NewGuid().ToString('N'))
  [System.IO.Directory]::CreateDirectory($tmpRoot) | Out-Null

  $stdoutPath = Join-Path $tmpRoot 'stdout.txt'
  $stderrPath = Join-Path $tmpRoot 'stderr.txt'

  $p = $null
  $timedOut = $false
  $exitCode = -1

  try {
    $startInfo = @{
      FilePath               = $ExePath
      ArgumentList           = @($Arguments)
      WorkingDirectory       = $WorkingDirectory
      NoNewWindow            = $true
      PassThru               = $true
      Wait                   = $false
      RedirectStandardOutput = $stdoutPath
      RedirectStandardError  = $stderrPath
    }

    $p = Start-Process @startInfo
    $ok = $p.WaitForExit($TimeoutSec * 1000)

    if (-not $ok) {
      $timedOut = $true
      try { Stop-Process -Id $p.Id -Force -ErrorAction Stop } catch { }
      $exitCode = -1
    } else {
      try { $exitCode = [int]$p.ExitCode } catch { $exitCode = -1 }
    }

    $stdout = ''
    $stderr = ''
    try { if (Test-Path -LiteralPath $stdoutPath) { $stdout = Get-Content -LiteralPath $stdoutPath -Raw -ErrorAction SilentlyContinue } } catch { }
    try { if (Test-Path -LiteralPath $stderrPath) { $stderr = Get-Content -LiteralPath $stderrPath -Raw -ErrorAction SilentlyContinue } } catch { }

    return [pscustomobject]@{
      Exe      = $ExePath
      Arguments = @($Arguments)
      ExitCode = $exitCode
      TimedOut = $timedOut
      Stdout   = [string]$stdout
      Stderr   = [string]$stderr
    }
  } finally {
    try { if ($p -and -not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } } catch { }
    try { Remove-Item -LiteralPath $tmpRoot -Recurse -Force -ErrorAction SilentlyContinue } catch { }
  }
}

function Get-RcgHttpStatusFromText {
  [CmdletBinding()]
  [OutputType([int])]
  param([Parameter(Mandatory)][string]$Text)

  $t = [string]$Text
  $m = [System.Text.RegularExpressions.Regex]::Match($t, '\b(401|403|404|409|422|429|500|502|503|504)\b')
  if ($m.Success) {
    try { return [int]$m.Groups[1].Value } catch { return 0 }
  }
  return 0
}

function New-RcgApiException {
  [CmdletBinding()]
  [OutputType([System.Exception])]
  param(
    [Parameter(Mandatory)][string]$Message,
    [Parameter(Mandatory)][string]$Endpoint,
    [Parameter(Mandatory)][int]$ExitCode,
    [Parameter(Mandatory = $false)][int]$HttpStatus = 0,
    [Parameter(Mandatory = $false)][switch]$TimedOut
  )

  $full = "API_ERROR endpoint=$Endpoint exit=$ExitCode http=$HttpStatus timedOut=$([bool]$TimedOut) message=$Message"
  return [System.Exception]::new($full)
}

function Invoke-RcgGhApiJson {
  [CmdletBinding()]
  [OutputType([object])]
  param(
    [Parameter(Mandatory)][string]$GhExePath,
    [Parameter(Mandatory)][string]$Endpoint,
    [Parameter(Mandatory = $false)][hashtable]$Query,
    [Parameter(Mandatory = $false)][ValidateRange(1, 10)][int]$Retries = 3,
    [Parameter(Mandatory = $false)][ValidateRange(5, 600)][int]$TimeoutSec = 60,
    [Parameter(Mandatory = $false)][switch]$DumpGhIo,
    [Parameter(Mandatory = $false)][string]$ReportsDir
  )

  if ([string]::IsNullOrWhiteSpace($GhExePath)) {
    throw (New-RcgApiException -Message 'gh not found' -Endpoint $Endpoint -ExitCode 127 -HttpStatus 0)
  }

  $ep = [string]$Endpoint
  if ($Query -and $Query.Count -gt 0) {
    $pairs = New-Object System.Collections.Generic.List[string]
    foreach ($k in $Query.Keys) {
      $key = [string]$k
      $val = [string]$Query[$k]
      $pairs.Add(("{0}={1}" -f [uri]::EscapeDataString($key), [uri]::EscapeDataString($val))) | Out-Null
    }
    $qs = ($pairs.ToArray() -join '&')
    if ($ep.Contains('?')) { $ep = $ep + '&' + $qs } else { $ep = $ep + '?' + $qs }
  }

  $last = $null
  for ($attempt = 1; $attempt -le ($Retries + 1); $attempt++) {
    try {

      if ($script:RcgVerboseGhApi) { Write-RcgLog -Message ("gh api {0}" -f $ep) }

      $args = @(
        'api',
        '-H', 'Accept: application/vnd.github+json',
        '-H', 'X-GitHub-Api-Version: 2022-11-28',
        $ep
      )

      $res = Invoke-RcgProcess -ExePath $GhExePath -Arguments $args -TimeoutSec $TimeoutSec

      $all = [string]((@([string]$res.Stdout, [string]$res.Stderr) | Where-Object { $_ -and $_.Trim() }) -join [Environment]::NewLine)
      $allTrim = $all.Trim()

      if ($DumpGhIo -and $ReportsDir) {
        try {
          if (-not (Test-Path -LiteralPath $ReportsDir)) {
            [System.IO.Directory]::CreateDirectory($ReportsDir) | Out-Null
          }
          $safe = ($ep -replace '[^a-zA-Z0-9_-]', '_')
          if ($safe.Length -gt 60) { $safe = $safe.Substring(0, 60) }
          $dumpPath = Join-Path $ReportsDir ("gh_io_{0}_attempt{1}.txt" -f $safe, $attempt)
          $dump = @(
            '=== ARGS ===',
            ($args -join ' '),
            '=== STDOUT ===',
            [string]$res.Stdout,
            '=== STDERR ===',
            [string]$res.Stderr
          ) -join [Environment]::NewLine
          Set-Content -LiteralPath $dumpPath -Value (ConvertTo-RcgRedactedText -Text $dump) -Encoding utf8
        } catch { }
      }

      if ($res.TimedOut) {
        throw (New-RcgApiException -Message ("gh api timed out after {0}s" -f $TimeoutSec) -Endpoint $ep -ExitCode -1 -HttpStatus 0 -TimedOut)
      }
      if ($res.ExitCode -ne 0) {
        $status = if ($allTrim) { Get-RcgHttpStatusFromText -Text $allTrim } else { 0 }
        $msg = if ($allTrim) { ConvertTo-RcgRedactedText -Text $allTrim } else { 'gh api failed with no output' }
        throw (New-RcgApiException -Message $msg -Endpoint $ep -ExitCode $res.ExitCode -HttpStatus $status)
      }

      $jsonText = ([string]$res.Stdout).Trim()
      if (-not $jsonText) {
        if (-not $allTrim) { throw (New-RcgApiException -Message 'empty response' -Endpoint $ep -ExitCode 0 -HttpStatus 0) }
        $jsonText = $allTrim
      }

      try {
        $obj = ($jsonText | ConvertFrom-Json -Depth 100)
        if ($null -eq $obj) { throw 'JSON parsed to null' }
        return $obj
      } catch {
        $head = if ($jsonText.Length -gt 600) { $jsonText.Substring(0, 600) + ' ...' } else { $jsonText }
        throw (New-RcgApiException -Message ("non-JSON payload: {0}" -f (ConvertTo-RcgRedactedText -Text $head)) -Endpoint $ep -ExitCode 0 -HttpStatus 0)
      }

    } catch {
      $last = $_
      if ($attempt -lt ($Retries + 1)) {
        $sleepMs = [Math]::Min(2000, 250 * $attempt)
        Write-RcgLog -Level 'WARN' -Message ("gh api attempt {0}/{1} failed for {2}: {3}" -f $attempt, ($Retries + 1), $ep, $_.Exception.Message)
        Start-Sleep -Milliseconds $sleepMs
        continue
      }
      throw
    }
  }
  throw $last
}

function Get-RcgRepoFromGitRemote {
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)][string]$GitExePath,
    [Parameter(Mandatory = $false)][int]$TimeoutSec = 15
  )

  if (-not $GitExePath) { return $null }

  $res = Invoke-RcgProcess -ExePath $GitExePath -Arguments @('remote','get-url','origin') -TimeoutSec $TimeoutSec
  if ($res.TimedOut -or $res.ExitCode -ne 0) { return $null }

  $url = ([string]$res.Stdout).Trim()
  if (-not $url) { return $null }

  $m1 = [System.Text.RegularExpressions.Regex]::Match($url, 'github\.com[:/]([^/]+)/([^/]+?)(?:\.git)?$')
  if ($m1.Success) {
    $owner = [string]$m1.Groups[1].Value
    $repo = [string]$m1.Groups[2].Value
    if ($owner -and $repo) { return ("{0}/{1}" -f $owner, $repo) }
  }
  return $null
}

function Get-RcgDefaultBranch {
  [CmdletBinding()]
  [OutputType([string])]
  param()

  $b = [System.Environment]::GetEnvironmentVariable('GITHUB_BASE_REF')
  if ($b) { return [string]$b }
  $b2 = [System.Environment]::GetEnvironmentVariable('GITHUB_REF_NAME')
  if ($b2) { return [string]$b2 }
  return 'main'
}

function Get-RcgHeadShaFromGit {
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)][string]$GitExePath,
    [Parameter(Mandatory = $false)][int]$TimeoutSec = 15
  )

  if (-not $GitExePath) { return $null }
  $res = Invoke-RcgProcess -ExePath $GitExePath -Arguments @('rev-parse','HEAD') -TimeoutSec $TimeoutSec
  if ($res.TimedOut -or $res.ExitCode -ne 0) { return $null }
  $sha = ([string]$res.Stdout).Trim()
  if ($sha -match '^[0-9a-fA-F]{7,40}$') { return $sha }
  return $null
}

function Get-RcgBranchProtectionRequired {
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param(
    [Parameter(Mandatory)][string]$GhExePath,
    [Parameter(Mandatory)][string]$Repo,
    [Parameter(Mandatory)][string]$Branch,
    [Parameter(Mandatory = $false)][int]$Retries = 3,
    [Parameter(Mandatory = $false)][int]$TimeoutSec = 60,
    [Parameter(Mandatory = $false)][switch]$DumpGhIo,
    [Parameter(Mandatory = $false)][string]$ReportsDir
  )

  $variants = @($Branch)
  if ($Branch -like '*/*') { $variants += [uri]::EscapeDataString($Branch) }

  $endpointsTried = New-Object System.Collections.Generic.List[string]
  $errors = New-Object System.Collections.Generic.List[string]

  foreach ($seg in $variants) {
    $ep = "repos/$Repo/branches/$seg/protection/required_status_checks"
    $endpointsTried.Add($ep) | Out-Null
    try {
      $obj = Invoke-RcgGhApiJson -GhExePath $GhExePath -Endpoint $ep -Retries $Retries -TimeoutSec $TimeoutSec -DumpGhIo:$DumpGhIo -ReportsDir $ReportsDir

      $strict = $false
      $pStrict = $obj.PSObject.Properties['strict']
      if ($pStrict) { try { $strict = [bool]$pStrict.Value } catch { $strict = $false } }

      $set = New-RcgStringSet

      $pCtx = $obj.PSObject.Properties['contexts']
      foreach ($c in @($pCtx.Value)) {
        $s = [string]$c
        if ([string]::IsNullOrWhiteSpace($s)) { continue }
        $null = $set.Add($s)
      }

      $pChecks = $obj.PSObject.Properties['checks']
      foreach ($chk in @($pChecks.Value)) {
        if ($null -eq $chk) { continue }
        $pC = $chk.PSObject.Properties['context']
        if (-not $pC) { continue }
        $s2 = [string]$pC.Value
        if ([string]::IsNullOrWhiteSpace($s2)) { continue }
        $null = $set.Add($s2)
      }

      return [pscustomobject]@{
        endpoint = $ep
        strict = $strict
        required_contexts = @($set)
        raw = $obj
        endpoints_tried = @($endpointsTried)
        errors = @($errors)
      }
    } catch {
      $errors.Add($_.Exception.Message) | Out-Null
    }
  }

  $msg = if ($errors.Count -gt 0) { ($errors.ToArray() -join '; ') } else { 'unknown error' }
  throw (New-RcgApiException -Message $msg -Endpoint ($endpointsTried.ToArray() -join ',') -ExitCode 1 -HttpStatus 0)
}

function Get-RcgPullRequestInfo {
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param(
    [Parameter(Mandatory)][string]$GhExePath,
    [Parameter(Mandatory)][string]$Repo,
    [Parameter(Mandatory)][int]$Number,
    [Parameter(Mandatory = $false)][int]$Retries = 3,
    [Parameter(Mandatory = $false)][int]$TimeoutSec = 60,
    [Parameter(Mandatory = $false)][switch]$DumpGhIo,
    [Parameter(Mandatory = $false)][string]$ReportsDir
  )

  $ep = "repos/$Repo/pulls/$Number"
  $obj = Invoke-RcgGhApiJson -GhExePath $GhExePath -Endpoint $ep -Retries $Retries -TimeoutSec $TimeoutSec -DumpGhIo:$DumpGhIo -ReportsDir $ReportsDir

  $headSha = $null
  $mergeSha = $null
  $baseRef = $null
  $headRef = $null

  $pBase = $obj.PSObject.Properties['base']
  if ($pBase -and $pBase.Value) {
    $pRef = $pBase.Value.PSObject.Properties['ref']
    if ($pRef) { $baseRef = [string]$pRef.Value }
  }
  $pHead = $obj.PSObject.Properties['head']
  if ($pHead -and $pHead.Value) {
    $pSha = $pHead.Value.PSObject.Properties['sha']
    if ($pSha) { $headSha = [string]$pSha.Value }
    $pRef2 = $pHead.Value.PSObject.Properties['ref']
    if ($pRef2) { $headRef = [string]$pRef2.Value }
  }
  $pMerge = $obj.PSObject.Properties['merge_commit_sha']
  if ($pMerge) { $mergeSha = [string]$pMerge.Value }

  return [pscustomobject]@{
    endpoint = $ep
    number = [int]$Number
    base_ref = $baseRef
    head_ref = $headRef
    head_sha = $headSha
    merge_sha = $mergeSha
    raw = $obj
  }
}

function Find-RcgPullRequestNumberFromEvent {
  [CmdletBinding()]
  [OutputType([int])]
  param()

  $path = [System.Environment]::GetEnvironmentVariable('GITHUB_EVENT_PATH')
  if (-not $path) { return 0 }
  if (-not (Test-Path -LiteralPath $path)) { return 0 }

  try {
    $txt = Get-Content -LiteralPath $path -Raw -ErrorAction Stop
    $obj = ($txt | ConvertFrom-Json -Depth 50)
    if ($null -eq $obj) { return 0 }
    $pPr = $obj.PSObject.Properties['pull_request']
    if (-not $pPr -or -not $pPr.Value) { return 0 }
    $pNum = $pPr.Value.PSObject.Properties['number']
    if (-not $pNum) { return 0 }
    return [int]$pNum.Value
  } catch {
    return 0
  }
}

function Find-RcgOpenPullRequestByHeadSha {
  [CmdletBinding()]
  [OutputType([int])]
  param(
    [Parameter(Mandatory)][string]$GhExePath,
    [Parameter(Mandatory)][string]$Repo,
    [Parameter(Mandatory)][string]$BaseBranch,
    [Parameter(Mandatory)][ValidatePattern('^[0-9a-fA-F]{7,40}$')][string]$HeadSha,
    [Parameter(Mandatory = $false)][int]$Retries = 3,
    [Parameter(Mandatory = $false)][int]$TimeoutSec = 60,
    [Parameter(Mandatory = $false)][switch]$DumpGhIo,
    [Parameter(Mandatory = $false)][string]$ReportsDir
  )

  for ($page = 1; $page -le 10; $page++) {
    $ep = "repos/$Repo/pulls"
    $q = @{ state='open'; base=$BaseBranch; per_page='100'; page=[string]$page }
    $obj = Invoke-RcgGhApiJson -GhExePath $GhExePath -Endpoint $ep -Query $q -Retries $Retries -TimeoutSec $TimeoutSec -DumpGhIo:$DumpGhIo -ReportsDir $ReportsDir
    $items = @($obj)
    if ($items.Count -eq 0) { break }

    foreach ($pr in $items) {
      if ($null -eq $pr) { continue }
      $pHead = $pr.PSObject.Properties['head']
      if (-not $pHead -or -not $pHead.Value) { continue }
      $pSha = $pHead.Value.PSObject.Properties['sha']
      if (-not $pSha) { continue }
      $sha = [string]$pSha.Value
      if ($sha -and $sha -eq $HeadSha) {
        $pNum = $pr.PSObject.Properties['number']
        if ($pNum) { return [int]$pNum.Value }
      }
    }

    if ($items.Count -lt 100) { break }
  }

  return 0
}

function Get-RcgBranchHeadSha {
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)][string]$GhExePath,
    [Parameter(Mandatory)][string]$Repo,
    [Parameter(Mandatory)][string]$Branch,
    [Parameter(Mandatory = $false)][int]$Retries = 3,
    [Parameter(Mandatory = $false)][int]$TimeoutSec = 60,
    [Parameter(Mandatory = $false)][switch]$DumpGhIo,
    [Parameter(Mandatory = $false)][string]$ReportsDir
  )

  $ep = "repos/$Repo/commits/$Branch"
  $obj = Invoke-RcgGhApiJson -GhExePath $GhExePath -Endpoint $ep -Retries $Retries -TimeoutSec $TimeoutSec -DumpGhIo:$DumpGhIo -ReportsDir $ReportsDir
  $pSha = $obj.PSObject.Properties['sha']
  if ($pSha) {
    $sha = [string]$pSha.Value
    if ($sha -match '^[0-9a-fA-F]{7,40}$') { return $sha }
  }
  return $null
}

function Get-RcgCommitObservation {
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param(
    [Parameter(Mandatory)][string]$GhExePath,
    [Parameter(Mandatory)][string]$Repo,
    [Parameter(Mandatory)][ValidatePattern('^[0-9a-fA-F]{7,40}$')][string]$Sha,
    [Parameter(Mandatory = $false)][ValidateRange(1,100)][int]$PerPage = 100,
    [Parameter(Mandatory = $false)][int]$Retries = 3,
    [Parameter(Mandatory = $false)][int]$TimeoutSec = 60,
    [Parameter(Mandatory = $false)][switch]$DumpGhIo,
    [Parameter(Mandatory = $false)][string]$ReportsDir
  )

  $endpoints = New-Object System.Collections.Generic.List[string]
  $checkRuns = New-Object System.Collections.Generic.List[object]
  $statusContexts = New-Object System.Collections.Generic.List[object]

  $total = $null
  for ($page = 1; $page -le 20; $page++) {
    $ep = "repos/$Repo/commits/$Sha/check-runs"
    $q = @{ per_page=[string]$PerPage; page=[string]$page }
    $endpoints.Add(($ep + '?per_page=' + $PerPage + '&page=' + $page)) | Out-Null

    $obj = Invoke-RcgGhApiJson -GhExePath $GhExePath -Endpoint $ep -Query $q -Retries $Retries -TimeoutSec $TimeoutSec -DumpGhIo:$DumpGhIo -ReportsDir $ReportsDir
    $cr = $null
    $pCr = $obj.PSObject.Properties['check_runs']
    if ($pCr) { $cr = $pCr.Value }

    if ($null -eq $total) {
      $pT = $obj.PSObject.Properties['total_count']
      if ($pT) { try { $total = [int]$pT.Value } catch { $total = $null } }
    }

    foreach ($r in @($cr)) {
      if ($null -eq $r) { continue }
      $name = $null
      $status = $null
      $conclusion = $null
      $startedAt = $null
      $completedAt = $null
      $detailsUrl = $null
      $appName = $null

      $pName = $r.PSObject.Properties['name']
      if ($pName) { $name = [string]$pName.Value }
      if ([string]::IsNullOrWhiteSpace($name)) { continue }

      $pStatus = $r.PSObject.Properties['status']
      if ($pStatus) { $status = [string]$pStatus.Value }
      $pCon = $r.PSObject.Properties['conclusion']
      if ($pCon) { $conclusion = [string]$pCon.Value }

      $pSa = $r.PSObject.Properties['started_at']
      if ($pSa) { $startedAt = [string]$pSa.Value }
      $pCa = $r.PSObject.Properties['completed_at']
      if ($pCa) { $completedAt = [string]$pCa.Value }

      $pDu = $r.PSObject.Properties['details_url']
      if ($pDu) { $detailsUrl = [string]$pDu.Value }

      $pApp = $r.PSObject.Properties['app']
      if ($pApp -and $pApp.Value) {
        $pAn = $pApp.Value.PSObject.Properties['name']
        if ($pAn) { $appName = [string]$pAn.Value }
      }

      $checkRuns.Add([pscustomobject]@{
        name = $name
        status = $status
        conclusion = $conclusion
        started_at = $startedAt
        completed_at = $completedAt
        details_url = $detailsUrl
        app = $appName
      }) | Out-Null
    }

    $countThis = @($cr).Count
    if ($countThis -lt $PerPage) { break }
    if ($null -ne $total) {
      $maxPage = [int][Math]::Ceiling($total / [double]$PerPage)
      if ($page -ge $maxPage) { break }
    }
  }

  $ep2 = "repos/$Repo/commits/$Sha/status"
  $endpoints.Add($ep2) | Out-Null
  $obj2 = Invoke-RcgGhApiJson -GhExePath $GhExePath -Endpoint $ep2 -Retries $Retries -TimeoutSec $TimeoutSec -DumpGhIo:$DumpGhIo -ReportsDir $ReportsDir
  $sts = $null
  $pSts = $obj2.PSObject.Properties['statuses']
  if ($pSts) { $sts = $pSts.Value }

  foreach ($s in @($sts)) {
    if ($null -eq $s) { continue }
    $ctx = $null
    $state = $null
    $updatedAt = $null
    $targetUrl = $null
    $desc = $null

    $pCtx = $s.PSObject.Properties['context']
    if ($pCtx) { $ctx = [string]$pCtx.Value }
    if ([string]::IsNullOrWhiteSpace($ctx)) { continue }

    $pState = $s.PSObject.Properties['state']
    if ($pState) { $state = [string]$pState.Value }

    $pUp = $s.PSObject.Properties['updated_at']
    if ($pUp) { $updatedAt = [string]$pUp.Value }

    $pTu = $s.PSObject.Properties['target_url']
    if ($pTu) { $targetUrl = [string]$pTu.Value }

    $pDe = $s.PSObject.Properties['description']
    if ($pDe) { $desc = [string]$pDe.Value }

    $statusContexts.Add([pscustomobject]@{
      context = $ctx
      state = $state
      updated_at = $updatedAt
      target_url = $targetUrl
      description = $desc
    }) | Out-Null
  }

  return [pscustomobject]@{
    sha = $Sha
    check_runs = @($checkRuns.ToArray())
    status_contexts = @($statusContexts.ToArray())
    endpoints = @($endpoints.ToArray())
  }
}

function Select-RcgBestCheckRun {
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param(
    [Parameter(Mandatory)][pscustomobject[]]$Runs
  )
  if ($null -eq $Runs -or $Runs.Count -eq 0) { return $null }

  $best = $null
  $bestKey = $null
  foreach ($r in @($Runs)) {
    if ($null -eq $r) { continue }
    $t = $null
    if ($r.completed_at) { $t = [string]$r.completed_at } elseif ($r.started_at) { $t = [string]$r.started_at }
    $key = $t
    if (-not $key) { $key = '' }
    if ($null -eq $best) { $best = $r; $bestKey = $key; continue }
    if ($key -gt $bestKey) { $best = $r; $bestKey = $key }
  }
  return $best
}

function Select-RcgBestStatusContext {
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param(
    [Parameter(Mandatory)][pscustomobject[]]$Statuses
  )
  if ($null -eq $Statuses -or $Statuses.Count -eq 0) { return $null }

  $best = $null
  $bestKey = ''
  foreach ($s in @($Statuses)) {
    if ($null -eq $s) { continue }
    $key = if ($s.updated_at) { [string]$s.updated_at } else { '' }
    if ($null -eq $best) { $best = $s; $bestKey = $key; continue }
    if ($key -gt $bestKey) { $best = $s; $bestKey = $key }
  }
  return $best
}

function Test-RcgCheckRunPass {
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param(
    [Parameter(Mandatory)][pscustomobject]$Run,
    [Parameter(Mandatory)][string[]]$AcceptedConclusions
  )

  $status = if ($Run.status) { [string]$Run.status } else { '' }
  $conclusion = if ($Run.conclusion) { [string]$Run.conclusion } else { '' }

  if (-not $status) { return [pscustomobject]@{ result='unknown'; reason='missing_status' } }

  if ($status -ne 'completed') {
    return [pscustomobject]@{ result='pending'; reason=('status_' + $status) }
  }

  if (-not $conclusion) {
    return [pscustomobject]@{ result='pending'; reason='conclusion_null' }
  }

  foreach ($a in @($AcceptedConclusions)) {
    if ($conclusion -eq $a) { return [pscustomobject]@{ result='pass'; reason=('conclusion_' + $conclusion) } }
  }

  if ($conclusion -eq 'skipped') {
    return [pscustomobject]@{ result='pending'; reason='conclusion_skipped' }
  }

  return [pscustomobject]@{ result='fail'; reason=('conclusion_' + $conclusion) }
}

function Test-RcgStatusContextPass {
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param([Parameter(Mandatory)][pscustomobject]$Status)

  $state = if ($Status.state) { [string]$Status.state } else { '' }
  if (-not $state) { return [pscustomobject]@{ result='unknown'; reason='missing_state' } }

  if ($state -eq 'success') { return [pscustomobject]@{ result='pass'; reason='state_success' } }
  if ($state -eq 'pending') { return [pscustomobject]@{ result='pending'; reason='state_pending' } }

  return [pscustomobject]@{ result='fail'; reason=('state_' + $state) }
}

function Get-RcgRequiredVerdict {
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param(
    [Parameter(Mandatory)][string[]]$RequiredContexts,
    [Parameter(Mandatory)][pscustomobject]$Observation,
    [Parameter(Mandatory)][string[]]$AcceptedConclusions
  )

  $evals = New-Object System.Collections.Generic.List[object]

  $byName = @{}
  foreach ($r in @($Observation.check_runs)) {
    if ($null -eq $r) { continue }
    $n = [string]$r.name
    if ([string]::IsNullOrWhiteSpace($n)) { continue }
    if (-not $byName.ContainsKey($n)) { $byName[$n] = New-Object System.Collections.Generic.List[object] }
    $byName[$n].Add($r) | Out-Null
  }

  $byCtx = @{}
  foreach ($s in @($Observation.status_contexts)) {
    if ($null -eq $s) { continue }
    $c = [string]$s.context
    if ([string]::IsNullOrWhiteSpace($c)) { continue }
    if (-not $byCtx.ContainsKey($c)) { $byCtx[$c] = New-Object System.Collections.Generic.List[object] }
    $byCtx[$c].Add($s) | Out-Null
  }

  $missing = New-Object System.Collections.Generic.List[string]
  $failing = New-Object System.Collections.Generic.List[string]
  $pending = New-Object System.Collections.Generic.List[string]
  $unknown = New-Object System.Collections.Generic.List[string]

  foreach ($req in @($RequiredContexts)) {
    $ctx = [string]$req
    if ([string]::IsNullOrWhiteSpace($ctx)) { continue }

    $evidence = $null
    $kind = 'missing'
    $result = 'missing'
    $reason = 'not_observed'

    if ($byName.ContainsKey($ctx)) {
      $kind = 'check_run'
      $best = Select-RcgBestCheckRun -Runs @($byName[$ctx].ToArray())
      $ver = Test-RcgCheckRunPass -Run $best -AcceptedConclusions $AcceptedConclusions
      $result = [string]$ver.result
      $reason = [string]$ver.reason
      $evidence = $best
    } elseif ($byCtx.ContainsKey($ctx)) {
      $kind = 'status_context'
      $best2 = Select-RcgBestStatusContext -Statuses @($byCtx[$ctx].ToArray())
      $ver2 = Test-RcgStatusContextPass -Status $best2
      $result = [string]$ver2.result
      $reason = [string]$ver2.reason
      $evidence = $best2
    }

    switch ($result) {
      'missing' { $missing.Add($ctx) | Out-Null }
      'fail'    { $failing.Add($ctx) | Out-Null }
      'pending' { $pending.Add($ctx) | Out-Null }
      default   { if ($result -ne 'pass') { $unknown.Add($ctx) | Out-Null } }
    }

    $evals.Add([pscustomobject]@{
      required_context = $ctx
      observed_kind = $kind
      result = $result
      reason = $reason
      evidence = $evidence
    }) | Out-Null
  }

  return [pscustomobject]@{
    sha = $Observation.sha
    evaluations = @($evals.ToArray())
    missing = @($missing.ToArray())
    failing = @($failing.ToArray())
    pending = @($pending.ToArray())
    unknown = @($unknown.ToArray())
  }
}

function ConvertTo-RcgNormalizedName {
  [CmdletBinding()]
  [OutputType([string])]
  param([Parameter(Mandatory)][AllowNull()][string]$Name)

  if ($null -eq $Name) { return '' }
  $s = [string]$Name
  $s = $s.Trim()
  $s = [System.Text.RegularExpressions.Regex]::Replace($s, '\s+', ' ')
  return $s
}

function Get-RcgWorkflowDiagnostics {
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param(
    [Parameter(Mandatory)][string]$WorkflowsDir,
    [Parameter(Mandatory)][string[]]$ContextsToAnalyze,
    [Parameter(Mandatory = $false)][switch]$Recurse
  )

  $warnings = New-Object System.Collections.Generic.List[string]
  $hits = New-Object System.Collections.Generic.List[object]

  if (-not (Test-Path -LiteralPath $WorkflowsDir)) {
    $warnings.Add(('workflows_dir_not_found: ' + $WorkflowsDir)) | Out-Null
    return [pscustomobject]@{ workflows_scanned=0; matches=@(); warnings=@($warnings.ToArray()) }
  }

  $gci = @{
    LiteralPath = $WorkflowsDir
    File = $true
    ErrorAction = 'SilentlyContinue'
  }
  if ($Recurse) { $gci.Recurse = $true }

  $files = @()
  $files += Get-ChildItem @gci -Filter '*.yml'
  $files += Get-ChildItem @gci -Filter '*.yaml'
  $files = @($files | Sort-Object FullName -Unique)

  $ctxSet = New-RcgStringSet
  foreach ($c in @($ContextsToAnalyze)) {
    $cs = ConvertTo-RcgNormalizedName -Name ([string]$c)
    if ($cs) { $null = $ctxSet.Add($cs) }
  }

  foreach ($f in @($files)) {
    $text = ''
    try { $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Stop } catch { $warnings.Add(('workflow_read_failed: ' + $f.FullName)) | Out-Null; continue }

    $wfName = $null
    $mName = [System.Text.RegularExpressions.Regex]::Match($text, '(?m)^\s*name\s*:\s*(.+?)\s*$')
    if ($mName.Success) { $wfName = (ConvertTo-RcgNormalizedName -Name $mName.Groups[1].Value) }

    $jobIds = New-Object System.Collections.Generic.List[string]
    $jobNames = New-Object System.Collections.Generic.List[string]

    $hasJobs = ($text -match '(?m)^\s*jobs\s*:\s*$')
    if ($hasJobs) {
      $rx = [System.Text.RegularExpressions.Regex]::new('(?m)^\s{2}([A-Za-z0-9_-]+)\s*:\s*$')
      $ms = $rx.Matches($text)
      foreach ($m in $ms) {
        if (-not $m.Success) { continue }
        $jid = ConvertTo-RcgNormalizedName -Name $m.Groups[1].Value
        if ($jid) { $jobIds.Add($jid) | Out-Null }
      }

      $rx2 = [System.Text.RegularExpressions.Regex]::new('(?m)^\s{4}name\s*:\s*(.+?)\s*$')
      $ms2 = $rx2.Matches($text)
      foreach ($m in $ms2) {
        if (-not $m.Success) { continue }
        $jn = ConvertTo-RcgNormalizedName -Name $m.Groups[1].Value
        if ($jn) { $jobNames.Add($jn) | Out-Null }
      }
    }

    $cands = New-Object System.Collections.Generic.List[string]
    if ($wfName) { $cands.Add($wfName) | Out-Null }
    foreach ($x in @($jobIds.ToArray())) { if ($x) { $cands.Add($x) | Out-Null } }
    foreach ($x in @($jobNames.ToArray())) { if ($x) { $cands.Add($x) | Out-Null } }

    $candArr = @($cands.ToArray() | Sort-Object -Unique)

    foreach ($ctx in @($ctxSet)) {
      foreach ($cand in @($candArr)) {
        if ($ctx -eq $cand) {
          $hits.Add([pscustomobject]@{
            required_context = $ctx
            workflow_path = $f.FullName
            matched_candidate = $cand
            workflow_name = $wfName
          }) | Out-Null
        } elseif ($ctx.StartsWith(($cand + ' ('), [System.StringComparison]::OrdinalIgnoreCase)) {
          $hits.Add([pscustomobject]@{
            required_context = $ctx
            workflow_path = $f.FullName
            matched_candidate = $cand
            workflow_name = $wfName
            note = 'matrix_like_suffix'
          }) | Out-Null
        }
      }
    }
  }

  return [pscustomobject]@{
    workflows_scanned = $files.Count
    matches = @($hits.ToArray())
    warnings = @($warnings.ToArray())
  }
}

$stage = 'init'
try {
  $scriptVersion = '10.1.11.0'
  $now = (Get-Date)

  $ghPath = Resolve-RcgCommandPath -NameOrPath $GhExe
  $gitPath = Resolve-RcgCommandPath -NameOrPath $GitExe

  if (-not $Repo) { $Repo = [System.Environment]::GetEnvironmentVariable('GITHUB_REPOSITORY') }
  if (-not $Repo -and $gitPath) { $Repo = Get-RcgRepoFromGitRemote -GitExePath $gitPath }
  if (-not $Repo) { throw 'Repo not specified and could not be derived. Provide -Repo OWNER/REPO.' }

  if (-not $Branch) { $Branch = Get-RcgDefaultBranch }

  if (-not (Test-Path -LiteralPath $ReportsDir)) {
    [System.IO.Directory]::CreateDirectory($ReportsDir) | Out-Null
  }

  $reportJsonPath = Join-Path $ReportsDir 'required_checks_guard_report.json'
  $reportMdPath = Join-Path $ReportsDir 'required_checks_guard_report.md'

  Write-RcgLog -Message ("required-checks-guard version={0}" -f $scriptVersion)
  Write-RcgLog -Message ("Repo={0} Branch={1} PR={2} TargetSha={3}" -f $Repo, $Branch, $PullRequestNumber, $TargetSha)

  $runMeta = [pscustomobject]@{
    timestamp_utc = $now.ToUniversalTime().ToString('o')
    timestamp_local = $now.ToString('o')
    host_os = [System.Environment]::OSVersion.VersionString
    pwsh_version = $PSVersionTable.PSVersion.ToString()
    cwd = (Get-Location).Path
    gh_path = $ghPath
    git_path = $gitPath
    gh_timeout_sec = [int]$GhTimeoutSec
    gh_retries = [int]$GhApiRetries
    poll_attempts = [int]$ObservationPollAttempts
    poll_interval_sec = [int]$ObservationPollIntervalSec
    accepted_check_conclusions = @($AcceptedCheckConclusions)
    flags = [pscustomobject]@{
      prefer_merge_commit = [bool]$PreferMergeCommit
      skip_online_observation = [bool]$SkipOnlineObservation
      also_run_yaml_analysis = [bool]$AlsoRunYamlAnalysis
      fail_on_api_error = [bool]$FailOnApiError
      fail_on_unknown = [bool]$FailOnUnknown
      fail_on_missing_protection = [bool]$FailOnMissingProtection
      dump_gh_io = [bool]$DumpGhIo
      recurse_workflows = [bool]$RecurseWorkflows
      verbose_gh_api = [bool]$VerboseGhApi
    }
  }

  $warnings = New-Object System.Collections.Generic.List[string]
  $apiFailures = New-Object System.Collections.Generic.List[object]

  $stage = 'branch_protection'
  $required = $null
  try {
    $required = Get-RcgBranchProtectionRequired -GhExePath $ghPath -Repo $Repo -Branch $Branch -Retries $GhApiRetries -TimeoutSec $GhTimeoutSec -DumpGhIo:$DumpGhIo -ReportsDir $ReportsDir
  } catch {
    $apiFailures.Add([pscustomobject]@{ stage='branch_protection'; message=$_.Exception.Message }) | Out-Null
    $warnings.Add(('branch_protection_fetch_failed: ' + $_.Exception.Message)) | Out-Null

    $status = Get-RcgHttpStatusFromText -Text $_.Exception.Message
    $is404 = ($status -eq 404) -or ($_.Exception.Message -match '\b404\b')

    $outFail = [ordered]@{
      version = $scriptVersion
      run_metadata = $runMeta
      repo = $Repo
      branch = $Branch
      verdict = 'unknown'
      verdict_reason = 'branch_protection_fetch_failed'
      api_failures = @($apiFailures.ToArray())
      warnings = @($warnings.ToArray())
      generated_at = (Get-Date).ToString('o')
    }
    ($outFail | ConvertTo-Json -Depth 40) | Set-Content -LiteralPath $reportJsonPath -Encoding utf8

    if ($is404 -and -not $FailOnMissingProtection -and -not $FailOnApiError) { exit 0 }
    if ($is404 -and $FailOnMissingProtection) { exit 1 }
    if ($FailOnApiError) { exit 1 }
    exit 0
  }

  $requiredContexts = @($required.required_contexts | ForEach-Object { [string]$_ } | Where-Object { $_ } | Sort-Object -Unique)
  Write-RcgLog -Message ("Required contexts: {0}" -f $requiredContexts.Count)
  if ($requiredContexts.Count -eq 0) { $warnings.Add('no_required_contexts_returned') | Out-Null }

  $targetInfo = [pscustomobject]@{
    repo = $Repo
    branch = $Branch
    strict = [bool]$required.strict
    pull_request = $null
    target_sha = $null
    evaluation_sha = $null
    evaluation_mode = 'unknown'
  }

  $observations = New-Object System.Collections.Generic.List[object]
  $primaryVerdict = $null

  $stage = 'resolve_target'
  $prNum = 0
  if ($PullRequestNumber -gt 0) { $prNum = [int]$PullRequestNumber }
  if ($prNum -le 0) { $prNum = Find-RcgPullRequestNumberFromEvent }
  if ($prNum -le 0 -and -not $TargetSha) {
    $candidate = [System.Environment]::GetEnvironmentVariable('GITHUB_SHA')
    if (-not $candidate -and $gitPath) { $candidate = Get-RcgHeadShaFromGit -GitExePath $gitPath }
    if ($candidate -and ($candidate -match '^[0-9a-fA-F]{7,40}$')) {
      try {
        $prNum = Find-RcgOpenPullRequestByHeadSha -GhExePath $ghPath -Repo $Repo -BaseBranch $Branch -HeadSha $candidate -Retries $GhApiRetries -TimeoutSec $GhTimeoutSec -DumpGhIo:$DumpGhIo -ReportsDir $ReportsDir
      } catch { }
    }
  }

  $shaToEvaluate = $null
  $shaSecondary = $null

  if ($TargetSha) {
    $shaToEvaluate = [string]$TargetSha
    $targetInfo.target_sha = $shaToEvaluate
    $targetInfo.evaluation_sha = $shaToEvaluate
    $targetInfo.evaluation_mode = 'explicit_sha'
  } elseif (-not $SkipOnlineObservation -and $prNum -gt 0) {
    $stage = 'fetch_pr'
    $pr = Get-RcgPullRequestInfo -GhExePath $ghPath -Repo $Repo -Number $prNum -Retries $GhApiRetries -TimeoutSec $GhTimeoutSec -DumpGhIo:$DumpGhIo -ReportsDir $ReportsDir
    $targetInfo.pull_request = [pscustomobject]@{
      number = $pr.number
      base_ref = $pr.base_ref
      head_ref = $pr.head_ref
      head_sha = $pr.head_sha
      merge_sha = $pr.merge_sha
      endpoint = $pr.endpoint
    }

    $headSha = [string]$pr.head_sha
    $mergeSha = [string]$pr.merge_sha

    if ($PreferMergeCommit -and $required.strict -and $mergeSha -and ($mergeSha -match '^[0-9a-fA-F]{7,40}$')) {
      $shaToEvaluate = $mergeSha
      $shaSecondary = $headSha
      $targetInfo.evaluation_mode = 'pr_merge_sha_strict'
    } else {
      $shaToEvaluate = $headSha
      $shaSecondary = $mergeSha
      $targetInfo.evaluation_mode = 'pr_head_sha'
    }

    $targetInfo.target_sha = $headSha
    $targetInfo.evaluation_sha = $shaToEvaluate
    Write-RcgLog -Message ("PR #{0} base={1} head={2} eval_sha={3}" -f $pr.number, $pr.base_ref, $pr.head_ref, $shaToEvaluate)
  } else {
    $stage = 'branch_head_fallback'
    try {
      $shaToEvaluate = Get-RcgBranchHeadSha -GhExePath $ghPath -Repo $Repo -Branch $Branch -Retries $GhApiRetries -TimeoutSec $GhTimeoutSec -DumpGhIo:$DumpGhIo -ReportsDir $ReportsDir
      $targetInfo.target_sha = $shaToEvaluate
      $targetInfo.evaluation_sha = $shaToEvaluate
      $targetInfo.evaluation_mode = 'branch_head_fallback'
      $warnings.Add('using_branch_head_fallback: PR context not resolved') | Out-Null
      Write-RcgLog -Level 'WARN' -Message ("Using branch head fallback sha={0}" -f $shaToEvaluate)
    } catch {
      $warnings.Add(('could_not_resolve_target_sha: ' + $_.Exception.Message)) | Out-Null
      $shaToEvaluate = $null
    }
  }

  if (-not $shaToEvaluate) {
    $warnings.Add('online_observation_unavailable: no target sha') | Out-Null
  }

  $stage = 'observe'
  $verdict = 'unknown'
  $verdictReason = 'unavailable'

  if ($shaToEvaluate -and -not $SkipOnlineObservation) {
    for ($poll = 1; $poll -le $ObservationPollAttempts; $poll++) {
      $stage = 'observe_poll'
      $obs = $null
      try {
        $obs = Get-RcgCommitObservation -GhExePath $ghPath -Repo $Repo -Sha $shaToEvaluate -PerPage $CheckRunsPerPage -Retries $GhApiRetries -TimeoutSec $GhTimeoutSec -DumpGhIo:$DumpGhIo -ReportsDir $ReportsDir
      } catch {
        $apiFailures.Add([pscustomobject]@{ stage='observe'; sha=$shaToEvaluate; message=$_.Exception.Message }) | Out-Null
        $warnings.Add(('commit_observation_failed: ' + $_.Exception.Message)) | Out-Null
        if ($FailOnApiError) { throw }
        break
      }

      $observations.Add($obs) | Out-Null
      $primaryVerdict = Get-RcgRequiredVerdict -RequiredContexts $requiredContexts -Observation $obs -AcceptedConclusions $AcceptedCheckConclusions

      $missingCnt = @($primaryVerdict.missing).Count
      $failCnt = @($primaryVerdict.failing).Count
      $pendCnt = @($primaryVerdict.pending).Count
      $unkCnt = @($primaryVerdict.unknown).Count

      if ($missingCnt -eq 0 -and $failCnt -eq 0 -and $pendCnt -eq 0 -and $unkCnt -eq 0) {
        $verdict = 'pass'
        $verdictReason = 'all_required_satisfied'
        break
      }

      if ($pendCnt -gt 0 -and $poll -lt $ObservationPollAttempts -and $ObservationPollIntervalSec -gt 0) {
        Write-RcgLog -Level 'WARN' -Message ("Pending required checks detected (count={0}) poll {1}/{2}; sleeping {3}s..." -f $pendCnt, $poll, $ObservationPollAttempts, $ObservationPollIntervalSec)
        Start-Sleep -Seconds $ObservationPollIntervalSec
        continue
      }

      if ($missingCnt -gt 0) { $verdict = 'fail'; $verdictReason = 'missing_required' }
      elseif ($failCnt -gt 0) { $verdict = 'fail'; $verdictReason = 'failing_required' }
      elseif ($pendCnt -gt 0) { $verdict = 'fail'; $verdictReason = 'pending_required' }
      elseif ($unkCnt -gt 0) { $verdict = 'unknown'; $verdictReason = 'unknown_required' }
      else { $verdict = 'unknown'; $verdictReason = 'inconclusive' }

      break
    }
  } else {
    $warnings.Add('online_observation_skipped_or_unavailable') | Out-Null
  }

  if ($shaSecondary -and ($shaSecondary -match '^[0-9a-fA-F]{7,40}$') -and $shaSecondary -ne $shaToEvaluate -and -not $SkipOnlineObservation) {
    try {
      $obs2 = Get-RcgCommitObservation -GhExePath $ghPath -Repo $Repo -Sha $shaSecondary -PerPage $CheckRunsPerPage -Retries $GhApiRetries -TimeoutSec $GhTimeoutSec -DumpGhIo:$DumpGhIo -ReportsDir $ReportsDir
      $observations.Add($obs2) | Out-Null
    } catch {
      $warnings.Add(('secondary_observation_failed: ' + $_.Exception.Message)) | Out-Null
    }
  }

  $yamlDiag = $null
  $contextsForYaml = @()
  if ($AlsoRunYamlAnalysis) {
    $contextsForYaml = @($requiredContexts)
  } elseif ($verdict -ne 'pass') {
    if ($primaryVerdict -and @($primaryVerdict.missing).Count -gt 0) {
      $contextsForYaml = @($primaryVerdict.missing)
    } else {
      $contextsForYaml = @($requiredContexts)
    }
  }

  if ($contextsForYaml.Count -gt 0) {
    $stage = 'yaml_diagnostics'
    $yamlDiag = Get-RcgWorkflowDiagnostics -WorkflowsDir $WorkflowsDir -ContextsToAnalyze $contextsForYaml -Recurse:$RecurseWorkflows
  } else {
    $warnings.Add('yaml_diagnostics_skipped: online PASS and -AlsoRunYamlAnalysis not set') | Out-Null
  }

  $stage = 'write_reports'

  $requiredRawNames = @($requiredContexts)
  $observedRawNames = @()
  if ($primaryVerdict) {
    $nameSet = New-RcgStringSet
    foreach ($r in @($observations)) {
      foreach ($x in @($r.check_runs)) { if ($x -and $x.name) { $null = $nameSet.Add([string]$x.name) } }
      foreach ($x in @($r.status_contexts)) { if ($x -and $x.context) { $null = $nameSet.Add([string]$x.context) } }
    }
    $observedRawNames = @($nameSet)
  }

  $requiredNorm = @($requiredRawNames | ForEach-Object { ConvertTo-RcgNormalizedName -Name $_ })
  $observedNorm = @($observedRawNames | ForEach-Object { ConvertTo-RcgNormalizedName -Name $_ })

  $out = [ordered]@{
    version = $scriptVersion
    run_metadata = $runMeta
    target_identity = $targetInfo
    required_side = [pscustomobject]@{
      endpoint = $required.endpoint
      strict = [bool]$required.strict
      required_contexts_raw = @($requiredRawNames)
      required_contexts_normalized = @($requiredNorm)
      endpoints_tried = @($required.endpoints_tried)
    }
    observed_side = [pscustomobject]@{
      observations = @($observations.ToArray())
      observed_names_raw = @($observedRawNames)
      observed_names_normalized = @($observedNorm)
    }
    diff = [pscustomobject]@{
      verdict_on_sha = if ($primaryVerdict) { $primaryVerdict.sha } else { $null }
      evaluations = if ($primaryVerdict) { @($primaryVerdict.evaluations) } else { @() }
      missing_required = if ($primaryVerdict) { @($primaryVerdict.missing) } else { @() }
      failing_required = if ($primaryVerdict) { @($primaryVerdict.failing) } else { @() }
      pending_required = if ($primaryVerdict) { @($primaryVerdict.pending) } else { @() }
      unknown_required = if ($primaryVerdict) { @($primaryVerdict.unknown) } else { @() }
    }
    yaml_diagnostics = $yamlDiag
    verdict = $verdict
    verdict_reason = $verdictReason
    api_failures = @($apiFailures.ToArray())
    warnings = @($warnings.ToArray())
    generated_at = (Get-Date).ToString('o')
  }

  ($out | ConvertTo-Json -Depth 60) | Set-Content -LiteralPath $reportJsonPath -Encoding utf8

  $md = New-Object System.Collections.Generic.List[string]
  $null = $md.Add('# Required Checks Guard Report')
  $null = $md.Add('')
  $null = $md.Add(('* Version: `{0}`' -f $scriptVersion))
  $null = $md.Add(('* Repo: `{0}`' -f $Repo))
  $null = $md.Add(('* Branch: `{0}`' -f $Branch))
  $null = $md.Add(('* Strict: `{0}`' -f ([bool]$required.strict)))
  $null = $md.Add(('* Verdict: **{0}** (`{1}`)' -f $verdict, $verdictReason))
  if ($primaryVerdict -and $primaryVerdict.sha) { $null = $md.Add(('* Evaluated SHA: `{0}`' -f $primaryVerdict.sha)) }
  $null = $md.Add('')

  $null = $md.Add('## Required checks')
  foreach ($c in @($requiredContexts)) { $null = $md.Add(('- `{0}`' -f $c)) }
  $null = $md.Add('')

  $null = $md.Add('## Result details')
  if ($primaryVerdict) {
    foreach ($e in @($primaryVerdict.evaluations)) {
      $ctx = [string]$e.required_context
      $res = [string]$e.result
      $kind = [string]$e.observed_kind
      $reason = [string]$e.reason
      $url = $null
      if ($e.evidence) {
        if ($kind -eq 'check_run' -and $e.evidence.details_url) { $url = [string]$e.evidence.details_url }
        if ($kind -eq 'status_context' -and $e.evidence.target_url) { $url = [string]$e.evidence.target_url }
      }
      if ($url) {
        $null = $md.Add(('- `{0}` => **{1}** ({2}/{3}) {4}' -f $ctx, $res, $kind, $reason, $url))
      } else {
        $null = $md.Add(('- `{0}` => **{1}** ({2}/{3})' -f $ctx, $res, $kind, $reason))
      }
    }
  } else {
    $null = $md.Add('- (no observation available)')
  }
  $null = $md.Add('')

  if ($yamlDiag) {
    $null = $md.Add('## YAML diagnostics (heuristic)')
    $null = $md.Add(('* Workflows scanned: `{0}`' -f $yamlDiag.workflows_scanned))
    if (@($yamlDiag.matches).Count -gt 0) {
      foreach ($m in @($yamlDiag.matches)) {
        $null = $md.Add(('- `{0}` matched `{1}` in `{2}`' -f $m.required_context, $m.matched_candidate, $m.workflow_path))
      }
    } else {
      $null = $md.Add('- No matches found.')
    }
    $null = $md.Add('')
  }

  if (@($warnings.ToArray()).Count -gt 0) {
    $null = $md.Add('## Warnings')
    foreach ($w in @($warnings.ToArray())) { $null = $md.Add(('- {0}' -f $w)) }
    $null = $md.Add('')
  }

  ($md -join "`n") | Set-Content -LiteralPath $reportMdPath -Encoding utf8

  if ($verdict -eq 'fail') {
    Write-RcgLog -Level 'ERROR' -Message 'FAIL: required checks not satisfied.'
    exit 1
  }
  if ($verdict -eq 'unknown' -and $FailOnUnknown) {
    Write-RcgLog -Level 'ERROR' -Message 'UNKNOWN: inconclusive and -FailOnUnknown set.'
    exit 1
  }
  if (@($apiFailures.ToArray()).Count -gt 0 -and $FailOnApiError) {
    Write-RcgLog -Level 'ERROR' -Message 'API errors and -FailOnApiError set.'
    exit 1
  }

  Write-RcgLog -Message 'OK.'
  exit 0

} catch {
  $ex = $_.Exception
  $stageLocal = if ($stage) { $stage } else { '(unknown)' }
  [System.Console]::Error.WriteLine(("ERROR: Stage={0} Message={1}" -f $stageLocal, $ex.Message))
  [System.Console]::Error.WriteLine(("ERROR_TYPE: {0}" -f $ex.GetType().FullName))
  if ($null -ne $_.InvocationInfo -and $null -ne $_.InvocationInfo.PositionMessage) {
    [System.Console]::Error.WriteLine($_.InvocationInfo.PositionMessage)
  }
  if ($null -ne $_.ScriptStackTrace) {
    [System.Console]::Error.WriteLine(("STACK: {0}" -f $_.ScriptStackTrace))
  }
  exit 10
}
