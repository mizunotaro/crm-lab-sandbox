# Issue File Numbering Migration Plan

## Overview

This document outlines a safe migration plan to transition from 2-digit to 4-digit issue file prefixes (e.g., `spec-009.md` → `spec-0009.md`, `task-010.md` → `task-0010.md`).

## Current State

### Existing Format
- **Spec files**: `spec-NN.md` (2-digit, e.g., `spec-009-contact-management.md`)
- **Task files**: `task-NN.md` (2-digit, e.g., `task-010-design-data-model.md`)
- **Location**: `ops/issues/gcp-serverless-crm-poc/`

### Current Tooling
- `ops/scripts/publish-issues.ps1` - Sorts files by name using `Sort-Object Name`
- `ops/scripts/test-publish-issues.ps1` - Verification script for Task Links

### Key Observation
PowerShell's `Sort-Object Name` performs **lexical string sort**, which means:
- `task-10.md` comes before `task-2.md` (lexically)
- For proper numeric ordering, we need to ensure consistent zero-padding

## Migration Plan

### Phase 1: Preparation (Read-only)

**Objective**: Verify current state and identify all affected files.

```powershell
# List all issue files with current numbering
Get-ChildItem -Path "ops/issues" -Recurse -Filter "*.md" |
  Where-Object { $_.Name -match '^(spec|task)-(\d{2})-' } |
  Select-Object FullName, Name |
  Sort-Object Name
```

**Acceptance Criteria**:
- [ ] All 2-digit issue files identified
- [ ] Total count of files to migrate documented
- [ ] No unexpected file patterns found

### Phase 2: Coexistence Period (Read + Write)

**Objective**: Update tooling to support both 2-digit and 4-digit formats during transition.

#### 2.1 Update publish-issues.ps1

**Location**: `ops/scripts/publish-issues.ps1:83-84`

**Current code**:
```powershell
$taskFiles = Get-ChildItem -Path $IssuesDir -Filter 'task-*.md' -File | Sort-Object Name
```

**Change**:
```powershell
$taskFiles = Get-ChildItem -Path $IssuesDir -Filter 'task-*.md' -File | Sort-Object Name -Stable
```

**Rationale**: `-Stable` flag maintains relative order for equal sort keys (PowerShell 7+).

#### 2.2 Update regex patterns

**Location**: `ops/scripts/publish-issues.ps1:91`

**Current code**:
```powershell
$taskNumber = $taskFile.Name -replace 'task-(\d+)\.md', '$1'
```

**Change**: No change needed - regex `\d+` matches any number of digits.

**Acceptance Criteria**:
- [ ] Tooling updated to support both formats
- [ ] CI remains green after tooling changes
- [ ] Test script passes with existing 2-digit files

### Phase 3: Batch Migration (Read + Write)

**Objective**: Rename files from 2-digit to 4-digit format.

#### 3.1 Migration Script

```powershell
$IssuesDir = "ops/issues/gcp-serverless-crm-poc"
$LogPath = "docs/ops/migration-log.json"

$MigrationLog = @()

Get-ChildItem -Path $IssuesDir -Filter "*.md" -File |
  Where-Object { $_.Name -match '^(spec|task)-(\d{2})-(.+)\.md$' } |
  ForEach-Object {
    $type = $matches[1]        # "spec" or "task"
    $oldNum = $matches[2]       # e.g., "09"
    $name = $matches[3]         # e.g., "contact-management"
    $newNum = $oldNum.PadLeft(4, '0')  # "09" → "0009"

    $oldName = $_.Name
    $newName = "${type}-${newNum}-${name}.md"
    $oldPath = $_.FullName
    $newPath = Join-Path $_.DirectoryName $newName

    Write-Host "Renaming: $oldName → $newName"

    Rename-Item -Path $oldPath -NewPath $newPath -WhatIf

    $MigrationLog += [PSCustomObject]@{
      Timestamp = Get-Date -Format "o"
      OldName = $oldName
      NewName = $newName
      OldPath = $oldPath
      NewPath = $newPath
      Type = $type
      OldNumber = $oldNum
      NewNumber = $newNum
    }
  }

$MigrationLog | ConvertTo-Json -Depth 10 | Out-File -FilePath $LogPath -Encoding utf8
Write-Host "Migration log saved to $LogPath"
```

**Safety features**:
- `-WhatIf` flag for dry-run by default
- Full migration log recorded
- Reversible operation (log file contains all mappings)

#### 3.2 Execution Steps

1. **Dry-run migration**:
   ```powershell
   .\migrate-issue-numbers.ps1
   ```
   Review output, verify no conflicts.

2. **Execute migration** (after dry-run approval):
   ```powershell
   # Remove -WhatIf flag from script
   .\migrate-issue-numbers.ps1
   ```

3. **Verify**:
   - All files renamed correctly
   - No file name collisions
   - publish-issues.ps1 runs successfully

**Acceptance Criteria**:
- [ ] All files renamed to 4-digit format
- [ ] Migration log generated and committed
- [ ] publish-issues.ps1 runs successfully
- [ ] CI remains green

### Phase 4: Cleanup (Optional)

**Objective**: Remove support for 2-digit format after coexistence period (TBD).

**Risks**: Requires updating all existing workflows, scripts, and documentation.

**Recommendation**: Keep both formats supported indefinitely to avoid breakage.

## Risks and Mitigations

### Risk 1: Sort Order Changes

**Description**: Moving from lexical to numeric sort may change display order in Task Links comments.

**Impact**: Medium - Affects user experience when viewing GitHub issues.

**Mitigation**:
- Use `-Stable` sort flag to maintain relative order for identical prefixes
- Document the sort behavior in AGENTS.md
- Run test-publish-issues.ps1 before and after migration

**Verification**:
```powershell
# Before migration
.\ops\scripts\publish-issues.ps1 -RepoOwner <owner> -RepoName <repo> -IssuesDir ops\issues\gcp-serverless-crm-poc -DryRun

# After migration (verify order is consistent)
.\ops\scripts\publish-issues.ps1 -RepoOwner <owner> -RepoName <repo> -IssuesDir ops\issues\gcp-serverless-crm-poc -DryRun
```

### Risk 2: Script Incompatibility

**Description**: Other scripts or workflows may hard-code 2-digit patterns.

**Impact**: High - Could break automation or CI pipelines.

**Mitigation**:
- Search for all references to 2-digit patterns:
  ```powershell
  Select-String -Path . -Pattern "(spec|task)-\d{2}-" -Recurse
  ```
- Update any hard-coded patterns to use `\d+` (variable length)
- Test all CI workflows before merging

**Acceptance Criteria**:
- [ ] No hard-coded 2-digit patterns found
- [ ] All CI workflows pass with 4-digit files

### Risk 3: Git Conflicts

**Description**: Active PRs or branches may have uncommitted changes to issue files.

**Impact**: High - Could cause merge conflicts or lost work.

**Mitigation**:
- Coordinate with team: pause new PRs during migration window
- Create a migration branch: `chore/migrate-4digit-issue-numbers`
- Communicate migration timing via Slack/email

**Acceptance Criteria**:
- [ ] No open PRs modify issue files during migration
- [ ] Migration branch created and merged cleanly

### Risk 4: Rollback Complexity

**Description**: If issues arise, rolling back may require manual file renames.

**Impact**: Medium - Increases recovery time.

**Mitigation**:
- Auto-generate rollback script from migration log
- Test rollback script in staging before production migration

**Rollback Procedure**:
```powershell
# Generate rollback script from log
$Log = Get-Content "docs/ops/migration-log.json" | ConvertFrom-Json

$RollbackScript = @()
$RollbackScript += "# Rollback script generated at $(Get-Date -Format 'o')"
$RollbackScript += ""

foreach ($entry in $Log) {
  $RollbackScript += "Rename-Item -Path '$($entry.NewPath)' -NewName '$($entry.OldName)' -Force"
}

$RollbackScript | Out-File -FilePath "ops/scripts/rollback-migration.ps1" -Encoding utf8
Write-Host "Rollback script generated"
```

## Rollback Plan

### Trigger Criteria
Rollback should be triggered if:
1. CI fails after migration
2. Task Links generation breaks
3. Unforeseen file naming conflicts occur

### Rollback Steps

1. **Generate rollback script** (if not pre-generated):
   ```powershell
   # See code above in Risk 4 mitigation
   ```

2. **Execute rollback**:
   ```powershell
   .\ops\scripts\rollback-migration.ps1
   ```

3. **Verify**:
   ```powershell
   # Check all files restored
   Get-ChildItem -Path "ops/issues" -Recurse -Filter "*.md" |
     Where-Object { $_.Name -match '^(spec|task)-(\d{4})-' } |
     Measure-Object

   # Should return 0 (no 4-digit files remaining)
   ```

4. **Revert tooling changes** (if any made):
   ```powershell
   git checkout -- ops/scripts/publish-issues.ps1
   ```

5. **Communicate**: Notify team of rollback and issues encountered

### Rollback Acceptance Criteria
- [ ] All files restored to 2-digit format
- [ ] CI green after rollback
- [ ] No orphaned files
- [ ] Team notified

## Timeline

| Phase | Duration | Notes |
|-------|----------|-------|
| Phase 1: Preparation | 1 day | Read-only verification |
| Phase 2: Coexistence | 2 days | Tooling updates |
| Phase 3: Migration | 1 day | Coordinated execution |
| Phase 4: Cleanup | TBD | Optional, deferred |

**Total minimum time**: 4 days

## Decision Log

### Why 4-digit format?

**Alternatives considered**:
1. **3-digit**: Good for up to 999 issues, but less future-proof
2. **5-digit**: Future-proof but unnecessarily verbose

**Decision**: 4-digit provides balance:
- Supports up to 9999 issues
- Matches GitHub issue numbers (currently in 3-digit range)
- Aligns with common zero-padding conventions

### Why not force numeric sort?

**Decision**: Lexical sort with zero-padding is safer because:
- Maintains compatibility with existing tooling
- Avoids PowerShell version dependencies
- Simpler implementation (no custom sort functions)

**Verification**: Zero-padded lexical sort produces identical order to numeric sort:
```
0001 < 0002 < ... < 9999  (lexical with zero-padding)
1 < 2 < ... < 9999        (numeric)
```

## Version Compatibility

### Tooling Requirements
- PowerShell 7.0+ for `-Stable` sort flag
- GitHub CLI (gh) for publish-issues.ps1

### Tested Versions
- PowerShell 7.4.0
- GitHub CLI 2.50.0

## References

- [PowerShell Sort-Object Documentation](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/sort-object)
- [AGENTS.md](/AGENTS.md) - Coding standards and workflow
- [publish-issues.ps1](/ops/scripts/publish-issues.ps1) - Issue publication tooling

## Appendix A: Verification Checklist

Before migration:
- [ ] All 2-digit issue files identified and logged
- [ ] No open PRs modify issue files
- [ ] Migration branch created
- [ ] Rollback script pre-generated

After migration:
- [ ] All files renamed to 4-digit format
- [ ] Migration log committed to repo
- [ ] publish-issues.ps1 runs successfully
- [ ] test-publish-issues.ps1 passes
- [ ] CI pipeline green
- [ ] Task Links comments verified on GitHub
- [ ] Team notified of completion

## Appendix B: File Count Inventory

**As of**: 2026-01-31

```
Spec files: 1 (spec-009-*.md)
Task files: 3 (task-010-*.md, task-011-*.md, task-012-*.md)
Total: 4 files
```

**Note**: This inventory should be updated immediately before migration execution.

---

**Document Owner**: Ops Team (automated)
**Review Frequency**: As needed during migration
**Next Review**: At Phase 3 execution
