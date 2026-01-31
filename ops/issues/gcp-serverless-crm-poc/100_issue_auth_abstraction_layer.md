# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Refactor auth logic behind a minimal interface so future SAML/Azure AD integration can be added without rewriting routes.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Auth provider interface exists (e.g., IAuthProvider) with current local provider implementation
- [ ] Login/session flows continue to work with no behavior regression
- [ ] Automated tests still pass
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Define minimal interface needed for current flows.
2) Implement LocalAuthProvider using existing code.
3) Swap route handlers to depend on interface.
4) Run tests.

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
- If refactor diff becomes large, stop and split into smaller PRs.

# 6) Context / Links
- Files/dirs:
- lib/auth/provider.ts (new)
- lib/auth/localProvider.ts (new/updated)
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
- Title: [AI] Introduce auth provider abstraction (prep for SAML) (area:auth)
- Requirements:
- [ ] Auth provider interface exists (e.g., IAuthProvider) with current local provider implementation
- [ ] Login/session flows continue to work with no behavior regression
- [ ] Automated tests still pass
