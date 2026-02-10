# AI Automation Control

**Version:** 1.0  
**Last Updated:** 2026-02-10  
**Purpose:** Control AI automation workflows via `AI_AUTOMATION_MODE` repository variable.

---

## Overview

The `AI_AUTOMATION_MODE` repository variable controls whether AI automation workflows (orchestrator, watchdog, triage, etc.) can create pull requests and issues.

**Valid Values:**
- `RUNNING` (default) - AI automation creates PRs and issues normally
- `PAUSE` - AI automation is paused; no new PRs/issues will be created

---

## When to Use PAUSE

Pause AI automation when:
- **Frequent CI failures** detected (e.g., AI Watchdog reports 20+ failures)
- **Incident in progress** requiring human attention
- **Unstable environment** (e.g., during major refactoring, deployment)
- **Testing or debugging** AI workflows

**AI Watchdog Trigger:** The AI Watchdog workflow runs every 15 minutes and creates issues when CI failure count exceeds thresholds.

---

## How to Set PAUSE

### Option 1: Using GitHub UI (Manual)

1. Navigate to: **Settings** → **Secrets and variables** → **Actions**
2. Under **Variables**, find `AI_AUTOMATION_MODE`
3. Click **Edit** and set value to `PAUSE`
4. Click **Update variable**

### Option 2: Using GitHub CLI (Automated)

```bash
# Set PAUSE
gh variable set AI_AUTOMATION_MODE --body "PAUSE" --repo OWNER/REPO

# Verify
gh variable get AI_AUTOMATION_MODE --repo OWNER/REPO
```

### Option 3: Using Helper Script

```powershell
# Run from repository root
pwsh -NoProfile -ExecutionPolicy Bypass -File ./ops/scripts/set-ai-automation-mode.ps1 -Mode PAUSE
```

---

## How to Resume (RUNNING)

After resolving the underlying issue (e.g., fixing CI failures):

### Option 1: Using GitHub UI (Manual)

1. Navigate to: **Settings** → **Secrets and variables** → **Actions**
2. Under **Variables**, find `AI_AUTOMATION_MODE`
3. Click **Edit** and set value to `RUNNING`
4. Click **Update variable**

### Option 2: Using GitHub CLI (Automated)

```bash
# Set RUNNING
gh variable set AI_AUTOMATION_MODE --body "RUNNING" --repo OWNER/REPO

# Verify
gh variable get AI_AUTOMATION_MODE --repo OWNER/REPO
```

### Option 3: Using Helper Script

```powershell
# Run from repository root
pwsh -NoProfile -ExecutionPolicy Bypass -File ./ops/scripts/set-ai-automation-mode.ps1 -Mode RUNNING
```

---

## Verification

### Check Current Mode

```bash
gh variable get AI_AUTOMATION_MODE --repo OWNER/REPO
```

Or via GitHub UI: **Settings** → **Secrets and variables** → **Actions** → **Variables**

### Monitor Workflows

- **AI Orchestrator:** `.github/workflows/ai-orchestrator.yml` (runs every 15 min)
- **AI Watchdog:** `.github/workflows/ai-watchdog.yml` (runs every 15 min)
- **AI Triage:** `.github/workflows/ai-triage.yml` (on workflow_dispatch)

When `AI_AUTOMATION_MODE=PAUSE`, these workflows should skip creating new issues/PRs.

---

## Troubleshooting

### Variable Missing

If `AI_AUTOMATION_MODE` is not set:
1. Create the variable via: **Settings** → **Secrets and variables** → **Actions** → **New repository variable**
2. Name: `AI_AUTOMATION_MODE`
3. Value: `RUNNING` (or `PAUSE` if needed)

### Workflows Still Creating Issues

After setting `PAUSE`, workflows may still create issues if:
- The external reusable workflows haven't been updated to check the variable
- Cache issues (wait up to 15 minutes for next scheduled run)
- Variable was set incorrectly (check spelling: all caps, underscore separator)

### Variable Permission Errors

If you see permission errors when using `gh variable set`:
1. Ensure you have `repo` scope permissions
2. Use a personal access token (PAT) with appropriate scopes: `repo`, `workflow`

---

## Related Procedures

- **Incident Response:** See `docs/ops/incident-response.md` for PAUSE circuit breaker guidance
- **AI Prerequisites:** See `.github/workflows/ai-prereqs-check.yml` for automated checks
- **Session Logs:** See `docs/ai/session-log/` for AI agent activity history

---

## Checklist: PAUSE Procedure

- [ ] Identify trigger (CI failures, incident, etc.)
- [ ] Set `AI_AUTOMATION_MODE=PAUSE` via UI, CLI, or script
- [ ] Verify variable is set correctly
- [ ] Update issue tracker with PAUSE status
- [ ] Investigate and resolve root cause
- [ ] Set `AI_AUTOMATION_MODE=RUNNING` after resolution
- [ ] Verify workflows resume normally

---

**Reference:** See `AGENTS.md` §2.3 (Autonomy Levels) and §9 (Release & Deployment) for operational policies.
