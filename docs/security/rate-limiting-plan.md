# Rate Limiting Plan

**Version:** 1.0  
**Last Updated:** 2026-02-01  
**Purpose:** Production-grade rate limiting strategy for multi-instance deployments

---

## 0) Current State

### 0.1 Problem Statement
- Current implementation: In-memory rate limiting (process-local)
- Issue: Does not work correctly with multiple instances behind a load balancer
- Each instance maintains its own counter, allowing global limits to be exceeded
- Example: With 3 instances and 100 requests/minute limit, actual limit becomes 300 requests/minute

### 0.2 Requirements
- **Multi-instance safe**: Shared state across all instances
- **Durability**: Survive instance restarts and deployments
- **Performance**: Minimal latency impact on API requests
- **Observability**: Metrics and logging for monitoring
- **Scalability**: Handle traffic growth without major redesign
- **GCP-compatible**: Work with Cloud Run infrastructure

---

## 1) Option Comparison

### Option A: Redis-based Rate Limiting

#### 1.1 Architecture
```
Load Balancer → Cloud Run Instances (N) → Redis (Memorystore)
                                        ↓
                                   Distributed Counter
```

#### 1.2 Implementation Approach

**Algorithm Choices:**

| Algorithm | Description | Pros | Cons |
|-----------|-------------|------|------|
| Token Bucket | Tokens refill over time, burst allowed | Smooth traffic handling, burst tolerance | Complex to implement correctly |
| Leaky Bucket | Requests processed at fixed rate | Predictable rate, memory efficient | Poor burst handling |
| Fixed Window | Counter resets at interval | Simple to implement | Spike at window boundaries |
| Sliding Window Log | Track all request timestamps | Precise, no boundary spikes | High memory usage |
| Sliding Window Counter | Approximate sliding window with fixed windows | Good balance of precision/efficiency | Slightly complex |

**Recommended:** Sliding Window Counter or Token Bucket

**Key Components:**
1. Redis connection pool (connection string from Secret Manager)
2. Rate limiting middleware/library (e.g., `rate-limiter-flexible` for Node.js)
3. Configuration:
   - Per-endpoint limits (API key, IP, user ID)
   - Time windows (minute, hour, day)
   - Burst allowances
4. Metrics:
   - Request count per key
   - Rejection count
   - Redis hit rate
   - Latency

#### 1.3 Estimated Effort

| Phase | Tasks | Effort |
|-------|-------|--------|
| Planning | Design, algorithm selection, capacity planning | 4-8 hours |
| Implementation | Library integration, middleware setup, configuration | 8-12 hours |
| Testing | Unit tests, integration tests, load testing | 8-12 hours |
| Deployment | Staging rollout, monitoring setup, production rollout | 4-8 hours |
| Documentation | Runbooks, monitoring dashboards, incident response | 4 hours |
| **Total** | | **28-44 hours** |

#### 1.4 Pros

- ✅ **Flexibility**: Granular control per endpoint/user/API key
- ✅ **Precision**: Accurate counting across instances
- ✅ **Features**: Built-in features like burst allowances, tiered limits
- ✅ **Cost-effective**: Lower operational cost for moderate traffic
- ✅ **Observability**: Easy to add metrics and logging
- ✅ **Portable**: Can move to other clouds or self-hosted Redis

#### 1.5 Cons

- ❌ **Infrastructure overhead**: Need to provision and manage Redis
- ❌ **Latency**: Network round-trip to Redis (adds 1-10ms)
- ❌ **Complexity**: More moving parts to monitor and debug
- ❌ **Cost scaling**: Redis cost increases with traffic and data size
- ❌ **SPOF risk**: Redis outage = rate limiting disabled (fail-open recommended)

#### 1.6 Deployment Strategy

**Rollout Plan:**
1. Set up Redis instance in non-production environment
2. Integrate Redis client and rate limiting library
3. Implement with "shadow mode" (log violations but don't block)
4. Monitor for 1-2 weeks to calibrate limits
5. Gradually enforce limits (10% → 50% → 100%)
6. Deploy to production with feature flag for instant rollback

**Monitoring Requirements:**
- Redis latency (p50, p95, p99)
- Redis memory usage
- Request rejection rate
- Rate limiting middleware latency impact

#### 1.7 Rollback Strategy

**Scenarios:**

| Scenario | Rollback Steps | Downtime |
|----------|----------------|----------|
| High latency | Increase Redis timeout, switch to fail-open | 0 min |
| Redis outage | Feature flag to disable rate limiting entirely | < 1 min |
| Incorrect limits | Adjust configuration, no rollback needed | 0 min |
| Implementation bug | Revert to previous deployment (no Redis) | 2-5 min |

**Fail-open Behavior:**
- On Redis connection failure, bypass rate limiting
- Log the failure and alert operations
- This ensures availability even if rate limiting is degraded

---

### Option B: Google Cloud Armor

#### 1.8 Architecture
```
External Load Balancer → Cloud Armor (Global) → Cloud Run Backend
                                ↓
                           Security Policies
```

#### 1.9 Implementation Approach

**Policy Types:**

| Type | Description | Use Case |
|------|-------------|----------|
| IP-based | Limit by source IP address | Basic DDoS protection, abusive IPs |
| Rate-based | Requests per second per IP/region | Volume-based attacks |
| WAF Rules | SQL injection, XSS, etc. | Application-layer attacks |
| Preconfigured Rules | Google-managed security rules | Known attack patterns |

**Key Components:**
1. Cloud Armor policy attached to Load Balancer
2. Rate-based rules (e.g., "reject > 100 req/sec per IP")
3. IP denylist/allowlist rules
4. Security rules (e.g., block specific paths, user agents)
5. Logging and monitoring via Cloud Logging

#### 1.10 Estimated Effort

| Phase | Tasks | Effort |
|-------|-------|--------|
| Planning | Policy design, rule definition, capacity planning | 4-6 hours |
| Implementation | Create LB, attach policy, configure rules | 4-6 hours |
| Testing | Unit tests, integration tests, attack simulation | 6-8 hours |
| Deployment | Staging validation, production rollout | 2-4 hours |
| Documentation | Runbooks, monitoring dashboards | 2 hours |
| **Total** | | **18-26 hours** |

#### 1.11 Pros

- ✅ **Infrastructure-as-code**: Policies version-controlled
- ✅ **Zero latency**: Handled before reaching application
- ✅ **Managed service**: No operational overhead for Redis
- ✅ **DDoS protection**: Integrated with Google's global network
- ✅ **WAF features**: Built-in security rule sets
- ✅ **Global enforcement**: Single policy for all regions
- ✅ **Scalability**: Auto-scales with Google's infrastructure

#### 1.12 Cons

- ❌ **Limited granularity**: Cannot rate limit by API key or user ID
- ❌ **No app-level context**: Cannot inspect request body or headers beyond supported fields
- ❌ **Configuration delay**: Policy changes take time to propagate
- ❌ **Cost scaling**: Pay-per-request pricing can be expensive at high volume
- ❌ **Lock-in**: Tied to GCP infrastructure
- ❌ **Limited flexibility**: Fewer algorithm options compared to Redis

#### 1.13 Deployment Strategy

**Rollout Plan:**
1. Create Cloud Armor policy in test mode (log-only, no enforcement)
2. Attach to existing or new Load Balancer
3. Monitor logs for 1-2 weeks to calibrate thresholds
4. Enable enforcement gradually (audit mode → warn → enforce)
5. Validate with synthetic traffic

**Monitoring Requirements:**
- Policy evaluation count
- Request rejection count
- False positive rate
- Latency impact (minimal expected)

#### 1.14 Rollback Strategy

**Scenarios:**

| Scenario | Rollback Steps | Downtime |
|----------|----------------|----------|
| False positives | Add whitelist rules, adjust thresholds | 0-5 min |
| Policy too aggressive | Edit policy to reduce strictness | < 1 min |
| Configuration error | Disable enforcement (log-only mode) | < 1 min |
| Complete failure | Remove policy from Load Balancer | < 1 min |

---

## 2) Decision Framework

### 2.1 Decision Criteria

| Criterion | Weight | Redis Option | Cloud Armor Option |
|-----------|--------|--------------|-------------------|
| **Multi-instance safety** | Critical | ✅ Excellent | ✅ Excellent |
| **Granular control (per user/key)** | High | ✅ Excellent | ❌ Poor |
| **Application-level context** | High | ✅ Excellent | ⚠️ Limited |
| **Operational overhead** | Medium | ⚠️ Higher | ✅ Low |
| **Latency impact** | Medium | ⚠️ 1-10ms added | ✅ Zero |
| **DDoS protection** | Medium | ⚠️ Basic | ✅ Excellent |
| **Cost predictability** | Medium | ✅ Flat Redis cost | ⚠️ Variable per-request |
| **Vendor lock-in** | Low | ✅ Portable | ❌ GCP-specific |
| **Development effort** | Low | ⚠️ Higher | ✅ Lower |

### 2.2 Use Case Recommendations

#### Choose Redis if:
- Need per-user or per-API-key rate limiting
- Require application-level context (e.g., plan tiers)
- Traffic volume is moderate to high
- Want burst allowances and flexible algorithms
- Prefer portable, multi-cloud approach
- Have existing Redis infrastructure

#### Choose Cloud Armor if:
- Primary concern is DDoS protection
- Traffic volume is low to moderate
- IP-based blocking is sufficient
- Want minimal infrastructure overhead
- Already fully committed to GCP
- Need WAF features (SQL injection, XSS, etc.)

### 2.3 Hybrid Approach (Recommended for Production)

**Combine both options for defense in depth:**

```
Layer 1: Cloud Armor (IP-based, DDoS protection)
Layer 2: Redis (Application-level, per-user/key limits)
```

**Rationale:**
- Cloud Armor handles volumetric attacks and abusive IPs at the edge
- Redis handles business-level rate limiting (API keys, user tiers)
- Redundant protection improves overall security posture
- If one layer fails, the other still provides some protection

**Implementation Order:**
1. Start with Cloud Armor (easier, faster to deploy)
2. Add Redis for application-specific needs
3. Monitor and adjust both layers independently

---

## 3) Recommended Implementation Path

### 3.1 Phase 1: Immediate Protection (Cloud Armor) - Week 1
**Effort:** 1-2 days

- Create Cloud Armor policy in audit mode
- Add rate-based rule: 100 req/sec per IP
- Add IP denylist rule for known abusive IPs
- Monitor logs for 3-5 days
- Enable enforcement

**Deliverables:**
- Cloud Armor policy configuration
- Monitoring dashboard
- Rollback procedure documented

### 3.2 Phase 2: Application-Level Control (Redis) - Weeks 2-3
**Effort:** 3-5 days

- Provision Redis instance (Memorystore for Redis)
- Integrate rate limiting library
- Implement per-API-key limits (e.g., 1000 req/min per key)
- Implement per-user limits (e.g., free tier: 100 req/min, paid: 1000 req/min)
- Deploy with shadow mode first
- Gradually enforce

**Deliverables:**
- Redis integration in codebase
- Rate limiting middleware
- Configuration management
- Metrics and alerts
- Runbook for troubleshooting

### 3.3 Phase 3: Optimization & Observability - Week 4
**Effort:** 1-2 days

- Fine-tune thresholds based on production data
- Add Prometheus/Grafana dashboards
- Create SLO for rate limiting accuracy
- Document incident response for rate limiting failures
- Run chaos engineering tests (Redis failure scenarios)

**Deliverables:**
- Production-tuned configuration
- Comprehensive monitoring
- Operational runbooks

---

## 4) Cost Estimate (Monthly)

### 4.1 Redis Option (Memorystore)
- **Basic tier (1GB):** ~$50/month
- **Standard tier (4GB):** ~$200/month
- **Network egress:** Additional if high traffic

### 4.2 Cloud Armor Option
- **Base:** Free (up to 1M evaluated requests/month)
- **Beyond 1M:** $0.75 per million evaluated requests
- **Example:**
  - 10M requests/month: ~$6.75
  - 100M requests/month: ~$73.50
  - 1B requests/month: ~$735.00

### 4.3 Hybrid Option
- **Low traffic (< 10M req/month):** ~$50-75/month
- **Medium traffic (10-100M req/month):** ~$200-300/month
- **High traffic (> 100M req/month):** ~$900-1000/month

**Note:** Costs are estimates. Consult GCP pricing calculator for accurate projections.

---

## 5) Risk Assessment

### 5.1 Common Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Redis latency spike | Medium | Medium | Connection pooling, timeout tuning, fail-open |
| False positive blocks | Low-Medium | High | Shadow mode first, alerting, easy rollback |
| Cost overrun | Low | Medium | Monitoring, budget alerts, tiered scaling |
| Configuration errors | Medium | High | IaC review, gradual rollout, feature flags |
| Redis SPOF | Low | High | Fail-open design, multi-az Redis (if needed) |
| Cloud Armor propagation delay | Low | Low | Test in staging first |

### 5.2 Risk Mitigation Checklist

- [ ] All policies configured via Infrastructure-as-Code (Terraform)
- [ ] Feature flags for enabling/disabling rate limiting
- [ ] Fail-open behavior on Redis connection failure
- [ ] Comprehensive logging and alerting
- [ ] Gradual rollout with shadow mode
- [ ] Budget alerts for cost monitoring
- [ ] Regular review of rate limit thresholds
- [ ] Incident response procedures documented

---

## 6) Success Metrics

### 6.1 Operational Metrics
- **Rate limiting accuracy:** < 0.1% false positive rate
- **Latency impact:** < 10ms p95 added latency
- **Availability:** > 99.9% uptime (including Redis outages via fail-open)
- **Cost:** Within projected budget (+/- 20%)

### 6.2 Security Metrics
- **DDoS attack mitigation:** 100% of volumetric attacks blocked
- **Abuse prevention:** 90%+ reduction in API abuse (as defined by security policy)
- **Alert response time:** < 5 minutes for critical alerts

---

## 7) References

### 7.1 GCP Documentation
- [Cloud Armor Documentation](https://cloud.google.com/armor/docs)
- [Cloud Memorystore for Redis](https://cloud.google.com/memorystore/docs/redis)
- [Security Best Practices](https://cloud.google.com/architecture/security-best-practices)

### 7.2 Implementation Libraries
- Node.js: `rate-limiter-flexible`, `express-rate-limit`
- Redis: `ioredis`, `redis`

### 7.3 Standards
- [OWASP Rate Limiting Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Rate_Limiting_Cheat_Sheet.html)
- [RFC 6585 (HTTP 429 Too Many Requests)](https://tools.ietf.org/html/rfc6585)

---

## 8) Appendix: Configuration Examples

### 8.1 Cloud Armor Policy Example (Terraform)

```hcl
resource "google_compute_security_policy" "rate_limit_policy" {
  name        = "rate-limit-policy"
  description = "Rate limiting policy for API"

  rule {
    action   = "rate_based_ban"
    priority = "1"
    description = "Block IPs exceeding 100 req/sec"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      enforce_on_key = "IP"
      ban_duration_sec = 3600
      ban_threshold {
        count        = 100
        interval_sec = 60
      }
      conform_action = "allow"
      exceed_action  = "deny(404)"
    }
  }
}
```

### 8.2 Redis Rate Limiting Example (Node.js)

```typescript
import { RateLimiterRedis } from 'rate-limiter-flexible';
import Redis from 'ioredis';

const redis = new Redis(process.env.REDIS_URL);

// Per-API-key rate limiter: 1000 requests per minute
const apiRateLimiter = new RateLimiterRedis({
  storeClient: redis,
  keyPrefix: 'api_limit',
  points: 1000, // Number of requests
  duration: 60, // Per 60 seconds
  blockDuration: 60, // Block for 60 seconds if limit exceeded
});

// Middleware function
export async function rateLimitMiddleware(req, res, next) {
  const apiKey = req.headers['x-api-key'];
  
  try {
    await apiRateLimiter.consume(apiKey);
    next();
  } catch (rej) {
    res.status(429).json({
      error: 'Too many requests',
      retryAfter: rej.msBeforeNext / 1000,
    });
  }
}
```

---

**Status:** Ready for review  
**Next Steps:** Create tracking issue for Phase 1 (Cloud Armor implementation)
