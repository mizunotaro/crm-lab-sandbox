# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Implement basic per-session/per-IP throttling for login and state-changing customer APIs to reduce brute force and abuse (best-effort, in-memory for PoC).

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Login endpoint enforces a simple rate limit (returns 429 when exceeded)
- [ ] At least one mutation endpoint (POST/PATCH/DELETE) enforces rate limit (429)
- [ ] Rate limit state is in-memory (PoC) and clearly documented as non-durable (Eval)
- [ ] Automated tests cover allowed vs throttled responses
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
1) Add a small in-memory token bucket/rolling window helper.
2) Apply to login and one mutation endpoint with configurable limits.
3) Add tests (time-mocked if needed).
4) Document limitations and recommended production approach (Cloud Armor / Redis) (Eval).

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
- If rate limiting should be per-IP vs per-session, mark ai:blocked and propose options.

# 6) Context / Links
- Files/dirs:
- lib/security/ratelimit.ts (new)
- app/api/auth/login/route.ts (or equivalent)
- app/api/customers/... route handlers
- tests/security/ratelimit.test.ts
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
- Title: [AI] Add basic rate limiting for auth + mutation APIs (area:security)
- Requirements:
- [ ] Login endpoint enforces a simple rate limit (returns 429 when exceeded)
- [ ] At least one mutation endpoint (POST/PATCH/DELETE) enforces rate limit (429)
- [ ] Rate limit state is in-memory (PoC) and clearly documented as non-durable (Eval)
- [ ] Automated tests cover allowed vs throttled responses
- [ ] No dependency changes
