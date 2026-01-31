# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Add a minimal feature flag helper driven by environment variables to safely roll out features.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Feature flag helper exists (isEnabled('FLAG_NAME'))
- [ ] At least one non-critical feature is guarded by a flag
- [ ] Flags are documented (no secrets)
- [ ] No new deps
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Add feature flag helper reading process.env.
2) Guard one feature (e.g., CSV import).
3) Document flags.

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
- lib/featureFlags.ts (new)
- docs/ops/feature-flags.md (new)
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
- Title: [AI] Add simple feature flags (env-based) (area:ops)
- Requirements:
- [ ] Feature flag helper exists (isEnabled('FLAG_NAME'))
- [ ] At least one non-critical feature is guarded by a flag
- [ ] Flags are documented (no secrets)
- [ ] No new deps
