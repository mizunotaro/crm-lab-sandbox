# Issue #391: AI Watchdog PAUSE Recommendation

## Context

On 2026-02-11, the AI Watchdog workflow detected 20 CI failures and created issue #391 recommending to set `AI_AUTOMATION_MODE=PAUSE`.

## Analysis

### Local CI Status (2026-02-11)
- TypeScript checks: PASSED (`pnpm -r exec tsc --noEmit`)
- API tests: PASSED (`pnpm --filter @crm/api test:run`)

### GitHub Actions CI Status
Recent failures in AI Orchestrator workflow at "Run OpenCode" step:
- 2026-02-11T05:09:16Z - AI Orchestrator (failure)
- 2026-02-10T23:45:13Z - AI Orchestrator (failure)
- 2026-02-10T21:51:44Z - AI Orchestrator (failure)

The failures appear to be related to the OpenCode automation system, not the core codebase.

## Recommended Action

### Manual Steps to Pause AI Automation

As of 2026-02-11, the AI Orchestrator failures are external to the codebase. To pause the AI automation:

1. **Set the GitHub Actions variable:**
   ```bash
   gh variable set AI_AUTOMATION_MODE --repo $(git config --get remote.origin.url | sed 's|.*github.com[:/]||' | sed 's|\.git$||') --body "PAUSE"
   ```

2. **Verify the variable is set:**
   ```bash
   gh variable get AI_AUTOMATION_MODE --repo $(git config --get remote.origin.url | sed 's|.*github.com[:/]||' | sed 's|\.git$||')
   ```

3. **Manually triage the failures:**
   - Review the AI Orchestrator logs
   - Identify the root cause of the "Run OpenCode" failures
   - Determine if it's a transient issue or a systemic problem

4. **Resume automation (after triage):**
   ```bash
   gh variable set AI_AUTOMATION_MODE --repo $(git config --get remote.origin.url | sed 's|.*github.com[:/]||' | sed 's|\.git$||') --body "RUN"
   ```

## Notes

- The core CI (build, typecheck, tests) is passing
- The AI Watchdog is doing its job by detecting automation failures
- Setting `AI_AUTOMATION_MODE=PAUSE` will prevent the AI from creating new PRs until the issue is resolved
- This does NOT stop the manual CI runs on PRs and pushes to main

## Related Documentation

- AGENTS.md - Project operating rules
- .github/workflows/ai-watchdog.yml - AI Watchdog workflow
- .github/workflows/ai-orchestrator.yml - AI Orchestrator workflow
