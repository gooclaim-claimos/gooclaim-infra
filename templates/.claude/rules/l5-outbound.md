<!-- rules-version: 1.0 -->
## L5 — Outbound Engine Rules

- L5 executes what L1 decides — never decides itself; execution only with full audit trail
- Compliance Gate runs in this order before every send: (1) TRAI DND check, (2) quiet hours 09:00–21:00 IST per tenant, (3) consent verification; first failure = block send
- TPL_ACK = acknowledgement template (message received); TPL_FALLBACK = sorry-we-will-get-back template; both Meta-approved
- Operational mode first: SUSPENDED = zero messages sent; RESTRICTED = only TPL_ACK + TPL_FALLBACK allowed
- Template-only outbound Phase 1; no free-text generation ever; only Meta-approved templates sent
- Phone number resolved only inside send function scope via Secrets Vault — if resolution fails = CANCEL intent; never stored or logged after use
- Idempotency: same intent_id processed twice = second silently skipped; Temporal workflow ID = l5-{intent_id}
- Write-back classes: Class 1 (auto-allowed: ticket create, callback schedule, CMS note), Class 2 (human approval required), Class 3 (never auto); Phase 1+2 = write-back fully disabled
- Priority queue: P0 never waits behind P3; intent states: QUEUED → PROCESSING → COMPLETED or EXPIRED (TTL 24h) or CANCELLED (operational mode)
- Delivery tracking fallback chain: WhatsApp → Email → SMS → Human Ticket; move to next only on confirmed delivery failure
- Every send logged as audit event with wamid; DELIVERED/READ/FAILED all tracked
- SW8 (System Workflow 8): Write-back Operational Mode — disables all CMS/CRM writes on anomaly detection; must be Redis-backed
