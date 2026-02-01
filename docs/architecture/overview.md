# Architecture Overview

**Version:** 1.0  
**Last Updated:** 2026-02-01  
**Purpose:** High-level system architecture for maintainers

---

## 0) System Overview

### 0.1 Purpose

This is a lightweight CRM application for contact management and business cards. The system follows a monorepo structure with separate web and API applications, targeting GCP deployment with PostgreSQL as the primary data store.

### 0.1 Tech Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Frontend | React + TypeScript | Web UI for contact management |
| Backend API | TypeScript + Express.js | RESTful API for business logic |
| Database | PostgreSQL | Persistent data storage (customers, users) |
| Hosting | GCP Cloud Run + Cloud SQL | Serverless deployment |
| Package Manager | pnpm 10.28.2 | Workspace dependency management |
| Runtime | Node.js 24+ | Application execution |
| Testing | Vitest | Unit and integration tests |

### 0.2 Monorepo Structure

```
crm-lab-sandbox/
├── apps/
│   ├── web/          # React frontend application
│   └── api/          # Express.js API backend
├── packages/
│   └── shared/       # Shared utilities and types
├── docs/
│   ├── api/          # OpenAPI specification
│   ├── architecture/ # Architecture documentation (this file)
│   ├── ai/           # AI agent logs and ADRs
│   ├── ops/          # Operational procedures
│   └── security/     # Security policies
└── ops/              # Issue specs and deployment scripts
```

---

## 1) System Components

### 1.1 Web Application (`apps/web`)

**Responsibilities:**
- User interface for contact management
- Authentication state management
- API client communication

**Key Features:**
- Contact list, search, and filtering
- Contact CRUD forms
- Session management (JWT handling)

### 1.2 API Application (`apps/api`)

**Responsibilities:**
- RESTful API endpoints
- Business logic validation
- JWT authentication/authorization
- Database operations

**API Boundaries:**

| Prefix | Purpose | Authentication |
|--------|---------|----------------|
| `/auth/*` | Authentication (login, logout, refresh) | Public (login), Private (logout) |
| `/customers/*` | Customer CRUD operations | JWT required |

### 1.3 Database (PostgreSQL)

**Data Entities:**

| Table | Purpose |
|-------|---------|
| `users` | User accounts (id, email, password_hash, name) |
| `customers` | Customer contacts (id, name, email, phone, company) |
| `refresh_tokens` | JWT refresh tokens (for session management) |

**Connection:**
- CI: GitHub Actions service container
- Production: GCP Cloud SQL (managed PostgreSQL)

---

## 2) Data Flows

### 2.1 Authentication Flow

```
┌─────────────┐      POST /auth/login      ┌─────────────┐
│   Web App   │ ───────────────────────────▶│   API       │
│             │                             │             │
│  (React)    │  ◀─ { accessToken, user } ── │  (Express)  │
└─────────────┘                             └──────┬──────┘
                                                   │
                                                   │ Validate credentials
                                                   │ Generate JWT
                                                   ▼
                                            ┌─────────────┐
                                            │ PostgreSQL  │
                                            │  (users)    │
                                            └─────────────┘

Subsequent Requests:

┌─────────────┐      Authorization: Bearer ┌─────────────┐
│   Web App   │ ───────────────────────────▶│   API       │
│             │                             │             │
│  (React)    │      Verify JWT signature   │  (Express)  │
│             │ ◀───────────────────────────│             │
└─────────────┘      Return data/errors    └──────┬──────┘
                                                   │
                                                   ▼
                                            ┌─────────────┐
                                            │ PostgreSQL  │
                                            │  (customers)│
                                            └─────────────┘
```

### 2.2 Refresh Token Flow

```
┌─────────────┐      POST /auth/refresh     ┌─────────────┐
│   Web App   │ ───────────────────────────▶│   API       │
│             │                             │             │
│  (React)    │  ◀─ { accessToken } ─────── │  (Express)  │
└─────────────┘                             └──────┬──────┘
                                                   │
                                                   │ Validate refresh token
                                                   │ Rotate tokens
                                                   ▼
                                            ┌─────────────┐
                                            │ PostgreSQL  │
                                            │(refresh_tok)│
                                            └─────────────┘
```

### 2.3 Customer CRUD Flow (Example: Create Customer)

```
┌─────────────┐      POST /customers        ┌─────────────┐
│   Web App   │ ───────────────────────────▶│   API       │
│             │      { name, email, phone } │             │
│             │                             │  (Express)  │
│             │  ◀─ { customer object } ────│             │
└─────────────┘    (201 Created)            └──────┬──────┘
                                                   │
                                                   │ Validate input
                                                   │ INSERT INTO customers
                                                   ▼
                                            ┌─────────────┐
                                            │ PostgreSQL  │
                                            │  (customers)│
                                            └─────────────┘
```

---

## 3) API Boundaries

### 3.1 Public Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/login` | Authenticate user, return JWT |
| POST | `/api/v1/auth/refresh` | Refresh access token |

### 3.2 Protected Endpoints (JWT Required)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/logout` | Invalidate session |
| GET | `/api/v1/customers` | List customers (paginated) |
| POST | `/api/v1/customers` | Create customer |
| GET | `/api/v1/customers/:id` | Get single customer |
| PUT | `/api/v1/customers/:id` | Update customer |
| DELETE | `/api/v1/customers/:id` | Delete customer |

### 3.3 Authentication Mechanism

- **Scheme:** HTTP Bearer Token (JWT)
- **Header:** `Authorization: Bearer <access_token>`
- **Token Validation:** API verifies signature and expiration
- **Token Storage:** Client stores in memory/secure storage (not localStorage for security)

---

## 4) Deployment Architecture (GCP)

### 4.1 Production Deployment

```
┌─────────────────────────────────────────────────────────┐
│                     GCP Cloud Run                      │
│  ┌──────────────┐        ┌──────────────┐             │
│  │  Web App     │        │    API       │             │
│  │  (React SPA) │        │  (Express)   │             │
│  └──────┬───────┘        └──────┬───────┘             │
│         │                      │                      │
│         └──────────┬───────────┘                      │
│                    ▼                                  │
│         ┌──────────────────────┐                      │
│         │  Cloud Load Balancer │                      │
│         └──────────┬───────────┘                      │
│                    ▼                                  │
│         ┌──────────────────────┐                      │
│         │   Cloud SQL (PostgreSQL)                   │
│         └──────────────────────┘                      │
└─────────────────────────────────────────────────────────┘
```

### 4.2 Infrastructure Components

| Component | Purpose | Notes |
|-----------|---------|-------|
| Cloud Run | Serverless compute | Auto-scaling web and API containers |
| Cloud SQL | Managed PostgreSQL | High availability, automated backups |
| Cloud Load Balancer | Traffic routing | SSL termination, global distribution |
| Secret Manager | Secrets storage | Database credentials, JWT secrets |
| Cloud Build | CI/CD pipeline | Container builds and deployments |

### 4.3 Environment Separation (Planned)

| Environment | Purpose | GCP Project |
|-------------|---------|--------------|
| Development | Local development | N/A (Docker Compose) |
| Staging | Pre-production testing | Separate GCP project |
| Production | Live application | Production GCP project |

---

## 5) Security Assumptions

### 5.1 Authentication & Authorization

- **Token Type:** JWT (JSON Web Tokens)
- **Algorithm:** RS256 (asymmetric) or HS256 (symmetric)
- **Token Lifetime:**
  - Access token: 15 minutes (configurable)
  - Refresh token: 7 days (configurable)
- **Token Storage:**
  - Access: In-memory or secure storage
  - Refresh: HttpOnly, Secure, SameSite cookies (recommended)

### 5.2 Data Security

| Concern | Mitigation |
|---------|------------|
| Password storage | Bcrypt hashing (cost factor: 12+) |
| Database access | Cloud SQL with IAM authentication |
| API communication | HTTPS only (TLS 1.2+) |
| SQL injection | Parameterized queries |
| XSS | Input validation, output encoding |

### 5.3 Rate Limiting (Planned)

- **Strategy:** Redis-based distributed rate limiting
- **Scope:** Per-IP, per-user, per-API-key
- **Fallback:** Fail-open on Redis failure
- **Reference:** `docs/security/rate-limiting-plan.md`

### 5.4 Secrets Management

| Secret | Storage | Access |
|--------|---------|--------|
| Database URL | Secret Manager | Cloud Run service account |
| JWT secret | Secret Manager | Cloud Run service account |
| API keys (future) | Secret Manager | Cloud Run service account |

**Rule:** Never commit secrets to Git. Use environment variables injected at runtime.

---

## 6) Observability & Monitoring

### 6.1 Logging

| Component | Destination | Purpose |
|-----------|-------------|---------|
| API logs | Cloud Logging | Request tracing, error tracking |
| Web logs | Cloud Logging | Client-side errors, performance |
| Database logs | Cloud Logging | Query performance, deadlocks |

### 6.2 Metrics (Planned)

| Metric | Purpose |
|--------|---------|
| Request latency (p50, p95, p99) | Performance monitoring |
| Error rate (5xx) | Reliability |
| Active users | Business metrics |
| Rate limiting violations | Security |

### 6.3 Alerts (Planned)

- Error rate > 5% for 5 minutes
- P95 latency > 1 second for 5 minutes
- Database connection failures
- Security-related events (failed auth attempts)

---

## 7) Development Workflow

### 7.1 Local Development

```bash
# Install dependencies
pnpm install

# Run type checking
pnpm -r exec tsc --noEmit

# Run tests
pnpm --filter @crm/api test:run

# Build
pnpm build
```

### 7.2 CI/CD Pipeline

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Push/PR   │ -> │  GitHub     │ -> │   Build     │
│   to Git    │    │  Actions    │    │   Images    │
└─────────────┘    └─────────────┘    └──────┬──────┘
                                               │
                                               ▼
                                        ┌─────────────┐
                                        │   Tests &   │
                                        │   Linting   │
                                        └──────┬──────┘
                                               │
                                               ▼
                                        ┌─────────────┐
                                        │  Deploy to  │
                                        │  Staging    │
                                        └─────────────┘
```

**Quality Gates:**
- TypeScript compilation (no errors)
- Unit tests (Vitest) - must pass
- Linting (configured) - no warnings
- Security scanning (planned)

### 7.3 Testing Strategy

| Type | Framework | Coverage Target |
|------|-----------|-----------------|
| Unit | Vitest | 80%+ |
| Integration | Vitest | Critical paths |
| E2E | Playwright (planned) | Key user flows |

---

## 8) References

### 8.1 Documentation

| Document | Path |
|----------|------|
| OpenAPI Specification | `docs/api/openapi.yaml` |
| Rate Limiting Plan | `docs/security/rate-limiting-plan.md` |
| Agent Operating Rules | `AGENTS.md` |
| Session Logs | `docs/ai/session-log/` |

### 8.2 External Links

| Resource | URL |
|----------|-----|
| GCP Cloud Run | https://cloud.google.com/run |
| GCP Cloud SQL | https://cloud.google.com/sql |
| Express.js | https://expressjs.com/ |
| React | https://react.dev/ |
| Vitest | https://vitest.dev/ |

---

## 9) Change Log

| Date | Version | Changes |
|------|---------|---------|
| 2026-02-01 | 1.0 | Initial architecture overview |

---

**Status:** Active  
**Maintained by:** Development Team  
**Last Review:** 2026-02-01
