# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Add UI controls to view/edit customer tags, aligned with the tags schema/API.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Customer form supports adding/removing tags (basic input)
- [ ] Tags render on detail page
- [ ] No new deps unless labeled ai:deps
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Add tags input control (simple comma-separated) (Eval).
2) Wire to create/update payload.
3) Render tags on detail.

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
- If tags UX needs a new component library, require ai:deps.

# 6) Context / Links
- Files/dirs:
- components/customers/CustomerForm.tsx
- app/customers/[id]/page.tsx
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
- Title: [AI] Add customer tags UI (area:ui)
- Requirements:
- [ ] Customer form supports adding/removing tags (basic input)
- [ ] Tags render on detail page
- [ ] No new deps unless labeled ai:deps
