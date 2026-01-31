# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Update the threat model document to reflect implemented controls (CSRF, headers, RBAC, audit logs, rate limiting).

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Threat model doc includes a table mapping controls to threats
- [ ] Documents remaining gaps and next-step mitigations
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
1) Update threat model sections.
2) Add mapping of controls and residual risks.

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
- docs/security/threat-model.md
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
- Title: [AI] Update threat model with new controls (area:docs)
- Requirements:
- [ ] Threat model doc includes a table mapping controls to threats
- [ ] Documents remaining gaps and next-step mitigations
- [ ] CI remains green
