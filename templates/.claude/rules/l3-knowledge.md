<!-- rules-version: 1.0 -->
## L3 — Knowledge Layer Rules

- Content Safety Gate: 8-stage ingestion pipeline applied to every file; all stages self-hosted for IRDAI data residency
- 8-stage pipeline order (never skip): C0 Source Auth → C1 Duplicate → C1.5 Format → C2 Malware (ClamAV) → C3 Integrity → C4 Semantic (Guardrails AI, shared container with L6) → C5 PHI (Presidio) → Index (Haystack → pgvector)
- Any single stage failure = hard reject; file never reaches next stage
- OCR chunks with confidence < 0.6 are rejected by Confidence Filter; never stored
- LoaderRegistry is YAML-driven — mime_type → ILoader class mapping via `config/ingestion/loader_registry.yml`; add new file types here
- No free-text generation to users ever; templates only in Phase 1
- Template Registry: pre-approved templates, version controlled, **channel-aware** — each template has variants per channel (WhatsApp HSM / Voice TTS / SMS / Web JSON) × language (HI/EN/HI_EN)
- Never design templates as WhatsApp-only — template structure must support all current and future channels from day 1
- KB chunks stored with versions; status transitions: STAGING → LIVE → DEPRECATED only on next version promotion
- Chunk deduplication scoped per tenant; cross-tenant hash matches are ignored
- SME Approval: clean chunks auto-approved; flagged chunks require human approval before going LIVE
- Version Controller: atomic promotion — all chunks promote together or none; immutable snapshots for IRDAI audit
- TenantFilter mandatory on every Haystack operation (read and write); never bypassed
- KB_MISS threshold: similarity < 0.65 = KB_MISS; escalate to human + emit KB_MISS signal to L4 for retraining
- Embedding model version stored per chunk; model swap requires full KB re-embed before swap completes
- Rollback: TENANT_ADMIN approval mandatory; SUPER_ADMIN = break glass only; every rollback audited; pending SME approvals cleared on rollback
- C4 Guardrails AI container shared with L6 — L3 uses it for ingestion safety, L6 uses it for output safety; coordinate deployments
