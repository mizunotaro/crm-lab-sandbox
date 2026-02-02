param(
  [Parameter(Mandatory=$false)]
  [string]$SnapshotsRoot = "ops/snapshots"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$OutDir = Get-ChildItem -Directory -Path $SnapshotsRoot |
  Where-Object Name -like "issue_quality_*" |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1 -ExpandProperty FullName

if (-not $OutDir) { throw "No snapshot directory found under: $SnapshotsRoot" }

$Files = Get-ChildItem -Path $OutDir -Filter "issue_*.md" | Sort-Object Name

function Test-HasAny($Text, [string[]]$Patterns) {
  foreach ($p in $Patterns) { if ($Text -match $p) { return $true } }
  return $false
}

$results = foreach ($f in $Files) {
  $t = Get-Content -Raw -Encoding UTF8 $f.FullName

  $hasAC = Test-HasAny $t @(
    "(?im)^\s*#+\s*Acceptance\s*Criteria\b",
    "(?im)^\s*-\s*Acceptance\s*Criteria\s*:",
    "(?im)\bAcceptance\s*Criteria\b",
    "(?im)\bAC\b",
    "(?im)受け入れ基準"
  )
  $hasVerify = Test-HasAny $t @(
    "(?im)^\s*#+\s*Verification\b",
    "(?im)^\s*-\s*Verification\s*Steps\s*:",
    "(?im)\bVerification\s*Steps\b",
    "(?im)\bVerify\b",
    "(?im)検証手順"
  )
  $hasRollback = Test-HasAny $t @(
    "(?im)\bRollback\b",
    "(?im)^\s*-\s*Risk\s*/\s*Rollback\s*:",
    "(?im)\bRisk\s*/\s*Rollback\b",
    "(?im)ロールバック",
    "(?im)リスク"
  )

  [pscustomobject]@{
    Issue = [int]([regex]::Match($f.BaseName, "\d+").Value)
    File  = $f.Name
    HasAC = $hasAC
    HasVerify = $hasVerify
    HasRollback = $hasRollback
    Missing = (@(
      if (-not $hasAC) { "AC" }
      if (-not $hasVerify) { "Verify" }
      if (-not $hasRollback) { "Rollback" }
    ) -join ",")
  }
}

$csvPath = Join-Path $OutDir "issue_quality_report.csv"
$results | Export-Csv -NoTypeInformation -Encoding UTF8 $csvPath

$mdPath = Join-Path $OutDir "issue_quality_report.md"
$lines = @(
  "# Issue Quality Report"
  ""
  "| Issue | HasAC | HasVerify | HasRollback | Missing |"
  "|---:|:---:|:---:|:---:|---|"
)
foreach ($r in $results) {
  $lines += "| $($r.Issue) | $($r.HasAC) | $($r.HasVerify) | $($r.HasRollback) | $($r.Missing) |"
}
$lines | Set-Content -Encoding UTF8 $mdPath

$results | Format-Table -AutoSize
Write-Host "Report:"
Write-Host " - $csvPath"
Write-Host " - $mdPath"

# CI向け: 欠落があれば exit 1（任意）
# if ($results | Where-Object { $_.Missing }) { exit 1 }
