## L3 — Knowledge Layer Rules

- Content Safety Gate: 6-check pipeline (C0–C5) applied to every ingested file; all checks self-hosted for IRDAI data residency
- C1–C5 always run regardless of source; any single failure = hard fail, reject file
- OCR chunks with confidence < 0.6 are rejected; never stored
- No free-text generation to users ever; templates only in Phase 1
- KB chunks stored with versions; status transitions: STAGING → LIVE → DEPRECATED only on next version promotion
- Chunk deduplication scoped per tenant; cross-tenant hash matches are ignored
- SME Approval: clean chunks auto-approved; flagged chunks require human approval before going LIVE
- Version Controller: atomic promotion — all chunks promote together or none; immutable snapshots for IRDAI audit
- TenantFilter mandatory on every Haystack operation (read and write); never bypassed
- KB_MISS threshold: similarity < 0.65 = KB_MISS; escalate to human
- Embedding model version stored per chunk; model swap requires full KB re-embed before swap completes
- Rollback: TENANT_ADMIN approval mandatory; SUPER_ADMIN = break glass only; every rollback audited
