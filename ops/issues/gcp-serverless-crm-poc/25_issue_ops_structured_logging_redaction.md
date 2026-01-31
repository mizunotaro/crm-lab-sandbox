# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Implement a minimal structured logger that redacts PII/sensitive fields and is suitable for Cloud Logging ingestion.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Logger outputs JSON with consistent keys (level, msg, requestId, userId where applicable)
- [ ] Sensitive fields (password, token, cookie, authorization, csrf) are redacted in logs
- [ ] At least one test verifies redaction behavior
- [ ] No secrets are printed in normal error paths
- [ ] No dependency changes
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Add logger utility with redaction.
2) Wire logger into API route error handling.
3) Add tests for redaction and output shape.
4) Document logging policy briefly.

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
N/A

# 6) Context / Links
- Files/dirs:
- lib/logging/logger.ts (new)
- lib/logging/redact.ts (new)
- tests/logging/redaction.test.ts
- docs/ops/logging.md (optional)
- Related issues/PRs:
- Screenshots/logs:

# 7) Risk Level
medium

# 8) Reporting requirement (daily + completion)
- During work: update PR description with progress + verification
- When “done & deployable”: comment back to Issue with:
  - Summary (EN+JP)
  - Verification evidence (commands + CI link)
  - Risk/rollback

対象タスク（Titleと要件）:
- Title: [AI] Add structured logging + PII redaction (area:ops)
- Requirements:
- [ ] Logger outputs JSON with consistent keys (level, msg, requestId, userId where applicable)
- [ ] Sensitive fields (password, token, cookie, authorization, csrf) are redacted in logs
- [ ] At least one test verifies redaction behavior
- [ ] No secrets are printed in normal error paths
- [ ] No dependency changes
