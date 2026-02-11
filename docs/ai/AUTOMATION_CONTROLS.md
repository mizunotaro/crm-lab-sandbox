# AI Automation Controls (SSOT)

**Status:** ACTIVE  
**Version:** 1.0  
**Last Updated:** 2026-02-11

## Overview

This document is the Single Source of Truth (SSOT) for AI automation mode controls in this repository.

## GitHub Actions Variables

### Required Variables

| Variable | Description | Valid Values | Default | Notes |
|----------|-------------|--------------|---------|-------|
| `AI_AUTOMATION_MODE` | Controls whether AI automation runs or pauses | `RUN`, `PAUSE` | - | Required by `check-ai-prereqs.ps1` |
| `AI_MAX_OPEN_AI_PRS` | Maximum number of open AI PRs allowed | Integer | 1 | Prevents PR spam |
| `AI_MAX_ATTEMPTS_PER_ISSUE` | Maximum AI attempts per issue | Integer | 3 | Prevents infinite loops |

### AI_AUTOMATION_MODE Behavior

| Value | Behavior |
|-------|----------|
| `RUN` | Automation proceeds normally. Orchestrator picks issues and runs OpenCode. |
| `PAUSE` (or any non-"RUN" value) | Automation skips execution. Orchestrator exits early with run=false. |

## How to Change Automation Mode

### Using GitHub CLI (gh)

```bash
# List current variables
gh variable list --repo owner/repo

# Pause automation
gh variable set AI_AUTOMATION_MODE --repo owner/repo --body "PAUSE"

# Resume automation
gh variable set AI_AUTOMATION_MODE --repo owner/repo --body "RUN"
```

### Using GitHub Web UI

1. Navigate to repository → Settings → Secrets and variables → Actions
2. Click "Variables" tab
3. Find `AI_AUTOMATION_MODE` and click "Edit"
4. Change value to `PAUSE` or `RUN`
5. Click "Update variable"

## When to Use PAUSE Mode

**PAUSE mode should be set when:**

1. **Frequent CI failures detected** - AI Watchdog will create issues recommending PAUSE
2. **Manual triage needed** - When human intervention is required to diagnose issues
3. **Emergency stop** - When automation is causing problems (e.g., PR spam, incorrect fixes)
4. **Planned maintenance** - When repository maintenance is scheduled

**Resuming (RUN mode):**

1. **Triage complete** - Root cause identified and documented
2. **Fixes merged** - Blocking issues resolved
3. **CI stable** - Recent CI runs are green
4. **Approved by human** - Only resume after human review

## Related Workflows

| Workflow | Controlled By | Check |
|----------|---------------|-------|
| `ai-orchestrator.yml` | `AI_AUTOMATION_MODE` | Exits early if != "RUN" |
| `ai-watchdog.yml` | Monitors failures | Creates PAUSE recommendation issues |
| `ai-triage-dispatcher.yml` | CI failures | Triggers triage on ci workflow failure |
| `ai-triage.yml` | Manual dispatch | Runs triage analysis |

## Troubleshooting

### Automation Not Running

Check:
1. `AI_AUTOMATION_MODE` variable is set to "RUN"
2. Secrets are present (`ZAI_API_KEY` or `ZHIPU_API_KEY`)
3. Labels exist (`ai:ready`, `ai:in-progress`, etc.)
4. Branch protection is enabled on default branch

### Automation Not Pausing

Check:
1. Variable value is NOT "RUN" (any other value triggers pause)
2. Variable was saved successfully
3. Workflow uses the variable (orchestrator has the check)

### Frequent Failures

1. Run `check-ai-prereqs.ps1` to verify setup
2. Review recent CI failures: `gh run list --limit 20`
3. Check AI Orchestrator logs for errors
4. Set `AI_AUTOMATION_MODE=PAUSE` and run manual triage

## Emergency Procedure

**If automation is causing issues:**

1. Immediately set `AI_AUTOMATION_MODE=PAUSE`
2. Close all open AI PRs with label `ai:in-progress`
3. Review and triage issues labeled `ai:blocked`
4. Document findings in `docs/ai/session-log/`
5. Resume only after approval

## References

- `AGENTS.md` - AI agent roles and operating rules
- `.github/workflows/ai-orchestrator.yml` - Orchestrator workflow
- `.github/workflows/ai-watchdog.yml` - Watchdog workflow
- `ops/scripts/check-ai-prereqs.ps1` - Prerequisites checker
