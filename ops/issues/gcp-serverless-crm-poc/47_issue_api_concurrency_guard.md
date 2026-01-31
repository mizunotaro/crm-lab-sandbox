# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Prevent lost updates by requiring an updatedAt/etag check for customer updates (minimal optimistic concurrency).

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Update API rejects stale updates with 409 (Conflict) when client version is older
- [ ] API documents how client supplies the version (e.g., If-Match or body.updatedAt)
- [ ] Automated test covers conflict case
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Pick minimal version field (updatedAt) used already in schema.
2) On update, compare stored updatedAt with provided value.
3) Return 409 on mismatch; add tests.

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
- If UI currently has no update flow, consider postponing to when edit UI exists.

# 6) Context / Links
- Files/dirs:
- app/api/customers/[id]/route.ts
- tests/api/customers_update_conflict.test.ts
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
- Title: [AI] Add optimistic concurrency guard (area:api)
- Requirements:
- [ ] Update API rejects stale updates with 409 (Conflict) when client version is older
- [ ] API documents how client supplies the version (e.g., If-Match or body.updatedAt)
- [ ] Automated test covers conflict case
