# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Replace any plaintext password handling with salted scrypt password hashing using Node.js crypto, and update login/seed flow accordingly.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] User password is stored only as salt+hash (no plaintext) in DB/seed
- [ ] Login verifies password using scrypt with constant-time compare
- [ ] Existing demo user seed is updated to use hash format
- [ ] Automated tests cover successful login and failed login (wrong password)
- [ ] No dependency changes (use Node.js built-in crypto)
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Add password hashing helper (scrypt + salt) and constant-time verification.
2) Update user schema/seed to store hash + salt (or combined encoded string).
3) Update auth login to use verification helper.
4) Add tests for login success/failure; ensure no secrets in logs.

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
- If existing schema already stores hashed passwords (unknown), mark ai:blocked and propose minimal migration/no-migration options.

# 6) Context / Links
- Files/dirs:
- lib/auth/password.ts (new)
- prisma/schema.prisma (or db schema)
- seed script(s)
- tests/auth/login.test.ts
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
- Title: [AI] Store password hashes (scrypt) for local auth (area:auth)
- Requirements:
- [ ] User password is stored only as salt+hash (no plaintext) in DB/seed
- [ ] Login verifies password using scrypt with constant-time compare
- [ ] Existing demo user seed is updated to use hash format
- [ ] Automated tests cover successful login and failed login (wrong password)
- [ ] No dependency changes (use Node.js built-in crypto)
