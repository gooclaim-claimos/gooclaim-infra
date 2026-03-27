# Gooclaim — Architecture & Layer Mapping
> Single source of truth — yahan se sab connect hota hai  
> Internal language (L0-L7) aur GitHub repos dono yahan map hain  
> Version: 1.0 | March 2026

---

## Layer → Repo Mapping

| Layer | Internal Name | GitHub Repo | Kya karta hai | Phase |
|-------|--------------|-------------|---------------|-------|
| L0 | Channel Gateway | `gooclaim-gateway` | WhatsApp webhook receive, lang detect, normalize → InteractionEvent | P1 |
| L1 | Workflow Engine | `gooclaim-engine` | Intent classify, RW1/RW2/RW3 execute, OutboundIntent produce | P1 |
| L2 | Truth Layer | `gooclaim-truth` | CMS connector, claim data fetch, circuit breaker | P1 |
| L3 | Knowledge Layer | `gooclaim-knowledge` | RAG, KB ingestion, Haystack, pgvector | P1 |
| L4 | Learning Loop | `gooclaim-learning` | Passive signal capture, SME feedback (P1 read-only) | P1 |
| L5 | Outbound Engine | `gooclaim-outbound` | WhatsApp templates send, retry, delivery track | P1 |
| L6 | Policy Gate | `gooclaim-policy` | Guardrails AI, PHI handler, RBAC, consent (DPDP) | P1 |
| L7 | Observability | `gooclaim-observe` | Metrics, alerting, tracing, dashboards | P1 |
| — | Audit Ledger | `gooclaim-audit` | BullMQ event queues, 7yr regulatory retention | P1 |
| — | Shared | `gooclaim-shared` | Types, utils, proto contracts — sab use karte hain | P1 |
| — | Infra | `gooclaim-infra` | CI/CD master, K8s, Terraform, Helm | P1 |
| Voice | Voice Gateway | `gooclaim-voice` | Exotel/Twilio, ASR, TTS (Phase 2) | P2 |
| — | Secrets Vault | `gooclaim-vault` | AWS SM wrapper, ESO, rotation | P2 |
| — | Access Control | `gooclaim-access` | RBAC schema, JWT, MFA | P2 |
| — | Console UI | `gooclaim-console` | Internal god-view dashboard | P2 |
| — | TPA Portal | `gooclaim-portal` | Tenant-isolated TPA/Insurer UI | P2 |

---

## Data Flow — Request Journey

```
User (WhatsApp)
      │
      ▼
┌─────────────┐
│  L0 GATEWAY │  gooclaim-gateway
│             │  • Webhook receive
│             │  • Lang detect (HI/EN/HI_EN)
│             │  • Normalize → InteractionEvent
└──────┬──────┘
       │ InteractionEvent
       ▼
┌─────────────┐
│  L6 POLICY  │  gooclaim-policy  ← RUNS FIRST, every request
│   GATE      │  • Operational Mode check
│             │  • Identity verify (OTP Tier 0/1/2)
│             │  • Consent check (DPDP)
│             │  • T1 keyword → T2 Guardrails AI → T3 PHI → T4
└──────┬──────┘
       │ Cleared request
       ▼
┌─────────────┐
│  L1 ENGINE  │  gooclaim-engine
│             │  • LLM classify intent (Azure OAI via Model Gateway)
│             │  • Route → RW1 / RW2 / RW3 / UNKNOWN
│             │  • Execute workflow
└──────┬──────┘
       │ Workflow needs data
       ├──────────────────────┐
       ▼                      ▼
┌─────────────┐      ┌─────────────────┐
│  L2 TRUTH   │      │  L3 KNOWLEDGE   │
│  gooclaim-  │      │  gooclaim-      │
│  truth      │      │  knowledge      │
│             │      │                 │
│ CMS fetch   │      │ KB / RAG lookup │
│ claim data  │      │ query reason    │
│ read-only   │      │ Haystack search │
└──────┬──────┘      └────────┬────────┘
       │                      │
       └──────────┬───────────┘
                  │ Data ready
                  ▼
┌─────────────┐
│  L1 ENGINE  │  gooclaim-engine
│  (back)     │  • Render template
│             │  • Produce OutboundIntent
└──────┬──────┘
       │ OutboundIntent
       ▼
┌─────────────┐
│  L5 OUTBOUND│  gooclaim-outbound
│             │  • WhatsApp template send
│             │  • Retry on failure
│             │  • Delivery tracking
└──────┬──────┘
       │ Response delivered
       ▼
User (WhatsApp)

─────────────────────────────────────────
Cross-cutting — parallel to every request:

gooclaim-audit   ← Every decision → audit event (BullMQ)
gooclaim-observe ← Metrics, traces, alerts
gooclaim-shared  ← Types/utils imported by all layers
```

---

## Workflows — L1 ke teen flows

| Workflow | ID | Type | L2 needed | L3 needed | SLA |
|----------|-----|------|-----------|-----------|-----|
| Claim Status | RW1 | FastAPI stateless | ✅ Yes | ❌ No | < 3s |
| Pending Docs | RW2 | Temporal stateful | ✅ Yes | ❌ No | 24h cycle |
| Query Reason | RW3 | FastAPI stateless | ✅ Yes | ✅ Yes | < 3s |

---

## Inter-Service Communication

| From | To | Method | Event/Contract |
|------|----|--------|----------------|
| L0 → L1 | gooclaim-gateway → gooclaim-engine | FastAPI HTTP | `InteractionEvent` |
| L1 → L2 | gooclaim-engine → gooclaim-truth | FastAPI HTTP | `ClaimRequest` |
| L1 → L3 | gooclaim-engine → gooclaim-knowledge | FastAPI HTTP | `KBQuery` |
| L1 → L5 | gooclaim-engine → gooclaim-outbound | BullMQ Queue | `OutboundIntent` |
| All → Audit | All layers → gooclaim-audit | BullMQ Queue | `AuditEvent` |
| All → Observe | All layers → gooclaim-observe | OpenTelemetry | Traces + metrics |

All contracts defined in: `gooclaim-shared/src/contracts/`

---

## Environment Mapping

| Env | Purpose | Trigger | K8s Namespace |
|-----|---------|---------|---------------|
| dev | Daily development | Auto on develop merge | gooclaim-dev |
| sdx | Shared sandbox testing | Manual dispatch | gooclaim-sdx |
| nprd | Pre-pilot verification | Auto on main merge | gooclaim-nprd |
| prod | Live TPA pilot | Manual + approval | gooclaim-prod |

---

## Phase 1 Scope — Kya hai, kya nahi

### Phase 1 mein hai
- Channel: WhatsApp WABA only
- Workflows: RW1, RW2, RW3
- Languages: HI, EN, HI_EN
- L2: Read-only (no write-back)
- L4: Passive signal capture only
- L6: Basic Guardrails AI (T1+T2+T3+T4)
- Output: Templates only — no free-text LLM generation
- TPA: One pilot TPA

### Phase 1 mein nahi hai
- Voice Gateway (L0 voice path)
- SMS channel
- Agentic workflows
- CRM connector (L2)
- Multi-language (Phase 3: TA, TE, BN, MR...)
- TPA Portal UI
- NeMo Guardrails (Phase 3)
- Write-back to CMS

---

## Glossary — Dono Languages

| Internal Term | GitHub / External Term | Meaning |
|---------------|----------------------|---------|
| L0 | gateway | Channel entry point |
| L1 | engine | Workflow orchestrator |
| L2 | truth | Data layer (CMS) |
| L3 | knowledge | KB / RAG layer |
| L4 | learning | Feedback loop |
| L5 | outbound | Message sender |
| L6 | policy | Safety + compliance gate |
| L7 | observe | Observability |
| InteractionEvent | — | L0 → L1 contract |
| OutboundIntent | — | L1 → L5 contract |
| RW1 | claim-status | Workflow 1 |
| RW2 | pending-docs | Workflow 2 |
| RW3 | query-reason | Workflow 3 |
| HI_EN | hinglish | Default language |
