# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Add a login UI that authenticates users and a logout action; ensure protected routes redirect to login when unauthenticated.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Login page exists and can authenticate using local auth
- [ ] Logout action clears session and redirects to login
- [ ] Visiting protected pages unauthenticated redirects to login
- [ ] UI displays minimal safe error messages on auth failure
- [ ] At least one UI-level test (or route test) verifies redirect behavior
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Implement login form UI and call login endpoint/action.
2) Implement logout endpoint/action.
3) Add route protection (middleware/guards).
4) Add tests for login success/failure and logout.

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
- app/login/page.tsx (or equivalent)
- app/logout (or API route)
- middleware.ts (if used)
- tests/ui/auth_redirect.test.ts
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
- Title: UI: Login page + logout + protected routing behavior
- Requirements:
- [ ] Login page exists and can authenticate using local auth
- [ ] Logout action clears session and redirects to login
- [ ] Visiting protected pages unauthenticated redirects to login
- [ ] UI displays minimal safe error messages on auth failure
- [ ] At least one UI-level test (or route test) verifies redirect behavior
