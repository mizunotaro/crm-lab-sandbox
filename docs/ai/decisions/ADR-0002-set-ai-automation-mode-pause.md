# ADR-0002: Set AI_AUTOMATION_MODE=PAUSE Due to Frequent CI Failures

## Status
Proposed

## Context
Since 2026-02-10, the AI Watchdog workflow (runs every 15 minutes) has been creating multiple "AI Watchdog: PAUSE recommended" issues (#395, #426-457) due to frequent CI failures. The AI automation continues to operate in a mode that may be contributing to these failures or generating unnecessary noise.

### Problem
- Multiple PAUSE recommendation issues have been created (#395, #426-457)
- 20+ CI failures detected by the AI Watchdog
- AI automation may be creating additional issues without addressing the underlying problems
- No documented procedure for when to pause AI automation

### Requirements (Issue #395)
- Set AI_AUTOMATION_MODE=PAUSE
- Run triage to identify root causes of CI failures
- Establish clear criteria for when to pause and resume AI automation

## Decision
Set `AI_AUTOMATION_MODE=PAUSE` in GitHub repository variables and document the triage process:

1. **Pause AI Automation**
   - Set GitHub repository variable `AI_AUTOMATION_MODE=PAUSE`
   - This will stop AI agents from automatically creating/processing issues
   - Maintain manual control until CI stability is restored

2. **Triage Process**
   - Analyze recent CI failures to identify patterns
   - Review AI-generated issues for quality and relevance
   - Identify root causes of failures
   - Create remediation plan

3. **Resumption Criteria**
   - CI passes consistently for 24 hours
   - Root causes identified and fixed
   - AI automation guidelines updated
   - Manual approval to resume

## Alternatives Considered

### Alternative A: Continue Automation with Throttling
- **Pros:** AI automation continues to work
- **Cons:** May continue generating noise; doesn't address underlying issues
- **Rejected:** Too much risk of compounding failures

### Alternative B: Disable All AI Workflows
- **Pros:** Complete stop to automation
- **Cons:** Too disruptive; loses benefits of AI assistance entirely
- **Rejected:** Overkill; PAUSE mode provides sufficient control

### Alternative C: Increase Failure Threshold Before Pausing
- **Pros:** Fewer PAUSE recommendations
- **Cons:** Allows failures to accumulate before action
- **Rejected:** Reactive instead of proactive

## Consequences

### Positive
- ✅ Stops AI automation from creating additional issues during unstable period
- ✅ Allows focused triage of existing issues
- ✅ Preserves AI automation capability for later use
- ✅ Forces human review before resuming automation
- ✅ Creates documented pause/resume criteria

### Negative
- ⚠️ AI agents cannot assist with issue resolution during PAUSE
- ⚠️ Manual intervention required for all AI-related work
- ⚠️ Potential delay in addressing issues if triage takes too long

### Neutral
- 🔄 Existing AI-generated issues remain open
- 🔄 AI Watchdog continues running (read-only monitoring)
- 🔄 Documentation updated for future reference

## Migration / Rollback Plan

### Migration (PAUSE)
1. Set GitHub repository variable `AI_AUTOMATION_MODE=PAUSE`
2. Verify AI Orchestrator workflow respects the PAUSE mode
3. Begin triage process on existing issues
4. Document findings and remediation plan

### Rollback (RESUME)
If AI automation needs to resume:
1. Verify CI stability for 24+ hours
2. Set `AI_AUTOMATION_MODE=ACTIVE` (or equivalent active mode value)
3. Monitor AI-generated issue quality
4. Adjust thresholds/guidelines based on triage findings

## References
- Issue #395: AI Watchdog: PAUSE recommended (failures=20)
- Related Issues: #426-457 (PAUSE recommended issues)
- AGENTS.md: Project operating rules and agent guidelines
- docs/ops/incident-response.md: Incident response procedures

## Valid AI_AUTOMATION_MODE Values
Based on AI automation best practices:
- `PAUSE`: AI automation paused (manual control only)
- `ACTIVE`: AI automation fully operational (default for stable state)
- `OBSERVE`: AI automation in read-only mode (no changes)

Note: Exact values may vary based on external ai-playbook implementation.
