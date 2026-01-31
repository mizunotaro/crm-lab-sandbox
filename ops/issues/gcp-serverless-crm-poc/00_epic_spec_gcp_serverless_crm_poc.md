# Epic/Spec: GCP Serverless CRM PoC (Internal-only Web CRM)

## 1. Purpose / Goals
- Build a **browser-based** internal CRM PoC that employees can access **only from inside the corporate network** (or via corporate VPN/approved egress).
- Provide **local authentication (employee ID + password)** for PoC, with a clean boundary to later replace/extend with **Azure AD + SAML**.
- Implement **minimum viable customer management**: login, customer list, customer detail (CRUD can be extended later).
- Operate via **GitHub Issue -> ai:ready -> GitHub Actions Orchestrator -> OpenCode -> PR** and keep changes **small PR**.

## 2. Non-goals (PoC)
- No full-featured CRM workflows (sales pipeline, email automation, etc.).
- No advanced RBAC beyond PoC minimum (single role or basic admin/user).
- No production-grade compliance (SOC2/ISO) in phase 1.

## 3. Target Hosting (GCP, serverless-first)
### 3.1 Compute
- **Cloud Run** (container-based serverless)
  - Min instances: **0** (cost optimization)
  - Small CPU/memory preset (e.g., 1 vCPU / 256–512Mi) (Eval)
  - Concurrency default unless performance issues found

### 3.2 Database (general + managed)
- **Cloud SQL for PostgreSQL** (managed relational DB; widely used)
  - Smallest practical tier for PoC (Eval)
  - Prefer private connectivity when feasible (see Decision Gates)

### 3.3 Networking & Edge security (minimum baseline)
- **External HTTP(S) Load Balancer** in front of Cloud Run (required for Cloud Armor)
- **Cloud Armor**
  - IP allowlist for corporate egress/VPN IP ranges (internal-only access)
  - Basic rate limiting rules (L7) to reduce trivial DoS
  - Optional managed WAF ruleset at PoC baseline (Eval)

### 3.4 Secrets & Config
- **No secrets in repo**. Runtime secrets come from:
  - GitHub Secrets (CI / deploy) and/or
  - GCP Secret Manager (runtime) (Eval)
- Local dev uses `.env.local` excluded by gitignore.

## 4. Application Architecture (repo-level)
### 4.1 Tech stack (OSS)
- Web framework: **Next.js (TypeScript)** (OSS)
- DB access: **Prisma ORM** (OSS) + PostgreSQL (Eval; alternative: node-postgres)
- Testing: unit/integration tests + minimal route/API tests (OSS)
- Lint/format/typecheck: standard TypeScript toolchain

> Note: Any dependency introduction MUST be done only in issues labeled **ai:deps**.

### 4.2 Modules / boundaries
- `app/` or `src/` (UI pages, server actions/route handlers)
- `lib/auth/` (auth boundary: local provider now; SAML adapter later)
- `lib/db/` (db client + repositories)
- `lib/security/` (headers, CSRF strategy, rate-limit helper if needed)
- `tests/` (API/auth tests)

### 4.3 Authentication (PoC local)
- Store **password hash only** (never plaintext)
- Session via secure random token:
  - session token stored hashed in DB
  - cookie: `HttpOnly`, `Secure` (prod), `SameSite=Lax` (Eval)
- Guardrails:
  - **Do NOT hardcode demo credentials** in code, README, Issues, or logs.
  - Demo credentials are injected via environment variables for seed.

### 4.4 Data model (PoC)
- `User` (employeeId, passwordHash, createdAt, disabled)
- `Session` (tokenHash, userId, expiresAt, createdAt)
- `Customer` (id, name, status, notes?, createdAt, updatedAt)
- Optional `AuditLog` (who/what/when) for customer reads/updates (phase 2)

## 5. Security Baseline (minimum viable)
- Network boundary:
  - Cloud Armor IP allowlist + (optional) VPN/IAP in future
- App security:
  - Authentication required for all customer routes/APIs
  - Basic input validation
  - Security headers (CSP-lite, X-Frame-Options, etc.) (Eval)
  - Avoid logging PII/credentials; redact auth-related logs
- Supply chain:
  - Dependabot (optional) + lockfile integrity
  - No dependency changes unless ai:deps

## 6. Observability (PoC)
- Cloud Run logs for request errors (no PII)
- Basic health endpoint for uptime checks (internal)

## 7. CI/CD (GitHub Actions)
- CI on PR:
  - install -> lint -> typecheck -> test -> build
- CD (optional PoC):
  - manual `workflow_dispatch` deploy to Cloud Run (requires human approval)
  - uses Workload Identity Federation preferred; service account key fallback (Decision Gate)

## 8. Risks / Limitations
- **Internal-only access** depends on correct IP ranges; remote workers need VPN or static egress (Risk: high).
- Cloud SQL private connectivity increases infra complexity (Risk: medium).
- PoC local auth can become “sticky”; ensure auth provider boundary for SAML (Risk: medium).
- DDoS protection is baseline only (Risk: medium).

## 9. Split Strategy (small PR)
- 1 PR = 1 screen OR 1 endpoint OR 1 schema migration OR 1 workflow change
- Use ai:deps only when introducing/modifying dependencies
- Any ambiguous infra choice -> Decision Gate -> ai:blocked

## 10. Decision Gates (human-only)
1) Corporate egress IP ranges to allowlist in Cloud Armor:
   - Option A: fixed office IPs only (simpler, blocks remote)
   - Option B: VPN egress IPs (recommended if remote work exists)
   - Criteria: operational convenience vs access strictness
2) Cloud SQL connectivity:
   - Option A: Private IP + Serverless VPC Access (more secure, more setup)
   - Option B: Public IP + connector (simpler; must still constrain exposure)
   - Criteria: security posture vs time-to-PoC
3) Deploy authentication method in GitHub Actions:
   - Option A: Workload Identity Federation (preferred; no long-lived keys)
   - Option B: Service account JSON key (simpler; higher key leak risk)
   - Criteria: security posture vs setup effort

## Task Links

> Legend: [ ] todo / [~] in progress / [x] done

### Foundation
- [ ] #<ISSUE> — [AI] Bootstrap: Next.js + CI baseline
      PR: <PR_URL> / Notes: <free text>
- [ ] #<ISSUE> — [AI] DB: Postgres schema + migration
      PR: <PR_URL> / deps: <yes/no> / Notes: <free text>

### Auth & Seed
- [ ] #<ISSUE> — [AI] Auth: Local login + session cookie
      PR: <PR_URL> / Notes: <free text>
- [ ] #<ISSUE> — [AI] Seed: Demo user + sample customers (env)
      PR: <PR_URL> / Notes: <free text>

### Customers API
- [ ] #<ISSUE> — [AI] API: Customers list (search + pagination)
      PR: <PR_URL> / Notes: <free text>
- [ ] #<ISSUE> — [AI] API: Customer detail (auth required)
      PR: <PR_URL> / Notes: <free text>

### UI
- [ ] #<ISSUE> — [AI] UI: Login/logout + route guards
      PR: <PR_URL> / Notes: <free text>
- [ ] #<ISSUE> — [AI] UI: Customers list (search + pagination)
      PR: <PR_URL> / Notes: <free text>

### Completion Gate (Spec-level)
- [ ] All above Issues are [x] and CI is green across PRs
- [ ] Spec notes updated (known limitations / rollback / next scope)