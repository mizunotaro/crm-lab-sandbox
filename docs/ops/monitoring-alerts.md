# Monitoring & Alerts

**Version:** 1.0  
**Last Updated:** 2026-02-01  
**Purpose:** Log-based metrics definition, alerting thresholds, and minimal runbook for Cloud Run/Cloud SQL monitoring.

---

## 1) Log-Based Metrics Overview

### 1.1 Metric Categories
- **Error Rate:** Percentage of failed requests
- **Latency:** Request response time (p50, p95, p99)
- **Throughput:** Requests per second
- **Availability:** Service uptime percentage

### 1.2 Data Sources
- **Cloud Run:** Request logs, container logs
- **Cloud SQL:** Query logs, connection logs, error logs
- **Application Logs:** Custom logs from application code

---

## 2) Cloud Run Metrics

### 2.1 Error Rate Metrics

#### 2.1.1 Log Filter (Error Rate)
```sql
resource.type="cloud_run_revision"
severity="ERROR"
```

**Aggregation:** Count errors / Total requests  
**Alert Threshold:** > 5% error rate for 5 minutes  
**Severity:** P1 (High)

#### 2.1.2 HTTP Status Code Breakdown
```sql
resource.type="cloud_run_revision"
http_request.status_code >= 400
```

**Key Status Codes to Monitor:**
- `4xx`: Client errors (potential API contract issues)
- `5xx`: Server errors (application failures)

### 2.2 Latency Metrics

#### 2.2.1 Response Time (p95)
```sql
resource.type="cloud_run_revision"
http_request.latency
```

**Alert Thresholds:**
- **Warning:** p95 latency > 1000ms for 5 minutes
- **Critical:** p95 latency > 3000ms for 5 minutes

**Severity:** P2 (Warning), P1 (Critical)

### 2.3 Availability Metrics

#### 2.3.1 Service Health Check
```sql
resource.type="cloud_run_revision"
http_request.request_path="/health"
```

**Alert Threshold:** Health check fails for 3 consecutive minutes  
**Severity:** P0 (Critical)

---

## 3) Cloud SQL Metrics

### 3.1 Query Performance

#### 3.1.1 Slow Query Detection
```sql
resource.type="cloudsql_database"
sql.googleapis.com/statement.execution_time > 1000
```

**Alert Threshold:** Queries exceeding 1 second execution time  
**Severity:** P2 (Medium)

#### 3.1.2 Failed Connections
```sql
resource.type="cloudsql_database"
severity="ERROR"
jsonPayload.message:"connection"
```

**Alert Threshold:** > 10 failed connections per minute  
**Severity:** P1 (High)

### 3.2 Database Resources

#### 3.2.1 CPU Utilization
```sql
resource.type="cloudsql_database"
metric.type="cloudsql.googleapis.com/database/cpu/utilization"
```

**Alert Thresholds:**
- **Warning:** CPU > 70% for 5 minutes
- **Critical:** CPU > 90% for 2 minutes

**Severity:** P2 (Warning), P1 (Critical)

#### 3.2.2 Memory Utilization
```sql
resource.type="cloudsql_database"
metric.type="cloudsql.googleapis.com/database/memory/utilization"
```

**Alert Threshold:** Memory > 85% for 5 minutes  
**Severity:** P1 (High)

### 3.3 Storage

#### 3.3.1 Disk Usage
```sql
resource.type="cloudsql_database"
metric.type="cloudsql.googleapis.com/database/disk/utilization"
```

**Alert Thresholds:**
- **Warning:** Disk usage > 70%
- **Critical:** Disk usage > 85%

**Severity:** P2 (Warning), P1 (Critical)

---

## 4) Alert Configuration Examples

### 4.1 Cloud Run Error Rate Alert

```yaml
name: cloud-run-error-rate
description: Alert on Cloud Run error rate > 5%
resourceLabels:
  service_name: web-app
logFilter: |
  resource.type="cloud_run_revision"
  severity="ERROR"
metricThreshold:
  comparison: COMPARISON_GT
  thresholdValue: 0.05
  duration: 300s
  aggregations:
    - alignmentPeriod: 60s
      crossSeriesReducer: REDUCE_FRACTION
      perSeriesAligner: ALIGN_COUNT
```

### 4.2 Cloud SQL CPU Alert

```yaml
name: cloud-sql-cpu-high
description: Alert on Cloud SQL CPU > 70%
resourceLabels:
  instance_name: crm-db
metricThreshold:
  comparison: COMPARISON_GT
  thresholdValue: 0.7
  duration: 300s
  aggregations:
    - alignmentPeriod: 60s
      perSeriesAligner: ALIGN_PERCENTILE_99
```

---

## 5) Minimal Runbook: Alert Response

### 5.1 P0 Critical Alerts (Service Down)

**Immediate Actions:**
- [ ] Check Cloud Run status in GCP Console
- [ ] Verify recent deployments (last 15 minutes)
- [ ] Review error logs for recent failures
- [ ] Notify on-call team via Slack/Teams

**Triage Steps:**
1. If deployment within last 15 minutes: Roll back to previous revision
2. If no recent deployment: Check external dependencies (APIs, DB)
3. Verify environment variables and secrets are loaded correctly
4. Check Cloud SQL connectivity

**Escalation:** If unresolved in 15 minutes, escalate to P0 incident response

### 5.2 P1 High Alerts (Degradation)

**Immediate Actions:**
- [ ] Review logs for error patterns
- [ ] Check Cloud Run instance count and health
- [ ] Monitor database connection pool

**Triage Steps:**
1. Identify error spike source (app code, DB, external service)
2. Check for increased traffic (scale event)
3. Review slow query logs if DB-related
4. Verify external API status

**Escalation:** If unresolved in 30 minutes, escalate to P1 incident

### 5.3 P2 Warning Alerts (Performance)

**Immediate Actions:**
- [ ] Monitor metric trends for 10 minutes
- [ ] Review recent code changes

**Triage Steps:**
1. Check if spike is transient (load burst, scheduled job)
2. Review slow queries for optimization opportunities
3. Consider scaling if persistent
4. Document for future optimization

**Escalation:** If trending toward P1 thresholds for > 1 hour, notify team

---

## 6) Common Investigation Commands

### 6.1 Cloud Run Logs (Last 15 Minutes)

```bash
gcloud logging read "resource.type=cloud_run_revision" \
  --format="table(timestamp,severity,jsonPayload.message)" \
  --freshness=15m
```

### 6.2 Cloud SQL Error Logs

```bash
gcloud logging read "resource.type=cloudsql_database severity=ERROR" \
  --format="table(timestamp,jsonPayload.message)" \
  --limit=50
```

### 6.3 Latency Breakdown

```bash
gcloud logging read "resource.type=cloud_run_revision httpRequest.latency" \
  --format="table(timestamp,httpRequest.requestMethod,httpRequest.requestPath,httpRequest.latency)" \
  --limit=100
```

---

## 7) Alert Threshold Tuning

### 7.1 When to Adjust Thresholds

**Reasons to Lower Thresholds (More Sensitive):**
- SLA requirements demand faster detection
- Critical business function
- Historical data shows lower baseline

**Reasons to Raise Thresholds (Less Sensitive):**
- Too many false positives
- Known scheduled high-load periods
- Non-critical service

### 7.2 Threshold Adjustment Process

1. Collect baseline data for 7 days
2. Analyze p95/p99 values
3. Test new thresholds in staging environment
4. Document rationale for change in ADR
5. Monitor alerting frequency for 14 days post-change

---

## 8) Integration with Incident Response

### 8.1 Alert-to-Incident Mapping

| Alert Severity | Incident Severity | Response Time |
|----------------|-------------------|---------------|
| P0 | P0 | Immediate (< 5 min) |
| P1 | P1 | < 15 minutes |
| P2 | P2 | < 30 minutes |

### 8.2 Auto-Triage Triggers

Create incident ticket automatically for:
- P0 alerts
- 3+ P1 alerts within 10 minutes
- Any alert persisting > 1 hour

---

## 9) Maintenance

### 9.1 Daily
- Review alert firing frequency
- Acknowledge and triage active alerts
- Update alert documentation if needed

### 9.2 Weekly
- Review threshold tuning needs
- Check for alert fatigue (false positives)
- Update runbook based on recent incidents

### 9.3 Monthly
- Full review of metric baselines
- Validate alert relevance
- Remove obsolete alerts
- Update documentation

---

## 10) Security Considerations

### 10.1 No Secrets in Logs
- Ensure application code never logs credentials
- Use structured logging with sanitization
- Validate log-based metrics don't expose sensitive data

### 10.2 Alert Notification Security
- Use secure channels (Slack, PagerDuty, etc.)
- Restrict access to sensitive alert details
- Rotate notification channel credentials regularly

---

## 11) Related Documentation

- `docs/ops/incident-response.md`: Full incident response procedures
- `AGENTS.md`: Agent roles and responsibilities
- `docs/ai/decisions/ADR-*.md`: Architecture decisions for monitoring

---

## 12) Quick Reference

### Alert Severity Levels
- **P0:** Service down or critical failure (immediate response)
- **P1:** High degradation or critical errors (15 minutes)
- **P2:** Performance warnings (30 minutes)
- **P3:** Informational (routine review)

### Key Metrics to Monitor
- Cloud Run error rate (target: < 1%)
- Cloud Run p95 latency (target: < 1000ms)
- Cloud SQL CPU (target: < 70%)
- Cloud SQL failed connections (target: 0/min)

### Common Issues & Fixes
| Symptom | Likely Cause | Quick Fix |
|---------|--------------|-----------|
| Error rate spike | Recent deployment | Rollback revision |
| High latency | Slow query | Optimize DB query |
| Connection errors | DB exhausted | Scale Cloud SQL |
| High CPU | Traffic spike | Scale Cloud Run |
