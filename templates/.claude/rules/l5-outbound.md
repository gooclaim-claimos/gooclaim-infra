## L5 — Outbound Engine Rules

- L5 executes what L1 decides — never decides itself; execution only with full audit trail
- Compliance Gate mandatory before every send: TRAI DND check, quiet hours (09:00–21:00 IST), consent verification
- Operational mode first: SUSPENDED = zero messages sent; RESTRICTED = only TPL_ACK + TPL_FALLBACK
- Template-only outbound Phase 1; no free-text generation ever; only Meta-approved templates sent
- Phone number resolved only inside the send function scope — never stored, never logged after use
- Idempotency: same intent_id processed twice = second is silently skipped; Temporal workflow ID = l5-{intent_id}
- Write-back disabled (Mode 1) in Phase 1; class 1 auto-allowed in Phase 3 only with operational mode check
- Priority queue: P0 never waits behind P3; intent TTL 24hrs → ABANDONED + logged if expired
- Delivery tracking: receipts, retries, fallback chain — WhatsApp → Email → SMS → Ticket
- Every send logged as audit event with wamid; DELIVERED/READ/FAILED all tracked
