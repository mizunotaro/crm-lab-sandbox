# Project Environment Variables Specification

This document is the **Single Source of Truth (SSOT)** for all environment variables required for the CRM Lab Sandbox project.

## Required GitHub Actions Variables

### `AI_AUTOMATION_MODE`
Controls the AI automation behavior in the repository.

**Valid values:**
- `PAUSE` - Pauses all AI-driven automation (AI agents, auto-PRs, etc.). Use when CI is unstable or during investigation.
- `RUN` - Normal operation: AI agents can create PRs, respond to issues, etc. (default)

**When to use PAUSE:**
- CI is experiencing frequent failures (e.g., >= 3 failures in 24h as detected by AI Watchdog)
- Investigating incidents or postmortems
- Manual intervention is required
- Before production deployments

**When to use RUN:**
- Normal development operations
- After resolving CI issues and all tests are green
- When AI assistance is desired for issue/PR automation

**How to set:**
```bash
gh variable set AI_AUTOMATION_MODE --body "PAUSE"
```

---

### `AI_MAX_OPEN_AI_PRS`
Maximum number of AI-generated PRs that can be open simultaneously.

**Valid values:** Integer (e.g., `3`, `5`, `10`)

**How to set:**
```bash
gh variable set AI_MAX_OPEN_AI_PRS --body "5"
```

---

### `AI_MAX_ATTEMPTS_PER_ISSUE`
Maximum retry attempts for AI agents per issue before marking as blocked.

**Valid values:** Integer (e.g., `3`, `5`)

**How to set:**
```bash
gh variable set AI_MAX_ATTEMPTS_PER_ISSUE --body "3"
```

---

## Required Secrets

At least one of the following API keys must be configured:

- `ZAI_API_KEY` - OpenCode API key
- `ZHIPU_API_KEY` - Alternative AI provider API key

These are secrets and should be configured via:
```bash
gh secret set ZAI_API_KEY
```

---

## Incident Response: PAUSE Mode

When CI becomes unstable, follow this procedure:

1. **Pause automation immediately:**
   ```bash
   gh variable set AI_AUTOMATION_MODE --body "PAUSE"
   ```

2. **Investigate CI failures:**
   - Run `gh run list --workflow=ci --limit 50` to see recent failures
   - Identify failing workflows and root causes
   - Fix issues and verify with manual runs

3. **Resume automation:**
   - Once CI is stable (tests passing, no recent failures)
   - Run: `gh variable set AI_AUTOMATION_MODE --body "RUN"`

4. **Monitor:**
   - Watch for the AI Watchdog workflow to re-trigger
   - Ensure new AI-generated PRs are reviewed properly

---

## AI Workflow Labels

The following GitHub labels are used for AI automation control:

- `ai:ready` - Issue ready for AI processing
- `ai:in-progress` - AI agent is working on this issue
- `ai:blocked` - Issue blocked (needs human intervention or automation paused)
- `ai:triage` - Issue in triage queue
- `ai:pr-open` - AI has opened a PR for this issue
- `ai:pause` - Manual pause requested for this specific issue
- `ai:deps` - Depends on other work
- `ai:risky-change` - High-risk change requiring extra review
- `ai:approved` - Human approved this AI work

---

## References

- AI Watchdog workflow: `.github/workflows/ai-watchdog.yml`
- Prereqs checker: `ops/scripts/check-ai-prereqs.ps1`
- Project operating rules: `AGENTS.md`

---

**Last updated:** 2026-02-10 (Issue #394 response)
