# check-ai-prereqs.ps1 - Preflight check for AI automation prerequisites

param(
    [Parameter(Mandatory = $true)]
    [string]$Repo,

    [string]$ConfigPath = "$PSScriptRoot/check-ai-prereqs.config.json",

    [switch]$JsonOnly
)

$ErrorActionPreference = 'Stop'

# Default configuration (can be overridden by config file)
$defaultConfig = @{
    labels = @(
        'ai:ready',
        'ai:blocked',
        'ai:in-progress',
        'ai:triage',
        'ai:approved',
        'ai:risky-change',
        'ai:deps',
        'ai:pr-open'
    )
    secrets = @(
        'ZAI_API_KEY',
        'ZHIPU_API_KEY'
    )
    variables = @()
}

# Load configuration if file exists
if (Test-Path $ConfigPath) {
    $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
} else {
    $config = $defaultConfig
}

# Helper function to check if a string matches a pattern
function Test-ItemMatch {
    param(
        [string[]]$required,
        [string[]]$existing
    )

    $missing = @()
    foreach ($item in $required) {
        if ($item -notin $existing) {
            $missing += $item
        }
    }

    return $missing
}

# Initialize result
$result = @{
    timestamp = (Get-Date).ToUniversalTime().ToString('o')
    repo = $Repo
    checks = @{}
    status = 'pass'
    summary = ''
}

# Check labels
Write-Host "Checking labels..." -ForegroundColor Cyan
$labelCheck = & gh label list --repo $Repo --json name --jq '.[].name' 2>&1
if ($LASTEXITCODE -eq 0) {
    $existingLabels = $labelCheck -split "`n" | Where-Object { $_ -ne '' }
    $missingLabels = Test-ItemMatch -required $config.labels -existing $existingLabels

    $result.checks.labels = @{
        required = $config.labels
        existing = $existingLabels
        missing = $missingLabels
        status = if ($missingLabels.Count -gt 0) { 'fail' } else { 'pass' }
    }

    if ($missingLabels.Count -gt 0) {
        Write-Host "  FAIL: Missing labels: $($missingLabels -join ', ')" -ForegroundColor Red
    } else {
        Write-Host "  PASS: All required labels exist" -ForegroundColor Green
    }
} else {
    $result.checks.labels = @{
        required = $config.labels
        existing = @()
        missing = $config.labels
        status = 'error'
        error = "$labelCheck"
    }
    Write-Host "  ERROR: Failed to list labels: $labelCheck" -ForegroundColor Red
}

# Check secrets (names only, not values)
Write-Host "`nChecking secrets (names only)..." -ForegroundColor Cyan
$secretCheck = & gh secret list --repo $Repo 2>&1
if ($LASTEXITCODE -eq 0) {
    $existingSecrets = $secretCheck -split "`n" | Where-Object { $_ -ne '' } | ForEach-Object { ($_ -split '\s+')[0] }
    $missingSecrets = Test-ItemMatch -required $config.secrets -existing $existingSecrets

    $result.checks.secrets = @{
        required = $config.secrets
        existing = $existingSecrets
        missing = $missingSecrets
        status = if ($missingSecrets.Count -gt 0) { 'fail' } else { 'pass' }
    }

    if ($missingSecrets.Count -gt 0) {
        Write-Host "  FAIL: Missing secrets: $($missingSecrets -join ', ')" -ForegroundColor Red
    } else {
        Write-Host "  PASS: All required secrets exist" -ForegroundColor Green
    }
} else {
    $result.checks.secrets = @{
        required = $config.secrets
        existing = @()
        missing = $config.secrets
        status = 'error'
        error = "$secretCheck"
    }
    Write-Host "  ERROR: Failed to list secrets (may need additional permissions): $secretCheck" -ForegroundColor Yellow
}

# Check variables
Write-Host "`nChecking variables..." -ForegroundColor Cyan
$variableCheck = & gh variable list --repo $Repo 2>&1
if ($LASTEXITCODE -eq 0) {
    $existingVariables = $variableCheck -split "`n" | Where-Object { $_ -ne '' } | ForEach-Object { ($_ -split '\s+')[0] }
    $missingVariables = Test-ItemMatch -required $config.variables -existing $existingVariables

    $result.checks.variables = @{
        required = $config.variables
        existing = $existingVariables
        missing = $missingVariables
        status = if ($missingVariables.Count -gt 0) { 'fail' } else { 'pass' }
    }

    if ($missingVariables.Count -gt 0) {
        Write-Host "  FAIL: Missing variables: $($missingVariables -join ', ')" -ForegroundColor Red
    } else {
        Write-Host "  PASS: All required variables exist" -ForegroundColor Green
    }
} else {
    $result.checks.variables = @{
        required = $config.variables
        existing = @()
        missing = $config.variables
        status = 'error'
        error = "$variableCheck"
    }
    Write-Host "  ERROR: Failed to list variables (may need additional permissions): $variableCheck" -ForegroundColor Yellow
}

# Determine overall status
$hasErrors = $result.checks.values | Where-Object { $_.status -eq 'error' }
$hasFailures = $result.checks.values | Where-Object { $_.status -eq 'fail' }

if ($hasErrors) {
    $result.status = 'error'
    $result.summary = 'Preflight check completed with errors (permission issues or API errors)'
    $exitCode = 1
} elseif ($hasFailures) {
    $result.status = 'fail'
    $missingItems = @()
    if ($result.checks.labels.missing.Count -gt 0) { $missingItems += "$($result.checks.labels.missing.Count) labels" }
    if ($result.checks.secrets.missing.Count -gt 0) { $missingItems += "$($result.checks.secrets.missing.Count) secrets" }
    if ($result.checks.variables.missing.Count -gt 0) { $missingItems += "$($result.checks.variables.missing.Count) variables" }
    $result.summary = "Preflight check failed: missing $($missingItems -join ', ')"
    $exitCode = 1
} else {
    $result.status = 'pass'
    $result.summary = 'Preflight check passed: all prerequisites found'
    $exitCode = 0
}

# Create log directory
$logDir = "$PSScriptRoot/../logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Write JSON output
$logFile = "$logDir/ai-prereqs-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$result | ConvertTo-Json -Depth 10 | Out-File -FilePath $logFile -Encoding UTF8

Write-Host "`nJSON report written to: $logFile" -ForegroundColor Cyan

# Print human-readable summary if not JSON-only mode
if (-not $JsonOnly) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "PREFLIGHT CHECK SUMMARY" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Repo: $($result.repo)" -ForegroundColor White
    Write-Host "Timestamp: $($result.timestamp)" -ForegroundColor White
    Write-Host "Status: " -NoNewline -ForegroundColor White
    if ($result.status -eq 'pass') {
        Write-Host "PASS" -ForegroundColor Green
    } elseif ($result.status -eq 'fail') {
        Write-Host "FAIL" -ForegroundColor Red
    } else {
        Write-Host "ERROR" -ForegroundColor Yellow
    }
    Write-Host "Summary: $($result.summary)" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
}

exit $exitCode
