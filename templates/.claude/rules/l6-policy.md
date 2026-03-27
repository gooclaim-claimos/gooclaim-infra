## L6 — Policy Gate Rules

- L6 cannot be bypassed — it is the last line of defense before anything leaves the system
- 4-tier Policy Engine runs in order: T1 (forbidden phrases) → T2 (Guardrails AI semantic) → T3 (PHI redaction via Presidio) → T4 (source verification); never skip tiers
- RBAC Middleware enforced on every API request — role + tenant enforcement, no exceptions
- Identity Verifier: Tier 0 (allowlist), Tier 1 (last-4 match), Tier 2 (OTP to registered phone)
- Consent Service: DPDP runtime check; consent cache max 5min TTL; mid-session revocation respected immediately
- PHI Handler: hash at ingestion, redact in logs and outbound; plaintext PHI never stored anywhere
- Audit Service: append-only security events; IRDAI export ready; 7-year retention
- Guardrails AI + Presidio self-hosted (shared Docker containers via Model Gateway) — never call external endpoints
- On any T1–T4 block: send TPL_FALLBACK, log audit event, alert ops on spikes
- L6 reads from Access Control schemas — L6 does not redefine them
