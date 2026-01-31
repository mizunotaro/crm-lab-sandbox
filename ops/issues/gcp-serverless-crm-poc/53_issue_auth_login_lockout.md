# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Add a minimal lockout/throttle mechanism for repeated failed logins (in-memory for PoC) with clear limitations documented.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] After N failed attempts, further login attempts return 429/403 for a cooldown period
- [ ] Lockout key is based on username and/or IP (documented)
- [ ] Automated test covers lockout trigger
- [ ] No new dependencies
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Implement small in-memory counter with TTL.
2) Apply to login handler before password check.
3) Add tests with time mocking if needed.
4) Document PoC limitation (non-shared state across instances) (Eval).

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
- app/api/auth/login/route.ts
- lib/security/lockout.ts (new)
- tests/auth/lockout.test.ts
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
- Title: [AI] Add brute-force lockout for login (PoC) (area:auth)
- Requirements:
- [ ] After N failed attempts, further login attempts return 429/403 for a cooldown period
- [ ] Lockout key is based on username and/or IP (documented)
- [ ] Automated test covers lockout trigger
- [ ] No new dependencies
