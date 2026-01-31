# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Mitigate CSRF risks for cookie-based sessions by implementing a minimal CSRF defense (Origin/Referer check or double-submit token) for state-changing routes.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] State-changing endpoints reject cross-site requests (403) under defined policy
- [ ] Policy is documented in code and docs
- [ ] Automated test covers at least one blocked CSRF-like request
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
1) Select minimal defense: Origin/Referer allowlist for same-site requests.
2) Apply to POST/PATCH/DELETE routes.
3) Add tests simulating cross-site headers.

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
- If app is behind a reverse proxy/IAP, confirm which headers are reliably present.

# 6) Context / Links
- Files/dirs:
- middleware.ts or lib/security/csrf.ts (new)
- app/api/customers/...
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
- Title: [AI] Add basic CSRF protection for session auth (area:security)
- Requirements:
- [ ] State-changing endpoints reject cross-site requests (403) under defined policy
- [ ] Policy is documented in code and docs
- [ ] Automated test covers at least one blocked CSRF-like request
- [ ] No new dependencies
