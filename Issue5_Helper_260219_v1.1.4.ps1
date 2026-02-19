#requires -Version 7.0
<#
.SYNOPSIS
  Issue5 Helper (CollectEvidence only) - required evidence focus.

.DESCRIPTION
  Focus: "合否基準で必須" の 3 ファイルを必ず証跡として生成し、ZIP化して _artifacts に保存する。

  Required evidence (ZIP root):
    - required_status_checks.json
    - gh_pr_view.json
    - gh_run_list.json

  Notes:
    - Uses GitHub CLI (gh) and git.
    - Even on failures, the required evidence files are created as JSON error objects.
    - Optional QualityGate runs Official Parser + PSScriptAnalyzer for this script (and optional guard script if present).

.VERSION
  1.1.4
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$RepoRoot,

  [Parameter()]
  [ValidateRange(0, 2147483647)]
  [int]$PrNumber = 0,

  [Parameter()]
  [string]$BaseBranch = '',

  [Parameter()]
  [ValidateNotNullOrEmpty()]
  [string]$ArtifactsDir = '_artifacts',

  [Parameter()]
  [ValidateRange(1, 3600)]
  [int]$TimeoutSeconds = 300,

  [Parameter()]
  [switch]$NoZip,

  [Parameter()]
  [switch]$QualityGate,

  [Parameter()]
  [switch]$Diag
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$InformationPreference = 'Continue'

function Get-NowStamp {
  (Get-Date).ToString('yyyyMMdd_HHmmss')
}

function New-EvidenceErrorObject {
  param(
    [Parameter(Mandatory = $true)][string]$Step,
    [Parameter(Mandatory = $true)][string]$Message,
    [string]$Exe,
    [string[]]$Args,
    [int]$ExitCode,
    [switch]$TimedOut
  )

  [pscustomobject]@{
    error = $Message
    step = $Step
    exe = $Exe
    args = $Args
    exitCode = $ExitCode
    timedOut = [bool]$TimedOut
    generatedAt = (Get-Date).ToString('o')
  }
}

function New-DirectoryIfMissing {
  param([Parameter(Mandatory = $true)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

function Write-TextFileUtf8 {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Value
  )
  New-DirectoryIfMissing -Path (Split-Path -Parent $Path)

  $enc = [System.Text.UTF8Encoding]::new($false)
  [System.IO.File]::WriteAllText($Path, $Value, $enc)
}

function Write-JsonFileUtf8 {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][object]$Object
  )
  $json = ConvertTo-Json -InputObject $Object -Depth 30
  if ([string]::IsNullOrEmpty($json)) { $json = 'null' }
  Write-TextFileUtf8 -Path $Path -Value $json
}

function Write-Stage {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$OutDir,
    [Parameter(Mandatory = $true)][string]$Message,
    [Parameter()][switch]$Diag
  )

  $line = ('{0} {1}' -f (Get-Date).ToString('o'), $Message)
  $log = Join-Path $OutDir 'run.log'
  try {
    Add-Content -LiteralPath $log -Value $line -Encoding utf8
  } catch {
    # ignore
  }
  if ($Diag) {
    try { [Console]::Error.WriteLine($line) } catch {}
  }
}


function Resolve-ExePath {
  [CmdletBinding()]
  param([Parameter(Mandatory = $true)][string]$Name)

  $cmd = Get-Command -Name $Name -ErrorAction SilentlyContinue
  if ($cmd -and $cmd.Source) { return [string]$cmd.Source }

  throw ("Executable not found on PATH: {0}" -f $Name)
}

function Invoke-External {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$Exe,
    [Parameter()][string[]]$Arguments = @(),
    [Parameter()][string]$WorkingDirectory,
    [Parameter()][int]$TimeoutSec = 300,
    [Parameter()][hashtable]$Environment = @{}
  )

  function Get-TaskResultOrEmpty {
    param(
      [Parameter(Mandatory = $true)][object]$Task,
      [Parameter(Mandatory = $true)][int]$TimeoutMs
    )
    try {
      if ($Task -and $Task.Wait($TimeoutMs)) {
        return [string]$Task.Result
      }
    } catch {
      return ''
    }
    return ''
  }

  $psi = [System.Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = $Exe
  foreach ($a in @($Arguments)) { [void]$psi.ArgumentList.Add([string]$a) }
  $psi.UseShellExecute = $false
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.CreateNoWindow = $true
  $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
  $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
  if ($WorkingDirectory) { $psi.WorkingDirectory = $WorkingDirectory }

  foreach ($k in @($Environment.Keys)) {
    $psi.Environment[$k] = [string]$Environment[$k]
  }

  $p = [System.Diagnostics.Process]::new()
  $p.StartInfo = $psi

  $null = $p.Start()

  $stdoutTask = $p.StandardOutput.ReadToEndAsync()
  $stderrTask = $p.StandardError.ReadToEndAsync()

  $timedOut = -not $p.WaitForExit([Math]::Max(1, $TimeoutSec) * 1000)
  if ($timedOut) {
    try { $p.Kill($true) } catch {}
    try { $null = $p.WaitForExit(5000) } catch {}
  }

  $out = Get-TaskResultOrEmpty -Task $stdoutTask -TimeoutMs 2000
  $err = Get-TaskResultOrEmpty -Task $stderrTask -TimeoutMs 2000

  [pscustomobject]@{
    TimedOut = [bool]$timedOut
    ExitCode = if ($timedOut) { -1 } else { [int]$p.ExitCode }
    Stdout = $out
    Stderr = $err
  }
}


function Invoke-ExternalChecked {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$Exe,
    [Parameter(Mandatory = $true)][string[]]$Arguments,
    [Parameter(Mandatory = $true)][string]$WorkingDirectory,
    [Parameter(Mandatory = $true)][int]$TimeoutSec,
    [Parameter()][int[]]$AllowedExitCodes = @(0),
    [Parameter()][hashtable]$Environment = @{}
  )

  $r = Invoke-External -Exe $Exe -Arguments $Arguments -WorkingDirectory $WorkingDirectory -TimeoutSec $TimeoutSec -Environment $Environment
  if ($r.TimedOut) {
    throw ("Timed out: {0} {1}" -f $Exe, ($Arguments -join ' '))
  }
  if (@($AllowedExitCodes) -notcontains $r.ExitCode) {
    $msg = "ExitCode {0}: {1}" -f $r.ExitCode, ($r.Stderr.Trim())
    throw $msg
  }
  return $r
}

function Get-RepoSlug {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)][string]$GitExe,
    [Parameter(Mandatory = $true)][string]$GhExe,
    [Parameter(Mandatory = $true)][int]$TimeoutSec
  )

  $envMap = @{
    GH_PAGER = 'cat'
    GH_PROMPT_DISABLED = 'true'
    GH_NO_UPDATE_NOTIFIER = '1'
    GIT_PAGER = 'cat'
  }

  # Primary: gh repo view
  try {
    $jq = '.nameWithOwner'
    $args = @('repo','view','--json','nameWithOwner','--jq',$jq)
    $r = Invoke-ExternalChecked -Exe $GhExe -Arguments $args -WorkingDirectory $Root -TimeoutSec $TimeoutSec -AllowedExitCodes @(0) -Environment $envMap
    $slug = $r.Stdout.Trim()
    if ($slug) { return $slug }
  } catch {
    # ignore
  }

  # Fallback: parse git remote url
  $r2 = Invoke-ExternalChecked -Exe $GitExe -Arguments @('config','--get','remote.origin.url') -WorkingDirectory $Root -TimeoutSec $TimeoutSec -AllowedExitCodes @(0,1) -Environment $envMap
  $u = $r2.Stdout.Trim()
  if (-not $u) { return '' }

  $m = [regex]::Match($u, 'github\.com[:/]([^/]+)/([^/]+?)(?:\.git)?$')
  if ($m.Success) {
    return ('{0}/{1}' -f $m.Groups[1].Value, $m.Groups[2].Value)
  }
  return ''
}

function Get-DefaultBranchName {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)][string]$GitExe,
    [Parameter(Mandatory = $true)][int]$TimeoutSec
  )

  $envMap = @{ GIT_PAGER = 'cat' }
  try {
    $r = Invoke-ExternalChecked -Exe $GitExe -Arguments @('symbolic-ref','--short','refs/remotes/origin/HEAD') -WorkingDirectory $Root -TimeoutSec $TimeoutSec -AllowedExitCodes @(0) -Environment $envMap
    $sym = $r.Stdout.Trim()
    if ($sym) {
      $m = [regex]::Match($sym, 'refs/remotes/origin/(.+)$')
      if ($m.Success) { return $m.Groups[1].Value }
    }
  } catch {
    # ignore
  }
  return 'main'
}

function Resolve-PrMetadata {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)][string]$GhExe,
    [Parameter(Mandatory = $true)][string]$GitExe,
    [Parameter(Mandatory = $true)][int]$TimeoutSec,
    [int]$PrNumber
  )

  $envMap = @{
    GH_PAGER = 'cat'
    GH_PROMPT_DISABLED = 'true'
    GH_NO_UPDATE_NOTIFIER = '1'
    GIT_PAGER = 'cat'
  }

  $resolvedPr = $PrNumber
  $headBranch = ''
  $baseBranch = ''

  # If no PR given, try current branch PR
  if ($resolvedPr -le 0) {
    try {
      $args = @('pr','view','--json','number,headRefName,baseRefName')
      $r = Invoke-ExternalChecked -Exe $GhExe -Arguments $args -WorkingDirectory $Root -TimeoutSec $TimeoutSec -AllowedExitCodes @(0) -Environment $envMap
      $obj = $r.Stdout | ConvertFrom-Json -ErrorAction Stop
      if ($obj.number) { $resolvedPr = [int]$obj.number }
      if ($obj.headRefName) { $headBranch = [string]$obj.headRefName }
      if ($obj.baseRefName) { $baseBranch = [string]$obj.baseRefName }
    } catch {
      # ignore
    }
  }

  if (-not $headBranch) {
    try {
      $r2 = Invoke-ExternalChecked -Exe $GitExe -Arguments @('rev-parse','--abbrev-ref','HEAD') -WorkingDirectory $Root -TimeoutSec $TimeoutSec -AllowedExitCodes @(0) -Environment $envMap
      $b = $r2.Stdout.Trim()
      if ($b -and $b -ne 'HEAD') { $headBranch = $b }
    } catch {
      # ignore
    }
  }

  [pscustomobject]@{
    PrNumber = $resolvedPr
    HeadBranch = $headBranch
    BaseBranch = $baseBranch
  }
}

function Assert-ParseOK {
  [CmdletBinding()]
  param([Parameter(Mandatory = $true)][string[]]$Paths)

  $allErrors = @()
  foreach ($p in @($Paths)) {
    if (-not (Test-Path -LiteralPath $p)) { continue }
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile([string]$p, [ref]$tokens, [ref]$errors) | Out-Null
    $errs = @($errors)
    if ($errs.Count -gt 0) {
      foreach ($e in $errs) {
        $allErrors += ("{0}:{1}:{2} {3}" -f $e.Extent.File, $e.Extent.StartLineNumber, $e.Extent.StartColumnNumber, $e.Message)
      }
    }
  }

  if ($allErrors.Count -gt 0) {
    throw ("Parse errors found:{0}{1}" -f [Environment]::NewLine, ($allErrors -join [Environment]::NewLine))
  }
}

function Invoke-ScriptAnalyzerSafe {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string[]]$Paths,
    [Parameter()][ValidateNotNullOrEmpty()][string[]]$Severities = @('Error'),
    [Parameter()][ValidateRange(10, 1800)][int]$TimeoutSec = 120
  )

  $p = @($Paths | ForEach-Object { [string]$_ } | Where-Object { $_ -and (Test-Path -LiteralPath $_) })
  if ($p.Count -eq 0) { return @() }

  $job = Start-Job -ScriptBlock {
    param($paths, $sevs)

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'

    try {
      Import-Module PSScriptAnalyzer -ErrorAction Stop -Force
    } catch {
      throw 'PSScriptAnalyzer module not found. Install-Module PSScriptAnalyzer -Scope CurrentUser -Force'
    }

    try {
      return @(Invoke-ScriptAnalyzer -Path $paths -Severity $sevs -Recurse:$false)
    } catch {
      $results = @()
      foreach ($one in @($paths)) {
        try {
          $results += @(Invoke-ScriptAnalyzer -Path $one -Severity $sevs -Recurse:$false)
        } catch {
          $results += [pscustomobject]@{
            RuleName = 'AnalyzerCrashed'
            Severity = 'Error'
            ScriptPath = $one
            Message = $_.Exception.Message
          }
        }
      }
      return $results
    }
  } -ArgumentList @($p, $Severities)

  if (-not (Wait-Job -Job $job -Timeout $TimeoutSec)) {
    try { Stop-Job -Job $job -Force -ErrorAction SilentlyContinue } catch {}
    try { Remove-Job -Job $job -Force -ErrorAction SilentlyContinue } catch {}
    throw ('Invoke-ScriptAnalyzer timed out after {0}s' -f $TimeoutSec)
  }

  $result = $null
  try {
    $result = Receive-Job -Job $job -ErrorAction Stop
  } finally {
    try { Remove-Job -Job $job -Force -ErrorAction SilentlyContinue } catch {}
  }

  if ($null -eq $result) { return @() }

  return @($result)
}

function Initialize-RequiredEvidenceFiles {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$OutDir
  )

  $req = @('required_status_checks.json','gh_pr_view.json','gh_run_list.json')
  foreach ($f in $req) {
    $p = Join-Path $OutDir $f
    if (-not (Test-Path -LiteralPath $p)) {
      $obj = New-EvidenceErrorObject -Step 'finalize' -Message ('Missing evidence file was created as placeholder: {0}' -f $f) -ExitCode 10
      Write-JsonFileUtf8 -Path $p -Object $obj
    }
  }
}

function Invoke-CollectEvidence {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)][string]$ArtifactsPath,
    [Parameter(Mandatory = $true)][int]$TimeoutSec,
    [int]$PrNumber,
    [string]$BaseBranch,
    [switch]$NoZip,
    [switch]$QualityGate,
    [switch]$Diag
  )
  New-DirectoryIfMissing -Path $ArtifactsPath

  $stamp = Get-NowStamp
  $outDir = Join-Path $ArtifactsPath ("issue5-evidence-{0}" -f $stamp)
  New-DirectoryIfMissing -Path $outDir

  $logPath = Join-Path $outDir 'run.log'
  Write-TextFileUtf8 -Path $logPath -Value ("startedAt={0}" -f (Get-Date).ToString('o'))
  Write-Stage -OutDir $outDir -Message 'START' -Diag:$Diag

  $hadEvidenceErrors = $false
  $qualityGateFailed = $false

  $gitExe = $null
  $ghExe = $null

  try { $gitExe = Resolve-ExePath -Name 'git' } catch { $gitExe = '' }
  try { $ghExe = Resolve-ExePath -Name 'gh' } catch { $ghExe = '' }

  Write-JsonFileUtf8 -Path (Join-Path $outDir 'tooling.json') -Object ([pscustomobject]@{
    git = $gitExe
    gh = $ghExe
    pwsh = $PSVersionTable.PSVersion.ToString()
    generatedAt = (Get-Date).ToString('o')
  })
  Write-Stage -OutDir $outDir -Message 'TOOLING_OK' -Diag:$Diag

  $targetsForGate = @($PSCommandPath)
  $guardPath = Join-Path $Root '.github/scripts/required-checks-guard.ps1'
  if (Test-Path -LiteralPath $guardPath) { $targetsForGate += $guardPath }

  if ($QualityGate) {
    try {
      Assert-ParseOK -Paths $targetsForGate
      Write-TextFileUtf8 -Path (Join-Path $outDir 'qualitygate_parser.txt') -Value 'PASS'
    } catch {
      Write-TextFileUtf8 -Path (Join-Path $outDir 'qualitygate_parser.txt') -Value ('FAIL' + [Environment]::NewLine + $_.Exception.Message)
      $qualityGateFailed = $true
    }

    try {
      $saErr = @(Invoke-ScriptAnalyzerSafe -Paths $targetsForGate -Severities @('Error'))
      if ($null -eq $saErr) { $saErr = @() }
      Write-JsonFileUtf8 -Path (Join-Path $outDir 'qualitygate_scriptanalyzer_errors.json') -Object $saErr
      if (@($saErr).Count -gt 0) {
        Write-TextFileUtf8 -Path (Join-Path $outDir 'qualitygate_scriptanalyzer_errors.txt') -Value ('FAIL findingsCount=' + @($saErr).Count.ToString())
        throw 'ScriptAnalyzer error findings detected.'
      }
      Write-TextFileUtf8 -Path (Join-Path $outDir 'qualitygate_scriptanalyzer_errors.txt') -Value 'PASS'

      $saWarn = @(Invoke-ScriptAnalyzerSafe -Paths $targetsForGate -Severities @('Warning'))
      if ($null -eq $saWarn) { $saWarn = @() }
      Write-JsonFileUtf8 -Path (Join-Path $outDir 'qualitygate_scriptanalyzer_warnings.json') -Object $saWarn
      Write-TextFileUtf8 -Path (Join-Path $outDir 'qualitygate_scriptanalyzer_warnings.txt') -Value ('warningsCount=' + @($saWarn).Count.ToString())
    } catch {
      if (-not (Test-Path -LiteralPath (Join-Path $outDir 'qualitygate_scriptanalyzer_errors.json'))) {
        Write-JsonFileUtf8 -Path (Join-Path $outDir 'qualitygate_scriptanalyzer_errors.json') -Object (New-EvidenceErrorObject -Step 'qualitygate_scriptanalyzer' -Message $_.Exception.Message -ExitCode 10)
      }
      $qualityGateFailed = $true
    }
  }

  # If gh missing, still create required evidence placeholders.
  if (-not $ghExe) {
    $obj = New-EvidenceErrorObject -Step 'preflight' -Message 'GitHub CLI (gh) not found on PATH.' -Exe 'gh' -ExitCode 10
    Write-JsonFileUtf8 -Path (Join-Path $outDir 'gh_pr_view.json') -Object $obj
    Write-JsonFileUtf8 -Path (Join-Path $outDir 'gh_run_list.json') -Object $obj
    Write-JsonFileUtf8 -Path (Join-Path $outDir 'required_status_checks.json') -Object $obj
    Initialize-RequiredEvidenceFiles -OutDir $outDir
    if (-not $NoZip) {
    Write-Stage -OutDir $outDir -Message 'ZIP_START' -Diag:$Diag
      $zip = Join-Path $ArtifactsPath ("issue5-evidence-{0}.zip" -f $stamp)
      if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
      Compress-Archive -Path (Join-Path $outDir '*') -DestinationPath $zip -Force
      Write-TextFileUtf8 -Path (Join-Path $outDir 'zip_path.txt') -Value $zip
    Write-Stage -OutDir $outDir -Message 'ZIP_OK' -Diag:$Diag
    }
    $hadEvidenceErrors = $true
    return 2
  }

  if (-not $gitExe) {
    # git is not strictly required for gh_pr_view and gh_run_list, but used for base branch fallback and slug fallback
    Write-TextFileUtf8 -Path (Join-Path $outDir 'WARN_git_missing.txt') -Value 'git not found on PATH. Some fallbacks are disabled.'
  }

  $repoSlug = ''
  if ($gitExe) {
    $repoSlug = Get-RepoSlug -Root $Root -GitExe $gitExe -GhExe $ghExe -TimeoutSec $TimeoutSec
  } else {
    # slug may still be available via gh repo view
    try {
      $jq = '.nameWithOwner'
      $args = @('repo','view','--json','nameWithOwner','--jq',$jq)
      $rSlug = Invoke-ExternalChecked -Exe $ghExe -Arguments $args -WorkingDirectory $Root -TimeoutSec $TimeoutSec -AllowedExitCodes @(0) -Environment @{
        GH_PAGER='cat'; GH_PROMPT_DISABLED='true'; GH_NO_UPDATE_NOTIFIER='1'
      }
      $repoSlug = $rSlug.Stdout.Trim()
    } catch { $repoSlug = '' }
  }

  $defaultBranch = 'main'
  if ($gitExe) {
    $defaultBranch = Get-DefaultBranchName -Root $Root -GitExe $gitExe -TimeoutSec $TimeoutSec
  }
  $effectiveBaseBranch = if ($BaseBranch) { $BaseBranch } else { $defaultBranch }

  $meta = Resolve-PrMetadata -Root $Root -GhExe $ghExe -GitExe $gitExe -TimeoutSec $TimeoutSec -PrNumber $PrNumber
  if ($meta.BaseBranch) { $effectiveBaseBranch = $meta.BaseBranch }
  $effectivePr = $meta.PrNumber
  $headBranch = $meta.HeadBranch

  Write-JsonFileUtf8 -Path (Join-Path $outDir 'resolution.json') -Object ([pscustomobject]@{
    repoSlug = $repoSlug
    prNumber = $effectivePr
    headBranch = $headBranch
    baseBranch = $effectiveBaseBranch
    generatedAt = (Get-Date).ToString('o')
  })

  $envMap = @{
    GH_PAGER = 'cat'
    GH_PROMPT_DISABLED = 'true'
    GH_NO_UPDATE_NOTIFIER = '1'
    GIT_PAGER = 'cat'
  }


# Preflight: gh auth status (fail-fast to avoid interactive hang)
$args = @('auth','status')
try {
  Write-Stage -OutDir $outDir -Message 'GH_AUTH_STATUS_START' -Diag:$Diag
  $rAuth = Invoke-External -Exe $ghExe -Arguments $args -WorkingDirectory $Root -TimeoutSec ([Math]::Min(30, $TimeoutSec)) -Environment $envMap
  Write-TextFileUtf8 -Path (Join-Path $outDir 'gh_auth_status_exitcode.txt') -Value ([string]$rAuth.ExitCode)
  if ($rAuth.ExitCode -ne 0) { throw ($rAuth.Stderr.Trim()) }
  Write-TextFileUtf8 -Path (Join-Path $outDir 'gh_auth_status.txt') -Value 'PASS'
  Write-Stage -OutDir $outDir -Message 'GH_AUTH_STATUS_PASS' -Diag:$Diag
} catch {
  $obj = New-EvidenceErrorObject -Step 'gh_auth_status' -Message ('gh auth status failed: ' + $_.Exception.Message) -Exe $ghExe -Args $args -ExitCode 10
  Write-JsonFileUtf8 -Path (Join-Path $outDir 'gh_auth_status.json') -Object $obj

  $obj2 = New-EvidenceErrorObject -Step 'preflight' -Message 'gh is not authenticated or gh auth status failed.' -Exe $ghExe -Args $args -ExitCode 10
  Write-JsonFileUtf8 -Path (Join-Path $outDir 'gh_pr_view.json') -Object $obj2
  Write-JsonFileUtf8 -Path (Join-Path $outDir 'gh_run_list.json') -Object $obj2
  Write-JsonFileUtf8 -Path (Join-Path $outDir 'required_status_checks.json') -Object $obj2
  Initialize-RequiredEvidenceFiles -OutDir $outDir

  if (-not $NoZip) {
    Write-Stage -OutDir $outDir -Message 'ZIP_START' -Diag:$Diag
    $zip = Join-Path $ArtifactsPath ("issue5-evidence-{0}.zip" -f $stamp)
    if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
    Compress-Archive -Path (Join-Path $outDir '*') -DestinationPath $zip -Force
    Write-TextFileUtf8 -Path (Join-Path $outDir 'zip_path.txt') -Value $zip
    Write-Stage -OutDir $outDir -Message 'ZIP_OK' -Diag:$Diag
  }

  return 2
}

  # 1) gh_pr_view.json (required)
  try {
    Write-Stage -OutDir $outDir -Message 'GH_PR_VIEW_START' -Diag:$Diag
    $args = @('pr','view')
    if ($effectivePr -gt 0) { $args += @($effectivePr.ToString()) }
    $args += @('--json','number,title,state,mergedAt,url,headRefName,baseRefName,reviewDecision,statusCheckRollup')
    $r = Invoke-ExternalChecked -Exe $ghExe -Arguments $args -WorkingDirectory $Root -TimeoutSec $TimeoutSec -AllowedExitCodes @(0) -Environment $envMap
    Write-TextFileUtf8 -Path (Join-Path $outDir 'gh_pr_view.json') -Value $r.Stdout
    Write-Stage -OutDir $outDir -Message 'GH_PR_VIEW_OK' -Diag:$Diag
  } catch {
    $obj = New-EvidenceErrorObject -Step 'gh_pr_view' -Message $_.Exception.Message -Exe $ghExe -Args $args -ExitCode 10
    Write-JsonFileUtf8 -Path (Join-Path $outDir 'gh_pr_view.json') -Object $obj
    $hadEvidenceErrors = $true
  }

  # 2) gh_run_list.json (required)
  try {
    Write-Stage -OutDir $outDir -Message 'GH_RUN_LIST_START' -Diag:$Diag
    $args = @('run','list','--limit','80','--json','databaseId,workflowName,status,conclusion,createdAt,updatedAt,url,headBranch,event')
    if ($headBranch) { $args += @('--branch',$headBranch) }
    $r = Invoke-ExternalChecked -Exe $ghExe -Arguments $args -WorkingDirectory $Root -TimeoutSec $TimeoutSec -AllowedExitCodes @(0) -Environment $envMap
    Write-TextFileUtf8 -Path (Join-Path $outDir 'gh_run_list.json') -Value $r.Stdout
    Write-Stage -OutDir $outDir -Message 'GH_RUN_LIST_OK' -Diag:$Diag
  } catch {
    $obj = New-EvidenceErrorObject -Step 'gh_run_list' -Message $_.Exception.Message -Exe $ghExe -Args $args -ExitCode 10
    Write-JsonFileUtf8 -Path (Join-Path $outDir 'gh_run_list.json') -Object $obj
    $hadEvidenceErrors = $true
  }

  # 3) required_status_checks.json (required)
  try {
    Write-Stage -OutDir $outDir -Message 'REQUIRED_STATUS_CHECKS_START' -Diag:$Diag
    if (-not $repoSlug) { throw 'repoSlug could not be resolved (owner/repo).' }
    if (-not $effectiveBaseBranch) { throw 'base branch could not be resolved.' }
    $endpoint = ('repos/{0}/branches/{1}/protection/required_status_checks' -f $repoSlug, $effectiveBaseBranch)
    $args = @('api','-H','Accept: application/vnd.github+json',$endpoint)
    $r = Invoke-ExternalChecked -Exe $ghExe -Arguments $args -WorkingDirectory $Root -TimeoutSec $TimeoutSec -AllowedExitCodes @(0) -Environment $envMap
    Write-TextFileUtf8 -Path (Join-Path $outDir 'required_status_checks.json') -Value $r.Stdout
    Write-Stage -OutDir $outDir -Message 'REQUIRED_STATUS_CHECKS_OK' -Diag:$Diag
    Write-TextFileUtf8 -Path (Join-Path $outDir 'required_status_checks_branch.txt') -Value $effectiveBaseBranch
  } catch {
    $obj = New-EvidenceErrorObject -Step 'required_status_checks' -Message $_.Exception.Message -Exe $ghExe -Args $args -ExitCode 10
    Write-JsonFileUtf8 -Path (Join-Path $outDir 'required_status_checks.json') -Object $obj
    if ($effectiveBaseBranch) {
      Write-TextFileUtf8 -Path (Join-Path $outDir 'required_status_checks_branch.txt') -Value $effectiveBaseBranch
    }
    $hadEvidenceErrors = $true
  }

  Initialize-RequiredEvidenceFiles -OutDir $outDir

  if (-not $NoZip) {
    Write-Stage -OutDir $outDir -Message 'ZIP_START' -Diag:$Diag
    $zip = Join-Path $ArtifactsPath ("issue5-evidence-{0}.zip" -f $stamp)
    if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
    Compress-Archive -Path (Join-Path $outDir '*') -DestinationPath $zip -Force
    Write-TextFileUtf8 -Path (Join-Path $outDir 'zip_path.txt') -Value $zip
    Write-Stage -OutDir $outDir -Message 'ZIP_OK' -Diag:$Diag
  }

  if ($hadEvidenceErrors -or $qualityGateFailed) { return 2 }
  return 0
}

try {
  if (-not (Test-Path -LiteralPath $RepoRoot)) {
    throw ("RepoRoot not found: {0}" -f $RepoRoot)
  }

  $rootFull = (Resolve-Path -LiteralPath $RepoRoot).Path

  $artifactsPath = if ([System.IO.Path]::IsPathRooted($ArtifactsDir)) {
    $ArtifactsDir
  } else {
    Join-Path $rootFull $ArtifactsDir
  }

  $rc = Invoke-CollectEvidence -Root $rootFull -ArtifactsPath $artifactsPath -TimeoutSec $TimeoutSeconds -PrNumber $PrNumber -BaseBranch $BaseBranch -NoZip:$NoZip -QualityGate:$QualityGate -Diag:$Diag

  exit [int]$rc
} catch {
  [Console]::Error.WriteLine(('ERROR: {0}' -f $_.Exception.Message))
  exit 10
}
