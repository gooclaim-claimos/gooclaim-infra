<!-- rules-version: 1.0 -->
## L1 — Workflow Engine Rules

- Operational mode check is Step 0a — before everything else; SUSPENDED = immediate return, zero L2 calls
- Input Safety Check is before consent — block prompt injection, jailbreak, social engineering at entry; uses Azure Content Safety + Guardrails AI
- DPDP consent verification is Step 0 — CONSENT_GIVEN required before any workflow proceeds
- Consent re-check on session expiry: session TTL = 30min; expired session = new consent check; consent cache TTL = 5min (independent of session TTL)
- LLM intent classifier: temperature=0, max_tokens=10 always; rule-based fallback if LLM times out
- Entity extraction via LLM only (handles HI/EN/HI_EN natively); no regex layer
- Language detection per message — never lock session language; HI→EN→HI_EN mid-session all valid
- Verification tiers: Tier 0 (allowlist) sufficient for RW1/RW2/RW3; Tier 1 (last-4 match) for sensitive; Tier 2 (OTP) for payment/member info
- Session state: restore last_claim_id + last_intent; summarize context after 10 turns to prevent LLM context overflow
- Duplicate message dedup: content-hash dedup with 30s window at L1 (separate from L0 wa_message_id dedup — catches user double-tap)
- Every output passes L6 PolicyEngine (T1→T2→T3→T4) before OutboundIntent is produced — never bypass
- Fraud detection: 5+ NOT_FOUND in session = fraud_suspect flag; 10+ messages in 2min = fraud_suspect; block L2 calls when flagged
- Workflows config-driven via `registry.yml` (workflow execution) + `prompt.yml` (intent classification) — no hardcoded intent-to-class mapping; both git versioned
- RW1 + RW3: FastAPI stateless, must complete < 3s
- RW2: Temporal stateful — 24h wait + reminder + upload link cycle
- Every workflow execution emits audit event with workflow_version + template_version
- Phase 1: templates only, deterministic; never generate free text for users
