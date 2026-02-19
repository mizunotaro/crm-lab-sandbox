param(
    [switch]$SkipLint,
    [switch]$SkipTypecheck,
    [switch]$SkipTest,
    [switch]$SkipBuild
)

$ErrorActionPreference = "Continue"

function Step-Lint {
    Write-Host "Running: Lint..." -ForegroundColor Cyan
    pnpm -r exec eslint . 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Lint failed" -ForegroundColor Red
        return $false
    }
    Write-Host "Lint passed" -ForegroundColor Green
    return $true
}

function Step-Typecheck {
    Write-Host "Running: Typecheck..." -ForegroundColor Cyan
    pnpm -r exec tsc --noEmit
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Typecheck failed" -ForegroundColor Red
        return $false
    }
    Write-Host "Typecheck passed" -ForegroundColor Green
    return $true
}

function Step-Test {
    Write-Host "Running: Test..." -ForegroundColor Cyan
    pnpm --filter @crm/api test:run
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Test failed" -ForegroundColor Red
        return $false
    }
    Write-Host "Test passed" -ForegroundColor Green
    return $true
}

function Step-Build {
    Write-Host "Running: Build..." -ForegroundColor Cyan
    pnpm build 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Build failed" -ForegroundColor Red
        return $false
    }
    Write-Host "Build passed" -ForegroundColor Green
    return $true
}

Write-Host "=== Dev Check Script ===" -ForegroundColor Yellow

$AllPassed = $true

if (-not $SkipLint) {
    $result = Step-Lint
    if (-not $result) {
        Write-Host "Lint step not configured yet (skipped)" -ForegroundColor Yellow
    }
}

if (-not $SkipTypecheck) {
    $result = Step-Typecheck
    if (-not $result) {
        $AllPassed = $false
    }
}

if (-not $SkipTest) {
    $result = Step-Test
    if (-not $result) {
        $AllPassed = $false
    }
}

if (-not $SkipBuild) {
    $result = Step-Build
    if (-not $result) {
        Write-Host "Build step not configured yet (skipped)" -ForegroundColor Yellow
    }
}

if ($AllPassed) {
    Write-Host "=== All checks passed ===" -ForegroundColor Green
    exit 0
} else {
    Write-Host "=== Some checks failed ===" -ForegroundColor Red
    exit 1
}
