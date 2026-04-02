# Lessons Learned

This file documents lessons learned from AI automation operations in the CRM Lab Sandbox project.

---

## 2026-02-10: AI Automation Pause Due to CI Failures

### Issue
- Issue #395: AI Watchdog PAUSE recommended (failures=20)
- Related Issues: #426-457 (multiple PAUSE recommendation issues created)
- AI Watchdog running every 15 minutes detected 20+ CI failures

### Root Cause
- AI automation was running without a documented PAUSE mode trigger
- No clear criteria for when to pause AI automation
- AI Watchdog creating issues without actually pausing automation

### Lessons Learned

1. **Always Document PAUSE Triggers**
   - Define clear thresholds for when to pause AI automation
   - Document who can authorize PAUSE mode
   - Establish resumption criteria before pausing

2. **GitHub Repository Variables Are SSOT for AI Automation**
   - `AI_AUTOMATION_MODE` is required by check-ai-prereqs.ps1
   - Valid values: PAUSE, ACTIVE, OBSERVE (exact values may vary)
   - Setting these variables requires repo admin permissions (cannot be done via PR)

3. **AI Watchdog Should Be Configurable**
   - 15-minute frequency may be too aggressive for unstable CI
   - Failure threshold (20 failures) should be configurable
   - Consider making Watchdog actions dependent on AI_AUTOMATION_MODE

4. **Triage Before Resuming**
   - When PAUSE is triggered, run triage immediately
   - Identify root causes before resuming automation
   - Document findings and remediation plan

5. **Manual Override is Essential**
   - Always provide manual control for AI automation
   - PAUSE mode should stop issue creation but allow monitoring
   - Human approval required to resume ACTIVE mode

### Remediation Actions
- Set AI_AUTOMATION_MODE=PAUSE in GitHub repository variables (manual action required)
- Create ADR-0002 documenting the pause decision
- Update AGENTS.md if needed to reference PAUSE mode procedures
- Triage existing PAUSE recommendation issues (#395, #426-457)
- Establish clear resumption criteria

### Prevention
- Add PAUSE mode documentation to AGENTS.md
- Configure AI Watchdog thresholds as environment variables
- Add CI stability check before AI automation resumes
- Document escalation procedures for AI automation incidents

---

## 2026-02-02: AI Automation Hardening Session

### Issue
- Issues #181-#188 created via publish-issues pipeline
- Multiple failures during issue publishing process

### Lessons Learned

1. **Publisher Contract is SSOT**
   - wrapper scripts must match publisher parameter names exactly
   - Example: `IssueRootRel` not `IssuesRoot`

2. **[bool] Parameters Require Values**
   - `[bool]$DryRun` requires `-DryRun:$true` (not just `-DryRun`)
   - Switch parameters and boolean parameters are different

3. **In-Process Execution Preserves Types**
   - Use `&` call operator instead of `pwsh -File` to preserve types
   - Cross-process execution can break type conversions

4. **Get-Command Can Fail in Some Environments**
   - ArgumentList-related failures observed
   - Minimize introspection dependencies

5. **Default to Low-Noise**
   - Side effects (like auto-comments) should default to OFF
   - PostTaskLinksToSpec defaults to `$false`

6. **DryRun → Apply Two-Phase Validation**
   - Always use DryRun before Apply for safety
   - Validate targets and titles before creating issues

7. **Static Quality Gates Are Practical**
   - Check for AC/Verify/Rollback sections in issues
   - Can be automated with regex-based checks

### References
- ops/handoff/ai-automation-hardening_20260202/
- ADR-0001: Update-in-place mode for task links comments

---

## Future Work
- Consider adding automated PAUSE mode triggers based on CI failure thresholds
- Create runbook for AI automation incidents (referencing incident-response.md)
- Add monitoring dashboards for AI automation metrics
- Document all valid AI_AUTOMATION_MODE values and their behaviors
