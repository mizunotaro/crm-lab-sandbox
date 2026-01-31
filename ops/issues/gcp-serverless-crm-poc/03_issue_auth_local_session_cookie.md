# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Implement local authentication using employee ID + password with password hashing and DB-backed sessions; protect all CRM routes/APIs behind auth.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Password is never stored or logged in plaintext; only hash is stored
- [ ] Session token is random; stored hashed in DB; cookie is HttpOnly and has sensible defaults
- [ ] Unauthenticated access to protected routes redirects to login (or returns 401 for APIs)
- [ ] Auth logic is isolated behind `lib/auth` boundary to allow future SAML adapter
- [ ] No demo credentials are present in code/README/Issue text/log output
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Implement password hashing using Node built-in crypto (PBKDF2/scrypt) to avoid extra deps.
2) Implement session creation/validation and cookie handling.
3) Add auth middleware/guards for protected routes/APIs.
4) Add unit/integration tests for login/session/guard behavior.

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
- lib/auth (new)
- lib/db (from DB issue)
- app/ or src/ routes/middleware
- tests/
- Related issues/PRs:
- Screenshots/logs:

# 7) Risk Level
high

# 8) Reporting requirement (daily + completion)
- During work: update PR description with progress + verification
- When “done & deployable”: comment back to Issue with:
  - Summary (EN+JP)
  - Verification evidence (commands + CI link)
  - Risk/rollback

対象タスク（Titleと要件）:
- Title: Auth: Local login + session cookie (no hardcoded credentials)
- Requirements:
- [ ] Password is never stored or logged in plaintext; only hash is stored
- [ ] Session token is random; stored hashed in DB; cookie is HttpOnly and has sensible defaults
- [ ] Unauthenticated access to protected routes redirects to login (or returns 401 for APIs)
- [ ] Auth logic is isolated behind `lib/auth` boundary to allow future SAML adapter
- [ ] No demo credentials are present in code/README/Issue text/log output
