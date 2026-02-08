#requires -Version 7.0
<#
probe-opencode.ps1
Purpose:
  - Static + minimal dynamic probing for OpenCode on Windows/PowerShell 7
  - Robust against npm shims (opencode.ps1/opencode.cmd)
  - Always produces summary.json (PASS/FAIL) with classified reason
  - Model fallback via -ModelCandidates (recommended)

Security:
  - Never prints secret values (only presence/length)
  - Writes stdout/stderr to files under OutDir for triage
#>

param(
  # Recommended: provide explicit ordered candidates (first successful wins)
  [Parameter()][string[]]$ModelCandidates = @(),


  # When invoking via `pwsh -File`, pass candidates as a single string and let the script split it.
  # Examples: \"a,b\" or \"a b\" or \"'a','b'\".
  [Parameter()][string]$ModelCandidatesCsv = '',

  # Backward-compat (if ModelCandidates not provided)
  [Parameter()][string]$Model = '',
  [Parameter()][string]$FallbackModel = 'zai-coding-plan/glm-4.6',

  [Parameter()][ValidateRange(10, 1800)][int]$TimeoutSeconds = 60,

  [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$OutDir,

  [Parameter()][ValidateSet('None','Npm')][string]$InstallIfMissing = 'None',
  [Parameter()][string]$OpenCodeNpmVersion = '1.1.44',

  [Parameter()][switch]$SkipModelRefresh,

  [Parameter()][ValidateSet('INFO','DEBUG','WARN','ERROR')][string]$LogLevel = 'INFO',

  # Probe prompts: try in order, first that yields acceptable output wins
  [Parameter()][string[]]$Prompts = @(
    'Return only OK. No other words.',
    '日本語で「了解」だけ返して。他の文字は禁止。'
  )
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-Dir {
  param([Parameter(Mandatory)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

function Write-Utf8File {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter()][AllowNull()][string]$Text
  )
  $dir = Split-Path -Parent $Path
  if (-not [string]::IsNullOrWhiteSpace($dir)) { New-Dir -Path $dir }
  Set-Content -LiteralPath $Path -Value $Text -Encoding utf8NoBOM
}

function Get-EnvValue {
  param([Parameter(Mandatory)][string]$Name)
  return [System.Environment]::GetEnvironmentVariable($Name)
}

function Get-EnvPresence {
  param([Parameter(Mandatory)][string]$Name)
  $v = Get-EnvValue -Name $Name
  if ([string]::IsNullOrWhiteSpace([string]$v)) { return 'MISSING' }
  return ('PRESENT(len={0})' -f ([string]$v).Length)
}

function Normalize-ModelCandidatesCsv([AllowNull()][string]$Text) {
  if ([string]::IsNullOrWhiteSpace($Text)) { return @() }

  $s = $Text.Trim()

  # strip one layer of surrounding quotes
  if (($s.StartsWith("'") -and $s.EndsWith("'")) -or ($s.StartsWith('"') -and $s.EndsWith('"'))) {
    $s = $s.Substring(1, $s.Length - 2).Trim()
  }

  # if it looks like "'a','b'" keep splitting by comma first
  $parts = @()

  if ($s -match ',') {
    $parts = @(
      ($s -split ',') |
        ForEach-Object { $_.Trim() } |
        ForEach-Object {
          $t = $_
          if (($t.StartsWith("'") -and $t.EndsWith("'")) -or ($t.StartsWith('"') -and $t.EndsWith('"'))) {
            $t = $t.Substring(1, $t.Length - 2)
          }
          $t.Trim()
        } |
        Where-Object { $_ -ne '' }
    )
    return $parts
  }

  # otherwise split by whitespace (for "a b")
  $parts = @(
    ($s -split '\s+') |
      ForEach-Object { $_.Trim() } |
      Where-Object { $_ -ne '' }
  )
  return $parts
}

function Sanitize-FileToken {
  param([Parameter(Mandatory)][string]$Text)
  return ($Text -replace '[^a-zA-Z0-9_.-]+','_')
}

function Invoke-Proc {
  param(
    [Parameter(Mandatory)][string]$FilePath,
    [Parameter()][string[]]$Args = @(),

    # Back-compat aliases (some earlier versions used these names)
    [Alias('TimeoutSec')][Parameter(Mandatory)][int]$TimeoutSeconds,
    [Parameter(Mandatory)][string]$StdoutPath,
    [Parameter(Mandatory)][string]$StderrPath,

    [Parameter()][hashtable]$ExtraEnv = @{},
    [Parameter()][string]$WorkingDirectory = ''
  )

  $exe  = $FilePath
  $argv = @($Args)

  # npm global installs may resolve to opencode.ps1 or opencode.cmd
  if ($FilePath.ToLowerInvariant().EndsWith('.ps1')) {
    $pwsh = (Get-Command pwsh -ErrorAction Stop).Source
    $exe  = $pwsh
    $argv = @('-NoProfile','-ExecutionPolicy','Bypass','-File', $FilePath) + @($Args)
  }
  elseif ($FilePath -match '\.(cmd|bat)$') {
    $cmdExe = if ($env:ComSpec) { $env:ComSpec } else { 'cmd.exe' }
    $exe  = $cmdExe
    $argv = @('/d','/s','/c', $FilePath) + @($Args)
  }

  $psi = [System.Diagnostics.ProcessStartInfo]::new()
  $psi.FileName               = $exe
  foreach ($a in $argv) { [void]$psi.ArgumentList.Add($a) }
  $psi.UseShellExecute        = $false
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError  = $true
  $psi.CreateNoWindow         = $true
  $psi.WorkingDirectory       = if (-not [string]::IsNullOrWhiteSpace($WorkingDirectory)) { $WorkingDirectory } else { (Get-Location).Path }

  foreach ($k in $ExtraEnv.Keys) {
    $v = $ExtraEnv[$k]
    if ($null -ne $v -and -not [string]::IsNullOrEmpty([string]$v)) {
      $psi.Environment[$k] = [string]$v
    }
  }

  $p = [System.Diagnostics.Process]::new()
  $p.StartInfo = $psi
  if (-not $p.Start()) { throw "Failed to start process: $exe" }

  $stdoutTask = $p.StandardOutput.ReadToEndAsync()
  $stderrTask = $p.StandardError.ReadToEndAsync()

  $timedOut = -not $p.WaitForExit([Math]::Max(1,$TimeoutSeconds) * 1000)
  if ($timedOut) {
    try { $p.Kill($true) } catch {}
  }

  $outText = $stdoutTask.GetAwaiter().GetResult()
  $errText = $stderrTask.GetAwaiter().GetResult()

  Write-Utf8File -Path $StdoutPath -Text $outText
  Write-Utf8File -Path $StderrPath -Text $errText

  return [pscustomobject]@{
    TimedOut = [bool]$timedOut
    ExitCode = if ($timedOut) { $null } else { $p.ExitCode }
    Stdout   = $outText
    Stderr   = $errText
  }
}

function Resolve-OpenCodeInvocation {
  param(
    [Parameter(Mandatory)][string]$InstallIfMissing,
    [Parameter(Mandatory)][string]$OpenCodeNpmVersion
  )

  $ocCmd = Get-Command opencode -ErrorAction SilentlyContinue
  if (-not $ocCmd) {
    if ($InstallIfMissing -ne 'Npm') { return $null }

    $npm = Get-Command npm -ErrorAction SilentlyContinue
    if (-not $npm) { throw "npm not found; cannot install opencode-ai" }

    $pkg = if ([string]::IsNullOrWhiteSpace($OpenCodeNpmVersion)) { 'opencode-ai' } else { ("opencode-ai@{0}" -f $OpenCodeNpmVersion) }
    $outP = Join-Path $OutDir 'npm_install.out.txt'
    $errP = Join-Path $OutDir 'npm_install.err.txt'

    Invoke-Proc -FilePath $npm.Source -Args @('i','-g',$pkg) -TimeoutSeconds 300 -StdoutPath $outP -StderrPath $errP -WorkingDirectory (Get-Location).Path | Out-Null
    $ocCmd = Get-Command opencode -ErrorAction SilentlyContinue
  }

  if (-not $ocCmd) { return $null }

  $src = [string]$ocCmd.Source
  $kind = 'exe'
  $exe  = $src
  $baseArgs = @()

  if ($src -match '\.ps1$') {
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if (-not $pwsh) { throw "pwsh not found; cannot run $src" }
    $kind = 'ps1'
    $exe  = $pwsh.Source
    $baseArgs = @('-NoProfile','-ExecutionPolicy','Bypass','-File', $src)
  }
  elseif ($src -match '\.(cmd|bat)$') {
    $cmdExe = if ($env:ComSpec) { $env:ComSpec } else { 'cmd.exe' }
    $kind = 'cmd'
    $exe  = $cmdExe
    $baseArgs = @('/d','/s','/c', $src)
  }

  return [pscustomobject]@{
    Kind = $kind
    Exe  = $exe
    BaseArgs = $baseArgs
    SourcePath = $src
    CommandType = [string]$ocCmd.CommandType
  }
}

function Invoke-OpenCode {
  param(
    [Parameter(Mandatory)][pscustomobject]$Invocation,
    [Parameter(Mandatory)][string[]]$Args,
    [Parameter(Mandatory)][int]$TimeoutSeconds,
    [Parameter()][hashtable]$ExtraEnv = @{},
    [Parameter(Mandatory)][string]$StdoutPath,
    [Parameter(Mandatory)][string]$StderrPath
  )

  $allArgs = @()
  $allArgs += $Invocation.BaseArgs
  $allArgs += $Args

  return Invoke-Proc -FilePath $Invocation.Exe -Args $allArgs -TimeoutSeconds $TimeoutSeconds -StdoutPath $StdoutPath -StderrPath $StderrPath -ExtraEnv $ExtraEnv -WorkingDirectory (Get-Location).Path
}

function Parse-Models {
  param([Parameter()][AllowNull()][string]$Text)
  if ([string]::IsNullOrWhiteSpace($Text)) { return @() }
  return ($Text -split "`r?`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
}

function Resolve-Candidate {
  param(
    [Parameter(Mandatory)][string]$Candidate,
    [Parameter()][object]$AvailableModels = @()
  )

  $avail = @($AvailableModels) | Where-Object { $_ -ne $null -and ([string]$_).Trim() -ne '' }
  if ($avail.Count -eq 0) { return $Candidate }

  if ($avail -contains $Candidate) { return $Candidate }

  $suffix = ($Candidate -split '/')[ -1 ]
  $matches = @($avail | Where-Object { (($_ -split '/')[ -1 ]) -eq $suffix })
  if ($matches.Count -eq 1) { return $matches[0] }

  return $null
}

function Classify-Text {
  param([Parameter()][AllowNull()][string]$Text)
  if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
  if ($Text -match '(?i)(unauthori|forbidden|invalid.*key|\b401\b|\b403\b)') { return 'API_AUTH_OR_PERMISSION' }
  if ($Text -match '(?i)(model.*not.*found|unknown model|invalid model|ProviderModelNotFound)') { return 'MODEL_ID_INVALID' }
  return $null
}

# ---------------- main ----------------
New-Dir -Path $OutDir

$metaPath = Join-Path $OutDir 'meta.txt'
$sumPath  = Join-Path $OutDir 'summary.json'
$errPath  = Join-Path $OutDir 'fatal_error.txt'

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add(("timestamp_utc={0:o}" -f [DateTime]::UtcNow))
$lines.Add(("pwsh_version={0}" -f $PSVersionTable.PSVersion))
$lines.Add(("os={0}" -f [System.Runtime.InteropServices.RuntimeInformation]::OSDescription))
$lines.Add(("env.ZAI_API_KEY={0}" -f (Get-EnvPresence -Name 'ZAI_API_KEY')))
$lines.Add(("env.ZHIPU_API_KEY={0}" -f (Get-EnvPresence -Name 'ZHIPU_API_KEY')))
$lines.Add(("env.GITHUB_TOKEN={0}" -f (Get-EnvPresence -Name 'GITHUB_TOKEN')))
$lines.Add(("env.GH_TOKEN={0}" -f (Get-EnvPresence -Name 'GH_TOKEN')))

$reason = 'INIT'
$inv = $null
$chosenModel = $null
$availableModels = @()
$attempts = New-Object System.Collections.Generic.List[object]
$hadException = $false
$fatalError = $null
$fatalStack = $null

$steps = [ordered]@{
  version   = $null
  auth_list = $null
  models    = $null
}


$openCodeVersion = [ordered]@{
  installed_before  = $null
  desired_tag       = $null
  desired_resolved  = $null
  installed_after   = $null
  ensured           = $false
  ensure_error      = $null
}

try {
  # Candidate list (ordered)
  $candidates = @()

  # Normalize candidates for cross-process invocation:
  # - If ModelCandidatesCsv is provided, split it into string[]
  # - Else, use ModelCandidates as provided in-process
  if (-not [string]::IsNullOrWhiteSpace($ModelCandidatesCsv)) {
    $ModelCandidates = [string[]](Normalize-ModelCandidatesCsv $ModelCandidatesCsv)
  }

  if ($ModelCandidates -and @($ModelCandidates).Count -gt 0) {
    $candidates = @($ModelCandidates)
  } else {
    if ([string]::IsNullOrWhiteSpace($Model)) { throw "Either -ModelCandidates or -Model is required." }
    $candidates += $Model
    if (-not [string]::IsNullOrWhiteSpace($FallbackModel) -and ($FallbackModel -ne $Model)) { $candidates += $FallbackModel }
  }
  $lines.Add(("model_candidates={0}" -f ($candidates -join ',')))

  # Resolve opencode invocation (supports npm shims)
  $inv = Resolve-OpenCodeInvocation -InstallIfMissing $InstallIfMissing -OpenCodeNpmVersion $OpenCodeNpmVersion
  if (-not $inv) {
    $reason = 'OPENCODE_NOT_FOUND'
    throw "opencode not found"
  }

  $lines.Add(("opencode_source={0}" -f $inv.SourcePath))
  $lines.Add(("opencode_kind={0}" -f $inv.Kind))
  $lines.Add(("opencode_commandType={0}" -f $inv.CommandType))
  $lines.Add(("opencode_invocation_exe={0}" -f $inv.Exe))

  # Normalize secrets: prefer ZAI; mirror to ZHIPU for compatibility
  $zai = Get-EnvValue -Name 'ZAI_API_KEY'
  $zhipu = Get-EnvValue -Name 'ZHIPU_API_KEY'
  if ([string]::IsNullOrWhiteSpace($zai) -and -not [string]::IsNullOrWhiteSpace($zhipu)) { $zai = $zhipu }
  if ([string]::IsNullOrWhiteSpace($zhipu) -and -not [string]::IsNullOrWhiteSpace($zai)) { $zhipu = $zai }

  $extraEnv = @{
    'OPENCODE_DISABLE_AUTOUPDATE'         = 'true'
    'OPENCODE_DISABLE_CLAUDE_CODE'        = 'true'
    'OPENCODE_DISABLE_CLAUDE_CODE_PROMPT' = 'true'
    'OPENCODE_DISABLE_CLAUDE_CODE_SKILLS' = 'true'
    'ZAI_API_KEY'                         = $zai
    'ZHIPU_API_KEY'                       = $zhipu
  }

  # If no API key is available, fail fast with a clear reason (do not attempt opencode run)
  if ([string]::IsNullOrWhiteSpace($zai) -and [string]::IsNullOrWhiteSpace($zhipu)) {
    $reason = 'API_KEY_MISSING'
    throw "ZAI_API_KEY and ZHIPU_API_KEY are both missing in environment."
  }

  # --version
  $steps.version = Invoke-OpenCode -Invocation $inv -Args @('--version') -TimeoutSeconds 30 -ExtraEnv $extraEnv `
    -StdoutPath (Join-Path $OutDir 'opencode_version.out.txt') -StderrPath (Join-Path $OutDir 'opencode_version.err.txt')


  # OpenCode version enforcement (optional, but recommended for repeatability):
  # - If -InstallIfMissing Npm and -OpenCodeNpmVersion is set (e.g. "latest" or "1.1.53"),
  #   ensure the installed OpenCode CLI matches the desired version BEFORE running auth/models/run.
  $installedVer = $null
  if ($steps.version -and -not $steps.version.TimedOut -and $steps.version.ExitCode -eq 0) {
    $mver = [regex]::Match([string]$steps.version.Stdout, '\b\d+\.\d+\.\d+\b')
    if ($mver.Success) { $installedVer = $mver.Value }
  }
  $openCodeVersion['installed_before'] = $installedVer

  $desiredTag = ([string]$OpenCodeNpmVersion).Trim()
  if ($InstallIfMissing -eq 'Npm' -and -not [string]::IsNullOrWhiteSpace($desiredTag)) {
    $openCodeVersion['desired_tag'] = $desiredTag

    $resolvedDesired = $null
    if ($desiredTag -ieq 'latest') {
      $npm = Get-Command npm -ErrorAction SilentlyContinue
      if ($npm) {
        $outP = Join-Path $OutDir 'npm_view_opencode_ai_version.out.txt'
        $errP = Join-Path $OutDir 'npm_view_opencode_ai_version.err.txt'
        $nv = Invoke-Proc -FilePath $npm.Source -Args @('view','opencode-ai','version') -TimeoutSeconds 60 -StdoutPath $outP -StderrPath $errP
        if (-not $nv.TimedOut -and $nv.ExitCode -eq 0) {
          $cand = ([string]$nv.Stdout).Trim()
          if ($cand -match '^\d+\.\d+\.\d+$') { $resolvedDesired = $cand }
        }
      }
    } elseif ($desiredTag -match '^\d+\.\d+\.\d+$') {
      $resolvedDesired = $desiredTag
    }
    $openCodeVersion['desired_resolved'] = $resolvedDesired

    $needInstall = $false
    if ($null -ne $resolvedDesired) {
      if ($null -eq $installedVer) { $needInstall = $true }
      elseif ($resolvedDesired -ne $installedVer) { $needInstall = $true }
    } elseif ($desiredTag -ieq 'latest') {
      # If we couldn't resolve latest (network / npm issue), still try tag install once.
      $needInstall = $true
    }

    if ($needInstall) {
      $npm = Get-Command npm -ErrorAction SilentlyContinue
      if ($npm) {
        try {
          $pkg = ("opencode-ai@{0}" -f $desiredTag)
          $outP = Join-Path $OutDir 'npm_install_upgrade.out.txt'
          $errP = Join-Path $OutDir 'npm_install_upgrade.err.txt'
          Invoke-Proc -FilePath $npm.Source -Args @('i','-g',$pkg) -TimeoutSeconds 300 -StdoutPath $outP -StderrPath $errP | Out-Null
          $openCodeVersion['ensured'] = $true

          # Refresh invocation + version
          $inv2 = Resolve-OpenCodeInvocation -InstallIfMissing 'None' -OpenCodeNpmVersion ''
          if ($inv2) { $inv = $inv2 }

          $steps.version = Invoke-OpenCode -Invocation $inv -Args @('--version') -TimeoutSeconds 30 -ExtraEnv $extraEnv `
            -StdoutPath (Join-Path $OutDir 'opencode_version_after.out.txt') -StderrPath (Join-Path $OutDir 'opencode_version_after.err.txt')

          $m2 = $null
          if ($steps.version -and -not $steps.version.TimedOut -and $steps.version.ExitCode -eq 0) {
            $m2 = [regex]::Match([string]$steps.version.Stdout, '\b\d+\.\d+\.\d+\b')
          }
          if ($m2 -and $m2.Success) { $openCodeVersion['installed_after'] = $m2.Value }
        } catch {
          $openCodeVersion['ensure_error'] = [string]$_.Exception.Message
        }
      } else {
        $openCodeVersion['ensure_error'] = 'npm not found; cannot ensure OpenCode version.'
      }
    } else {
      $openCodeVersion['installed_after'] = $installedVer
    }
  } else {
    $openCodeVersion['installed_after'] = $installedVer
  }

  if ($openCodeVersion['installed_before'])  { $lines.Add(("opencode_version_before={0}" -f $openCodeVersion['installed_before'])) }
  if ($openCodeVersion['desired_tag'])       { $lines.Add(("opencode_version_desired_tag={0}" -f $openCodeVersion['desired_tag'])) }
  if ($openCodeVersion['desired_resolved'])  { $lines.Add(("opencode_version_desired_resolved={0}" -f $openCodeVersion['desired_resolved'])) }
  if ($openCodeVersion['installed_after'])   { $lines.Add(("opencode_version_after={0}" -f $openCodeVersion['installed_after'])) }
  $lines.Add(("opencode_version_ensured={0}" -f [bool]$openCodeVersion['ensured']))
  if ($openCodeVersion['ensure_error'])      { $lines.Add(("opencode_version_ensure_error={0}" -f $openCodeVersion['ensure_error'])) }

  # auth list (best-effort; may be empty depending on setup)
  $steps.auth_list = Invoke-OpenCode -Invocation $inv -Args @('auth','list') -TimeoutSeconds 30 -ExtraEnv $extraEnv `
    -StdoutPath (Join-Path $OutDir 'opencode_auth_list.out.txt') -StderrPath (Join-Path $OutDir 'opencode_auth_list.err.txt')

  # models --refresh (optional)
  if (-not $SkipModelRefresh) {
    $steps.models = Invoke-OpenCode -Invocation $inv -Args @('models','--refresh') -TimeoutSeconds $TimeoutSeconds -ExtraEnv $extraEnv `
      -StdoutPath (Join-Path $OutDir 'opencode_models.out.txt') -StderrPath (Join-Path $OutDir 'opencode_models.err.txt')

    if (-not $steps.models.TimedOut -and $steps.models.ExitCode -eq 0) {
      $availableModels = Parse-Models -Text ([string]$steps.models.Stdout)
    }
  }

  # run attempts (model fallback + prompt fallback)
  $reason = 'OPENCODE_RUN_FAILED'

  for ($mi = 0; $mi -lt $candidates.Count; $mi++) {
    $requested = $candidates[$mi]
    $resolved = Resolve-Candidate -Candidate $requested -AvailableModels $availableModels

    if ([string]::IsNullOrWhiteSpace($resolved)) {
      $attempts.Add([pscustomobject]@{ index=$mi; requested=$requested; resolved=$null; promptIndex=$null; timedOut=$false; exitCode=$null; ok=$false; classified='MODEL_NOT_IN_LIST' })
      continue
    }

    $modelToken = Sanitize-FileToken -Text $resolved
    $modelReason = $null
    $modelOk = $false

    for ($pi = 0; $pi -lt $Prompts.Count; $pi++) {
      $prompt = $Prompts[$pi]

      $outP = Join-Path $OutDir ("opencode_run_{0}_p{1}.out.txt" -f $modelToken, $pi)
      $errP = Join-Path $OutDir ("opencode_run_{0}_p{1}.err.txt" -f $modelToken, $pi)

      $res = Invoke-OpenCode -Invocation $inv -Args @('run','--format','json','--log-level',$LogLevel,'--model',$resolved,$prompt) `
        -TimeoutSeconds $TimeoutSeconds -ExtraEnv $extraEnv -StdoutPath $outP -StderrPath $errP

      if ($res.TimedOut) {
        $attempts.Add([pscustomobject]@{ index=$mi; requested=$requested; resolved=$resolved; promptIndex=$pi; timedOut=$true; exitCode=$null; ok=$false; classified='TIMEOUT_OR_INTERACTIVE' })
        $modelReason = 'HANG_OR_INTERACTIVE_WAIT'
        continue
      }

      $combined = ([string]$res.Stderr + "`n" + [string]$res.Stdout)
      $cls = Classify-Text -Text $combined
      if ($cls) {
        $attempts.Add([pscustomobject]@{ index=$mi; requested=$requested; resolved=$resolved; promptIndex=$pi; timedOut=$false; exitCode=$res.ExitCode; ok=$false; classified=$cls })
        $modelReason = $cls
        if ($cls -eq 'API_AUTH_OR_PERMISSION') { break }
        continue
      }

      $outTrim = ([string]$res.Stdout).Trim()
      if ($res.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($outTrim)) {
        $attempts.Add([pscustomobject]@{ index=$mi; requested=$requested; resolved=$resolved; promptIndex=$pi; timedOut=$false; exitCode=$res.ExitCode; ok=$true; classified='OK' })
        $modelOk = $true
        $chosenModel = $resolved
        $reason = if ($mi -eq 0) { 'OK' } else { 'OK_WITH_FALLBACK_MODEL' }
        break
      }

      if ($res.ExitCode -eq 0 -and [string]::IsNullOrWhiteSpace($outTrim)) {
        $attempts.Add([pscustomobject]@{ index=$mi; requested=$requested; resolved=$resolved; promptIndex=$pi; timedOut=$false; exitCode=$res.ExitCode; ok=$false; classified='EMPTY_STDOUT' })
        $modelReason = 'EMPTY_STDOUT'
        continue
      }

      $attempts.Add([pscustomobject]@{ index=$mi; requested=$requested; resolved=$resolved; promptIndex=$pi; timedOut=$false; exitCode=$res.ExitCode; ok=$false; classified='OPENCODE_RUN_FAILED' })
      $modelReason = 'OPENCODE_RUN_FAILED'
    }

    if ($modelOk) { break }

    if ($modelReason) {
      if ($modelReason -eq 'API_AUTH_OR_PERMISSION') { $reason = 'API_AUTH_OR_PERMISSION'; break }
      elseif ($modelReason -eq 'MODEL_ID_INVALID') { $reason = 'MODEL_ID_INVALID' }
      elseif ($modelReason -eq 'HANG_OR_INTERACTIVE_WAIT') { $reason = 'HANG_OR_INTERACTIVE_WAIT' }
      elseif ($modelReason -eq 'EMPTY_STDOUT') { $reason = 'EMPTY_STDOUT' }
      else { $reason = 'OPENCODE_RUN_FAILED' }
    }
  }
}
catch {
  $hadException = $true
  $msg = [string]$_.Exception.Message
  Write-Utf8File -Path $errPath -Text ("{0}`n{1}" -f $msg, ([string]$_.ScriptStackTrace))
  if ($reason -eq 'INIT' -or $reason -eq 'OK') { $reason = 'FATAL_EXCEPTION' }
}
finally {
  # Copy recent OpenCode logs (best-effort)
  $copied = @()
  $logCandidates = @()

  $p1 = Join-Path $HOME '.local/share/opencode/log'
  if (Test-Path -LiteralPath $p1) { $logCandidates += $p1 }

  if ($env:USERPROFILE) {
    $p2 = Join-Path $env:USERPROFILE '.local/share/opencode/log'
    if (Test-Path -LiteralPath $p2) { $logCandidates += $p2 }
  }

  $logCandidates = $logCandidates | Select-Object -Unique
  foreach ($ld in $logCandidates) {
    $dst = Join-Path $OutDir 'opencode_log'
    New-Dir -Path $dst
    Get-ChildItem -LiteralPath $ld -File -Recurse -ErrorAction SilentlyContinue |
      Sort-Object LastWriteTime -Descending |
      Select-Object -First 30 |
      ForEach-Object {
        $target = Join-Path $dst $_.Name
        try {
          Copy-Item -LiteralPath $_.FullName -Destination $target -Force -ErrorAction Stop
          $copied += $_.FullName
        } catch {
          # ignore copy failures
        }
      }
  }

  Write-Utf8File -Path $metaPath -Text ($lines -join "`n")

  $status = if (-not $hadException -and ($reason -eq 'OK' -or $reason -eq 'OK_WITH_FALLBACK_MODEL')) { 'PASS' } else { 'FAIL' }

  try {
  $summaryObj = @{
      fatalError = $fatalError
      fatalStack = $fatalStack
      status = $status
      reason = $reason
      chosenModel = $chosenModel
      invocation = if ($inv) {
        @{
          kind = $inv.Kind
          sourcePath = $inv.SourcePath
          exe = $inv.Exe
          commandType = $inv.CommandType
        }
      } else { $null }
      openCodeVersion = $openCodeVersion
      steps = @{
        version   = if ($steps.version)   { @{ timedOut=[bool]$steps.version.TimedOut;   exitCode=$steps.version.ExitCode } } else { $null }
        auth_list = if ($steps.auth_list) { @{ timedOut=[bool]$steps.auth_list.TimedOut; exitCode=$steps.auth_list.ExitCode } } else { $null }
        models    = if ($steps.models)    { @{ timedOut=[bool]$steps.models.TimedOut;    exitCode=$steps.models.ExitCode } } else { $null }
      }
      attempts = $attempts
      logsCopiedCount = $copied.Count
      outDir = $OutDir
    } | ConvertTo-Json -Depth 10
  
    Write-Utf8File -Path $sumPath -Text $summaryObj
} catch {
  $hadException = $true
  if ($reason -eq 'OK') { $reason = 'FATAL_EXCEPTION' }
  $fatalError = if ($fatalError) { $fatalError } else { [string]$_.Exception.Message }
  $fatalStack = if ($fatalStack) { $fatalStack } else { [string]$_.ScriptStackTrace }
  Write-Utf8File -Path $errPath -Text ("{0}`n{1}" -f $fatalError, $fatalStack)
  $min = @{ status='FAIL'; reason='SUMMARY_WRITE_FAILED'; fatalError=$fatalError; fatalStack=$fatalStack; outDir=$OutDir } | ConvertTo-Json -Depth 6
  Write-Utf8File -Path $sumPath -Text $min
}
}

if ($reason -eq 'OK' -or $reason -eq 'OK_WITH_FALLBACK_MODEL') { exit 0 }
exit 1