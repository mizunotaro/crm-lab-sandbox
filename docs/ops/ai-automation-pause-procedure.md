# AI Automation Pause Procedure

**Version:** 1.0  
**Last Updated:** 2026-02-10  
**Purpose:** Step-by-step procedure for pausing and resuming AI automation during incidents

---

## Pre-Pause Checklist

Before pausing AI automation, verify:

- [ ] Confirm issue: e.g., AI Watchdog issue created with failure count
- [ ] Review recent CI failures to understand scope
- [ ] Check if any automated PRs are in-flight
- [ ] Identify affected workflows (ai-orchestrator, ai-triage, ai-daily)

---

## Step 1: Activate PAUSE Mode

### 1.1 Set Repository Variable

```bash
gh variable set AI_AUTOMATION_MODE --body "PAUSE" --repo mizunotaro/crm-lab-sandbox
```

**Or via GitHub UI:**
1. Settings → Secrets and variables → Actions → Variables
2. New repository variable: `AI_AUTOMATION_MODE = PAUSE`

### 1.2 Add Pause Label to Triggering Issue (If exists)

```bash
gh issue edit 397 --add-label "ai:pause" --repo mizunotaro/crm-lab-sandbox
```

### 1.3 Create or Update Incident Ticket

If not already created, create an issue with:
- Title: `AI Automation: PAUSED - [reason]`
- Label: `ai:blocked`
- Description: Include failure count, timestamp, and initial assessment

---

## Step 2: Verify PAUSE is Active

### 2.1 Check Variable

```bash
gh variable get AI_AUTOMATION_MODE --repo mizunotaro/crm-lab-sandbox
```

Expected output: `PAUSE`

### 2.2 Wait for Next Scheduled Run

- AI Orchestrator runs every 15 minutes
- Manually trigger workflow to verify immediately:
  ```bash
  gh workflow run ai-orchestrator.yml --repo mizunotaro/crm-lab-sandbox
  ```

### 2.3 Check Workflow Logs

Run logs should show:
```
AI automation paused (AI_AUTOMATION_MODE=PAUSE)
```

---

## Step 3: Conduct Triage

### 3.1 Gather Evidence

- [ ] Review CI failure logs (last 20+ runs)
- [ ] Check AI agent session logs: `docs/ai/session-log/`
- [ ] Review open AI-generated PRs
- [ ] Check dependency logs: `ops/logs/`

### 3.2 Identify Root Cause

Common causes:
- API rate limiting / quota exhaustion
- Dependency conflicts
- Environment misconfiguration
- Logic errors in AI-generated code
- Test flakiness

### 3.3 Document Findings

Create or update incident issue with:
- Root cause analysis
- Affected components
- Proposed remediation steps
- Estimated time to resume

---

## Step 4: Remediation

### 4.1 Apply Fixes

- Fix code issues
- Update dependencies
- Adjust configuration
- Fix test flakiness

### 4.2 Verify CI is Green

```bash
gh run list --repo mizunotaro/crm-lab-sandbox --limit 5
```

Ensure at least 3 consecutive successful CI runs.

---

## Step 5: Resume AI Automation

### 5.1 Set Repository Variable to RUN

```bash
gh variable set AI_AUTOMATION_MODE --body "RUN" --repo mizunotaro/crm-lab-sandbox
```

### 5.2 Remove Pause Label (if added)

```bash
gh issue edit 397 --remove-label "ai:pause" --repo mizunotaro/crm-lab-sandbox
```

### 5.3 Close Incident Issue (if resolved)

```bash
gh issue close 397 --comment "Resumed AI automation. CI is green." --repo mizunotaro/crm-lab-sandbox
```

### 5.4 Verify Resumption

- Wait for next scheduled AI Orchestrator run
- Or manually trigger: `gh workflow run ai-orchestrator.yml`
- Check logs show normal execution

---

## Quick Reference Commands

```bash
# Check current mode
gh variable get AI_AUTOMATION_MODE --repo mizunotaro/crm-lab-sandbox

# Pause
gh variable set AI_AUTOMATION_MODE --body "PAUSE" --repo mizunotaro/crm-lab-sandbox

# Resume
gh variable set AI_AUTOMATION_MODE --body "RUN" --repo mizunotaro/crm-lab-sandbox

# Add pause label to issue
gh issue edit <ISSUE_NUMBER> --add-label "ai:pause" --repo mizunotaro/crm-lab-sandbox

# List AI-related workflows
gh workflow list --repo mizunotaro/crm-lab-sandbox | grep ai

# Trigger workflow manually
gh workflow run <WORKFLOW_FILE> --repo mizunotaro/crm-lab-sandbox

# Check recent CI runs
gh run list --repo mizunotaro/crm-lab-sandbox --limit 10
```

---

## Emergency Rollback

If resumption causes new failures:

1. Immediately re-activate PAUSE:
   ```bash
   gh variable set AI_AUTOMATION_MODE --body "PAUSE" --repo mizunotaro/crm-lab-sandbox
   ```

2. Reopen incident issue and update with new findings

3. Investigate further before resuming

---

## Related Documentation

- `docs/ops/ai-automation-mode.md` - Variable configuration reference
- `docs/ops/incident-response.md` - General incident response procedures
- `AGENTS.md` - Project operating rules

---

**Reference:** See `AGENTS.md` §7.2 for "Red CI" protocol.
