# Architecture Overview

**Version:** 1.0  
**Last Updated:** 2026-02-01  
**Purpose:** High-level architecture reference for maintainers and new contributors.

---

## 1) System Overview

The CRM Lab Sandbox is a contact management / business cards / lightweight CRM application designed for web and mobile platforms.

### 1.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Client Layer                             │
├──────────────────────────────┬──────────────────────────────────┤
│   Web App (React/TypeScript) │   Mobile App (iOS/Android - TBD)  │
└──────────────┬───────────────┴───────────────┬──────────────────┘
               │                               │
               │ HTTPS / REST API              │
               │                               │
┌──────────────▼───────────────┐   ┌───────────▼───────────────────┐
│   GCP External Load Balancer   │   │   (Future: Mobile API Gateway)│
└──────────────┬───────────────┘   └────────────────────────────────┘
               │
┌──────────────▼───────────────┐
│     Cloud Armor Security     │  (DDoS protection, rate limiting)
└──────────────┬───────────────┘
               │
┌──────────────▼───────────────────────────────────────────────────┐
│                    Application Layer (Cloud Run)                  │
├───────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              API Server (Express.js / Node.js)             │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │ │
│  │  │ Auth &       │  │ Contact      │  │ Rate Limiting    │ │
│  │  │ Session Mgmt  │  │ Management   │  │ Middleware       │ │
│  │  └──────────────┘  └──────────────┘  └──────────────────┘  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Shared Types & Utilities                        │ │
│  │  (featureFlags, csvImport, type definitions)                │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────┬───────────────────────────────────────────────────┘
               │
               │ Connection Pool
               │
┌──────────────▼───────────────────────────────────────────────────┐
│                      Data Layer                                   │
├───────────────────────┬───────────────────────────────────────────┤
│   PostgreSQL (Cloud SQL)  │   Redis (Memorystore - Optional)      │
│   - Contacts              │   - Rate limiting counters            │
│   - Users/Sessions        │   - Session cache                     │
│   - Audit logs            │   - Feature flags cache               │
└───────────────────────────┴───────────────────────────────────────┘
```

---

## 2) Module Organization

### 2.1 Monorepo Structure

```
crm-lab-sandbox/
├── apps/
│   ├── api/           # Backend API server
│   │   ├── index.ts   # Entry point
│   │   ├── contacts.ts # Contact CRUD endpoints
│   │   └── contract.spec.ts # API contract tests
│   └── web/           # Frontend web app
│       └── index.ts   # Entry point
├── packages/
│   └── shared/        # Shared code between apps
│       ├── index.ts
│       ├── lib/featureFlags.ts
│       └── lib/csvImport.ts
└── docs/
    └── architecture/  # This document and related diagrams
```

### 2.2 API Boundaries

```
┌─────────────────────────────────────────────────────────────────┐
│                        API Surface                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Authentication & Session:                                       │
│  - POST   /api/auth/login          # User login                 │
│  - POST   /api/auth/logout         # User logout                │
│  - GET    /api/auth/session        # Session validation         │
│                                                                  │
│  Contact Management (CRUD):                                     │
│  - GET    /api/contacts             # List all contacts          │
│  - GET    /api/contacts/:id        # Get single contact         │
│  - POST   /api/contacts             # Create contact             │
│  - PUT    /api/contacts/:id        # Update contact             │
│  - DELETE /api/contacts/:id        # Delete contact             │
│                                                                  │
│  Bulk Operations:                                               │
│  - POST   /api/contacts/import      # CSV import                │
│  - GET    /api/contacts/export      # CSV export                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3) Data Flow

### 3.1 Authentication Flow

```
Client → Cloud Run API
   │
   ├─→ POST /api/auth/login
   │      │
   │      ├─→ Validate credentials (PostgreSQL)
   │      │
   │      ├─→ Generate session token (JWT)
   │      │
   │      ├─→ Cache session in Redis (optional)
   │      │
   │      └─→ Return token to client
   │
   ├─→ Client stores token (httpOnly cookie or localStorage)
   │
   └─→ Subsequent requests include token
          │
          └─→ Middleware validates token
                 │
                 ├─→ Valid: Proceed to handler
                 └─→ Invalid: Return 401 Unauthorized
```

### 3.2 Contact CRUD Flow

```
Client Request
   │
   ├─→ Rate Limiting Check (Cloud Armor + Redis)
   │      │
   │      ├─→ Within limits: Continue
   │      └─→ Exceeded: Return 429 Too Many Requests
   │
   ├─→ Authentication Middleware
   │      │
   │      ├─→ Valid token: Continue
   │      └─→ Invalid: Return 401 Unauthorized
   │
   ├─→ Input Validation
   │      │
   │      ├─→ Valid: Process request
   │      └─→ Invalid: Return 400 Bad Request
   │
   ├─→ Business Logic (Contact Controller)
   │      │
   │      ├─→ PostgreSQL Query/Transaction
   │      └─→ Handle errors
   │
   └─→ Response
          │
          ├─→ Success: Return data + 200/201/204
          └─→ Error: Return error message + 4xx/5xx
```

### 3.3 CSV Import Flow

```
Client Upload
   │
   ├─→ POST /api/contacts/import
   │      │
   │      ├─→ Parse CSV (streaming)
   │      │
   │      ├─→ Validate each record
   │      │
   │      ├─→ Batch insert to PostgreSQL
   │      │
   │      └─→ Return success count + errors
   │
   └─→ Client can retry failed records
```

---

## 4) Security Assumptions

### 4.1 Threat Model

| Threat | Mitigation |
|--------|------------|
| DDoS attacks | Cloud Armor (rate limiting, IP blocking) |
| Credential stuffing | Rate limiting per IP, account lockout |
| SQL injection | Parameterized queries, input validation |
| XSS attacks | Content Security Policy, output sanitization |
| CSRF attacks | CSRF tokens, SameSite cookies |
| Data exposure | Encryption at rest, TLS in transit, least-privilege IAM |

### 4.2 Security Boundaries

```
┌─────────────────────────────────────────────────────────────────┐
│ External (Internet)                                             │
│  - Threat: DDoS, malicious actors                              │
│  - Protection: Cloud Armor, rate limiting                      │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ TLS
                            │
┌─────────────────────────────────────────────────────────────────┐
│ Perimeter (GCP VPC, Cloud Run)                                  │
│  - Threat: compromised workloads                               │
│  - Protection: VPC firewall, service account IAM               │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ Internal network
                            │
┌─────────────────────────────────────────────────────────────────┐
│ Data Layer (Cloud SQL, Memorystore)                            │
│  - Threat: unauthorized DB access, data breaches               │
│  - Protection: SSL, IAM roles, connection pooling               │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5) GCP Deployment Components

### 5.1 Production Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Google Cloud Platform                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Cloud Run (Managed, Serverless)                          │  │
│  │  - Auto-scaling (0 to N instances)                         │  │
│  │  - HTTPS-only, auto-cert management                        │  │
│  │  - Container-based (Docker image)                          │  │
│  │  - Environment variables for config                       │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Cloud SQL (Managed PostgreSQL)                           │  │
│  │  - Automatic backups, point-in-time recovery             │  │
│  │  - High availability (multi-zone)                         │  │
│  │  - Private IP connection from Cloud Run                  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Memorystore (Optional - Redis)                          │  │
│  │  - Distributed rate limiting                            │  │
│  │  - Session cache                                        │  │
│  │  - Private IP connection                                │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Secret Manager                                            │  │
│  │  - Database credentials                                   │  │
│  │  - API keys                                               │  │
│  │  - JWT secrets                                            │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Cloud Armor                                              │  │
│  │  - Global security policies                              │  │
│  │  - Rate-based rules (req/sec per IP)                      │  │
│  │  - IP denylists/allowlists                                │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Cloud Logging & Monitoring                              │  │
│  │  - Request logs, error logs                               │  │
│  │  - Metrics (CPU, memory, latency)                        │  │
│  │  - Alert policies                                         │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 Environment Separation (Future)

```
Development (dev-crm-lab-sandbox)
  - Cloud Run: smaller instance, auto-scale 0-2
  - Cloud SQL: shared instance, smaller storage
  - Separate project/region isolation

Staging (staging-crm-lab-sandbox)
  - Cloud Run: same config as production
  - Cloud SQL: production-sized for load testing
  - Integration with external services (mocked)

Production (prod-crm-lab-sandbox)
  - Cloud Run: production config, high availability
  - Cloud SQL: multi-zone HA, automated backups
  - Full monitoring, alerting, observability
```

---

## 6) Key Dependencies

### 6.1 Backend (apps/api)

| Category | Dependency | Purpose |
|----------|-----------|---------|
| Runtime | Node.js 24+ | JavaScript runtime |
| Framework | Express.js (planned) | HTTP server |
| Database | pg (node-postgres) | PostgreSQL client |
| Testing | Vitest | Test runner |
| Type Checking | TypeScript 5.9+ | Static typing |

### 6.2 Frontend (apps/web)

| Category | Dependency | Purpose |
|----------|-----------|---------|
| Runtime | Node.js 24+ | JavaScript runtime |
| Framework | TBD (React planned) | UI framework |
| Type Checking | TypeScript 5.9+ | Static typing |

### 6.3 Infrastructure

| Service | Purpose |
|---------|---------|
| Google Cloud Run | Serverless container hosting |
| Google Cloud SQL | Managed PostgreSQL |
| Google Memorystore | Redis (optional, for rate limiting) |
| Google Secret Manager | Secrets management |
| Google Cloud Armor | DDoS protection, rate limiting |
| Google Cloud Logging | Log aggregation |
| Google Cloud Monitoring | Metrics and alerting |

---

## 7) Data Model Overview

### 7.1 Core Tables

```
contacts
  - id: UUID (PK)
  - name: VARCHAR(255)
  - email: VARCHAR(255)
  - phone: VARCHAR(50)
  - company: VARCHAR(255)
  - tags: JSONB (flexible array of strings)
  - created_at: TIMESTAMPTZ
  - updated_at: TIMESTAMPTZ
  - user_id: UUID (FK to users) (planned)

users (planned)
  - id: UUID (PK)
  - email: VARCHAR(255) (unique)
  - password_hash: VARCHAR(255)
  - created_at: TIMESTAMPTZ
  - updated_at: TIMESTAMPTZ

sessions (planned)
  - id: UUID (PK)
  - user_id: UUID (FK to users)
  - token: VARCHAR(255) (hashed)
  - expires_at: TIMESTAMPTZ
  - created_at: TIMESTAMPTZ
```

---

## 8) Development Workflow

### 8.1 Local Development

```
1. pnpm install           # Install dependencies
2. pnpm build             # Build all packages
3. pnpm -r exec tsc       # Type check all code
4. pnpm --filter @crm/api test:run  # Run API tests
```

### 8.2 CI/CD Pipeline

```
GitHub Actions (.github/workflows/ci.yml)
  ├─ Checkout code
  ├─ Setup pnpm (v10.28.2) and Node.js 24
  ├─ Install dependencies (frozen-lockfile)
  ├─ Type check (tsc --noEmit)
  └─ Run tests (vitest)

Future: Add deployment stages (staging → production)
```

---

## 9) Observability & Monitoring

### 9.1 Logging Strategy

- **Structured logs**: JSON format with request ID, user ID, timestamp
- **Log levels**: ERROR, WARN, INFO, DEBUG (controlled by env var)
- **Sensitive data**: Redact passwords, tokens, PII from logs

### 9.2 Metrics to Track

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| API latency (p95) | < 200ms | > 500ms |
| Error rate | < 0.1% | > 1% |
| Database connection pool usage | < 80% | > 90% |
| Rate limiting rejections | < 0.5% | > 2% |

### 9.3 SLI/SLO Targets (Planned)

- **Availability**: 99.9% uptime (~43 minutes/month downtime allowed)
- **Latency**: 99th percentile < 500ms
- **Error Rate**: < 0.5% of requests

---

## 10) Related Documentation

- **Security**: See `docs/security/rate-limiting-plan.md` for detailed rate limiting strategy
- **AI Agents**: See `AGENTS.md` for operating rules and agent guidelines
- **Project Context**: See `README.md` for project overview
- **Ops Procedures**: See `ops/` directory for operational procedures
- **Architecture Decisions**: See `docs/ai/decisions/ADR-*.md` for design decisions

---

## 11) Glossary

| Term | Definition |
|------|------------|
| **Cloud Run** | Google Cloud's serverless compute platform for running containers |
| **Cloud SQL** | Google Cloud's fully-managed relational database service |
| **Cloud Armor** | Google Cloud's DDoS protection and WAF service |
| **Memorystore** | Google Cloud's fully-managed Redis service |
| **Secret Manager** | Google Cloud's secure secrets storage service |
| **Monorepo** | Single repository containing multiple projects/packages |
| **Vitess** | Database clustering for MySQL (not used here, for reference) |

---

**Status:** Draft - Ready for review  
**Maintainer**: AI-generated per Issue #103  
**Next Steps**: Review with team, add missing components as they are implemented
