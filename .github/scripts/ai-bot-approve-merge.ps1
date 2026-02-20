#requires -Version 7.0
<#
.SYNOPSIS
  Approve a PR (if required) and enable GitHub Auto-merge, using GitHub CLI (gh).

.DESCRIPTION
  - Designed for GitHub Actions (PowerShell 7) on Windows/Linux runners.
  - Uses GH_TOKEN (recommended: bot classic PAT) for authentication.
  - Tries to resolve REVIEW_REQUIRED by approving (when possible).
  - Determines check health using `gh pr view --json statusCheckRollup` (does NOT rely on branch protection endpoints).
  - If it cannot satisfy branch protection (e.g., CODEOWNERS required, self-approval, insufficient permissions),
    it falls back to labeling the PR as ai:blocked and adding a comment with next actions.

.PARAMETER Repo
  Repository in "owner/name" format.

.PARAMETER PullNumber
  Pull Request number.

.PARAMETER RunId
  Optional Actions run id (for traceability in comments/logs).

.PARAMETER MaxAttempts
  Retry attempts for polling merge/review/check states.

.PARAMETER SleepSeconds
  Sleep between attempts.

.PARAMETER MergeMethod
  merge method: squash|merge|rebase

.PARAMETER DeleteBranch
  If set, request deletion of the head branch when auto-merge completes.

.PARAMETER EnableAutoMerge
  If set (default), enable auto-merge when the PR is mergeable & approved & checks are green.

.PARAMETER TryAutoApprove
  If set (default), attempt to approve when reviewDecision=REVIEW_REQUIRED.

.PARAMETER BlockLabel
  Label to add when automation cannot proceed safely.

.PARAMETER BlockCommentHeader
  Prefix header for automation comments.
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
  Write-Host "[$ts][$Level] $Message"
}

function New-NativeResult {
  param(
    [int]$ExitCode,
    [string]$StdOut,
    [string]$StdErr
  )
  [pscustomobject]@{
    ExitCode = $ExitCode
    StdOut   = $StdOut
    StdErr   = $StdErr
  }
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

  $res = New-NativeResult -ExitCode $p.ExitCode -StdOut $stdout -StdErr $stderr
  if (-not $AllowNonZeroExit -and $res.ExitCode -ne 0) {
    $cmd = ($ExeArgs -join ' ')
    $msg = "gh failed (exit=$($res.ExitCode)): $Exe $cmd"
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
  param([string]$Name)
  try {
    Invoke-Native -Exe 'gh' -ExeArgs @('label','create',$Name,'-R',$Repo,'--color','BFD4F2','--description','Automation label') -AllowNonZeroExit | Out-Null
  } catch { }
}

function Add-LabelSafe {
  param([string]$Name)
  Ensure-Label -Name $Name
  $r = Invoke-Native -Exe 'gh' -ExeArgs @('pr','edit',"$PullNumber",'-R',$Repo,'--add-label',$Name) -AllowNonZeroExit
  if ($r.ExitCode -ne 0) {
    Write-Log WARN "Failed to add label '$Name' (continuing). stderr=$($r.StdErr.Trim())"
  }
}

function Comment-Safe {
  param([string]$Body)
  $full = "$BlockCommentHeader $Body"
  $r = Invoke-Native -Exe 'gh' -ExeArgs @('pr','comment',"$PullNumber",'-R',$Repo,'--body',$full) -AllowNonZeroExit
  if ($r.ExitCode -ne 0) {
    Write-Log WARN "Failed to comment on PR (continuing). stderr=$($r.StdErr.Trim())"
  }
}

function Get-PrState {
  # Use gh pr view --json for portability and to avoid branch protection REST endpoints.
  $fields = 'mergeStateStatus,reviewDecision,statusCheckRollup,isDraft,author,headRefName,url'
  return Invoke-GhJson -GhArgs @('pr','view',"$PullNumber",'-R',$Repo,'--json',$fields)
}

function Get-RollupState {
  param($PrView)
  # Preferred: statusCheckRollup.state (SUCCESS/FAILURE/PENDING/ERROR/...)
  $state = $null
  try { $state = $PrView.statusCheckRollup.state } catch { $state = $null }
  if (-not $state) { return 'UNKNOWN' }
  return [string]$state
}

function Rollup-IsGreen {
  param([string]$RollupState)
  switch ($RollupState) {
    'SUCCESS' { return $true }
    default   { return $false }
  }
}

function Rollup-IsTerminalFailure {
  param([string]$RollupState)
  switch ($RollupState) {
    'FAILURE' { return $true }
    'ERROR'   { return $true }
    'CANCELLED' { return $true }
    'TIMED_OUT' { return $true }
    default { return $false }
  }
}

function Try-Approve {
  param([string]$Actor, [string]$Author)

  if (-not $TryAutoApprove) { return $false }

  if (-not $Actor) {
    Write-Log WARN "Cannot determine token subject; skipping auto-approve."
    return $false
  }

  if ($Actor -eq $Author) {
    Write-Log WARN "Token subject '$Actor' equals PR author '$Author'. Self-approval typically does not satisfy review requirements. Skipping auto-approve."
    return $false
  }

  $body = "Auto-approval by bot ($Actor). RunId=$RunId"
  $r = Invoke-Native -Exe 'gh' -ExeArgs @('pr','review',"$PullNumber",'-R',$Repo,'--approve','--body',$body) -AllowNonZeroExit
  if ($r.ExitCode -eq 0) {
    Write-Log INFO "Submitted approval review as '$Actor'."
    return $true
  }

  $stderr = ($r.StdErr ?? '').Trim()
  Write-Log WARN "Auto-approve failed (exit=$($r.ExitCode)). stderr=$stderr"
  return $false
}

function Try-EnableAutoMerge {
  param([string]$Method)

  if (-not $EnableAutoMerge) { return $false }

  $args = @('pr','merge',"$PullNumber",'-R',$Repo,'--auto',"--$Method")
  if ($DeleteBranch) { $args += '--delete-branch' }

  $r = Invoke-Native -Exe 'gh' -ExeArgs $args -AllowNonZeroExit
  if ($r.ExitCode -eq 0) {
    Write-Log INFO "Auto-merge enabled via: gh $($args -join ' ')"
    return $true
  }

  $stderr = ($r.StdErr ?? '').Trim()
  if ($stderr -match 'Auto-merge is already enabled' -or $stderr -match 'already enabled') {
    Write-Log INFO "Auto-merge already enabled."
    return $true
  }

  Write-Log WARN "Enable auto-merge failed (exit=$($r.ExitCode)). stderr=$stderr"
  return $false
}

# --- Main ---
Write-Log INFO "Repo=$Repo PR=$PullNumber RunId=$RunId MaxAttempts=$MaxAttempts SleepSeconds=$SleepSeconds MergeMethod=$MergeMethod DeleteBranch=$($DeleteBranch.IsPresent)"

if (-not $env:GH_TOKEN) {
  Write-Log WARN "GH_TOKEN is not set. gh will use its own auth context (likely github.token in Actions). For bot PAT, set GH_TOKEN at job level."
}

$actor = Try-GetGhLogin
if ($actor) {
  Write-Log INFO "Token subject (gh api user) = $actor"
} else {
  Write-Log WARN "Could not determine token subject via gh api user."
}

for ($i = 1; $i -le $MaxAttempts; $i++) {
  $pr = Get-PrState
  $mergeState = [string]$pr.mergeStateStatus
  $reviewDecision = [string]$pr.reviewDecision
  $isDraft = [bool]$pr.isDraft
  $author = $null
  try { $author = [string]$pr.author.login } catch { $author = $null }
  $rollupState = Get-RollupState -PrView $pr

  $checksOK = Rollup-IsGreen -RollupState $rollupState

  Write-Log INFO "Attempt $i/$MaxAttempts: mergeState=$mergeState reviewDecision=$reviewDecision rollupState=$rollupState checksOK=$checksOK draft=$isDraft author=$author actor=$actor"

  if ($isDraft) {
    Add-LabelSafe -Name $BlockLabel
    Comment-Safe -Body "PR is a draft. Please mark it as 'Ready for review' to proceed. (mergeState=$mergeState reviewDecision=$reviewDecision rollup=$rollupState run_id=$RunId)"
    throw "PR is draft; cannot proceed."
  }

  if (Rollup-IsTerminalFailure -RollupState $rollupState) {
    Add-LabelSafe -Name $BlockLabel
    Comment-Safe -Body "Checks are failing (statusCheckRollup=$rollupState). Fix checks before auto-merge. run_id=$RunId"
    throw "Checks failing: $rollupState"
  }

  if (-not $checksOK) {
    # Pending or unknown checks: wait.
    Start-Sleep -Seconds $SleepSeconds
    continue
  }

  switch ($reviewDecision) {
    'APPROVED' {
      # ok
    }
    'REVIEW_REQUIRED' {
      $didApprove = Try-Approve -Actor $actor -Author $author
      if (-not $didApprove) {
        Add-LabelSafe -Name $BlockLabel
        Comment-Safe -Body "Review is required but automation could not approve (actor=$actor author=$author). Please approve manually or adjust branch protection settings. run_id=$RunId"
        throw "Review required but auto-approve not possible."
      }
      # After approving, wait a bit and re-check.
      Start-Sleep -Seconds 10
      Start-Sleep -Seconds $SleepSeconds
      continue
    }
    'CHANGES_REQUESTED' {
      Add-LabelSafe -Name $BlockLabel
      Comment-Safe -Body "Changes were requested on this PR. Please address review comments, then re-run automation. run_id=$RunId"
      throw "Changes requested."
    }
    default {
      # Unknown review state -> fail-closed
      Add-LabelSafe -Name $BlockLabel
      Comment-Safe -Body "Unknown reviewDecision='$reviewDecision'. Please review manually. run_id=$RunId"
      throw "Unknown reviewDecision: $reviewDecision"
    }
  }

  # At this point checks green and approved.
  # mergeStateStatus may still be BLOCKED if something else (e.g. required conversations, merge queue, etc.)
  $enabled = Try-EnableAutoMerge -Method $MergeMethod
  if ($enabled) { exit 0 }

  # If auto-merge couldn't be enabled, classify and block.
  Add-LabelSafe -Name $BlockLabel
  Comment-Safe -Body "Automation could not enable auto-merge (mergeState=$mergeState). Please check branch protection / merge queue / permissions. run_id=$RunId"
  throw "Failed to enable auto-merge. mergeState=$mergeState"
}

Add-LabelSafe -Name $BlockLabel
Comment-Safe -Body "Failed after $MaxAttempts attempts. Please review manually. run_id=$RunId"
throw "Failed after $MaxAttempts attempts."
