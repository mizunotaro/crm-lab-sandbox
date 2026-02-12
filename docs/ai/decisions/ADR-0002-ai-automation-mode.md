# ADR-0002: AI Automation Mode and Triage Process

**Status:** Accepted
**Date:** 2026-02-10
**Context:** Issue #398 - AI Watchdog: PAUSE recommended (failures=20)

## Context

The AI Orchestrator workflow uses a repository variable `AI_AUTOMATION_MODE` to control automated issue processing. The AI Watchdog workflow monitors CI failures and creates issues recommending to pause automation when failure thresholds are exceeded.

### Current Behavior

- **AI Watchdog:** Runs every 15 minutes, checks last 50 CI runs, creates issue when failures >= 3
- **AI Orchestrator:** Checks `AI_AUTOMATION_MODE` variable; exits early if not set to "RUN"
- **Required Variables:** `AI_AUTOMATION_MODE`, `AI_MAX_OPEN_AI_PRS`, `AI_MAX_ATTEMPTS_PER_ISSUE`

### Valid AI_AUTOMATION_MODE Values

| Value | Behavior |
|-------|----------|
| `RUN` | Normal operation: Orchestrator picks and processes `ai:ready` issues |
| `PAUSE` | Orchestrator exits early; automation paused for manual triage |

## Decision

### 1. Variable Configuration

Set `AI_AUTOMATION_MODE` as a GitHub repository variable (not secret) with one of:
- `RUN` (default for normal operation)
- `PAUSE` (to pause automation for triage)

### 2. When to Use PAUSE Mode

Set `AI_AUTOMATION_MODE=PAUSE` when:
- AI Watchdog creates a triage issue (failures >= 3 in last 50 runs)
- Manual investigation is needed for CI failures
- Coordinating with team before resuming automation

### 3. Triage Process (When PAUSE is triggered)

1. **Immediate Actions:**
   - Set `AI_AUTOMATION_MODE=PAUSE` in repository variables
   - Review recent CI failures in GitHub Actions tab
   - Identify failure patterns (e.g., specific tests, time-based spikes)

2. **Investigation:**
   - Check PRs merged before failure spike
   - Review external dependencies (APIs, services)
   - Examine error logs from failed runs

3. **Resolution:**
   - Fix identified issues
   - Verify CI is green (run `ci.yml` manually if needed)
   - Document root cause in issue comments or session log

4. **Resume Automation:**
   - Set `AI_AUTOMATION_MODE=RUN`
   - Close the watchdog/triage issue with resolution notes

### 4. CI Failure Thresholds

- **Watchdog Trigger:** >= 3 failures in last 50 CI runs
- **Investigation Required:** >= 5 failures or persistent pattern
- **P0 Incident:** All CI runs failing for > 30 minutes

## Alternatives Considered

1. **Label-based control:** Use labels like `ai:pause` instead of variable
   - **Rejected:** Variable is checked early in orchestrator; labels require additional API calls
   - Variable provides immediate exit path

2. **Secret vs Variable:** Use GitHub secret for `AI_AUTOMATION_MODE`
   - **Rejected:** This is configuration, not a secret. Secrets add unnecessary overhead

3. **Automatic PAUSE on failure:** Watchdog sets PAUSE automatically
   - **Rejected:** Requires additional permissions (variable write). Manual review is safer

## Consequences

### Positive
- Clear circuit breaker for automation during CI instability
- Documented triage process reduces panic response
- Variable-based control is fast and reliable

### Negative
- Requires manual intervention to set PAUSE (cannot automate due to permissions)
- Must remember to set back to RUN after triage

### Migration Plan

No migration needed. Variable must be set manually via:
```bash
gh variable set AI_AUTOMATION_MODE --repo <owner/repo> --body "PAUSE"
```

Or via GitHub UI: Settings → Secrets and variables → Actions → Variables

## Rollback Plan

If PAUSE causes unintended issues:
1. Set `AI_AUTOMATION_MODE=RUN` immediately
2. Close any related watchdog issues as invalid
3. Review why the watchdog triggered (possible false positive)

## References

- Issue #398: AI Watchdog: PAUSE recommended (failures=20)
- `.github/workflows/ai-orchestrator.yml` - Pre-flight mode check
- `.github/workflows/ai-watchdog.yml` - Failure detection
- `ops/scripts/check-ai-prereqs.ps1` - Variable validation
- `AGENTS.md` §2.3 - Autonomy levels (A2 default, A3 requires human approval)
- `docs/ops/incident-response.md` - PAUSE circuit breaker procedures
