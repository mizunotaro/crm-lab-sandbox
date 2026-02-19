# PROJECT_ENV_SPEC.md

## AI Automation Configuration (SSOT)

This document is the single source of truth (SSOT) for AI automation operational configuration.

### GitHub Actions Repository Variables

The following repository-level variables must be configured in GitHub Actions:

| Variable | Description | Current Value | Notes |
|----------|-------------|---------------|-------|
| `AI_AUTOMATION_MODE` | Controls AI automation behavior | `PAUSE` | Valid values: `AUTO`, `PAUSE` |
| `AI_MAX_OPEN_AI_PRS` | Maximum number of concurrent AI-generated PRs | `5` | Prevents PR spam |
| `AI_MAX_ATTEMPTS_PER_ISSUE` | Maximum attempts per issue before giving up | `3` | Prevents infinite loops |

### AI_AUTOMATION_MODE Values

- `AUTO` - AI operates normally, automatically creating PRs and handling issues
- `PAUSE` - AI operations paused; human must manually trigger or approve actions

### How to Set Variables

Using GitHub CLI:

```bash
gh variable set AI_AUTOMATION_MODE --body "PAUSE"
gh variable set AI_MAX_OPEN_AI_PRS --body "5"
gh variable set AI_MAX_ATTEMPTS_PER_ISSUE --body "3"
```

Or via GitHub UI:
1. Go to repository Settings
2. Navigate to Secrets and variables > Actions
3. Click "New repository variable"
4. Add each variable with its value

### Prerequisites Check

Run `ops/scripts/check-ai-prereqs.ps1` to verify configuration:

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File ./ops/scripts/check-ai-prereqs.ps1 -Repo owner/repo
```

### Change History

| Date | Variable | Old Value | New Value | Reason |
|------|----------|-----------|-----------|--------|
| 2026-02-10 | `AI_AUTOMATION_MODE` | - | `PAUSE` | Issue #403 - PAUSE recommended (failures=20) |
