<!-- rules-version: 1.0 -->
## L4 — Learning Loop Rules

- L4 is offline only: never handles live user requests; zero runtime latency impact allowed
- L4 has three motives: (1) Asset Factory — build/improve AI assets; (2) Agentic Assistant — SME tooling; (3) Fine Tuning Pipeline — improve models on outcome data
- Signals read-only from 4 sources: L1 action_log, L3 KB_MISS_log + sme_approval_log, L5 edit_diff_log + approval_log, Outcomes action_outcome_join table
- All signal reads are tenant-scoped; PHI fields never read; only claim_id, tenant_id, metadata
- Phase 1: passive signal capture only — no active model updates, no asset promotion
- Asset types managed: prompt_asset, model_asset, kb_asset, guardrail_asset, workflow_asset — all versioned and tenant-isolated
- Fine-tuning targets: Intent Classifier (Phase 1 data = LOW confidence cases + human corrections), Response Generator, Agentic Planner
- Every asset promotion requires HITL (Human-in-the-Loop) approval — IRDAI mandatory; no automated promotion ever
- Asset Registry versioned and tenant-isolated; Model Gateway consumes registry.yml updates on promotion
- Langfuse self-hosted in Mumbai; captures full trace per LLM call: input, output, latency, cost, model version
- Golden Set: fixed curated evaluation dataset; every asset version must benchmark against Golden Set before promotion
- Drift detection: flag statistical shifts in intent distribution, language patterns, performance; never auto-fix
- Tenant isolation in assets: LoRA adapters per tenant — never share fine-tuned weights across tenants
