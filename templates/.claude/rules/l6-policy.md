<!-- rules-version: 1.0 -->
## L6 — Policy Gate Rules

- L6 cannot be bypassed — it is the last line of defense before anything leaves the system
- 4-tier Policy Engine runs in strict order; never skip tiers:
  T1 = deterministic forbidden phrase exact match
  T2 = semantic safety via Guardrails AI (shared Docker container with L3 C4; L6 owns validator config, not container)
  T3 = PHI detection + auto-redaction via Presidio (self-hosted); PHI fields: member name, DOB, Aadhaar, PAN, IFSC, raw phone, amounts
  T4 = source verification — output must be traceable to verified L2/L3 data; unverified source = blocked
- RBAC Middleware enforced on every API request — role + tenant enforcement, no exceptions
- Identity Verifier step-up tiers: Tier 0 (allowlist — sufficient for RW1/RW2/RW3), Tier 1 (last-4 claim match), Tier 2 (OTP to registered phone — required for payment/member info)
- Consent Service: DPDP runtime check per message; consent cache max 5min TTL; mid-session revocation bypasses cache — immediate effect
- PHI Handler: hash at ingestion, redact in logs and outbound; plaintext PHI never stored anywhere
- Audit Service: append-only security events; IRDAI export ready; 7-year retention; BullMQ concurrency=1 for guaranteed ordering
- Guardrails AI + Presidio self-hosted — never call external endpoints; containers shared via Model Gateway
- On any T1–T4 block: send TPL_FALLBACK (sorry-we-will-get-back template), log audit event, alert ops on spikes
- L6 reads from Access Control schemas (roles, permissions, tenant config) — L6 does not redefine or duplicate them
