#requires -Version 7.0
param(
  [Parameter(Mandatory)]
  [string]$Repo,

  [Parameter(Mandatory)]
  [int]$PullNumber,

  [Parameter(Mandatory)]
  [string]$RunId,

  [Parameter(Mandatory=$false)]
  [int]$MaxAttempts = 10,

  [Parameter(Mandatory=$false)]
  [int]$SleepSeconds = 30,

  [Parameter(Mandatory=$false)]
  [string]$BotUser = 'mizunotarobot'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Log([string]$Level, [string]$Message) {
  $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
  Write-Host ("[{0}][{1}] {2}" -f $ts, $Level.ToUpperInvariant(), $Message)
}

function Assert-Env([string]$name) {
    $item = Get-Item -Path "Env:$name" -ErrorAction SilentlyContinue
  if (-not $item -or [string]::IsNullOrEmpty($item.Value)) {
    throw "Required env var missing: $name"
  }
}

function Invoke-Json([string[]]$args) {
  $raw = & gh @args 2>&1
  $code = $LASTEXITCODE
  if ($code -ne 0) {
    $msg = ($raw | Out-String).Trim()
    throw ("gh failed (exit={0}): gh {1}`n{2}" -f $code, ($args -join ' '), $msg)
  }
  $txt = ($raw | Out-String)
  $txtStr = if ($txt -is [string]) { $txt } else { ($txt | Out-String) }
$trim = $txtStr.Trim()
if ($trim.Length -eq 0) { throw "Expected JSON but got empty output." }

$trim2 = $trim.TrimStart()
if ($trim2.Length -eq 0) { throw "Expected JSON but got whitespace-only output." }

$first = $trim2[0]
if ($first -ne '{' -and $first -ne '[') {
  $snippet = $trim2.Substring(0, [Math]::Min(300, $trim2.Length))
  throw "Expected JSON but got non-JSON output (first 300 chars): $snippet"
}

return ($trim | ConvertFrom-Json -Depth 100)
}

function Try-Invoke([scriptblock]$Block, [string]$Label) {
  try { & $Block; return $true }
  catch { Write-Log 'WARN' ("{0} failed: {1}" -f $Label, $_.Exception.Message); return $false }
}

function Get-RequiredChecks([string]$repo, [string]$branch) {
  try {
    $rsc = Invoke-Json @('api', "repos/$repo/branches/$branch/protection/required_status_checks")
    $contexts = @()
    if ($rsc.checks) {
      foreach ($c in $rsc.checks) { if ($c.context) { $contexts += [string]$c.context } }
    }
    if ($rsc.contexts) {
      foreach ($c in $rsc.contexts) { $contexts += [string]$c }
    }
    return ($contexts | Sort-Object -Unique)
  } catch {
    Write-Log 'WARN' ("required_status_checks not available (treated as none): {0}" -f $_.Exception.Message)
    return @()
  }
}

function Get-StatusRollup([string]$repo, [int]$pr) {
  return Invoke-Json @('pr','view',"$pr",'-R',"$repo",'--json','isDraft,mergeStateStatus,reviewDecision,author,statusCheckRollup,url')
}

function All-RequiredChecksSuccess($rollupList, [string[]]$required) {
  if (-not $required -or $required.Count -eq 0) { return $true }

  $index = @{}
  foreach ($item in $rollupList) {
    if ($null -ne $item.name) { $index[[string]$item.name] = $item }
  }

  foreach ($ctx in $required) {
    if (-not $index.ContainsKey($ctx)) { return $false }
    $it = $index[$ctx]
    if ($it.status -ne 'COMPLETED') { return $false }
    if ($it.conclusion -ne 'SUCCESS') { return $false }
  }
  return $true
}

function Comment-And-Block([string]$repo, [int]$pr, [string]$msg) {
  Try-Invoke { & gh pr comment "$pr" -R "$repo" -b "$msg" | Out-Null } 'pr comment' | Out-Null
  Try-Invoke { & gh pr edit "$pr" -R "$repo" --add-label "ai:blocked" | Out-Null } 'add label ai:blocked' | Out-Null
}

try {
  Assert-Env 'GH_TOKEN'
  Write-Log 'INFO' ("Repo={0} PR={1} RunId={2} MaxAttempts={3}" -f $Repo, $PullNumber, $RunId, $MaxAttempts)

  $null = & gh --version
  if ($LASTEXITCODE -ne 0) { throw 'gh is not available' }

  $pr0 = Get-StatusRollup $Repo $PullNumber
  if ($pr0.isDraft -eq $true) {
    Write-Log 'INFO' 'PR is draft. Exiting without action.'
    exit 0
  }

  $author = $pr0.author.login
  if ($author -eq $BotUser) {
    $m = "Blocked: PR author is $BotUser, so bot cannot approve its own PR. Ensure PR author is github-actions[bot] (or another actor) and reviewer is $BotUser. run_id=$RunId"
    Write-Log 'ERROR' $m
    Comment-And-Block $Repo $PullNumber $m
    exit 1
  }

  $baseBranch = (Invoke-Json @('pr','view',"$PullNumber",'-R',"$Repo",'--json','baseRefName')).baseRefName
  $required = Get-RequiredChecks $Repo $baseBranch
  Write-Log 'INFO' ("Required checks ({0}): {1}" -f $required.Count, ($required -join ', '))

  $attempt = 0
  while ($attempt -lt $MaxAttempts) {
    $attempt++
    $st = Get-StatusRollup $Repo $PullNumber

    $mergeState = [string]$st.mergeStateStatus
    $reviewDecision = [string]$st.reviewDecision
    $okChecks = All-RequiredChecksSuccess $st.statusCheckRollup $required

    Write-Log 'INFO' ("Attempt {0}/{1}: mergeState={2} reviewDecision={3} checksOK={4}" -f $attempt, $MaxAttempts, $mergeState, $reviewDecision, $okChecks)

    if ($okChecks -and $mergeState -ne 'BLOCKED') {
      Try-Invoke {
        & gh pr review "$PullNumber" -R "$Repo" --approve --body ("Approved by {0}. run_id={1}" -f $BotUser, $RunId) | Out-Null
      } 'approve' | Out-Null

      $merged = $false
      foreach ($strategy in @('squash','merge','rebase')) {
        if ($merged) { break }
        $label = "merge --auto --$strategy"
        $merged = Try-Invoke {
          $args = @('pr','merge',"$PullNumber",'-R',"$Repo",'--auto',("--" + $strategy),'--delete-branch')
          & gh @args | Out-Null
        } $label
      }

      if ($merged) {
        Write-Log 'INFO' 'Auto-merge enabled (or merge queued). Done.'
        exit 0
      }

      Write-Log 'WARN' 'Could not enable auto-merge yet. Will retry.'
    }

    Start-Sleep -Seconds $SleepSeconds
  }

  $finalMsg = "Failed after {0} attempts. Please review manually. run_id={1}" -f $MaxAttempts, $RunId
  Write-Log 'ERROR' $finalMsg
  Comment-And-Block $Repo $PullNumber $finalMsg
  exit 1

} catch {
  Write-Log 'ERROR' $_.Exception.Message
  Write-Log 'ERROR' $_.ScriptStackTrace
  try {
    Comment-And-Block $Repo $PullNumber ("Exception: {0} run_id={1}" -f $_.Exception.Message, $RunId)
  } catch { }
  throw
}
