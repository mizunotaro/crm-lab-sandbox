param(
  [Parameter(Mandatory=$false)]
  [string]$Repo = "mizunotaro/crm-lab-sandbox",

  [Parameter(Mandatory=$false)]
  [int]$StartIssue = 181,

  [Parameter(Mandatory=$false)]
  [int]$EndIssue = 188,

  [Parameter(Mandatory=$false)]
  [string]$SnapshotsRoot = "ops/snapshots"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Issues = $StartIssue..$EndIssue
$Ts = Get-Date -Format "yyyyMMdd_HHmmss"
$OutDir = Join-Path (Get-Location) ("{0}/issue_quality_{1}" -f $SnapshotsRoot, $Ts)
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$items = foreach ($n in $Issues) {
  gh issue view $n -R $Repo --json number,title,url,labels,body,createdAt,updatedAt |
    ConvertFrom-Json
}

$items | ConvertTo-Json -Depth 20 |
  Set-Content -Encoding UTF8 (Join-Path $OutDir ("issues_{0}_{1}.json" -f $StartIssue, $EndIssue))

foreach ($it in $items) {
  $path = Join-Path $OutDir ("issue_{0}.md" -f $it.number)
  @(
    "# $($it.title)"
    ""
    "URL: $($it.url)"
    "UpdatedAt: $($it.updatedAt)"
    "Labels: " + (($it.labels.name) -join ", ")
    ""
    $it.body
  ) | Set-Content -Encoding UTF8 $path
}

Write-Host "Saved to: $OutDir"
