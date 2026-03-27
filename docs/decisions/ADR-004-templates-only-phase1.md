# ADR-004: Templates Only in Phase 1 (No Free-Text LLM Generation)

**Date:** March 2026
**Status:** Accepted
**Deciders:** Team

---

## Context

Gooclaim uses LLMs (Azure OpenAI via Model Gateway) for intent classification. Question: should LLMs also generate free-text responses to users in Phase 1?

## Decision

**Templates only in Phase 1.** Zero free-text LLM generation to end users.

LLM role in Phase 1 is limited to:
- Intent classification (RW1/RW2/RW3/UNKNOWN) — temperature=0, deterministic

## Reasons

- Zero hallucination requirement — insurance claim information must be 100% accurate
- IRDAI compliance — every message to a user must be traceable to a pre-approved template
- WhatsApp WABA requires pre-approved message templates anyway
- Phase 1 is a pilot — de-risk by eliminating LLM generation surface area
- Operators (TPAs, hospitals) need to trust the system before agentic generation

## Phase Progression

**Phase 2 (AI-Assisted):** LLM suggests response → human agent approves → template sent. Still no direct LLM-to-user.

**Phase 3 (Fully Agentic):** Free-text LLM generation to users. Unlocks only after:
- 3+ months stable Phase 1 operation
- Zero L6 policy incidents
- TPA explicit approval per tenant (opt-in, never forced)
- L6 upgraded to handle semantic safety on free text
- Human oversight layer maintained

## Consequences

- Every user-facing message must have a corresponding template in L3
- Template registry must be maintained and versioned
- L5 Outbound Engine renders templates — never calls LLM for response generation
- If a workflow cannot be handled by a template → escalate to human, never hallucinate
