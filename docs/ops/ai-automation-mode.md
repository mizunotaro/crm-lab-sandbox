# AI Automation Mode Configuration

**Version:** 1.0  
**Last Updated:** 2026-02-10  
**Purpose:** Control AI automation behavior via repository variable `AI_AUTOMATION_MODE`

---

## Overview

`AI_AUTOMATION_MODE` is a GitHub repository variable that controls whether AI-powered automation workflows should run or pause.

---

## Valid Values

| Value | Behavior | Use Case |
|-------|----------|----------|
| `RUN` | AI automation runs normally | Default state for normal operations |
| `PAUSE` | AI automation pauses before execution | Circuit breaker during incidents or when investigating issues |

---

## When to Use PAUSE

Set `AI_AUTOMATION_MODE=PAUSE` when:

1. **Frequent CI failures** (e.g., 20+ consecutive failures detected by AI Watchdog)
2. **Security incidents** requiring investigation
3. **API rate limiting** or quota exhaustion
4. **Manual intervention** needed (e.g., dependency upgrades, config changes)
5. **Human-approved triage** required before continuing automation

---

## How to Set PAUSE

### Method 1: GitHub Repository Variable (Recommended)

1. Go to repo Settings → Secrets and variables → Actions → Variables
2. Click "New repository variable"
3. Name: `AI_AUTOMATION_MODE`
4. Value: `PAUSE`
5. Click "Add variable"

### Method 2: GitHub CLI

```bash
gh variable set AI_AUTOMATION_MODE --body "PAUSE" --repo mizunotaro/crm-lab-sandbox
```

---

## How to Resume (Set RUN)

### Method 1: GitHub UI

1. Go to repo Settings → Secrets and variables → Actions → Variables
2. Find `AI_AUTOMATION_MODE`
3. Click "Update"
4. Change value to `RUN`
5. Click "Update variable"

### Method 2: GitHub CLI

```bash
gh variable set AI_AUTOMATION_MODE --body "RUN" --repo mizunotaro/crm-lab-sandbox
```

---

## AI Watchdog Integration

The AI Watchdog workflow (runs every 15 minutes) monitors CI health and may automatically recommend setting `PAUSE` when:

- Consecutive CI failures reach threshold (default: 20)
- AI automation appears to be causing repeated failures

**Note:** The watchdog creates an issue (e.g., #397) but does NOT automatically change the variable. Human intervention is required to activate PAUSE.

---

## Workflow Behavior

### When AI_AUTOMATION_MODE=RUN

- AI Orchestrator runs every 15 minutes
- AI Triage runs on CI failures
- AI Daily runs scheduled tasks
- Normal automation behavior

### When AI_AUTOMATION_MODE=PAUSE

- AI Orchestrator skips execution
- AI Triage is suppressed
- AI Daily is suppressed
- Workflows log: "AI automation paused (AI_AUTOMATION_MODE=PAUSE)"

---

## Related Documentation

- `docs/ops/incident-response.md` - Incident response procedures
- `docs/ops/ai-automation-pause-procedure.md` - Step-by-step pause procedure
- `.github/workflows/ai-watchdog.yml` - Automated failure monitoring
- `.github/workflows/ai-orchestrator.yml` - Main AI automation entry point

---

## Troubleshooting

### Automation still running despite PAUSE

1. Verify variable is set correctly (case-sensitive: `PAUSE`)
2. Check that the variable is at the repository level, not environment level
3. Confirm variable name is exactly `AI_AUTOMATION_MODE` (no typos)
4. Check workflow logs for variable read errors

### Variable not taking effect immediately

- Workflows on a new schedule run after current workflow completes
- Manually dispatch workflow to test immediately

---

## Related Labels

| Label | Purpose |
|-------|---------|
| `ai:pause` | Manual pause indicator (optional) |
| `ai:blocked` | Requires human decision before automation can proceed |
| `ai:ready` | Queue: ready for AI run |
| `ai:in-progress` | AI working on this task |

---

**Reference:** See `AGENTS.md` §2.3 for autonomy levels and §7 for CI quality gates.
