# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Improve user experience by adding friendly error handling pages for common failures (401/403/404/500).

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] 404 page exists for missing routes/resources
- [ ] Unauthorized access results in clear redirect or message (no leak)
- [ ] Unexpected errors show a friendly page (no stack traces)
- [ ] CI remains green
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Add/adjust framework error pages.
2) Ensure server error output is safe.
3) Add minimal tests if feasible.

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
- app/not-found.tsx / error.tsx (framework specific)
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
- Title: [AI] Add global error boundary and friendly error pages (area:ui)
- Requirements:
- [ ] 404 page exists for missing routes/resources
- [ ] Unauthorized access results in clear redirect or message (no leak)
- [ ] Unexpected errors show a friendly page (no stack traces)
- [ ] CI remains green
