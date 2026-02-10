# ADR-001 - Pause AI Automation Due to Frequent CI Failures

## Status: Accepted

## Context

Issues #402, #403, and #404 were raised by the AI Watchdog system indicating frequent CI failures (20 failures detected). The AI Watchdog recommended setting `AI_AUTOMATION_MODE=PAUSE` and running triage.

### Symptom
- Frequent CI failures occurring in AI-generated PRs
- AI automation creating PRs that fail CI checks
- Wasted CI resources on failing builds

## Decision

1. Set `AI_AUTOMATION_MODE` repository variable to `PAUSE`
2. Document this configuration in `docs/ai/PROJECT_ENV_SPEC.md` as SSOT
3. Require manual approval before resuming `AUTO` mode

## Alternatives Considered

1. **Continue AUTO mode** - Rejected: Would continue wasting CI resources
2. **Delete AI workflows** - Rejected: Too destructive, loses automation capability
3. **Reduce CI frequency** - Rejected: Does not address root cause of failures
4. **PAUSE mode with triage** - Accepted: Safer, allows investigation while preserving infrastructure

## Consequences

### Positive
- Stops creation of failing AI PRs
- Allows team to investigate root cause
- Preserves AI automation infrastructure for future use
- Improves CI resource utilization

### Negative
- AI automation paused until manually resumed
- Requires human intervention for triage

### Neutral
- Creates documentation precedent for operational SSOT

## Migration / Rollback Plan

### Migration (PAUSE -> AUTO)
1. Investigate and fix CI failure root causes
2. Run test suite to verify fixes
3. Update `AI_AUTOMATION_MODE` to `AUTO` via:
   ```bash
   gh variable set AI_AUTOMATION_MODE --body "AUTO"
   ```
4. Monitor AI Watchdog for failure count
5. If failures exceed threshold, repeat PAUSE process

### Rollback (AUTO -> PAUSE)
1. Set `AI_AUTOMATION_MODE` to `PAUSE` via:
   ```bash
   gh variable set AI_AUTOMATION_MODE --body "PAUSE"
   ```
2. Close any in-progress AI PRs if needed
3. Run triage on existing failures

## References

- Issue #402: AI Watchdog: PAUSE recommended (failures=20)
- Issue #403: AI Watchdog: PAUSE recommended (failures=20)
- Issue #404: AI Watchdog: PAUSE recommended (failures=20)
- PR #440: PR: Pause AI automation (20 CI failures) - addresses #403
- `docs/ai/PROJECT_ENV_SPEC.md` - Operational configuration SSOT
- `AGENTS.md` - Section 3.3 Multi-agent workflow
- `ops/scripts/check-ai-prereqs.ps1` - Prerequisites check script
