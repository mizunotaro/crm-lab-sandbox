# E2E Smoke Test Checklist

This document provides a checklist for validating the full pipeline (Issue → PR → CI → Triage → Daily) for this repository.

## Overview

Smoke tests verify that the core AI automation and CI/CD pipeline is functioning correctly. Run these tests after:
- Setting up a new repository
- Making changes to workflows
- Changing AI agent configuration
- Suspecting pipeline issues

## Prerequisites

- GitHub repository with AI workflows configured
- Required secrets set (`ZAI_API_KEY`, `ZHIPU_API_KEY`)
- Basic understanding of GitHub Actions workflow syntax

## Smoke Test Checklist

### 1. Issue Creation & Labeling

**Step:** Create a test issue with AI labels

```bash
# Via GitHub CLI (gh)
gh issue create --title "[Smoke Test] Test Issue" --body "Testing AI pipeline" --label "ai:agent,area:ops"
```

**Expected Output:**
- Issue created successfully
- Issue has appropriate labels (ai:agent, area:ops, etc.)

**Verification:**
- Issue exists in the repository
- Labels are visible on the issue page

---

### 2. Branch Creation & PR Opening

**Step:** Create a feature branch and open a PR

```bash
# Create a test branch
git checkout -b feat/smoke-test-$(date +%s)

# Make a minimal change (e.g., update README.md)
echo "# Smoke Test $(date)" >> docs/ops/smoke-test.md

# Commit and push
git add docs/ops/smoke-test.md
git commit -m "chore: add smoke test marker"
git push -u origin feat/smoke-test-$(date +%s)

# Open PR
gh pr create --title "[Smoke Test] Test PR" --body "Testing CI pipeline"
```

**Expected Output:**
- Branch created and pushed
- PR opened successfully
- PR description is populated

**Verification:**
- PR appears in the Pull Requests tab
- Branch is visible in the repository

---

### 3. CI Workflow Execution

**Step:** Monitor CI workflow run

```bash
# Wait for CI to start (typically 30-60 seconds)
sleep 60

# List recent workflow runs
gh run list --workflow=ci.yml --limit 5

# Watch the CI run in real-time
gh run watch
```

**Expected Output:**
- CI workflow starts automatically on PR push
- All steps complete successfully:
  - Checkout repository
  - Setup pnpm and Node.js
  - Install dependencies (`pnpm install --frozen-lockfile`)
  - Typecheck (`pnpm -r exec tsc --noEmit`)
  - Run tests (`pnpm --filter @crm/api test:run`)

**Verification:**
- CI run shows green ✅ status
- All job steps completed without errors
- PR checks show passing status

**Rollback/Circuit Breaker:**
- If CI fails:
  - Check logs: `gh run view <run-id> --log`
  - Verify pnpm-lock.yaml is consistent
  - Ensure Node.js version is 24
  - Check for TypeScript errors
  - Verify tests exist and pass

---

### 4. AI Orchestrator Execution

**Step:** Verify AI Orchestrator picks up the PR

**Expected Output:**
- AI Orchestrator runs on schedule (every 15 minutes)
- Or can be triggered manually via `workflow_dispatch`
- Orchestrator identifies the PR with AI labels
- Agent processes the issue according to AGENTS.md rules

**Verification:**
- Check recent orchestrator runs: `gh run list --workflow=ai-orchestrator.yml --limit 5`
- Look for comments or updates on the PR from AI agent
- Verify agent follows AGENTS.md conventions

**Rollback/Circuit Breaker:**
- If AI Orchestrator fails:
  - Check secret is set: `gh secret list`
  - Verify model configuration: `zai-coding-plan/glm-4.7`
  - Check workflow permissions (contents, pull-requests, issues)
  - Review orchestrator logs for API errors

---

### 5. AI Triage Execution

**Step:** Verify AI Triage triggers after CI

**Expected Output:**
- AI Triage workflow runs when CI completes
- Triage analyzes CI results
- If CI failed: triage identifies root cause and adds labels/comments
- If CI passed: triage marks as healthy or flags for review

**Verification:**
- Check recent triage runs: `gh run list --workflow=ai-triage.yml --limit 5`
- Look for triage comments on the PR
- Verify appropriate labels applied (e.g., `ai:blocked`, `ci:failed`)

**Rollback/Circuit Breaker:**
- If AI Triage fails:
  - Verify CI workflow name matches in ai-triage.yml
  - Check ZAI_API_KEY is properly configured
  - Review triage logs for API errors
  - Manually review CI logs as fallback

---

### 6. Daily Report Generation

**Step:** Verify daily report workflow

**Expected Output:**
- Daily report runs at scheduled time (UTC 0:00 / JST 9:00)
- Report is generated and posted as a comment on dashboard issue
- Dashboard issue exists and is labeled `dashboard`

**Verification:**
- Check recent daily runs: `gh run list --workflow=ai-daily.yml --limit 5`
- Locate dashboard issue: `gh issue list --label dashboard`
- Verify daily report comment exists
- Report includes key metrics and status

**Rollback/Circuit Breaker:**
- If daily report fails:
  - Ensure dashboard issue exists and is not closed
  - Verify workflow has issue write permissions
  - Check for API rate limits
  - Manually create daily report as fallback

---

## Full Pipeline Smoke Test (End-to-End)

Execute all steps in order to validate the complete pipeline:

1. ✅ Create labeled issue
2. ✅ Open PR from issue
3. ✅ CI runs and passes
4. ✅ AI Orchestrator processes PR
5. ✅ AI Triage analyzes CI results
6. ✅ Daily report aggregates activity

**Success Criteria:**
- All workflows execute without errors
- Agent comments appear on PR/issue
- Dashboard is updated with latest activity
- No secrets or sensitive data exposed

---

## Quick Validation Commands

```bash
# Quick smoke test (runs all verifications)
#!/bin/bash
set -e

echo "Checking CI status..."
gh run list --workflow=ci.yml --limit 1 | grep "completed"

echo "Checking AI Orchestrator status..."
gh run list --workflow=ai-orchestrator.yml --limit 1 | grep "completed"

echo "Checking AI Triage status..."
gh run list --workflow=ai-triage.yml --limit 1 | grep "completed"

echo "Checking Daily Report status..."
gh run list --workflow=ai-daily.yml --limit 1 | grep "completed"

echo "✅ All smoke tests passed"
```

---

## Troubleshooting Common Issues

### CI Fails with TypeScript Errors

- Run locally: `pnpm -r exec tsc --noEmit`
- Fix type errors before pushing
- Verify all packages compile correctly

### Tests Fail in CI but Pass Locally

- Check environment differences (Node.js version, OS)
- Verify pnpm-lock.yaml is committed
- Run tests in CI mode: `pnpm --filter @crm/api test:run`

### AI Agent Not Responding

- Verify secrets are set: `gh secret list`
- Check workflow permissions in YAML files
- Review agent logs for API errors
- Ensure model configuration is correct

### Dashboard Issue Not Found

- Create dashboard issue from template
- Apply `dashboard` label
- Ensure issue is not closed

---

## Security Checklist

- [ ] No API keys or secrets in logs or comments
- [ ] No credentials in commit messages
- [ ] Workflows use secret references (`${{ secrets.NAME }}`)
- [ ] Permissions are minimal required for each workflow
- [ ] Rate limits and throttling are respected

---

## Related Files

- `.github/workflows/ci.yml` - Main CI workflow
- `.github/workflows/ai-orchestrator.yml` - AI Orchestrator (every 15 min)
- `.github/workflows/ai-triage.yml` - AI Triage (triggers after CI)
- `.github/workflows/ai-daily.yml` - Daily Report (daily)
- `AGENTS.md` - Agent operating rules and guidelines
- `docs/ops/daily-report.md` - Daily report operations guide
- `docs/ops/incident-response.md` - Incident response procedures

---

## Maintenance

Update this document when:
- Adding new AI workflows
- Changing pipeline structure
- Updating quality gates or checks
- Modifying agent roles or autonomy levels

---

**Last Updated:** 2026-02-01  
**Maintained By:** AI DevOps/Staff+Security Lead
