## L4 — Learning Loop Rules

- L4 is offline only: never handles live user requests; zero runtime latency impact allowed
- Signals read-only from source tables — never write to production tables directly
- All signal reads are tenant-scoped; PHI fields never read; only claim_id, tenant_id, metadata
- Phase 1: passive signal capture only — no active model updates, no asset promotion
- Every asset promotion requires HITL (Human-in-the-Loop) approval — IRDAI mandatory; no automated promotion
- Asset Registry versioned and tenant-isolated; Model Gateway consumes registry.yml updates
- Langfuse self-hosted in Mumbai; captures full trace (input, output, latency, cost)
- Golden Set: fixed curated evaluation dataset; every asset version must benchmark before promotion
- Drift detection: flag statistical shifts in intent distribution, language patterns, performance; never auto-fix
