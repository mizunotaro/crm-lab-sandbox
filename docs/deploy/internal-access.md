# Internal-Only Access Options

This document outlines options for restricting web application access to internal users only, suitable for the CRM lab sandbox project.

## Context

For the CRM application, we may need to restrict browser access to internal users only (e.g., for staging environments, internal tools, or specific tenant scenarios).

## Options

### Option A: Identity-Aware Proxy (IAP)

**Description:** Google Cloud IAP provides authenticated access to web applications running on Google Cloud, with fine-grained access control through IAM.

**Pros:**
- Strong security: Zero Trust model, requires authentication at the perimeter
- Flexible access control: IAM-based, supports groups, roles, and conditions
- No VPN infrastructure needed: Works over public internet securely
- Audit logging: Built-in Cloud Audit Logs for all access attempts
- Easy integration: Works with Cloud Run, App Engine, GKE, and Compute Engine
- Supports MFA: Enforce 2FA through Identity Platform

**Cons:**
- GCP-specific: Lock-in to Google Cloud ecosystem
- Cost: Additional cost per user/month (pricing model)
- Setup complexity: Requires proper IAM configuration and OAuth consent screen setup
- Learning curve: Team needs to understand IAM and IAP concepts

**Setup Effort:** Medium (2-4 hours initial setup, ongoing maintenance)

**Risk Level:** Low (well-documented, managed service)

---

### Option B: IP Allowlist

**Description:** Restrict access to the application by allowing only specific IP addresses or IP ranges (corporate network, office locations, VPN endpoints).

**Pros:**
- Simple to implement: Basic firewall rules at load balancer or application level
- No additional infrastructure: Uses existing networking components
- No per-user cost: Free (no licensing or per-user fees)
- Predictable: Clear rule set, easy to understand and audit

**Cons:**
- Security concerns: IP-based security is relatively weak (IPs can be spoofed, mobile workers need VPN)
- Maintenance overhead: IP changes require updates (office moves, ISP changes)
- Remote work challenges: All remote users need VPN or static IPs
- Limited granularity: All-or-nothing access, hard to enforce per-user rules
- IP spoofing risk: Not a strong security boundary for sensitive data

**Setup Effort:** Low (1-2 hours initial setup, moderate ongoing maintenance)

**Risk Level:** Medium (weak security boundary, high maintenance overhead)

---

### Option C: VPN / Zero Trust Network Access (ZTNA)

**Description:** Require users to connect through a corporate VPN or Zero Trust solution before accessing the application.

**Pros:**
- Strong security: Network-level isolation, device posture checks (with ZTNA)
- Familiar model: Most enterprises already have VPN infrastructure
- Device-level control: Enforce device compliance, certificates
- Comprehensive: Can secure multiple applications behind one solution
- Audit capability: Detailed logging of connections and sessions

**Cons:**
- User friction: VPN connection adds step to workflow, potential performance impact
- Infrastructure cost: VPN/ZTNA licensing and maintenance
- Client software: Requires installation on all user devices
- Scalability: VPN gateways can become bottlenecks
- Complexity: VPN management, certificate rotation, policy updates

**Setup Effort:** High (depends on existing infrastructure, 1-2 weeks if starting from scratch)

**Risk Level:** Medium to High (depends on implementation quality, user experience impact)

---

## Decision Criteria

When selecting an option, consider:

| Criterion | Weight | Notes |
|-----------|--------|-------|
| Security Strength | High | For sensitive CRM data, prefer IAP or VPN/ZTNA over IP allowlist |
| Setup Effort | Medium | For PoC, prefer faster setup (IP allowlist or IAP) |
| Ongoing Maintenance | Medium | Consider team capacity and operational overhead |
| User Experience | High | Evaluate impact on user productivity and workflow |
| Cost | Medium | Factor in both initial and ongoing costs |
| Scalability | Medium | Consider future growth (users, applications) |
| Integration | Medium | Fit with existing GCP infrastructure and tooling |

---

## Decision Gate (Human Selection Required)

**Question:** Which option should we select for the internal-only access PoC?

**Option A: IAP (Identity-Aware Proxy)**
- **Pros:** Strong security, flexible IAM, no VPN needed, good for GCP-native deployment
- **Cons:** GCP lock-in, per-user cost, medium setup complexity
- **Risk:** Low (managed service)
- **Effort:** Medium (2-4 hours)
- **Rollback:** Remove IAP configuration, re-open to public (if applicable)

**Option B: IP Allowlist**
- **Pros:** Simple implementation, no additional cost, quick setup
- **Cons:** Weak security boundary, high maintenance, poor fit for remote work
- **Risk:** Medium (security limitations)
- **Effort:** Low (1-2 hours)
- **Rollback:** Remove firewall rules or allowlist entries

**Option C: VPN / Zero Trust Network Access**
- **Pros:** Strong security, device-level control, enterprise standard
- **Cons:** High infrastructure cost, user friction, complex setup
- **Risk:** Medium to High (operational complexity)
- **Effort:** High (1-2 weeks if no existing VPN)
- **Rollback:** Disconnect VPN integration, open application access

**Decision Criteria:** For this PoC, optimize for:
- Quick PoC (minimal setup time)
- Minimum exposure (adequate security for testing)
- Alignment with GCP deployment strategy

---

## Recommended Approach for PoC

Given the training scope (PoC on GCP), the recommended order for evaluation:

1. **Start with IP allowlist** for fastest PoC validation (1-2 hours)
2. **Evaluate IAP** as the production-ready GCP-native solution (2-4 hours)
3. **Consider VPN/ZTNA** only if organization already has infrastructure

## Next Steps

Once decision is made:
1. Update this document with the selected option
2. Create implementation plan in `docs/ops/`
3. Add ADR (Architecture Decision Record) in `docs/ai/decisions/`
4. Implement and test access restriction
5. Document operational procedures (how to add/remove users, rotate configurations)
