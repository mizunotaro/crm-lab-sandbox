# AI Automation Mode

**Version:** 1.0  
**Last Updated:** 2026-02-02  
**Purpose:** Controls AI automation behavior in GitHub Actions workflows.

## Overview

`AI_AUTOMATION_MODE` is a repository-level environment variable that controls whether AI agents can automatically create issues, pull requests, and make changes to the repository.

## Modes

### PAUSE (Default for incidents)
- **Description:** Stops all AI automation. No new issues, PRs, or code changes will be created by AI agents.
- **Use When:**
  - Frequent CI failures detected (e.g., > 5 failures in 1 hour)
  - Security incident in progress
  - Manual intervention required
  - Testing changes without AI interference
- **Activation:** Set `AI_AUTOMATION_MODE=PAUSE` in repository variables
- **Effect:** AI workflows will skip all automated actions but continue to monitor

### AUTO
- **Description:** Full AI automation enabled. AI agents can create issues, PRs, and code changes.
- **Use When:**
  - CI is stable (all tests passing)
  - No active incidents
  - Normal operations
- **Activation:** Set `AI_AUTOMATION_MODE=AUTO` in repository variables
- **Effect:** AI agents operate normally

## Emergency PAUSE Procedure

### When to Activate PAUSE

1. **Frequent CI Failures**: AI Watchdog (issue #195) detects 20+ failures
2. **Security Incident**: Any confirmed or suspected security issue
3. **Data Risk**: Potential data loss or corruption
4. **Manual Override**: Need to take manual control

### How to Activate PAUSE

**Via GitHub UI:**
1. Go to repository Settings → Secrets and variables → Actions
2. Click "New repository variable"
3. Name: `AI_AUTOMATION_MODE`
4. Value: `PAUSE`
5. Click "Add variable"

**Via GitHub CLI:**
```bash
gh variable set AI_AUTOMATION_MODE --body "PAUSE"
```

**Note:** Requires repo admin permissions.

### How to Resume AUTO

**Via GitHub UI:**
1. Go to repository Settings → Secrets and variables → Actions
2. Find `AI_AUTOMATION_MODE` variable
3. Update value to: `AUTO`
4. Click "Update variable"

**Via GitHub CLI:**
```bash
gh variable set AI_AUTOMATION_MODE --body "AUTO"
```

## Triage Checklist After PAUSE

When `AI_AUTOMATION_MODE=PAUSE` is activated, complete these steps before resuming AUTO:

### 1. Assess Situation
- [ ] Review CI failure logs
- [ ] Identify root cause
- [ ] Determine impact scope
- [ ] Check for security incidents

### 2. Fix Underlying Issues
- [ ] Create issues for each problem found
- [ ] Fix broken tests
- [ ] Update dependencies if needed
- [ ] Address security vulnerabilities

### 3. Verify Fixes
- [ ] Run CI manually (or wait for next scheduled run)
- [ ] Confirm all tests passing
- [ ] Review any AI-generated code for correctness
- [ ] Check for unintended side effects

### 4. Resume AUTO
- [ ] Set `AI_AUTOMATION_MODE=AUTO`
- [ ] Monitor first few AI actions for correctness
- [ ] Update documentation with lessons learned

## Monitoring

### AI Watchdog Workflow

The `.github/workflows/ai-watchdog.yml` workflow runs every 15 minutes and:
- Checks for CI failures
- Monitors AI automation activity
- Creates issues when failures exceed thresholds
- Recommends PAUSE mode when appropriate

### Alerts

- **Warning:** 5+ CI failures in 1 hour
- **Critical:** 20+ CI failures in 1 hour (triggers issue #195)

## Related Documentation

- [Incident Response Template](./incident-response.md) - For handling security incidents
- [Feature Flags](./feature-flags.md) - For application-level feature toggles
- [Monitoring & Alerts](./monitoring-alerts.md) - For Cloud Run/Cloud SQL monitoring

## Current Status

- **Issue:** #195 - AI Watchdog: PAUSE recommended (failures=20)
- **Action Required:** Set `AI_AUTOMATION_MODE=PAUSE`
- **Triage Owner:** TBD
- **Resume Criteria:** CI green for 24 hours, root cause fixed

## FAQ

**Q: Can AI agents still read the repo in PAUSE mode?**  
A: Yes, AI agents can still read and analyze the codebase, but cannot write or create issues/PRs.

**Q: Will existing PRs be affected?**  
A: No, existing PRs are not affected. PAUSE only prevents new AI-generated content.

**Q: Can I still manually create issues and PRs?**  
A: Yes, human-created content is not affected by AI_AUTOMATION_MODE.

**Q: How long should I stay in PAUSE mode?**  
A: Minimum 1 hour after fixes are deployed, longer if issues are complex or security-related.

**Q: What if I forget to set this variable?**  
A: The AI workflows assume AUTO by default. It's safer to explicitly set the variable.

---

**Reference:** See `AGENTS.md` for agent operating rules and `docs/ops/incident-response.md` for emergency procedures.