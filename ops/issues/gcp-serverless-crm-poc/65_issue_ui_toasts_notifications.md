# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Provide consistent user feedback for create/update/delete actions (toast or inline alerts).

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Success/failure feedback is visible for create/update/delete flows
- [ ] Notifications do not leak internal error details
- [ ] If a new UI library is added, issue has ai:deps label
- [ ] CI is green
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? Yes (requires label ai:deps)

# 4) Suggested Plan (optional but recommended)
1) Select existing notification approach (built-in or library).
2) Implement minimal wrapper (notifySuccess/notifyError).
3) Use in customer flows.

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
- If repository already has a toast system, reuse it and do not add deps.

# 6) Context / Links
- Files/dirs:
- components/ui/notifications.ts (new or existing)
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
- Title: [AI] Add basic user notifications for actions (area:ui) [needs ai:deps]
- Requirements:
- [ ] Success/failure feedback is visible for create/update/delete flows
- [ ] Notifications do not leak internal error details
- [ ] If a new UI library is added, issue has ai:deps label
- [ ] CI is green
