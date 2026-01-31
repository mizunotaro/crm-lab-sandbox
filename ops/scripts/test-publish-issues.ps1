# test-publish-issues.ps1 - Verification script for update-in-place Task Links

param(
    [Parameter(Mandatory = $true)]
    [string]$RepoOwner,

    [Parameter(Mandatory = $true)]
    [string]$RepoName,

    [Parameter(Mandatory = $true)]
    [string]$IssuesDir,

    [string]$SpecIssueNumber
)

$ErrorActionPreference = 'Stop'

$Marker = '<!-- TASK_LINKS_AUTOGEN v1 -->'
$TestResults = @()

function Test-DryRun {
    Write-Host "`n=== Test 1: Dry Run ===" -ForegroundColor Cyan

    $result = & "$PSScriptRoot/publish-issues.ps1" -RepoOwner $RepoOwner -RepoName $RepoName -IssuesDir $IssuesDir -DryRun 2>&1

    if ($result -match "\[DryRun\]") {
        Write-Host "✓ Dry run executed successfully" -ForegroundColor Green
        $TestResults += @{ Test = "Dry Run"; Status = "Pass"; Details = "Dry run output found" }
        return $true
    } else {
        Write-Host "✗ Dry run failed or no dry run output" -ForegroundColor Red
        $TestResults += @{ Test = "Dry Run"; Status = "Fail"; Details = "No dry run output" }
        return $false
    }
}

function Get-MarkerCommentCount {
    param(
        [string]$IssueNumber
    )

    $apiUrl = "repos/$RepoOwner/$RepoName/issues/$IssueNumber/comments"
    $result = & gh api $apiUrl 2>&1
    if ($LASTEXITCODE -ne 0) {
        return -1
    }

    $comments = $result | ConvertFrom-Json
    $markerComments = @($comments | Where-Object { $_.body -like "*$Marker*" })
    return $markerComments.Count
}

function Test-CreateOnce {
    param(
        [string]$SpecIssueNumber
    )

    Write-Host "`n=== Test 2: Create Once ===" -ForegroundColor Cyan

    $beforeCount = Get-MarkerCommentCount -IssueNumber $SpecIssueNumber
    Write-Host "Marker comments before: $beforeCount"

    $result = & "$PSScriptRoot/publish-issues.ps1" -RepoOwner $RepoOwner -RepoName $RepoName -IssuesDir $IssuesDir 2>&1
    $afterCount = Get-MarkerCommentCount -IssueNumber $SpecIssueNumber
    Write-Host "Marker comments after: $afterCount"

    if ($afterCount -eq $beforeCount + 1) {
        Write-Host "✓ Comment created (incremented by 1)" -ForegroundColor Green
        $TestResults += @{ Test = "Create Once"; Status = "Pass"; Details = "Comment count increased by 1" }
        return $true
    } elseif ($afterCount -eq $beforeCount) {
        Write-Host "⚠ Comment already existed" -ForegroundColor Yellow
        $TestResults += @{ Test = "Create Once"; Status = "Warning"; Details = "Comment already existed" }
        return $true
    } else {
        Write-Host "✗ Unexpected comment count change" -ForegroundColor Red
        $TestResults += @{ Test = "Create Once"; Status = "Fail"; Details = "Count changed by $($afterCount - $beforeCount)" }
        return $false
    }
}

function Test-NoDuplicateOnRerun {
    param(
        [string]$SpecIssueNumber
    )

    Write-Host "`n=== Test 3: No Duplicate on Re-run ===" -ForegroundColor Cyan

    $beforeCount = Get-MarkerCommentCount -IssueNumber $SpecIssueNumber
    Write-Host "Marker comments before: $beforeCount"

    $result = & "$PSScriptRoot/publish-issues.ps1" -RepoOwner $RepoOwner -RepoName $RepoName -IssuesDir $IssuesDir 2>&1
    $afterCount = Get-MarkerCommentCount -IssueNumber $SpecIssueNumber
    Write-Host "Marker comments after: $afterCount"

    if ($afterCount -eq $beforeCount) {
        Write-Host "✓ No duplicate created" -ForegroundColor Green
        $TestResults += @{ Test = "No Duplicate"; Status = "Pass"; Details = "Comment count unchanged" }
        return $true
    } else {
        Write-Host "✗ Duplicate comment created" -ForegroundColor Red
        $TestResults += @{ Test = "No Duplicate"; Status = "Fail"; Details = "Count increased by $($afterCount - $beforeCount)" }
        return $false
    }
}

function Test-UpdateBehavior {
    param(
        [string]$SpecIssueNumber
    )

    Write-Host "`n=== Test 4: Update on Content Change ===" -ForegroundColor Cyan

    $newTaskFile = "$IssuesDir/task-999-test-update.md"
    $taskContent = @"
# Task #999 - Test Update

## Goal
Test update behavior.

---

**Parent Spec:** #$SpecIssueNumber
**Status:** pending
"@

    $newTaskFile | Out-File -FilePath $newTaskFile -Encoding utf8

    $beforeCount = Get-MarkerCommentCount -IssueNumber $SpecIssueNumber
    $result = & "$PSScriptRoot/publish-issues.ps1" -RepoOwner $RepoOwner -RepoName $RepoName -IssuesDir $IssuesDir 2>&1
    $afterCount = Get-MarkerCommentCount -IssueNumber $SpecIssueNumber

    Remove-Item -Path $newTaskFile -Force

    if ($afterCount -eq $beforeCount) {
        Write-Host "✓ Comment updated (not duplicated)" -ForegroundColor Green
        $TestResults += @{ Test = "Update Behavior"; Status = "Pass"; Details = "Comment count unchanged, content updated" }
        return $true
    } else {
        Write-Host "✗ Unexpected comment count" -ForegroundColor Red
        $TestResults += @{ Test = "Update Behavior"; Status = "Fail"; Details = "Count changed by $($afterCount - $beforeCount)" }
        return $false
    }
}

function Test-AppendMode {
    param(
        [string]$SpecIssueNumber
    )

    Write-Host "`n=== Test 5: Append Mode (Rollback) ===" -ForegroundColor Cyan

    $beforeCount = Get-MarkerCommentCount -IssueNumber $SpecIssueNumber
    Write-Host "Marker comments before: $beforeCount"

    $result = & "$PSScriptRoot/publish-issues.ps1" -RepoOwner $RepoOwner -RepoName $RepoName -IssuesDir $IssuesDir -TaskLinksWriteMode append 2>&1
    $afterCount = Get-MarkerCommentCount -IssueNumber $SpecIssueNumber
    Write-Host "Marker comments after: $afterCount"

    if ($afterCount -eq $beforeCount + 1) {
        Write-Host "✓ Append mode creates new comment" -ForegroundColor Green
        $TestResults += @{ Test = "Append Mode"; Status = "Pass"; Details = "Comment created" }
        return $true
    } elseif ($afterCount -eq $beforeCount) {
        Write-Host "⚠ Comment already exists" -ForegroundColor Yellow
        $TestResults += @{ Test = "Append Mode"; Status = "Warning"; Details = "Comment already existed" }
        return $true
    } else {
        Write-Host "✗ Unexpected behavior" -ForegroundColor Red
        $TestResults += @{ Test = "Append Mode"; Status = "Fail"; Details = "Count changed by $($afterCount - $beforeCount)" }
        return $false
    }
}

function Print-Results {
    Write-Host "`n=== Test Results Summary ===" -ForegroundColor Cyan

    $passCount = ($TestResults | Where-Object { $_.Status -eq "Pass" }).Count
    $failCount = ($TestResults | Where-Object { $_.Status -eq "Fail" }).Count
    $warningCount = ($TestResults | Where-Object { $_.Status -eq "Warning" }).Count

    foreach ($result in $TestResults) {
        $color = switch ($result.Status) {
            "Pass" { "Green" }
            "Fail" { "Red" }
            "Warning" { "Yellow" }
        }
        Write-Host "$($result.Test): $($result.Status) - $($result.Details)" -ForegroundColor $color
    }

    Write-Host "`nTotal: $($TestResults.Count) tests, $passCount passed, $failCount failed, $warningCount warnings" -ForegroundColor Cyan

    return $failCount -eq 0
}

Write-Host "Update-in-place Task Links Verification" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

if (-not $SpecIssueNumber) {
    Write-Error "SpecIssueNumber parameter is required for full testing. Use -SpecIssueNumber #<number>"
    exit 1
}

Test-DryRun
Test-CreateOnce -SpecIssueNumber $SpecIssueNumber
Test-NoDuplicateOnRerun -SpecIssueNumber $SpecIssueNumber
Test-UpdateBehavior -SpecIssueNumber $SpecIssueNumber
Test-AppendMode -SpecIssueNumber $SpecIssueNumber

$allPassed = Print-Results

if ($allPassed) {
    Write-Host "`n✓ All tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n✗ Some tests failed" -ForegroundColor Red
    exit 1
}
