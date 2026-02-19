# PROJECT_ENV_SPEC.md — Project Environment Specification

**Version:** 1.0.0
**Status:** Active
**Purpose:** Define environment variables, labels, and operational controls for AI automation

---

## Required GitHub Actions Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `AI_AUTOMATION_MODE` | string | `RUN` | Controls AI automation behavior. Values: `RUN` (normal), `PAUSE` (stop new AI runs), `MAINTENANCE` (read-only) |
| `AI_MAX_OPEN_AI_PRS` | number | `5` | Maximum number of open AI-generated PRs |
| `AI_MAX_ATTEMPTS_PER_ISSUE` | number | `3` | Maximum retry attempts per issue |

---

## AI Labels (GitHub)

### Status Labels
- `ai:ready` - Queue: ready for AI run
- `ai:in-progress` - AI working
- `ai:blocked` - Stop: needs decision / prevent rerun
- `ai:pr-open` - PR created; awaiting review/merge

### Control Labels
- `ai:pause` - Pause AI automation (used with AI_AUTOMATION_MODE=PAUSE)
- `ai:approved` - Human approved
- `ai:risky-change` - Potential unexpected change; needs review
- `ai:deps` - Deps upgrade allowed
- `ai:triage` - Triage needed

---

## AI_AUTOMATION_MODE Values

### RUN
- Normal AI automation operation
- AI workflows process issues in `ai:ready` queue
- Creates PRs, updates issues

### PAUSE
- Stop processing new AI work
- Existing PRs remain open for review
- Used during CI failures, incidents, or planned maintenance
- Set `ai:pause` label on active issues

### MAINTENANCE
- Read-only mode: AI can read but not modify
- Used for observation/debugging only

---

## Triggering PAUSE Mode

When the AI Watchdog detects frequent failures (threshold: 20 failures):

1. Set GitHub Actions variable `AI_AUTOMATION_MODE=PAUSE`
2. Add `ai:pause` label to all `ai:in-progress` issues
3. Review failure logs and determine root cause
4. Fix underlying issues
5. Set `AI_AUTOMATION_MODE=RUN` and remove `ai:pause` labels

See `ops/handoff/ai-automation-hardening_20260202/08_failure_modes_and_triage.md` for triage procedures.
