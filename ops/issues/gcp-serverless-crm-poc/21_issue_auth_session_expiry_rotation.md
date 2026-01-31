# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Introduce a clear session expiry policy (idle + absolute) and rotate session identifier on login to reduce fixation risk.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Session has absolute expiry and idle timeout (values documented in code)
- [ ] Session ID/token is rotated on successful login
- [ ] Expired sessions are rejected (401) and cleared (cookie) as applicable
- [ ] Automated tests cover expiry behavior (can be time-mocked)
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
1) Define expiry constants and store expiry metadata with session.
2) Rotate session on login (invalidate old session).
3) Implement expiry checks in auth middleware.
4) Add tests with clock control/mocking.

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
- lib/auth/session.ts
- middleware.ts (or equivalent)
- tests/auth/session_expiry.test.ts
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
- Title: [AI] Add session expiry + rotation policy (area:auth)
- Requirements:
- [ ] Session has absolute expiry and idle timeout (values documented in code)
- [ ] Session ID/token is rotated on successful login
- [ ] Expired sessions are rejected (401) and cleared (cookie) as applicable
- [ ] Automated tests cover expiry behavior (can be time-mocked)
- [ ] No dependency changes
