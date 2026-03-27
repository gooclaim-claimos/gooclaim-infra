## L1 — Workflow Engine Rules

- Operational mode check is Step 0a — before everything else; SUSPENDED = immediate return, zero L2 calls
- Input Safety Check at Step 0a.5 — block prompt injection, jailbreak, social engineering before consent check
- DPDP consent verification is Step 0 — CONSENT_GIVEN required before any workflow proceeds
- LLM intent classifier: temperature=0, max_tokens=10 always; rule-based fallback if timeout > 2s
- Entity extraction via LLM only (handles HI/EN/HI_EN natively); no regex layer
- Verification tiers: Tier 0 (allowlist) sufficient for RW1/RW2/RW3; Tier 1 (last-4 match) for sensitive; Tier 2 (OTP) for payment/member info
- Session state: restore last_claim_id + last_intent; summarize context after 10 turns; language detected per message, never locked
- Every output passes L6 PolicyEngine (T1→T2→T3→T4) before OutboundIntent is produced — never bypass
- Fraud detection: 5+ NOT_FOUND in session = fraud_suspect flag; 10+ messages in 2min = fraud_suspect; block L2 calls when flagged
- Workflows are config-driven via `registry.yml` and `prompt.yml` — no hardcoded intent-to-class mapping
- RW1 + RW3: FastAPI stateless, must complete < 3s
- RW2: Temporal stateful — 24h wait + reminder + upload link cycle
- Every workflow execution emits audit event with workflow_version + template_version
- Phase 1: templates only, deterministic; never generate free text for users
