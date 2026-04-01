# AI Automation Mode

**Version:** 1.0  
**Last Updated:** 2026-02-23  
**Purpose:** Controls AI automation behavior and provides circuit breaker for CI/CD stability.

---

## Overview

`AI_AUTOMATION_MODE` is a repository-level GitHub Actions variable that controls whether AI agents can automate tasks in this repository. It acts as a circuit breaker to prevent AI agents from creating cascading failures when CI is unstable.

---

## Valid Values

| Value | Behavior | When to Use |
|-------|----------|-------------|
| `ACTIVE` | AI agents can create issues, PRs, and automated commits | Normal operations, CI stable |
| `PAUSE` | AI agents stop creating new automated changes | CI failures detected, under investigation |
| `TESTING` | AI agents operate but with limited scope | Testing AI agent changes |

---

## Setting the Variable

### Via GitHub Web UI

1. Navigate to repository Settings → Actions → General → Variables
2. Click "New repository variable"
3. Name: `AI_AUTOMATION_MODE`
4. Value: `ACTIVE`, `PAUSE`, or `TESTING`
5. Click "Add variable"

### Via GitHub CLI (requires admin permissions)

```bash
gh variable set AI_AUTOMATION_MODE --body "PAUSE"
```

---

## Circuit Breaker Behavior

### When to Set PAUSE

Set `AI_AUTOMATION_MODE=PAUSE` when:
- AI Watchdog reports 20+ CI failures
- Multiple AI agent PRs are causing cascading failures
- Manual triage required before automation resumes
- During production deployment freeze periods

### PAUSE Mode Effects

When `AI_AUTOMATION_MODE=PAUSE`:
- AI Orchestrator skips new issue processing
- AI agents do not create new PRs or commits
- Existing AI-labeled issues can still be manually addressed
- CI continues to run normally

---

## Monitoring

### AI Watchdog Integration

The AI Watchdog workflow runs every 15 minutes and monitors:
- CI failure rate
- Time since last successful CI run
- Number of consecutive AI agent failures

When thresholds are exceeded, it creates an issue with title:
`AI Watchdog: PAUSE recommended (failures=N)`

### Checking Current Mode

```bash
gh variable get AI_AUTOMATION_MODE
```

---

## Resuming Automation

### Prerequisites

Before setting back to `ACTIVE`:
1. [ ] CI is green (all required checks passing)
2. [ ] Root cause of failures identified and fixed
3. [ ] Test with a controlled AI agent run (optional)
4. [ ] Session log updated with findings

### Steps

1. Set `AI_AUTOMATION_MODE=ACTIVE`
2. Monitor next few AI agent runs
3. Verify no cascading failures occur
4. Document in session log

---

## Integration with Other Controls

### Labels

The AI Orchestrator checks for the `ai:pause` label on issues. When set:
- Overrides `AI_AUTOMATION_MODE=ACTIVE` for specific issues
- Allows selective pausing of specific work

### Rate Limits

`AI_MAX_OPEN_AI_PRS` and `AI_MAX_ATTEMPTS_PER_ISSUE` provide additional throttling independent of automation mode.

---

## Troubleshooting

### Variable Not Found

Error: `AI_AUTOMATION_MODE missing`

**Fix:** Create the variable as described above. Value must be one of: `ACTIVE`, `PAUSE`, `TESTING`.

### AI Still Creating PRs Despite PAUSE

Check:
1. Variable value is exactly `PAUSE` (case-sensitive)
2. Repository-level (not environment-level) variable is set
3. No workflow is bypassing the check
4. Check `ops/logs/check-ai-prereqs-*.json` for variable validation results

---

## Related Documentation

- `ops/scripts/check-ai-prereqs.ps1` - Prerequisite validation script
- `.github/workflows/ai-watchdog.yml` - AI Watchdog workflow
- `.github/workflows/ai-orchestrator.yml` - AI Orchestrator workflow
- `docs/ops/incident-response.md` - PAUSE circuit breaker procedures
- `AGENTS.md` - AI agent operating rules
