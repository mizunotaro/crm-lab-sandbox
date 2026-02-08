#requires -Version 7.0
<#
New-AIProbePR.ps1 (fixed v2)
Purpose:
- Create a small, safe PR while preventing "zero-diff PR" accidents.
- Stages ONLY explicit paths (no accidental _probe/ logs / backups).
- Fails fast if there are no staged changes or no commits vs base.

Key fixes vs v1:
- Avoid the ambiguous parameter name '$Args' and bind git arguments by name.
- Add explicit debug output of the git command being executed (without secrets).

Notes:
- Does NOT run destructive cleanup (no git clean).
- Does NOT print secrets.
#>

[CmdletBinding(PositionalBinding=$false)]
param(
  [Parameter()][ValidateNotNullOrEmpty()][string]$RepoRoot = (Get-Location).Path,
  [Parameter()][ValidateNotNullOrEmpty()][string]$Branch = '',
  [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Title,
  [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Body,

  # Stage only these paths. Relative to RepoRoot.
  [Parameter()][string[]]$PathsToAdd = @(
    '.gitignore',
    'ops/scripts/probe-opencode.ps1',
    'ops/scripts/RUN_probe-opencode.safe.ps1',
    'ops/scripts/RUN_probe-opencode.local.ps1',
    'ops/scripts/New-AIProbePR.ps1'
  ),

  # Prefer origin/main if present; will fallback to local main/master.
  [Parameter()][ValidateNotNullOrEmpty()][string]$BaseRef = 'origin/main'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-Command([string]$Name) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Required command not found: $Name"
  }
}

function Invoke-Git {
  [CmdletBinding(PositionalBinding=$false)]
  param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string[]]$GitArgs
  )
  # Debug (safe): show only the command and args
  Write-Host ("git {0}" -f ($GitArgs -join ' '))
  & git @GitArgs
  if ($LASTEXITCODE -ne 0) {
    throw ("git {0} failed (exit={1})" -f ($GitArgs -join ' '), $LASTEXITCODE)
  }
}

function Test-GitRef([string]$Ref) {
  & git show-ref --verify --quiet $Ref
  return ($LASTEXITCODE -eq 0)
}

function Get-RepoTop() {
  $top = & git rev-parse --show-toplevel
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($top)) {
    throw "Not a git repository (git rev-parse --show-toplevel failed)."
  }
  return $top.Trim()
}

function Ensure-Branch([string]$Name) {
  if ([string]::IsNullOrWhiteSpace($Name)) {
    $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
    return ("chore/opencode-probe-{0}" -f $ts)
  }
  return $Name
}

function Switch-Or-CreateBranch([string]$Name) {
  if ([string]::IsNullOrWhiteSpace($Name)) { throw "Branch name is empty." }

  & git show-ref --verify --quiet ("refs/heads/{0}" -f $Name)
  if ($LASTEXITCODE -eq 0) {
    Invoke-Git -GitArgs @('switch', $Name)
    return
  }

  # If remote branch exists, create local tracking branch
  & git show-ref --verify --quiet ("refs/remotes/origin/{0}" -f $Name)
  if ($LASTEXITCODE -eq 0) {
    Invoke-Git -GitArgs @('switch', '--track', ("origin/{0}" -f $Name))
    return
  }

  Invoke-Git -GitArgs @('switch', '-c', $Name)
}

function Stage-ExplicitPaths([string]$Root, [string[]]$RelPaths) {
  foreach ($rp in @($RelPaths)) {
    if ([string]::IsNullOrWhiteSpace($rp)) { continue }
    $full = Join-Path $Root $rp
    if (Test-Path -LiteralPath $full) {
      Invoke-Git -GitArgs @('add', '--', $rp)
    } else {
      Write-Host ("SKIP (not found): {0}" -f $rp)
    }
  }

  $names = & git diff --cached --name-only
  if ($LASTEXITCODE -ne 0) { throw "git diff --cached failed." }
  if (-not $names -or $names.Count -eq 0) {
    throw "No staged changes. Abort (zero-diff PR prevention)."
  }
}

function Ensure-BaseRef([string]$Ref) {
  # Accept either:
  # - 'refs/remotes/origin/main' style (show-ref verify)
  # - or 'origin/main' style in rev-parse
  $refVerify = $Ref
  if ($Ref -eq 'origin/main')   { $refVerify = 'refs/remotes/origin/main' }
  if ($Ref -eq 'origin/master') { $refVerify = 'refs/remotes/origin/master' }

  if (Test-GitRef $refVerify) { return $Ref }

  # Fallback to local main/master
  if (Test-GitRef 'refs/heads/main') { return 'main' }
  if (Test-GitRef 'refs/heads/master') { return 'master' }

  throw "Base ref not found: $Ref (and no local main/master). Run 'git fetch origin' and try again."
}

function Ensure-CommitsVsBase([string]$Base) {
  $cnt = & git rev-list --count ("{0}..HEAD" -f $Base)
  if ($LASTEXITCODE -ne 0) { throw "git rev-list failed for base: $Base" }
  if ([int]$cnt -le 0) { throw "No commits between $Base and HEAD. Abort (zero-diff PR prevention)." }
}

function Ensure-GhAuth() {
  & gh auth status
  if ($LASTEXITCODE -ne 0) {
    throw "gh auth status failed. Please authenticate: gh auth login"
  }
}

function Create-Or-ShowPR([string]$Br, [string]$T, [string]$B) {
  $existing = & gh pr view --head $Br --json url -q ".url" 2>$null
  if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($existing)) {
    Write-Host ("PR already exists: {0}" -f $existing.Trim())
    return
  }

  $url = & gh pr create --title $T --body $B --head $Br
  if ($LASTEXITCODE -ne 0) { throw "gh pr create failed." }
  Write-Host ("PR created: {0}" -f $url.Trim())
}

# ---- main ----
Assert-Command git
Assert-Command gh

if (-not (Test-Path -LiteralPath $RepoRoot)) { throw "RepoRoot not found: $RepoRoot" }
Set-Location -LiteralPath $RepoRoot

# Verify repo root
$top = Get-RepoTop
$resolved = (Resolve-Path -LiteralPath $RepoRoot).Path
if ($top -ne $resolved) {
  Write-Host ("WARN: RepoRoot differs from git top-level. Using: {0}" -f $top)
  Set-Location -LiteralPath $top
  $RepoRoot = $top
}

# Ensure base ref exists (fetch is not automatic to avoid network surprises)
$BaseRef = Ensure-BaseRef $BaseRef

# Decide branch name
$Branch = Ensure-Branch $Branch

# Switch/create branch
Switch-Or-CreateBranch $Branch

# Stage explicit paths only
Stage-ExplicitPaths -Root $RepoRoot -RelPaths $PathsToAdd

# Commit
Invoke-Git -GitArgs @('commit', '-m', $Title)

# Push
Invoke-Git -GitArgs @('push', '-u', 'origin', $Branch)

# Prevent zero-diff PR
Ensure-CommitsVsBase $BaseRef

# GH auth check + create PR
Ensure-GhAuth
Create-Or-ShowPR -Br $Branch -T $Title -B $Body
