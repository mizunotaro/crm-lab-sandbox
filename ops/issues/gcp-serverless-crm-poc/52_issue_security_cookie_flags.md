# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Ensure auth cookies are configured with secure defaults (HttpOnly, SameSite, Secure where applicable) and consistent path/domain scope.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Auth/session cookies are HttpOnly and SameSite is set explicitly
- [ ] Secure flag is enabled in production mode (documented)
- [ ] Automated test (or unit test) validates Set-Cookie attributes
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Centralize cookie options in one helper.
2) Ensure flags are set for login/logout and session refresh.
3) Add tests for Set-Cookie header.

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
- lib/auth/cookies.ts (new or updated)
- tests/auth/cookie_flags.test.ts
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
- Title: [AI] Harden session cookie flags (area:auth)
- Requirements:
- [ ] Auth/session cookies are HttpOnly and SameSite is set explicitly
- [ ] Secure flag is enabled in production mode (documented)
- [ ] Automated test (or unit test) validates Set-Cookie attributes
