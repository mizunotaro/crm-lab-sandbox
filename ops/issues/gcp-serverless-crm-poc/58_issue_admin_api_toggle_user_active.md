# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Add an admin-only endpoint to enable/disable a user account by id.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] PATCH /api/admin/users/:id toggles active field (admin-only)
- [ ] Cannot disable self (or behavior documented) (Decision Gate)
- [ ] Automated test covers toggle behavior
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Implement PATCH admin handler.
2) Add safety guard for self-disable if required.
3) Add tests.

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
- Decide behavior: allow self-disable vs block; optimize for safety (prevent lockout).

# 6) Context / Links
- Files/dirs:
- app/api/admin/users/[id]/route.ts
- tests/api/admin_users_toggle_active.test.ts
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
- Title: [AI] Add admin API: toggle user active (area:api)
- Requirements:
- [ ] PATCH /api/admin/users/:id toggles active field (admin-only)
- [ ] Cannot disable self (or behavior documented) (Decision Gate)
- [ ] Automated test covers toggle behavior
