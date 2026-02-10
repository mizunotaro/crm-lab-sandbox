# Lessons Learned

This document captures cumulative lessons learned during AI automation operations and CI/CD management.

## 2026-02-10: CI Failure Triage and AI Automation PAUSE (Issue #404)

### Problem
AI Watchdog detected 20 CI failures and recommended setting `AI_AUTOMATION_MODE=PAUSE`. Multiple AI-related workflows were failing repeatedly, wasting CI resources and potentially creating cascading issues.

### Root Cause
- CI failures in AI Orchestrator and AI Prerequisites Preflight Check workflows
- Possible causes: API rate limits, credential issues, network problems, or model service availability
- AI automation continued running every 15 minutes despite failures

### What Worked
- AI Watchdog workflow detected the pattern and created issue #404
- Clear recommendation to set `AI_AUTOMATION_MODE=PAUSE`
- Documentation captured in session log and triage report

### What Didn't Work
- Cannot directly read/modify repository variables via gh CLI due to API permissions (403 error)
- Requires manual intervention to set `AI_AUTOMATION_MODE=PAUSE` in repository settings
- No automatic PAUSE activation even after threshold detection

### Lessons

1. **Manual Intervention Still Required:**
   - Even with automated monitoring, some actions require human approval
   - Setting `AI_AUTOMATION_MODE=PAUSE` must be done manually via repository settings
   - Consider adding a workflow step that outputs clear instructions when threshold is reached

2. **Circuit Breaker Enhancement Needed:**
   - Current AI Watchdog detects failures but doesn't stop automation
   - Consider implementing automatic PAUSE after N consecutive failures (beyond current threshold of 20)
   - Add notification to maintainers when threshold is approached (e.g., at 15 failures)

3. **Monitoring Gaps:**
   - No alerts for AI API rate limits or service availability
   - Need better visibility into why workflows are failing (API errors vs. code issues)
   - Consider adding workflow-specific success rate monitoring

4. **Documentation Process:**
   - Session logs and triage reports are valuable for post-incident analysis
   - Should update this lessons-learned file after each incident
   - Consider automating some documentation generation

### Action Items
- [ ] Add workflow step to ai-watchdog.yml that outputs clear manual intervention instructions
- [ ] Consider implementing automatic PAUSE activation after exceeding threshold
- [ ] Add alerts for AI API rate limits and service availability
- [ ] Create runbook for "Red CI" incidents involving AI automation
- [ ] Consider adjusting failure thresholds or adding exponential backoff

### Related Documents
- Issue #404: AI Watchdog: PAUSE recommended
- Triage Report: `docs/ai/triage/20260210_404-ci-failures.md`
- Session Log: `docs/ai/session-log/20260210_0514.md`
- Incident Response: `docs/ops/incident-response.md`
