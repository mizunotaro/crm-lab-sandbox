# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Add CSRF protection for POST/PATCH/DELETE endpoints using a minimal approach compatible with cookie-based sessions, and test it.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] State-changing endpoints (POST/PATCH/DELETE) require a valid CSRF token/header (policy defined in code/docs)
- [ ] GET endpoints remain unaffected
- [ ] CSRF token is bound to session and does not leak via logs
- [ ] Automated tests cover CSRF pass/fail for at least one endpoint
- [ ] No dependency changes in this PR
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Choose minimal CSRF strategy (double-submit or session-bound token) and document it.
2) Implement token issuance (e.g., endpoint or server action) and validation middleware/helper.
3) Apply protection to POST/PATCH/DELETE routes.
4) Add tests for CSRF enforcement.

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
- If choosing CSRF strategy affects UX/API significantly, mark ai:blocked with options.

# 6) Context / Links
- Files/dirs:
- lib/security/csrf (new)
- middleware.ts or route handlers
- tests/security/csrf.test.ts
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
- Title: [AI] Add CSRF protection for state-changing requests (area:security)
- Requirements:
- [ ] State-changing endpoints (POST/PATCH/DELETE) require a valid CSRF token/header (policy defined in code/docs)
- [ ] GET endpoints remain unaffected
- [ ] CSRF token is bound to session and does not leak via logs
- [ ] Automated tests cover CSRF pass/fail for at least one endpoint
- [ ] No dependency changes in this PR
