# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Add request body size limits for API routes and ensure errors are returned safely (no stack traces), mitigating simple DoS vectors.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] API rejects oversized request bodies with 413 (Payload Too Large) or equivalent
- [ ] Error responses do not include stack traces or internal paths
- [ ] At least one test covers oversized body rejection
- [ ] Logging (if any) redacts request bodies by default
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
1) Implement a shared request parsing helper that enforces a max size.
2) Apply helper to customer mutation endpoints.
3) Ensure error handler returns safe messages.
4) Add tests for 413 behavior.

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
- lib/api/request.ts (new or updated)
- app/api/customers/... route handlers
- tests/security/request_size.test.ts
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
- Title: [AI] Enforce request size limits + safe error handling (area:security)
- Requirements:
- [ ] API rejects oversized request bodies with 413 (Payload Too Large) or equivalent
- [ ] Error responses do not include stack traces or internal paths
- [ ] At least one test covers oversized body rejection
- [ ] Logging (if any) redacts request bodies by default
- [ ] No dependency changes
