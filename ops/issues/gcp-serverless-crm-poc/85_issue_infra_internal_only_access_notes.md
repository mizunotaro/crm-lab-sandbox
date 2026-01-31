# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Document practical options for 'internal-only' browser access (IAP, VPN, IP allowlist) and choose one for PoC (Decision Gate).

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] docs/deploy/internal-access.md exists with 2-3 options and pros/cons
- [ ] Includes decision criteria (security vs setup effort)
- [ ] No secrets in docs
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Write doc describing options.
2) Add Decision Gate section for human selection.

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
- Select one: A) IAP, B) IP allowlist, C) VPN/Zero Trust. Optimize for quick PoC + minimum exposure.

# 6) Context / Links
- Files/dirs:
- docs/deploy/internal-access.md (new)
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
- Title: [AI] Document internal-only access options (area:infra)
- Requirements:
- [ ] docs/deploy/internal-access.md exists with 2-3 options and pros/cons
- [ ] Includes decision criteria (security vs setup effort)
- [ ] No secrets in docs
