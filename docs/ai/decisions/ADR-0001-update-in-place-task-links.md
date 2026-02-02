# ADR-0001: Update-in-place Mode for Task Links Comments

## Status
Accepted

## Context
The `publish-issues` script was appending new Task Links comments to Spec Issues every time it ran. This caused comment duplication and cluttered issue threads when the script was executed multiple times (e.g., when new tasks were added or updated).

### Problem
- Running `publish-issues` multiple times created duplicate Task Links comments
- Issue threads became cluttered with redundant comments
- No easy way to update existing comments with new task links
- Users had to manually clean up duplicates

### Requirements (Issue #129)
- Task Links comments must not duplicate on repeated runs
- Comments should be updated in-place when possible
- Must support rollback to old behavior (append mode)
- Must be idempotent and low-noise
- Must support dry-run mode

## Decision
Implement update-in-place mode for Task Links comments with the following approach:

1. **Marker-based comment identification**
   - Add marker: `<!-- TASK_LINKS_AUTOGEN v1 -->` to all auto-generated comments
   - Use marker to identify existing Task Links comments

2. **Update-or-create logic**
   - Search for existing comments containing the marker
   - If found: update the newest comment (PATCH)
   - If not found: create new comment (POST)
   - If content identical: skip update (idempotent)

3. **Parameter for mode selection**
   - Add `-TaskLinksWriteMode append|update` parameter
   - Default: `update` (new behavior)
   - Option: `append` (old behavior for rollback)

4. **Duplicate handling**
   - If multiple marker comments exist: update the newest one
   - Log warning with duplicate comment IDs (no bodies)
   - Do NOT delete old comments (non-destructive)

5. **Dry-run support**
   - `-DryRun` flag outputs "would update/create/skip" messages
   - No actual POST/PATCH to GitHub API

## Alternatives Considered

### Alternative A: Delete old marker comments
- **Pros**: Cleaner history, no duplicates
- **Cons**: Destructive, requires delete privileges, difficult to rollback
- **Rejected**: Violates safety preference, higher risk

### Alternative B: Use search API to find comments
- **Pros**: Simpler initial query
- **Cons**: Search is non-deterministic, rate-limited, may miss comments
- **Rejected**: GitHub issues API is more reliable and deterministic

### Alternative C: Hard switch to update-only (no flag)
- **Pros**: Minimal code surface, simpler
- **Cons**: No easy rollback path without code revert
- **Rejected**: Operational safety requires rollback capability

## Consequences

### Positive
- ✅ No duplicate Task Links comments
- ✅ Idempotent runs (same result every time)
- ✅ Low-noise updates (only changes when content differs)
- ✅ Safe rollback path with `-TaskLinksWriteMode append`
- ✅ Dry-run mode for testing
- ✅ Non-destructive approach (doesn't delete comments)

### Negative
- ⚠️ Slightly more complex code
- ⚠️ Old duplicate comments remain if they existed before this change
- ⚠️ Requires additional API call to fetch comments

### Neutral
- 🔄 Default behavior changes from append to update
- 🔄 Adds one parameter to script interface

## Migration / Rollback Plan

### Migration
1. Deploy new script with `-TaskLinksWriteMode update` as default
2. Run script on all Spec Issues
3. Existing duplicate comments will remain but won't be updated
4. New runs will update the newest marker comment only

### Rollback
If issues arise, immediate rollback steps:
1. Use `-TaskLinksWriteMode append` to restore old behavior
2. Or revert code to previous commit
3. Duplicates created during update mode remain but are harmless

### Cleanup (Optional)
Manual cleanup of old duplicate comments can be done after validation:
```powershell
# Use gh api to list and review marker comments
gh api repos/owner/repo/issues/9/comments --jq '.[] | select(.body | contains("TASK_LINKS_AUTOGEN")) | {id, created_at}'
```

## Implementation
Implemented in `ops/scripts/publish-issues.ps1` with:
- `Find-AutogenTaskLinksComment()` function for marker detection
- `Update-Or-Create-TaskLinksComment()` function for update/create logic
- `Get-SpecComments()` function for API-based comment fetching
- `Build-TaskLinksBody()` function with marker inclusion
- `-TaskLinksWriteMode` parameter for mode selection

## References
- Issue #129: [AI] Make Spec Task Links update-in-place (no duplicates)
- Implementation commit: (to be added after PR merge)
