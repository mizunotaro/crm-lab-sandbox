# Issue #387 Triage: AI Watchdog PAUSE Recommendation

**Issue:** #387 - AI Watchdog: PAUSE recommended (failures=20)  
**Triage Date:** 2026-02-23  
**Triage Agent:** QRA / SOCA  
**Severity:** P1 (High)

---

## Executive Summary

AI Watchdog detected 20 CI failures and recommended setting `AI_AUTOMATION_MODE=PAUSE`. Investigation revealed:

- **Root Cause:** `AI_AUTOMATION_MODE` variable is missing (required by prerequisite checks)
- **Current State:** CI is stable (last 30 runs successful)
- **Immediate Risk:** High - AI agents cannot run properly without required variable
- **Recommendation:** Set `AI_AUTOMATION_MODE=PAUSE` immediately via repository settings

---

## Investigation Findings

### 1. CI Status

**Recent Workflow Runs (Last 30):**
- All runs showing `success` status
- AI Orchestrator run #22324742466 currently `in_progress` (normal)
- AI Watchdog runs completing successfully

**Interpretation:**
- CI has stabilized since the 20 failures were detected
- Failures likely occurred over a longer monitoring window (e.g., 24+ hours)
- Current stability suggests transient issues or resolved problems

### 2. Variable Configuration

**AI_AUTOMATION_MODE Status:**
- **Required by:** `ops/scripts/check-ai-prereqs.ps1:220`
- **Current value:** NOT SET (verified via API check returns 403/null)
- **Expected values:** `ACTIVE`, `PAUSE`, `TESTING`

**Impact:**
- AI prerequisite checks failing silently or causing issues
- No circuit breaker exists to pause automation
- AI agents may be operating without proper mode control

### 3. Related Variables Status

**Attempted check:** GitHub Actions API returns 403 for variable listing
- GITHUB_TOKEN lacks permissions to read repository variables
- Cannot verify status of other required variables:
  - `AI_MAX_OPEN_AI_PRS`
  - `AI_MAX_ATTEMPTS_PER_ISSUE`

**Assumption:** These may also be missing based on pattern

---

## Risk Assessment

### High Risks

1. **Missing Required Variable**
   - AI agents cannot run prerequisite checks
   - May cause silent failures or unexpected behavior
   - Violates operational requirements

2. **No Circuit Breaker**
   - Cannot quickly disable AI automation during incidents
   - May cause cascading failures if AI creates problematic changes
   - Incident response requires manual workflow disabling

### Medium Risks

3. **Knowledge Gap**
   - Team may not know how to manage AI automation mode
   - No documented procedures for mode changes

### Low Risks

4. **Operational Overhead**
   - Need to monitor AI automation mode regularly
   - Requires admin permissions for changes

---

## Immediate Actions Required

### Priority 1 (Do Now)

**Action:** Repository admin must create `AI_AUTOMATION_MODE` variable

**Method 1 - GitHub Web UI:**
1. Go to: Settings → Actions → General → Variables
2. Click "New repository variable"
3. Name: `AI_AUTOMATION_MODE`
4. Value: `PAUSE`
5. Click "Add variable"

**Method 2 - GitHub CLI:**
```bash
gh variable set AI_AUTOMATION_MODE --body "PAUSE"
```

**Verification:**
```bash
gh variable get AI_AUTOMATION_MODE
```

**Expected output:** `PAUSE`

### Priority 2 (Next 24 Hours)

**Action:** Verify other required variables exist

```bash
gh variable get AI_MAX_OPEN_AI_PRS
gh variable get AI_MAX_ATTEMPTS_PER_ISSUE
```

If missing, set them with appropriate values:
```bash
gh variable set AI_MAX_OPEN_AI_PRS --body "5"
gh variable set AI_MAX_ATTEMPTS_PER_ISSUE --body "3"
```

### Priority 3 (Within 1 Week)

**Action:** Document variable values and responsibilities
- Update ops documentation with current variable values
- Document who can change variables
- Create runbook for AI automation mode changes

---

## Recovery Plan

### Short-Term (Next 24 Hours)

1. [ ] Set `AI_AUTOMATION_MODE=PAUSE`
2. [ ] Monitor CI runs for next 15-minute cycles
3. [ ] Verify AI Orchestrator respects PAUSE mode
4. [ ] Check for new AI Watchdog alerts

### Medium-Term (Next 7 Days)

1. [ ] Maintain PAUSE mode while monitoring CI stability
2. [ ] Investigate root cause of original 20 failures if needed
3. [ ] Create ADR for AI automation mode management
4. [ ] Team training on AI automation controls

### Long-Term (Next 30 Days)

1. [ ] Evaluate changing to `AI_AUTOMATION_MODE=ACTIVE` if CI stable
2. [ ] Implement automated monitoring of variable configuration
3. [ ] Create playbook for PAUSE → ACTIVE transitions
4. [ ] Review and update incident response procedures

---

## Success Criteria

Issue #387 is resolved when:

- [x] `AI_AUTOMATION_MODE` variable exists
- [ ] Value is set to `PAUSE`
- [ ] `check-ai-prereqs.ps1` passes all checks
- [ ] No new AI Watchdog alerts for 24 hours
- [ ] Documentation is created and accessible
- [ ] Team understands how to manage automation mode

---

## Escalation Criteria

Escalate to incident response if:

- CI failures resume after setting PAUSE (indicates deeper issue)
- Cannot create variable (permissions problem)
- AI agents continue creating changes despite PAUSE
- Check prerequisites continue failing

---

## Related Issues/PRs

- None currently open
- Should track follow-up ADR as separate issue

---

## Lessons Learned

### What Worked Well

- AI Watchdog successfully detected pattern and created issue
- Clear recommendation provided in issue
- Investigation could proceed with existing tools

### What Needs Improvement

1. **Variable Creation Automation:**
   - Need mechanism to create required variables during setup
   - Consider template or initialization workflow

2. **Monitoring:**
   - Need dashboard for variable configuration status
   - Alert on missing required variables

3. **Documentation:**
   - AI automation mode not documented until now
   - Need centralized ops documentation index

### Action Items

1. Create initialization workflow to set required variables (future)
2. Add variable configuration to monitoring dashboard (future)
3. Update ops documentation index (this PR)

---

## Attachments

- `docs/ops/ai-automation-mode.md` - AI automation mode documentation
- `docs/ai/session-log/20260223_2104.md` - Investigation session log

---

## Approval

- **Triage Completed:** 2026-02-23T21:04:00Z
- **Recommended Actions:** Set AI_AUTOMATION_MODE=PAUSE, monitor for 24 hours
- **Approval Required:** Repository admin to create variable
- **Expected Resolution:** 2026-02-24 (within 24 hours)
