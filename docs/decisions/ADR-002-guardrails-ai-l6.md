# ADR-002: Guardrails AI for L6 Policy Gate (Not NeMo)

**Date:** March 2026
**Status:** Accepted
**Deciders:** Team

---

## Context

L6 Policy Gate must check every LLM output before it reaches end users. Requirements:
- IRDAI compliance — every check must be auditable and deterministic
- Hinglish (HI_EN) support — mixed Hindi-English outputs
- PHI detection and redaction
- Forbidden phrase blocking
- Must work in Phase 1 (templates only) and Phase 3 (agentic free text)

## Decision

Use **Guardrails AI** (semantic rules-based) for L6 instead of NeMo Guardrails.

## Reasons

- Hinglish is non-deterministic in NeMo — IRDAI requires auditable, traceable decisions
- Guardrails AI uses explicit semantic rules — every block/pass decision is traceable
- NeMo requires LLM inference for guardrailing — adds latency + cost + another LLM dependency
- Guardrails AI integrates cleanly with existing Python/FastAPI stack
- Phase 1 uses templates only — NeMo's LLM-based approach is overkill

## Rejected Alternatives

| Option | Why rejected |
|--------|-------------|
| NeMo Guardrails | Hinglish non-deterministic, not IRDAI auditable in Phase 1 |
| Custom ML classifier | Too slow to build, not auditable, needs labeled data we don't have yet |
| Rule-only (regex) | Can't handle semantic policy violations — too brittle for production |

## L6 Gate Architecture (4 Tiers)

Every output passes through all 4 tiers in sequence:

| Tier | Type | What it checks |
|------|------|----------------|
| T1 | Exact match | Forbidden phrases, banned keywords |
| T2 | Semantic | Guardrails AI — policy violations, misleading claims |
| T3 | PHI redaction | Phone, name, claim_id stripped from output |
| T4 | Source check | Output must be traceable to approved template or KB article |

## Consequences

- Guardrails AI cold start ~2s — warm pool in Docker required (see Known Issue I-002)
- **L3 C4 Content Safety Gate shares the same Guardrails AI Docker container** — changes to the container affect both L3 ingestion and L6 output checking
- Every L6 check result must be logged as AuditEvent
- L6 must run on EVERY output — no exceptions, no bypass
- Phase 3: Re-evaluate NeMo when Hinglish training data is sufficient
