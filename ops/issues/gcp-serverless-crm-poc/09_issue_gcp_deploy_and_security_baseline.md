# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Add a safe, reproducible deployment skeleton for GCP that targets Cloud Run + Cloud SQL and documents/enforces a minimum security baseline (internal-only via IP allowlist + basic rate limiting).

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Repository includes a deploy workflow (manual workflow_dispatch) that deploys to Cloud Run using provided config/secrets
- [ ] Workflow does NOT create/modify Cloud Armor/WAF rules automatically unless explicitly gated (Decision Gate); it may generate commands/docs
- [ ] Docs specify how to configure: Cloud Run service, Cloud SQL instance, Secret Manager (optional), and Cloud Armor policy for IP allowlist + rate limiting
- [ ] No secrets are printed in logs; workflow uses GitHub Secrets or Workload Identity Federation
- [ ] A clear rollback procedure is documented (redeploy previous revision / disable traffic)
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Add `.github/workflows/deploy_gcp.yml` with workflow_dispatch only.
2) Support Workload Identity Federation by default; document SA key fallback.
3) Add `docs/deploy/gcp.md` with step-by-step setup and security baseline.
4) Add `docs/security/baseline.md` describing IP allowlist + rate limiting + headers.
5) Verify workflow syntax and local build artifact.

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
- Corporate egress IP ranges to allowlist in Cloud Armor (office/VPN).
- Cloud SQL connectivity choice: Private IP + VPC connector vs simpler public option.
- Auth method: Workload Identity Federation vs Service Account JSON key.

# 6) Context / Links
- Files/dirs:
- .github/workflows/deploy_gcp.yml (new)
- docs/deploy/gcp.md (new)
- docs/security/baseline.md (new)
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
- Title: GCP: Deployment skeleton + security baseline (Cloud Run + Cloud SQL + Cloud Armor)
- Requirements:
- [ ] Repository includes a deploy workflow (manual workflow_dispatch) that deploys to Cloud Run using provided config/secrets
- [ ] Workflow does NOT create/modify Cloud Armor/WAF rules automatically unless explicitly gated (Decision Gate); it may generate commands/docs
- [ ] Docs specify how to configure: Cloud Run service, Cloud SQL instance, Secret Manager (optional), and Cloud Armor policy for IP allowlist + rate limiting
- [ ] No secrets are printed in logs; workflow uses GitHub Secrets or Workload Identity Federation
- [ ] A clear rollback procedure is documented (redeploy previous revision / disable traffic)
