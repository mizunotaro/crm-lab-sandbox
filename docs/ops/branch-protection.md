# Branch Protection Guidance

**Version:** 1.0  
**Last Updated:** 2026-02-01  
**Purpose:** Recommended branch protection settings for the CRM Lab Sandbox repository.

---

## Overview

Branch protection rules enforce quality gates before code can be merged into protected branches. This document provides recommended settings for both public and private repositories.

---

## Recommended Settings for Protected Branches

### Branches to Protect

Protect these branches by default:
- `main` (primary branch)
- `release/*` (release branches, if used)
- `dev` (development branch, if used)

### Required Status Checks

For this repository, require the following status checks:

| Check Name | Description | Source |
|------------|-------------|--------|
| `build` | Type checking and tests | `.github/workflows/ci.yml` |

### Protection Rules

#### Basic Settings (Recommended)

| Setting | Value | Rationale |
|---------|-------|-----------|
| **Require a pull request before merging** | ✅ Enabled | Ensures code review before merge |
| **Require approvals** | 1 approval | At least one reviewer must approve |
| **Require review from CODEOWNERS** | ❌ Optional | Consider enabling if using CODEOWNERS file |
| **Require status checks to pass** | ✅ Enabled | CI must pass before merge |
| **Require branches to be up to date** | ✅ Enabled | Prevents stale branch merges |

#### Advanced Settings (Recommended)

| Setting | Value | Rationale |
|---------|-------|-----------|
| **Require conversation resolution** | ✅ Enabled | All review comments must be resolved |
| **Require signed commits** | ❌ Disabled | Not currently using commit signing |
| **Linear history** | ✅ Enabled | Prevents merge commits, prefers rebase |
| **Allow force pushes** | ❌ Disabled | Prevents history rewrites |
| **Allow deletions** | ❌ Disabled | Prevents accidental deletion |

---

## Public vs Private Repositories

### Public Repository

Public repositories benefit from stricter protections:

| Setting | Recommendation |
|---------|---------------|
| **Required approvals** | 2 (reduces risk of single-reviewer errors) |
| **Require CODEOWNERS review** | ✅ Enabled (if applicable) |
| **Require branches to be up to date** | ✅ Enabled |
| **Require conversation resolution** | ✅ Enabled |

**Rationale:** Public repos are more exposed and benefit from additional review layers.

### Private Repository

Private repositories can use slightly relaxed rules:

| Setting | Recommendation |
|---------|---------------|
| **Required approvals** | 1 |
| **Require CODEOWNERS review** | ❌ Optional |
| **Require branches to be up to date** | ✅ Enabled |
| **Require conversation resolution** | ✅ Enabled |

**Rationale:** Trusted team members can work with fewer constraints while maintaining quality.

---

## How to Apply via GitHub UI

### Step 1: Navigate to Settings

1. Go to the repository on GitHub
2. Click **Settings** tab
3. Click **Branches** in the left sidebar

### Step 2: Add Branch Protection Rule

1. Click **Add branch protection rule**
2. Enter the branch name pattern (e.g., `main` or `main,release/*`)
3. Configure settings using the tables above as reference

### Step 3: Configure Status Checks

1. Under **Require status checks to pass before merging**, click **Add status check**
2. Enter check name: `build`
3. Enable **Require branches to be up to date before merging**

### Step 4: Configure Pull Request Requirements

1. Under **Require a pull request before merging**:
   - Set **Require approvals** to 1 (or 2 for public repos)
   - Enable **Dismiss stale PR approvals when new commits are pushed**
   - Enable **Require conversation resolution before merging**

### Step 5: Save

Click **Create** or **Save changes** to apply the rule.

---

## Security Considerations

### Code Review Best Practices

1. **Always require review**: Never bypass code review, even for "trivial" changes.
2. **Separate author and reviewer**: The same person should not approve their own PR.
3. **Document security changes**: PRs touching security-sensitive areas (auth, secrets) should have explicit approval.

### Bypass Protection Rules

Only administrators should have permission to bypass branch protection rules. If used:
- Document the reason in the PR description
- Notify the team immediately
- Ensure the change is still reviewed promptly

---

## Troubleshooting

### Status Checks Not Passing

1. Check the Actions tab to see which step failed
2. Verify all required status checks are listed in branch protection settings
3. Ensure the check name matches exactly (case-sensitive)

### Required Approvals Not Met

1. Verify reviewers have write access to the repository
2. Check if approvals were dismissed due to new commits
3. Ensure CODEOWNERS file is correctly configured if using that feature

### Stale Branch Errors

1. Fetch the latest changes from the target branch
2. Rebase or merge the updates into your feature branch
3. Push the updated branch

---

## Related Documentation

- `AGENTS.md` — Project operating rules and agent guidelines
- `.github/workflows/ci.yml` — CI workflow definition
- `docs/ops/incident-response.md` — Incident response procedures

---

## Reference

See [GitHub Branch Protection Documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches) for official GitHub documentation.
