# AI Automation Mode

## Overview

`AI_AUTOMATION_MODE` is a repository variable that controls whether AI automation (orchestrator, watchdog, triage) runs automatically or pauses.

## Valid Values

| Value | Behavior |
|-------|----------|
| `RUN` | AI automation runs normally (default) |
| `PAUSE` | AI automation is paused; workflows skip execution |

## When to Use PAUSE

Use `AI_AUTOMATION_MODE=PAUSE` when:

- **AI Watchdog detects frequent CI failures** (e.g., >= 20 failures)
- **Human investigation is needed** to understand root cause
- **Blocking issues exist** that require human attention
- **Emergency situation** requiring manual control

## Triage Process

### Immediate Actions

1. Set `AI_AUTOMATION_MODE=PAUSE`:
   ```bash
   gh variable set AI_AUTOMATION_MODE --repo mizunotaro/crm-lab-sandbox --body "PAUSE"
   ```
   Or via GitHub UI: Settings → Secrets and variables → Actions → Variables

2. Acknowledge the watchdog issue with a comment

### Investigation

3. Review failed CI runs:
   ```bash
   gh run list --limit 50 --json status,conclusion,displayTitle,createdAt --jq '.[] | select(.conclusion == "failure")'
   ```

4. Identify patterns:
   - Which workflows are failing?
   - What are the error messages?
   - Is there a root cause common across failures?

5. Create or update issue tracking the investigation

### Resolution

6. Fix the root cause (create PRs, update configuration, etc.)

7. Verify CI is green:
   ```bash
   gh run list --limit 30 --json conclusion --jq '.[] | select(.conclusion != "success")'
   ```

### Resume

8. Set `AI_AUTOMATION_MODE=RUN`:
   ```bash
   gh variable set AI_AUTOMATION_MODE --repo mizunotaro/crm-lab-sandbox --body "RUN"
   ```

9. Close the watchdog issue with resolution notes

## Workflow Implementation

The `ai-orchestrator.yml` workflow includes a guard job:

```yaml
check_pause:
  if: ${{ github.event_name == 'schedule' || github.event_name == 'workflow_dispatch' }}
  runs-on: ubuntu-latest
  steps:
    - name: Check AI_AUTOMATION_MODE
      id: check
      run: |
        MODE="${{ vars.AI_AUTOMATION_MODE }}"
        if [ "$MODE" = "PAUSE" ]; then
          echo "status=paused" >> $GITHUB_OUTPUT
          echo "AI automation paused (AI_AUTOMATION_MODE=PAUSE)"
        else
          echo "status=running" >> $GITHUB_OUTPUT
        fi
```

If paused, subsequent jobs are skipped with `if: needs.check_pause.outputs.status == 'running'`.

## CI Failure Thresholds

- **Watchdog trigger**: 20+ failures in recent runs
- **Recommendation**: Pause and investigate
- **Recovery**: CI green (0 failures) before resuming

## References

- External workflow: `mizunotaro/ai-playbook/.github/workflows/reuse-ai-watchdog.yml@ce0d8fc`
- Incident response: `docs/ops/incident-response.md`
- AGENTS.md: Project operating rules

## Security

- `AI_AUTOMATION_MODE` is a **repository variable**, not a secret
- Changes require repository admin permissions
- Audit trail exists in GitHub Actions logs
