#requires -Version 7.0
<#
.SYNOPSIS
  Approve a PR (if required) and enable GitHub Auto-merge, using GitHub CLI (gh).

.DESCRIPTION
  Hardened for GitHub Actions:
  - Uses GH_TOKEN (recommended: bot classic PAT) for authentication.
  - Logs token subject via `gh api user --jq .login` (no secrets).
  - Attempts to resolve REVIEW_REQUIRED by approving (when possible), BEFORE waiting for checks.
  - Tries to enable auto-merge (`gh pr merge --auto`) even when checks are pending/unknown.
  - Never fails the workflow for "not ready yet" conditions. If requirements aren't met after retries,
    it leaves a comment + label and exits 0 (so it does NOT become an additional failing check).
  - Still throws on unexpected script/runtime failures (to surface real bugs).

.NOTES
  Intended path: .github/scripts/ai-bot-approve-merge.ps1
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string]$Repo,

  [Parameter(Mandatory)]
  [ValidateRange(1, 10000000)]
  [int]$PullNumber,

  [Parameter()]
  [string]$RunId = "",

  [Parameter()]
  [ValidateRange(1, 50)]
  [int]$MaxAttempts = 10,

  [Parameter()]
  [ValidateRange(5, 600)]
  [int]$SleepSeconds = 30,

  [Parameter()]
  [ValidateSet('squash','merge','rebase')]
  [string]$MergeMethod = 'squash',

  [Parameter()]
  [switch]$DeleteBranch,

  [Parameter()]
  [switch]$EnableAutoMerge = $true,

  [Parameter()]
  [switch]$TryAutoApprove = $true,

  [Parameter()]
  [ValidateNotNullOrEmpty()]
  [string]$BlockLabel = 'ai:blocked',

  [Parameter()]
  [ValidateNotNullOrEmpty()]
  [string]$BlockCommentHeader = '[AI Automation]'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Write-Log {
  param(
    [Parameter(Mandatory)][ValidateSet('INFO','WARN','ERROR','DEBUG')] [string]$Level,
    [Parameter(Mandatory)][string]$Message
  )
  $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
  Write-Host ("[{0}][{1}] {2}" -f $ts, $Level, $Message)
}

function Invoke-Native {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Exe,
    [Parameter(Mandatory)][string[]]$ExeArgs,
    [Parameter()][switch]$AllowNonZeroExit
  )

  $psi = [System.Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = $Exe
  foreach ($a in $ExeArgs) { [void]$psi.ArgumentList.Add($a) }
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError  = $true
  $psi.UseShellExecute        = $false
  $psi.CreateNoWindow         = $true

  $p = [System.Diagnostics.Process]::new()
  $p.StartInfo = $psi

  [void]$p.Start()
  $stdout = $p.StandardOutput.ReadToEnd()
  $stderr = $p.StandardError.ReadToEnd()
  $p.WaitForExit()

  $res = [pscustomobject]@{
    ExitCode = $p.ExitCode
    StdOut   = $stdout
    StdErr   = $stderr
  }

  if (-not $AllowNonZeroExit -and $res.ExitCode -ne 0) {
    $cmd = ($ExeArgs -join ' ')
    $msg = "Command failed (exit=$($res.ExitCode)): $Exe $cmd"
    if ($res.StdErr) { $msg += "`n$($res.StdErr.TrimEnd())" }
    throw $msg
  }

  return $res
}

function Invoke-GhJson {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [Alias('ExeArgs')]
    [string[]]$GhArgs
  )

  $r = Invoke-Native -Exe 'gh' -ExeArgs $GhArgs
  $out = ($r.StdOut ?? '').Trim()
  if (-not $out) { throw "Expected JSON output from gh, but got empty output. args=gh $($GhArgs -join ' ')" }
  try {
    return ($out | ConvertFrom-Json -Depth 100)
  } catch {
    throw "Failed to parse JSON from gh output. args=gh $($GhArgs -join ' ')`n$out"
  }
}

function Try-GetGhLogin {
  try {
    $r = Invoke-Native -Exe 'gh' -ExeArgs @('api','user','--jq','.login') -AllowNonZeroExit
    $login = ($r.StdOut ?? '').Trim()
    if ($r.ExitCode -eq 0 -and $login) { return $login }
  } catch { }
  return $null
}

function Ensure-Label {
  param([Parameter(Mandatory)][string]$Name)
  try {
    [void](Invoke-Native -Exe 'gh' -ExeArgs @('label','create',$Name,'-R',$Repo,'--color','BFD4F2','--description','Automation label') -AllowNonZeroExit)
  } catch { }
}

function Add-LabelSafe {
  param([Parameter(Mandatory)][string]$Name)
  Ensure-Label -Name $Name
  $r = Invoke-Native -Exe 'gh' -ExeArgs @('pr','edit',"$PullNumber",'-R',$Repo,'--add-label',$Name) -AllowNonZeroExit
  if ($r.ExitCode -ne 0) {
    Write-Log WARN ("Failed to add label '{0}' (continuing). stderr={1}" -f $Name, (($r.StdErr ?? '').Trim()))
  }
}

function Comment-Safe {
  param([Parameter(Mandatory)][string]$Body)
  $full = "$BlockCommentHeader $Body"
  $r = Invoke-Native -Exe 'gh' -ExeArgs @('pr','comment',"$PullNumber",'-R',$Repo,'--body',$full) -AllowNonZeroExit
  if ($r.ExitCode -ne 0) {
    Write-Log WARN ("Failed to comment on PR (continuing). stderr={0}" -f (($r.StdErr ?? '').Trim()))
  }
}

function Get-PrState {
  # NOTE: statusCheckRollup may be null/absent depending on API/gh version/permissions; handle as UNKNOWN.
  $fields = 'mergeStateStatus,reviewDecision,statusCheckRollup,isDraft,author,headRefName,url'
  return Invoke-GhJson -GhArgs @('pr','view',"$PullNumber",'-R',$Repo,'--json',$fields)
}

function Get-RollupState {
  param([Parameter(Mandatory)]$PrView)
  try {
    $state = $PrView.statusCheckRollup.state
    if ($state) { return [string]$state }
  } catch { }
  return 'UNKNOWN'
}

function Is-TerminalBadRollup {
  param([Parameter(Mandatory)][string]$RollupState)
  switch ($RollupState) {
    'FAILURE' { return $true }
    'ERROR' { return $true }
    'CANCELLED' { return $true }
    'TIMED_OUT' { return $true }
    default { return $false }
  }
}

function Try-Approve {
  param(
    [Parameter(Mandatory)][string]$Actor,
    [Parameter(Mandatory)][string]$Author
  )

  if (-not $TryAutoApprove) { return $false }

  if (-not $Actor) {
    Write-Log WARN "Cannot determine token subject; skipping auto-approve."
    return $false
  }

  if ($Actor -eq $Author) {
    Write-Log WARN ("Token subject '{0}' equals PR author '{1}'. Self-approval typically does not satisfy review requirements. Skipping auto-approve." -f $Actor, $Author)
    return $false
  }

  $body = "Auto-approval by bot ($Actor). RunId=$RunId"
  $r = Invoke-Native -Exe 'gh' -ExeArgs @('pr','review',"$PullNumber",'-R',$Repo,'--approve','--body',$body) -AllowNonZeroExit
  if ($r.ExitCode -eq 0) {
    Write-Log INFO ("Submitted approval review as '{0}'." -f $Actor)
    return $true
  }

  Write-Log WARN ("Auto-approve failed (exit={0}). stderr={1}" -f $r.ExitCode, (($r.StdErr ?? '').Trim()))
  return $false
}

function Try-EnableAutoMerge {
  param([Parameter(Mandatory)][string]$Method)

  if (-not $EnableAutoMerge) { return $false }

  $args = @('pr','merge',"$PullNumber",'-R',$Repo,'--auto',"--$Method")
  if ($DeleteBranch) { $args += '--delete-branch' }

  $r = Invoke-Native -Exe 'gh' -ExeArgs $args -AllowNonZeroExit
  if ($r.ExitCode -eq 0) {
    Write-Log INFO ("Auto-merge enabled via: gh {0}" -f ($args -join ' '))
    return $true
  }

  $stderr = ($r.StdErr ?? '').Trim()
  if ($stderr -match 'Auto-merge is already enabled' -or $stderr -match 'already enabled') {
    Write-Log INFO "Auto-merge already enabled."
    return $true
  }

  Write-Log WARN ("Enable auto-merge failed (exit={0}). stderr={1}" -f $r.ExitCode, $stderr)
  return $false
}

# ---------------- main ----------------
Write-Log INFO ("Repo={0} PR={1} RunId={2} MaxAttempts={3} SleepSeconds={4} MergeMethod={5} DeleteBranch={6}" -f $Repo, $PullNumber, $RunId, $MaxAttempts, $SleepSeconds, $MergeMethod, $DeleteBranch.IsPresent)

if (-not $env:GH_TOKEN) {
  Write-Log WARN "GH_TOKEN is not set. gh will use its own auth context (likely github.token in Actions). For bot PAT, set GH_TOKEN at job level."
}

$actor = Try-GetGhLogin
if ($actor) { Write-Log INFO ("Token subject (gh api user) = {0}" -f $actor) } else { Write-Log WARN "Could not determine token subject via gh api user." }

for ($i = 1; $i -le $MaxAttempts; $i++) {
  $pr = Get-PrState
  $mergeState = [string]$pr.mergeStateStatus
  $reviewDecision = [string]$pr.reviewDecision
  $isDraft = [bool]$pr.isDraft

  $author = $null
  try { $author = [string]$pr.author.login } catch { $author = $null }

  $rollupState = Get-RollupState -PrView $pr
  $checksOK = ($rollupState -eq 'SUCCESS')

  Write-Log INFO ("Attempt {0}/{1}: mergeState={2} reviewDecision={3} rollupState={4} checksOK={5} draft={6} author={7} actor={8}" -f $i, $MaxAttempts, $mergeState, $reviewDecision, $rollupState, $checksOK, $isDraft, $author, $actor)

  if ($isDraft) {
    Add-LabelSafe -Name $BlockLabel
    Comment-Safe -Body ("PR is a draft. Please mark it as 'Ready for review' to proceed. run_id={0}" -f $RunId)
    exit 0
  }

  if ($reviewDecision -eq 'CHANGES_REQUESTED') {
    Add-LabelSafe -Name $BlockLabel
    Comment-Safe -Body ("Changes were requested on this PR. Please address review comments, then re-run automation. run_id={0}" -f $RunId)
    exit 0
  }

  # REVIEW_REQUIRED is handled FIRST, regardless of check state.
  if ($reviewDecision -eq 'REVIEW_REQUIRED') {
    $didApprove = Try-Approve -Actor $actor -Author $author
    if (-not $didApprove) {
      Add-LabelSafe -Name $BlockLabel
      Comment-Safe -Body ("Review is required but automation could not approve (actor={0} author={1}). Please approve manually or adjust branch protection. run_id={2}" -f $actor, $author, $RunId)
      exit 0
    }

    Start-Sleep -Seconds 5
    Start-Sleep -Seconds $SleepSeconds
    continue
  }

  # If checks are failing, do NOT fail this workflow. Leave a note and exit 0.
  if (Is-TerminalBadRollup -RollupState $rollupState) {
    Add-LabelSafe -Name $BlockLabel
    Comment-Safe -Body ("Checks are failing (statusCheckRollup={0}). Fix checks before merge. run_id={1}" -f $rollupState, $RunId)
    exit 0
  }

  # Try enabling auto-merge even if checks are pending/unknown.
  $enabled = Try-EnableAutoMerge -Method $MergeMethod
  if ($enabled) { exit 0 }

  # Not enabled yet. If checks are not green, wait and retry; otherwise leave a note and exit.
  if (-not $checksOK) {
    Start-Sleep -Seconds $SleepSeconds
    continue
  }

  Add-LabelSafe -Name $BlockLabel
  Comment-Safe -Body ("Automation could not enable auto-merge (mergeState={0}). Please check branch protection / merge queue / permissions. run_id={1}" -f $mergeState, $RunId)
  exit 0
}

# Retries exhausted -> do NOT fail; leave guidance and exit 0.
Add-LabelSafe -Name $BlockLabel
Comment-Safe -Body ("Not ready after {0} attempts (mergeState/review/checks unresolved). Please review manually. run_id={1}" -f $MaxAttempts, $RunId)
exit 0
