# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Improve basic a11y for key UI components (labels, aria attributes, focus management).

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Form inputs have associated labels and error messages are announced (aria-describedby)
- [ ] Buttons/links have accessible names
- [ ] Tab order works on customers list and forms
- [ ] CI is green
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Audit key screens for labels and aria.
2) Fix missing attributes and focus behavior.
3) Add minimal lint/test if available.

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
- components/customers/*
- app/customers/*
- Related issues/PRs:
- Screenshots/logs:

# 7) Risk Level
low

# 8) Reporting requirement (daily + completion)
- During work: update PR description with progress + verification
- When “done & deployable”: comment back to Issue with:
  - Summary (EN+JP)
  - Verification evidence (commands + CI link)
  - Risk/rollback

対象タスク（Titleと要件）:
- Title: [AI] Improve basic accessibility for forms and tables (area:ui)
- Requirements:
- [ ] Form inputs have associated labels and error messages are announced (aria-describedby)
- [ ] Buttons/links have accessible names
- [ ] Tab order works on customers list and forms
- [ ] CI is green
