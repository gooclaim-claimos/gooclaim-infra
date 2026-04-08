# Gooclaim — Email Directory
> Owner: admin@gooclaim.com
> Version: 1.0 | April 2026
> Infra team manages: AWS SES config, Workspace admin

---

## Active Emails (14)

| Email | Owner / Team | Purpose |
|-------|-------------|---------|
| `admin@gooclaim.com` | Platform Admin | Jira, AWS, Atlassian, GitHub org, GKE, domain registrar |
| `engineering@gooclaim.com` | Dev Team | GitHub notifications, CI alerts, dev tooling |
| `product@gooclaim.com` | CEO / PM | Roadmap, stakeholder comms, investor updates |
| `ops@gooclaim.com` | Operations | L7 monitoring alerts, incident notifications, on-call |
| `security@gooclaim.com` | Infra / Security | AWS Secrets Manager, ESO, TruffleHog alerts, CVE notices |
| `compliance@gooclaim.com` | Legal / IRDAI | IRDAI audit exports, DPDP legal notices, regulatory filings |
| `grievance@gooclaim.com` | Compliance (DPO) | **DPDP Act 2023 — legally required.** Claimant data requests |
| `noreply@gooclaim.com` | System (AWS SES) | Automated emails — audit exports, alerts, notifications |
| `support@gooclaim.com` | TPA Support | Post go-live TPA support, WABA issues, integration help |
| `hello@gooclaim.com` | Public Facing | Website contact, investor inquiries, press |
| `partnerships@gooclaim.com` | TPA BD | MediAssist, Bajaj Finserv, MDIndia — business development |
| `dev@gooclaim.com` | Engineering | Dev environment access, sandbox credentials |
| `test@gooclaim.com` | QA | Test environment access, QA team |
| `uat@gooclaim.com` | Pilot / UAT | All pilot TPAs — UAT access, onboarding |

## Add Later (post-revenue)

| Email | Purpose |
|-------|---------|
| `alerts@gooclaim.com` | L7 observability alert routing (email fallback to Slack) |
| `billing@gooclaim.com` | TPA invoicing, payment confirmations |

---

## DPDP Act Compliance — grievance@gooclaim.com

**Legally mandatory** under Digital Personal Data Protection Act 2023.

Gooclaim as Data Fiduciary must:
- Publish this email publicly at `gooclaim.com/privacy`
- Respond to data principal (claimant) requests: access / correction / erasure / consent withdrawal
- SLA: 72 hours recommended, 30 days max (DPDP mandate)

Monitored by: `compliance@gooclaim.com` team.

---

## AWS SES Setup (infra responsibility)

Region: `ap-south-1` (Mumbai) — IRDAI data residency requirement

```bash
# Verify domain
aws ses verify-domain-identity --domain gooclaim.com

# Verify sender
aws ses verify-email-identity --email-address noreply@gooclaim.com
```

**DNS records required:**

| Type | Name | Value |
|------|------|-------|
| TXT | gooclaim.com | `v=spf1 include:amazonses.com ~all` |
| CNAME | (SES DKIM keys × 3) | From AWS SES console |
| TXT | _dmarc.gooclaim.com | `v=DMARC1; p=quarantine; rua=mailto:admin@gooclaim.com` |

**SES Checklist:**
- [ ] Domain verified in SES (ap-south-1)
- [ ] SPF record added in DNS
- [ ] DKIM CNAME records added (3 records from SES console)
- [ ] DMARC record added
- [ ] `noreply@gooclaim.com` sender verified
- [ ] SES production access requested (out of sandbox — default sandbox = 200 emails/day only)
- [ ] Bounce SNS topic → `ops@gooclaim.com`
- [ ] Complaint SNS topic → `security@gooclaim.com`

---

## Google Workspace Setup

All emails under Google Workspace for gooclaim.com.

| Type | Emails |
|------|--------|
| Individual mailboxes | admin@, product@, security@, compliance@ |
| Google Groups (team aliases) | engineering@, ops@, support@, partnerships@, grievance@ |
| System / AWS SES only | noreply@, dev@, test@, uat@ |
| Public inboxes | hello@ |
