#requires -Version 7.0
[CmdletBinding()]
param(
  [Parameter(Mandatory = $false)]
  [string]$Repo,

  [Parameter(Mandatory = $false)]
  [string]$Branch = 'main',

  [Parameter(Mandatory = $false)]
  [string]$WorkflowsDir = '.github/workflows',

  [Parameter(Mandatory = $false)]
  [switch]$FailOnUnknown
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Log {
  param([string]$Message, [ValidateSet('INFO','WARN','ERROR')][string]$Level='INFO')
  $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
  Write-Host ("[{0}][{1}] {2}" -f $ts,$Level,$Message)
}

function Assert-Command {
  param([string]$Name)
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Required command not found: $Name"
  }
}

function Get-RepoFromGit {
  $u = (git remote get-url origin) 2>$null
  if (-not $u) { return $null }
  if ($u -match 'github\.com[:/](?<o>[^/]+)/(?<r>[^/]+?)(?:\.git)?$') {
    return ("{0}/{1}" -f $Matches.o, $Matches.r)
  }
  return $null
}

function Read-WorkflowMeta {
  param([string]$Path)

  $lines = Get-Content -LiteralPath $Path -ErrorAction Stop

  $wfName = $null
  foreach ($l in $lines | Select-Object -First 80) {
    if ($l -match '^\s*name\s*:\s*(.+)\s*$') {
      $wfName = $Matches[1].Trim().Trim('"')
      break
    }
  }

  $hasPR = $false
  $hasPaths = $false

  for ($i = 0; $i -lt $lines.Count; $i++) {
    $l = $lines[$i]
    if ($l -match '^\s*pull_request\s*:') {
      $hasPR = $true
      $jMax = [Math]::Min($i + 10, $lines.Count - 1)
      for ($j = $i; $j -le $jMax; $j++) {
        if ($lines[$j] -match '^\s*(paths|paths-ignore)\s*:') {
          $hasPaths = $true
          break
        }
      }
    }
    if ($l -match 'pull_request') { $hasPR = $true }
  }

  $jobIds = New-Object System.Collections.Generic.List[string]
  $jobNames = New-Object System.Collections.Generic.List[string]
  $inJobs = $false
  $currentJobId = $null

  for ($i = 0; $i -lt $lines.Count; $i++) {
    $l = $lines[$i]
    if ($l -match '^\s*jobs\s*:') { $inJobs = $true; continue }
    if (-not $inJobs) { continue }

    if ($l -match '^\s{2}([A-Za-z0-9_-]+)\s*:\s*$') {
      $currentJobId = $Matches[1]
      if ($currentJobId -and -not $jobIds.Contains($currentJobId)) { $jobIds.Add($currentJobId) }
      continue
    }

    if ($currentJobId -and $l -match '^\s{4}name\s*:\s*(.+)\s*$') {
      $jn = $Matches[1].Trim().Trim('"')
      if ($jn -and -not $jobNames.Contains($jn)) { $jobNames.Add($jn) }
    }

    if ($l -match '^[A-Za-z0-9_-]+\s*:') { break }
  }

  [pscustomobject]@{
    Path           = $Path
    Name           = $wfName
    HasPullRequest = $hasPR
    HasPathsFilter = $hasPaths
    JobIds         = $jobIds
    JobNames       = $jobNames
  }
}

Assert-Command gh
Assert-Command git

if (-not $Repo) { $Repo = $env:GITHUB_REPOSITORY }
if (-not $Repo) { $Repo = Get-RepoFromGit }
if (-not $Repo) { throw "Repo not specified and could not be derived. Provide -Repo OWNER/REPO." }

$reportsDir = Join-Path (Resolve-Path '.').Path '.github/scripts/_reports'
if (-not (Test-Path -LiteralPath $reportsDir)) {
  New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}

Write-Log "Repo=$Repo Branch=$Branch WorkflowsDir=$WorkflowsDir FailOnUnknown=$FailOnUnknown"

$required = $null
try {
  $required = gh api -H "Accept: application/vnd.github+json" "repos/$Repo/branches/$Branch/protection/required_status_checks" | ConvertFrom-Json
} catch {
  Write-Log ("WARN: required_status_checks not accessible. {0}" -f $_.Exception.Message) 'WARN'
  @{ repo=$Repo; branch=$Branch; warnings=@('required_status_checks not accessible') } |
    ConvertTo-Json -Depth 10 |
    Set-Content -LiteralPath (Join-Path $reportsDir 'required_checks_guard_report.json') -Encoding utf8
  exit 0
}

$contexts = @()
if ($required -and $required.contexts) { $contexts = @($required.contexts) }
Write-Log ("Required contexts: {0}" -f $contexts.Count)

$wfMetas = @()
$wfFiles = @()
$wfFiles += Get-ChildItem -LiteralPath $WorkflowsDir -Filter *.yml -File -ErrorAction SilentlyContinue
$wfFiles += Get-ChildItem -LiteralPath $WorkflowsDir -Filter *.yaml -File -ErrorAction SilentlyContinue
$wfFiles = $wfFiles | Sort-Object FullName -Unique

foreach ($f in $wfFiles) {
  try { $wfMetas += Read-WorkflowMeta -Path $f.FullName } catch { }
}

$problems = New-Object System.Collections.Generic.List[object]
$warnings = New-Object System.Collections.Generic.List[string]
$unknown  = New-Object System.Collections.Generic.List[string]

foreach ($ctx in $contexts) {
  $matches = @($wfMetas | Where-Object {
    ($_.Name -and $_.Name -eq $ctx) -or
    ($_.JobIds -and $_.JobIds.Contains($ctx)) -or
    ($_.JobNames -and $_.JobNames.Contains($ctx))
  })

  if ($matches.Count -eq 0) {
    $unknown.Add($ctx) | Out-Null
    continue
  }

  foreach ($m in $matches) {
    if (-not $m.HasPullRequest) {
      $problems.Add([pscustomobject]@{
        required_context = $ctx
        type             = 'missing_pull_request_trigger'
        workflow_path     = $m.Path
      }) | Out-Null
    }
    if ($m.HasPathsFilter) {
      $problems.Add([pscustomobject]@{
        required_context = $ctx
        type             = 'pull_request_paths_filter_present'
        workflow_path     = $m.Path
      }) | Out-Null
    }
  }
}

if ($unknown.Count -gt 0) {
  $warnings.Add(("Unknown contexts: {0}" -f ($unknown -join ', '))) | Out-Null
}

$out = @{
  repo = $Repo
  branch = $Branch
  required_contexts = $contexts
  problems = @($problems)
  warnings = @($warnings)
  unknown_required_contexts = @($unknown)
  generated_at = (Get-Date).ToString('o')
}

($out | ConvertTo-Json -Depth 10) |
  Set-Content -LiteralPath (Join-Path $reportsDir 'required_checks_guard_report.json') -Encoding utf8

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Required Checks Guard Report") | Out-Null
$md.Add("") | Out-Null
$md.Add(("* Repo: `{0}`" -f $Repo)) | Out-Null
$md.Add(("* Branch: `{0}`" -f $Branch)) | Out-Null
$md.Add(("* Required contexts: `{0}`" -f $contexts.Count)) | Out-Null
$md.Add(("* Workflows scanned: `{0}`" -f $wfMetas.Count)) | Out-Null
$md.Add("") | Out-Null

if ($problems.Count -gt 0) {
  $md.Add("## Problems") | Out-Null
  foreach ($p in $problems) {
    $md.Add(("- `{0}`: **{1}** in `{2}`" -f $p.required_context, $p.type, $p.workflow_path)) | Out-Null
  }
  $md.Add("") | Out-Null
} else {
  $md.Add("## Problems") | Out-Null
  $md.Add("- None detected (high-confidence).") | Out-Null
  $md.Add("") | Out-Null
}

if ($warnings.Count -gt 0) {
  $md.Add("## Warnings") | Out-Null
  foreach ($w in $warnings) { $md.Add(("- {0}" -f $w)) | Out-Null }
  $md.Add("") | Out-Null
}

($md -join "`n") |
  Set-Content -LiteralPath (Join-Path $reportsDir 'required_checks_guard_report.md') -Encoding utf8

if ($problems.Count -gt 0) {
  Write-Log ("ERROR: {0} problem(s) detected." -f $problems.Count) 'ERROR'
  exit 1
}

if ($FailOnUnknown -and $unknown.Count -gt 0) {
  Write-Log "ERROR: unknown contexts present and -FailOnUnknown set." 'ERROR'
  exit 1
}

Write-Log "OK: no definite problems detected."
exit 0
