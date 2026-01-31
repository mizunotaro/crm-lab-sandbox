# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Add UI controls for search and pagination that align with the list API contract.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Customers list page has search box wired to ?q= and debounced (no new deps)
- [ ] Pagination controls (next/prev) reflect API metadata
- [ ] URL query params reflect state for shareable links
- [ ] Basic test or manual verification steps included in PR
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Add search input with simple debounce via setTimeout.
2) Add pagination controls based on metadata.
3) Sync state to URL params.

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
- app/customers/page.tsx
- components/customers/ListControls.tsx (new)
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
- Title: [AI] Add search + pagination controls to customers list UI (area:ui)
- Requirements:
- [ ] Customers list page has search box wired to ?q= and debounced (no new deps)
- [ ] Pagination controls (next/prev) reflect API metadata
- [ ] URL query params reflect state for shareable links
- [ ] Basic test or manual verification steps included in PR
