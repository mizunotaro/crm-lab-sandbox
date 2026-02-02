# Cloud Armor / WAF Baseline

**Version:** 1.0  
**Last Updated:** 2026-02-01  
**Purpose:** Minimum viable external attack protection using Cloud Armor and WAF rules for PoC deployment

---

## 0) Current State

### 0.1 Problem Statement
- **Current implementation:** No external WAF or rate limiting at the edge
- **Issue:** Application is directly exposed to:
  - Volumetric DDoS attacks
  - Common web vulnerabilities (SQL injection, XSS, etc.)
  - Abuse from malicious IPs or bots
  - Resource exhaustion attacks
- **Risk:** Service disruption, data exposure, operational costs from abuse

### 0.2 Requirements
- **Minimum viable protection:** Baseline WAF rules without complex configuration
- **GCP-native:** Leverage Cloud Armor for simplicity and integration
- **Low operational overhead:** Minimal maintenance for PoC phase
- **Defense in depth:** Work alongside application-level controls
- **Observable:** Clear metrics and logging for security events
- **Gradual rollout:** Start in audit mode before enforcement

---

## 1) Cloud Armor Architecture

### 1.1 Components

```
Internet → Global Load Balancer (GCLB)
              ↓
         Cloud Armor Security Policy
              ↓
         Cloud Run Backend Service
```

**Security Policy Layers:**
1. **Preconfigured Rules:** Google-managed WAF signatures (OWASP Top 10, CVE signatures)
2. **Rate-Based Rules:** Threshold-based blocking (e.g., reject > 100 req/sec per IP)
3. **IP-Based Rules:** Allowlist/denylist for specific IP ranges
4. **Custom Rules:** Application-specific conditions (paths, headers, etc.)

---

## 2) Recommended Baseline Rules

### 2.1 Preconfigured WAF Rules (Google-Managed)

**Priority 1 (Critical) - OWASP Top 10:**

| Rule Name | Description | Action | Risk Level |
|-----------|-------------|--------|------------|
| `sqli_detection` | SQL injection patterns | Deny (403) | High |
| `xss_detection` | Cross-site scripting patterns | Deny (403) | High |
| `rfi_detection` | Remote file inclusion | Deny (403) | High |
| `lfi_detection` | Local file inclusion | Deny (403) | High |
| `rce_detection` | Remote code execution | Deny (403) | High |
| `php_injection` | PHP code injection | Deny (403) | High |
| `java_injection` | Java code injection | Deny (403) | High |

**Priority 2 (High) - Common Attack Patterns:**

| Rule Name | Description | Action | Risk Level |
|-----------|-------------|--------|------------|
| `user_agent_scanner` | Scanner/bot detection | Deny (403) | Medium |
| `comment_spam` | Comment spam patterns | Deny (403) | Medium |
| `protocol_attack` | Protocol abuse attempts | Deny (403) | Medium |

**Deployment Mode:** Start with **preview mode** (log-only) for 1-2 weeks before enforcement.

### 2.2 Rate-Based Rules

**Default Rule:**

```yaml
Rule: Rate Limit per IP
Priority: 1000
Description: Limit requests per IP address
Action: Deny (429) when exceeded
Configuration:
  Threshold: 100 requests per 60 seconds
  Enforce on: Source IP
  Ban duration: 300 seconds (5 minutes)
```

**Alternative Configurations:**

| Traffic Profile | Threshold | Window | Use Case |
|-----------------|-----------|--------|----------|
| Low traffic (< 10K req/day) | 50 req/min | 60 sec | Conservative, safer for PoC |
| Medium traffic (< 100K req/day) | 100 req/min | 60 sec | Balanced protection |
| High traffic (> 100K req/day) | 200 req/min | 60 sec | Permissive, needs tuning |

**Note:** Start with conservative thresholds and adjust based on monitoring.

### 2.3 IP-Based Rules

**Default Allowlist (Optional):**

```yaml
Rule: Allow Office IPs
Priority: 1
Description: Allow traffic from known office/VPN ranges
Action: Allow
Source Ranges:
  - 192.0.2.0/24  # Placeholder - replace with actual CIDR
  - 203.0.113.0/24  # Placeholder - replace with actual CIDR
```

**Default Denylist:**

```yaml
Rule: Block Known Malicious IPs
Priority: 2
Description: Block IPs from threat intelligence feeds
Action: Deny (403)
Source Ranges:
  # Add from threat intel feeds (e.g., AbuseIPDB, Spamhaus)
  - placeholder-cidr-range-1
```

**Recommendation:** Maintain external IP list (e.g., in secret manager) and update via automation.

### 2.4 Custom Rules (Optional for PoC)

**Example: Block API Abuse:**

```yaml
Rule: Block API Path Abuse
Priority: 500
Description: Excessive requests to sensitive endpoints
Action: Deny (429)
Expression: |
  evaluatePreconfiguredExpr('sqli_detection') == false &&
  evaluatePreconfiguredExpr('xss_detection') == false &&
  request.path.matches('/api/v1/users.*') &&
  rateLimitThrottleKey.key == request.headers['x-api-key'][0] &&
  rateLimitThrottleKey.requests_per_second > 10
```

**Recommendation:** Skip for initial PoC; add during evaluation phase.

---

## 3) Terraform Configuration Example

### 3.1 Cloud Armor Policy (Baseline)

```hcl
resource "google_compute_security_policy" "app_security_policy" {
  name        = "app-security-policy"
  description = "Baseline WAF and rate limiting for application"

  # Preconfigured WAF rules (OWASP Top 10)
  rule {
    action      = "allow"
    priority    = "2147483647"  # Default rule (lowest priority)
    description = "Default allow rule"
    match {
      config {
        src_ip_ranges = ["*"]
      }
      versioned_expr = "SRC_IPS_V1"
    }
  }

  # SQL injection detection
  rule {
    action      = "deny(403)"
    priority    = "100"
    description = "Block SQL injection attacks"
    preview     = true  # Start in preview mode
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli_detection')"
      }
    }
  }

  # XSS detection
  rule {
    action      = "deny(403)"
    priority    = "101"
    description = "Block XSS attacks"
    preview     = true
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss_detection')"
      }
    }
  }

  # Rate limiting per IP
  rule {
    action      = "rate_based_ban"
    priority    = "1000"
    description = "Rate limit: 100 req/min per IP"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      enforce_on_key     = "IP"
      ban_duration_sec   = 300
      conform_action     = "allow"
      exceed_action      = "deny(429)"
      ban_threshold {
        count        = 100
        interval_sec = 60
      }
    }
  }
}
```

### 3.2 Attach Policy to Load Balancer

```hcl
resource "google_compute_backend_service" "app_backend" {
  name        = "app-backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 30

  # ... other backend configuration ...

  security_policy = google_compute_security_policy.app_security_policy.id
}
```

---

## 4) Deployment Strategy

### 4.1 Phase 1: Setup (Day 1-2)

**Tasks:**
1. Create Cloud Armor security policy via Terraform
2. Attach to existing or new Load Balancer
3. Enable logging (Cloud Logging)
4. Verify traffic flows through policy

**Verification:**
```bash
# Check policy exists
gcloud compute security-policies list

# View policy details
gcloud compute security-policies describe app-security-policy

# Test connectivity (should pass)
curl -I https://your-app.example.com
```

### 4.2 Phase 2: Preview Mode (Week 1)

**Tasks:**
1. Enable `preview: true` on all WAF rules (log-only mode)
2. Enable rate limiting with high threshold (e.g., 1000 req/min)
3. Monitor logs for 5-7 days
4. Identify false positives

**Monitoring Queries:**

```sql
-- WAF rule violations (Cloud Logging)
SELECT
  jsonPayload.rule_priority,
  jsonPayload.rule_description,
  COUNT(*) as violations
FROM `your-project.cloudaudit_googleapis_com_activity`
WHERE
  resource.type = "gce_backend_service"
  AND jsonPayload.action = "denied"
GROUP BY
  jsonPayload.rule_priority,
  jsonPayload.rule_description
ORDER BY violations DESC
LIMIT 20
```

```sql
-- Rate limit triggers
SELECT
  jsonPayload.src_ip,
  COUNT(*) as trigger_count
FROM `your-project.cloudaudit_googleapis_com_activity`
WHERE
  resource.type = "gce_backend_service"
  AND jsonPayload.action = "rate_limit"
GROUP BY
  jsonPayload.src_ip
ORDER BY trigger_count DESC
LIMIT 10
```

### 4.3 Phase 3: Gradual Enforcement (Week 2-3)

**Tasks:**
1. Remove `preview: true` from low-risk rules (rate limiting)
2. Monitor for 2-3 days
3. Enable enforcement on medium-risk rules (e.g., scanner detection)
4. Monitor for 2-3 days
5. Enable enforcement on high-risk rules (OWASP Top 10)

**Rollback if:**
- False positive rate > 1% of requests
- Legitimate users report blocking
- Error rate increases significantly

### 4.4 Phase 4: Evaluation (Month 1+)

**Tasks:**
1. Review security metrics (blocked attacks, prevented incidents)
2. Review performance metrics (latency impact, cost)
3. Adjust thresholds based on traffic patterns
4. Consider adding custom rules if needed
5. Document lessons learned

---

## 5) Cost Estimate

### 5.1 Cloud Armor Pricing (as of 2026)

| Component | Cost |
|-----------|------|
| Base (up to 1M evaluated requests/month) | Free |
| Additional requests | $0.75 per million requests |
| Preconfigured WAF rules | Included in base cost |
| Custom security rules | $5.00 per 1000 requests evaluated |

### 5.2 Example Costs

| Traffic Volume | Monthly Cost | Notes |
|----------------|--------------|-------|
| 100K requests/month | $0 | Free tier |
| 1M requests/month | $0 | Free tier |
| 10M requests/month | ~$6.75 | Beyond free tier |
| 100M requests/month | ~$73.50 | 99M evaluated requests @ $0.75/M |
| 1B requests/month | ~$735.00 | 999M evaluated requests @ $0.75/M |

**Note:** Costs are estimates. Consult [GCP Pricing Calculator](https://cloud.google.com/products/calculator) for accurate projections.

### 5.3 Cost Optimization Tips

1. **Start with free tier:** Most PoC deployments stay within 1M requests/month
2. **Filter noise:** Block obvious bots/scanners to reduce evaluated requests
3. **Monitor regularly:** Set budget alerts in GCP billing
4. **Tune thresholds:** Higher rate limits reduce evaluation load

---

## 6) Tradeoffs and Considerations

### 6.1 Pros

| Benefit | Explanation |
|---------|-------------|
| **Zero application latency** | Filtering happens at edge, before reaching Cloud Run |
| **Managed service** | No infrastructure to maintain; Google handles updates |
| **DDoS protection** | Integrated with Google's global network and DDoS response |
| **IaC support** | Policies version-controlled via Terraform |
| **Observability** | Built-in logging and metrics integration |
| **Global enforcement** | Single policy applies across all regions |

### 6.2 Cons

| Limitation | Impact |
|------------|--------|
| **No application context** | Cannot inspect request body beyond supported fields |
| **Limited granularity** | Cannot rate limit by API key, user ID, or plan tier |
| **Propagation delay** | Policy changes may take 1-2 minutes to propagate globally |
| **GCP lock-in** | Tied to Google Cloud infrastructure |
| **Cost at scale** | Per-request pricing can be expensive for high-volume APIs |
| **False positives** | WAF rules may block legitimate traffic (requires tuning) |

### 6.3 When to Use Cloud Armor

**Good fit if:**
- Primary threat is volumetric DDoS or common web vulnerabilities
- Application does not need per-user or per-key rate limiting
- Already using GCP infrastructure
- Want minimal operational overhead
- Traffic volume is low to moderate (< 100M requests/month)

**Consider alternatives if:**
- Need per-user or per-API-key rate limiting
- Require application-level context (e.g., request body validation)
- Want to avoid GCP vendor lock-in
- Traffic volume is very high (> 1B requests/month)

---

## 7) Monitoring and Alerting

### 7.1 Key Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `security_policy_evaluated_requests` | Total requests evaluated by policy | - |
| `security_policy_request_count` | Requests matching each rule | > 1000/min (investigate) |
| `security_policy_prevented_requests` | Requests blocked by policy | > 100/min (investigate) |

### 7.2 Recommended Dashboards

**Dashboard: Cloud Armor Security**
- Request volume (evaluated, allowed, denied)
- Top blocked IPs (last 1 hour)
- Top triggered rules (last 24 hours)
- False positive rate (calculated from feedback)
- Latency impact (p50, p95, p99)

### 7.3 Alerting Rules

**Critical Alerts:**
- Block rate > 10% of total requests for 5+ minutes (may indicate over-blocking)
- Rate limit triggered by > 100 unique IPs in 1 minute (possible attack)
- Policy evaluation failures (configuration error)

**Warning Alerts:**
- New rule triggered > 100 times in 1 hour (may need tuning)
- Traffic spike > 3x normal (potential attack or scaling issue)

---

## 8) Risk Assessment

### 8.1 Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| False positives blocking users | Medium | High | Preview mode first, gradual rollout, easy rollback |
| Configuration errors | Medium | Medium | IaC review, test in staging, gradual rollout |
| Cost overruns | Low | Medium | Budget alerts, regular monitoring |
| Policy propagation delay | Low | Low | Test in staging, allow propagation time |
| DDoS exceeding capacity | Low | High | Cloud Armor scales with Google's infrastructure |

### 8.2 Mitigation Checklist

- [ ] All policies defined in Terraform (IaC)
- [ ] Preview mode enabled before enforcement
- [ ] Budget alerts configured in GCP billing
- [ ] Rollback procedure documented
- [ ] Monitoring dashboards created
- [ ] Alerting rules configured
- [ ] Incident response procedure documented
- [ ] Regular review of blocked requests (weekly)

---

## 9) Success Criteria

### 9.1 Functional Requirements
- [ ] Cloud Armor policy attached to Load Balancer
- [ ] Preconfigured WAF rules enabled (OWASP Top 10)
- [ ] Rate limiting rule active (configurable threshold)
- [ ] Logging enabled and verified

### 9.2 Operational Requirements
- [ ] Zero false positives during preview mode
- [ ] < 0.1% false positive rate after enforcement
- [ ] Latency impact < 5ms p95
- [ ] Cost within projected budget

### 9.3 Security Requirements
- [ ] 100% of OWASP Top 10 patterns detected
- [ ] DDoS attacks mitigated (tested via load testing)
- [ ] Security events logged with full context
- [ ] Incident response time < 15 minutes for critical alerts

---

## 10) Next Steps (Evaluation Phase)

### 10.1 Immediate Actions (Week 1)
1. Create Cloud Armor policy via Terraform (baseline rules)
2. Attach to existing Load Balancer
3. Enable logging and monitoring
4. Start in preview mode (log-only)
5. Document deployment process

### 10.2 Evaluation Actions (Week 2-4)
1. Monitor preview logs for false positives
2. Adjust thresholds based on traffic patterns
3. Enable rate limiting enforcement (gradual)
4. Enable WAF rule enforcement (gradual, low-risk first)
5. Document learnings and blocked attacks

### 10.3 Decision Points (End of Month 1)

**Continue with Cloud Armor if:**
- False positive rate < 0.1%
- Latency impact < 5ms
- Cost < $100/month
- Security value demonstrated (blocked attacks detected)

**Consider alternatives if:**
- False positive rate > 1% after tuning
- Need per-user or per-key rate limiting
- Cost exceeds budget significantly

**Possible alternatives:**
- **Application-level rate limiting** (Redis-based) for per-user control
- **CDN-based WAF** (e.g., Cloudflare) for multi-cloud deployment
- **Hybrid approach:** Cloud Armor for DDoS + Redis for app-level limits

---

## 11) References

### 11.1 GCP Documentation
- [Cloud Armor Documentation](https://cloud.google.com/armor/docs)
- [Cloud Armor Preconfigured Rules](https://cloud.google.com/armor/docs/preconfigured-rules)
- [Security Best Practices](https://cloud.google.com/architecture/security-best-practices)
- [Load Balancer Configuration](https://cloud.google.com/load-balancing/docs)

### 11.2 Standards
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP Cheat Sheets](https://cheatsheetseries.owasp.org/)
- [CWE/SANS Top 25](https://cwe.mitre.org/top25/)

### 11.3 Terraform Provider
- [Google Cloud Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_security_policy)

---

**Status:** Draft - Ready for Implementation  
**Owner:** Security Team  
**Reviewers:** DevOps Team, Engineering Team  
**Next Steps:** Create tracking issue for Phase 1 (Policy Setup)
