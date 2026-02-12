# AI Automation Pause Procedure

## Overview

This document provides step-by-step instructions for pausing and resuming AI automation when CI failures are detected by the AI Watchdog.

## When to Pause

The AI Watchdog will create an issue with the title "AI Watchdog: PAUSE recommended (failures=N)" when:
- >= 20 CI failures detected in recent runs
- Failures are frequent and persistent
- Human investigation is required

**Do not ignore watchdog alerts.** Frequent CI failures indicate a problem that requires attention.

## Step-by-Step Pause Procedure

### 1. Acknowledge the Watchdog Issue

1. Navigate to the AI Watchdog issue (e.g., #396)
2. Add a comment: "Investigating. Will pause AI automation."

### 2. Set AI_AUTOMATION_MODE=PAUSE

**Option A: Using GitHub CLI**
```bash
gh variable set AI_AUTOMATION_MODE --repo mizunotaro/crm-lab-sandbox --body "PAUSE"
```

**Option B: Using GitHub UI**
1. Go to repository Settings
2. Navigate to Secrets and variables → Actions → Variables
3. Click "New repository variable"
4. Name: `AI_AUTOMATION_MODE`
5. Value: `PAUSE`
6. Click "Add variable"

### 3. Verify Pause is Active

**Option A: Check via GitHub CLI**
```bash
gh variable view AI_AUTOMATION_MODE --repo mizunotaro/crm-lab-sandbox
```
Expected output: `PAUSE`

**Option B: Check via GitHub UI**
1. Go to repository Settings
2. Navigate to Secrets and variables → Actions → Variables
3. Confirm `AI_AUTOMATION_MODE` is set to `PAUSE`

### 4. Review Failed CI Runs

**List recent failures:**
```bash
gh run list --limit 50 --json status,conclusion,displayTitle,createdAt,workflowName \
  --jq '.[] | select(.conclusion == "failure") | {title: .displayTitle, workflow: .workflowName, created: .createdAt}'
```

**Analyze patterns:**
- Which workflows are failing?
- What are the error messages?
- Is there a common root cause?

### 5. Create Tracking Issue (if not already created)

Create an issue documenting:
- Root cause analysis
- Impact assessment
- Proposed fix
- Steps to reproduce

### 6. Implement Fix

Create one or more PRs to address the root cause:
- Update configuration
- Fix code bugs
- Update dependencies
- Adjust thresholds

### 7. Verify CI is Green

**Wait for CI to pass:**
```bash
gh run list --limit 30 --json conclusion --jq '.[] | select(.conclusion != "success")'
```
Expected: No output (all runs successful)

**Manually trigger workflows to verify:**
```bash
gh workflow run ci.yml --repo mizunotaro/crm-lab-sandbox
gh workflow run ai-orchestrator.yml --repo mizunotaro/crm-lab-sandbox
```

Check results:
```bash
gh run list --limit 5 --json status,conclusion,displayTitle
```

### 8. Set AI_AUTOMATION_MODE=RUN

**Option A: Using GitHub CLI**
```bash
gh variable set AI_AUTOMATION_MODE --repo mizunotaro/crm-lab-sandbox --body "RUN"
```

**Option B: Using GitHub UI**
1. Go to repository Settings
2. Navigate to Secrets and variables → Actions → Variables
3. Find `AI_AUTOMATION_MODE`
4. Update value to `RUN`
5. Click "Update variable"

### 9. Close Watchdog Issue

1. Return to the AI Watchdog issue
2. Add a closing comment with:
   - Root cause summary
   - Fix implemented
   - CI status confirmation
   - Reference to fix PR(s)

Example:
```
Resolved AI Watchdog alert (20 failures).

Root cause: [brief description]
Fix: PR #454 - [PR title]
CI status: Green (0 failures in last 30 runs)
AI_AUTOMATION_MODE: Set to RUN
```

3. Close the issue

## Common Scenarios

### Scenario 1: False Positive

If the watchdog triggers but investigation shows no real problem:

1. Document findings in watchdog issue
2. Adjust thresholds if needed (requires updating external workflow)
3. Keep AI_AUTOMATION_MODE=RUN (or set to RUN if already paused)
4. Close watchdog issue with notes

### Scenario 2: External Service Outage

If failures are due to external services (e.g., API rate limits):

1. Document the outage
2. Implement retry logic or circuit breakers (future work)
3. Keep AI_AUTOMATION_MODE=PAUSE until service recovers
4. Resume when service is stable

### Scenario 3: Code Regression

If failures are due to a recent code change:

1. Identify the problematic PR or commit
2. Revert or fix the regression
3. Merge fix PR
4. Verify CI is green
5. Resume automation

## Checklist

Before pausing:
- [ ] Watchdog issue reviewed
- [ ] Failure patterns analyzed
- [ ] Root cause identified

After pausing:
- [ ] AI_AUTOMATION_MODE=PAUSE set
- [ ] Tracking issue created/updated
- [ ] Fix PR(s) created
- [ ] CI verified green

Before resuming:
- [ ] Root cause fixed
- [ ] CI green (no failures in recent runs)
- [ ] Fix tested and verified

After resuming:
- [ ] AI_AUTOMATION_MODE=RUN set
- [ ] Watchdog issue closed with resolution notes
- [ ] Post-mortem documented (if applicable)

## References

- AI Automation Mode: `docs/ops/ai-automation-mode.md`
- Incident Response: `docs/ops/incident-response.md`
- AGENTS.md: Project operating rules
