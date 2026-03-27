# Issue Publishing Runbook

**Version:** 1.0  
**Last Updated:** 2026-02-01  
**Purpose:** End-to-end guide for creating issue markdown files and publishing them to GitHub via publish-issues script.

---

## 0) Overview

This runbook documents the workflow for:
1. Creating spec and task markdown files locally
2. Running the `publish-issues.ps1` script to update GitHub issues with Task Links
3. Troubleshooting common issues (ExecutionPolicy, MOTW, idempotency)

The system maintains a single source of truth (SSOT) in markdown files and publishes Task Links comments to spec issues automatically.

---

## 1) Prerequisites

### 1.1 Required Tools

- **PowerShell 7+** (`pwsh`)
- **GitHub CLI** (`gh`) installed and authenticated
- Write permissions to the target repository

### 1.2 Authentication

```powershell
# Authenticate with GitHub CLI
gh auth login

# Verify authentication
gh auth status
```

### 1.3 Script Permissions

Windows may block downloaded PowerShell scripts with MOTW (Mark of the Web). See §5 for troubleshooting.

---

## 2) Creating Issue Files

### 2.1 Directory Structure

Issue files are stored in `ops/issues/<area>/`:

```
ops/issues/
└── gcp-serverless-crm-poc/
    ├── spec-009-contact-management.md
    ├── task-010-design-data-model.md
    ├── task-011-api-endpoints.md
    └── task-012-ui-components.md
```

### 2.2 Spec File Format (`spec-<id>.md`)

```markdown
# Spec #<id> - <Title>

## Overview
<Brief description>

## Goals
- <Goal 1>
- <Goal 2>

## Acceptance Criteria
- [ ] <AC 1>
- [ ] <AC 2>

## Tasks
- [ ] <Task 1>
- [ ] <Task 2>

## Technical Notes
<Any technical details>

## Dependencies
- <Dependency 1>

---

Spec Issue: #<github-issue-number>
```

**Required Field:** `Spec Issue: #<github-issue-number>` at the end (no markdown bold)

**Note:** Use plain text without markdown bold (`**`). The script regex `Spec Issue:\s*#(\d+)` does not match `**Spec Issue:** #9`. Existing files with markdown bold should be updated to use plain text.

### 2.3 Task File Format (`task-<id>.md`)

```markdown
# Task #<id> - <Title>

## Goal
<What this task achieves>

## Acceptance Criteria
- [ ] <AC 1>
- [ ] <AC 2>

## Implementation Notes
<Any technical details>

## Dependencies
<Any dependencies>

---

**Parent Spec:** #<parent-spec-id>
**Status:** pending|in-progress|completed
```

**Required Fields:**
- `Parent Spec: #<parent-spec-id>` - Links to the spec file ID (not GitHub issue number)
- `Status:` - Current status of the task

### 2.4 Example: Creating New Files

```powershell
# Create directory structure
New-Item -ItemType Directory -Force -Path "ops/issues/my-feature"

# Create spec file
@'
# Spec #100 - New Feature

## Overview
Add a new feature.

## Goals
- Feature works
- Tests pass

---

Spec Issue: #100
'@ | Out-File -Encoding utf8 "ops/issues/my-feature/spec-100-new-feature.md"

# Create task file
@'
# Task #101 - Implementation

## Goal
Implement the feature.

---

**Parent Spec:** #100
**Status:** pending
'@ | Out-File -Encoding utf8 "ops/issues/my-feature/task-101-implementation.md"
```

---

## 3) Publishing Issues

### 3.1 Basic Usage

```powershell
# Navigate to repo root
cd /path/to/repo

# Run the script
pwsh -NoProfile -Command "ops/scripts/publish-issues.ps1 -RepoOwner 'owner' -RepoName 'repo' -IssuesDir 'ops/issues/my-feature'"
```

**Parameters:**
- `-RepoOwner` - GitHub repository owner (e.g., `mizunotaro`)
- `-RepoName` - GitHub repository name (e.g., `crm-lab-sandbox`)
- `-IssuesDir` - Path to directory containing spec/task files
- `-DryRun` - Preview changes without modifying GitHub (optional)
- `-TaskLinksWriteMode` - `update` (default) or `append` (optional)

### 3.2 Dry Run (Recommended First Step)

```powershell
# Preview what will happen
pwsh -NoProfile -Command "ops/scripts/publish-issues.ps1 -RepoOwner 'owner' -RepoName 'repo' -IssuesDir 'ops/issues/my-feature' -DryRun"
```

Expected output:
```
Processing Task Links for Spec #100...
[DryRun] Would create Task Links comment.
```

### 3.3 Full Publish

```powershell
# Actually publish the Task Links
pwsh -NoProfile -Command "ops/scripts/publish-issues.ps1 -RepoOwner 'owner' -RepoName 'repo' -IssuesDir 'ops/issues/my-feature'"
```

Expected output:
```
Processing Task Links for Spec #100...
Task Links comment created.
```

### 3.4 Task Links Write Modes

**Update Mode (Default):**
- Updates existing autogen comment if content changed
- Skips if content is already up-to-date
- Maintains a single autogen comment per spec issue

```powershell
pwsh -NoProfile -Command "ops/scripts/publish-issues.ps1 -RepoOwner 'owner' -RepoName 'repo' -IssuesDir 'ops/issues/my-feature' -TaskLinksWriteMode update"
```

**Append Mode:**
- Always creates a new comment
- Useful for rollback or manual review
- Can create duplicate comments if run multiple times

```powershell
pwsh -NoProfile -Command "ops/scripts/publish-issues.ps1 -RepoOwner 'owner' -RepoName 'repo' -IssuesDir 'ops/issues/my-feature' -TaskLinksWriteMode append"
```

---

## 4) What the Script Does

### 4.1 Task Links Generation

The script automatically generates a Task Links comment on the spec issue:

```markdown
<!-- TASK_LINKS_AUTOGEN v1 -->

## Task Links

- Task #10
- Task #11
- Task #12

*Auto-generated by publish-issues.ps1*
```

### 4.2 Marker Format

The autogen comment uses the marker: `<!-- TASK_LINKS_AUTOGEN v1 -->`

This marker is used to:
- Identify autogen comments
- Prevent duplicate comments in update mode
- Enable comment updates instead of creating new ones

---

## 5) Troubleshooting

### 5.1 ExecutionPolicy Errors

**Error:**
```
publish-issues.ps1: File ... cannot be loaded because running scripts is disabled on this system.
```

**Solution A: Unblock the file (Recommended)**
```powershell
# Unblock the specific script
Unblock-File -Path "ops/scripts/publish-issues.ps1"

# Or unblock all scripts in directory
Get-ChildItem -Path "ops/scripts" -Filter "*.ps1" | Unblock-File
```

**Solution B: Set ExecutionPolicy for current session**
```powershell
# For current PowerShell session only (safer)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Then run the script
pwsh -NoProfile -Command "ops/scripts/publish-issues.ps1 ..."
```

**Solution C: Run via pwsh with -NoProfile**
```powershell
# Already included in recommended commands
pwsh -NoProfile -Command "ops/scripts/publish-issues.ps1 ..."
```

### 5.2 MOTW (Mark of the Web) Issues

**Symptom:** Scripts downloaded from GitHub are blocked on Windows.

**Solution:**
```powershell
# Check if file is blocked
Get-Item "ops/scripts/publish-issues.ps1" | Select-Object ZoneIdentifier

# Unblock the file
Unblock-File "ops/scripts/publish-issues.ps1"
```

**Prevention:**
- Clone the repo using `git clone --config core.autocrlf=false`
- Or run `git config --global core.autocrlf false` before cloning

### 5.3 GitHub CLI Not Authenticated

**Error:**
```
Failed to fetch comments: HTTP 401: Bad credentials
```

**Solution:**
```powershell
# Re-authenticate
gh auth login

# Select GitHub.com, then choose authentication method (browser or token)
# Verify
gh auth status
```

### 5.4 No Task Links Created

**Possible Causes:**

1. **Spec issue number not found in spec file**
   ```powershell
   # Check spec file has required field
   Get-Content "ops/issues/my-feature/spec-100-*.md" | Select-String "Spec Issue:"
   ```

2. **No task files found**
   ```powershell
   # Check for task files
   Get-ChildItem "ops/issues/my-feature/task-*.md"
   ```

3. **GitHub issue doesn't exist or no permissions**
   ```powershell
   # Verify issue exists and you have access
   gh issue view <issue-number> --repo owner/repo
   ```

### 5.5 Idempotency Issues

**Symptom:** Multiple autogen comments created on re-run.

**Diagnosis:**
```powershell
# Check for multiple autogen comments
gh api repos/owner/repo/issues/<issue-number>/comments | jq '.[] | select(.body | contains("TASK_LINKS_AUTOGEN")) | .id'
```

**Fix:**
1. Delete duplicate comments (keep the newest):
```powershell
$comments = gh api repos/owner/repo/issues/<issue-number>/comments --paginate | ConvertFrom-Json
$autogen = $comments | Where-Object { $_.body -like "*TASK_LINKS_AUTOGEN*" } | Sort-Object created_at -Descending
# Keep first (newest), delete rest
$autogen | Select-Object -Skip 1 | ForEach-Object { 
    gh api --method DELETE repos/owner/repo/issues/comments/$($_.id)
}
```

2. Ensure you're using `update` mode (default):
```powershell
pwsh -NoProfile -Command "ops/scripts/publish-issues.ps1 ... -TaskLinksWriteMode update"
```

### 5.6 Verify Task Links After Publish

```powershell
# View the comment on the spec issue
gh issue view <spec-issue-number> --repo owner/repo --comments | Select-String "TASK_LINKS"
```

---

## 6) Testing

### 6.1 Test Script

Use the provided test script to verify behavior:

```powershell
pwsh -NoProfile -Command "ops/scripts/test-publish-issues.ps1 -RepoOwner 'owner' -RepoName 'repo' -IssuesDir 'ops/issues/my-feature' -SpecIssueNumber 100"
```

**Tests performed:**
1. Dry run
2. Create once
3. No duplicate on re-run
4. Update on content change
5. Append mode

### 6.2 Manual Verification Checklist

- [ ] Dry run completes without errors
- [ ] Spec files contain `Spec Issue: #<number>`
- [ ] Task files contain `Parent Spec: #<id>` and `Status:`
- [ ] Task Links comment appears on spec issue
- [ ] Re-running script doesn't create duplicate comments (update mode)
- [ ] Modifying task file updates the comment content

---

## 7) Best Practices

### 7.1 Workflow

1. **Create spec/task files** in `ops/issues/<area>/`
2. **Run dry run** to verify parameters
3. **Run full publish** with update mode (default)
4. **Verify** Task Links comment on GitHub issue
5. **Test** using test script if needed

### 7.2 Naming Conventions

- **Spec files:** `spec-<id>-<kebab-title>.md`
- **Task files:** `task-<id>-<kebab-title>.md`
- **Area directories:** Use feature or project name (e.g., `gcp-serverless-crm-poc`, `auth-system`)

### 7.3 File Format Tips

- Always include required footer fields
- Use kebab-case in filenames
- Keep filenames under 50 characters
- Use consistent indentation (2 spaces or 4 spaces)

### 7.4 Idempotency

- Always use `-TaskLinksWriteMode update` (default) for normal operations
- Use `-DryRun` before full publish to preview changes
- Avoid `-TaskLinksWriteMode append` unless intentionally creating new comments

### 7.5 Security

- Never commit secrets or credentials to issue files
- Use issue numbers only (no tokens in comments)
- Verify `gh auth status` before running scripts

---

## 8) Related Files

- `ops/scripts/publish-issues.ps1` - Main publishing script
- `ops/scripts/test-publish-issues.ps1` - Verification test script
- `ops/issues/` - Directory containing spec/task markdown files
- `AGENTS.md` - Project operating rules
- `docs/ops/incident-response.md` - Incident response procedures

---

## 9) Quick Reference

### Common Commands

```powershell
# Unblock script (if blocked)
Unblock-File "ops/scripts/publish-issues.ps1"

# Dry run
pwsh -NoProfile -Command "ops/scripts/publish-issues.ps1 -RepoOwner 'owner' -RepoName 'repo' -IssuesDir 'ops/issues/my-area' -DryRun"

# Full publish
pwsh -NoProfile -Command "ops/scripts/publish-issues.ps1 -RepoOwner 'owner' -RepoName 'repo' -IssuesDir 'ops/issues/my-area'"

# Test script
pwsh -NoProfile -Command "ops/scripts/test-publish-issues.ps1 -RepoOwner 'owner' -RepoName 'repo' -IssuesDir 'ops/issues/my-area' -SpecIssueNumber 100"

# View Task Links comment
gh issue view <issue-number> --repo owner/repo --comments
```

### Marker
`<!-- TASK_LINKS_AUTOGEN v1 -->`

### Required Footer Fields
- Spec file: `Spec Issue: #<number>` (no markdown bold)
- Task file: `Parent Spec: #<id>` and `Status: <status>`

---

## 10) Changelog

| Date | Version | Changes |
|------|---------|---------|
| 2026-02-01 | 1.0 | Initial version |
