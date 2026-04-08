# Gooclaim — Architecture & Layer Mapping
> Single source of truth — yahan se sab connect hota hai  
> Internal language (L0-L7) aur GitHub repos dono yahan map hain  
> Version: 1.1 | Updated: April 2026 (20 repos finalized)

---

## Complete Repo Map (20 repos)

### Foundation (4)
| Repo | Kya karta hai | Status |
|------|---------------|--------|
| `gooclaim-infra` | CI/CD master, K8s, reusable workflows | ✅ Done |
| `gooclaim-shared` | Enums, contracts, ABCs — 93% coverage | ✅ Done |
| `gooclaim-docs` | Architecture source of truth | ✅ Done |
| `gooclaim-load-tests` | k6 load test scenarios | ✅ Done |

### Platform Services (6)
| Repo | Kya karta hai | Status |
|------|---------------|--------|
| `gooclaim-audit` | Immutable ledger, SHA-256 chain, 82% coverage | ✅ Done |
| `gooclaim-auth` | JWT + RBAC + tenant scoping — **MOST URGENT** | ❌ Sprint 2 |
| `gooclaim-config` | Template Registry (channel × language matrix) | ❌ Sprint 2 |
| `gooclaim-model-gateway` | Azure OAI proxy — /complete /embed /moderate | ⚙️ Sprint 3 |
| `gooclaim-connector-hub` | CMS + channel connectors, fallback chain | ⚙️ Sprint 3 |
| `gooclaim-policy` | L6 — T1+T2+T3+T4, Guardrails AI, PHI, RBAC | ❌ Sprint 4 |

### Channel Layer (2)
| Layer | Repo | Kya karta hai | Status |
|-------|------|---------------|--------|
| L0 messaging | `gooclaim-gateway` | WhatsApp webhook, ~92% coverage | ✅ Done |
| L0 voice | `gooclaim-voice` | Telephony + ASR + TTS (Bajaj Finserv P2) | ❌ P2 |

### Service Layers (6)
| Layer | Repo | Kya karta hai | Status |
|-------|------|---------------|--------|
| L1 | `gooclaim-engine` | RW1/RW2/RW3 workflows | ❌ Sprint 5 |
| L2 | `gooclaim-truth` | CMS data fetch, fallback chain | ❌ Sprint 5 |
| L3 | `gooclaim-knowledge` | Haystack + pgvector, KB ingestion | ❌ Sprint 5 |
| L4 | `gooclaim-learning` | Passive signal capture (P1 read-only) | ❌ Sprint 7 |
| L5 | `gooclaim-outbound` | Template send, TRAI DND, delivery tracking | ❌ Sprint 6 |
| L7 | `gooclaim-observe` | Prometheus + Grafana, SLOs | ❌ Sprint 7 |

### Products / UIs (2)
| Repo | Kya karta hai | Status |
|------|---------------|--------|
| `gooclaim-console` | Internal console — audit viewer, KB mgmt, tickets | ❌ P2 |
| `gooclaim-copilot` | TPA Agent Copilot — AI assist for escalated cases | ❌ P2 |

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
| L0 → L1 | gooclaim-gateway → gooclaim-engine | BullMQ Queue | `InteractionEvent` |
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

## gooclaim-shared — What Lives Here

**Rule:** Agar koi cheez 2+ services use karti hai → `gooclaim-shared`. 1 service use kare → us service ka repo.

| Module | Path | Kya hai |
|--------|------|---------|
| Proto contracts | `proto/` | `InteractionEvent`, `OutboundIntent`, `AuditEvent` — `.proto` files |
| Generated stubs | `generated/` | Auto-generated Python gRPC classes — never edit manually |
| Python contracts | `contracts/` | Pydantic dataclasses matching proto contracts |
| Enums | `enums/` | `Language` (HI/EN/HI_EN), `TemplateID` (TPL_*), `WorkflowID` (RW1/RW2/RW3), `OperationalMode` (OPERATIONAL/RESTRICTED/SUSPENDED), `ErrorCode` (6 codes) |
| Tenant middleware | `middleware/tenant_context.py` | `TenantIsolationMiddleware` — request-level tenant scoping, same pattern across all services |
| OpenTelemetry | `observability/tracer.py` | Shared tracer factory — one setup, all services import |
| Structured logger | `logging/logger.py` | Logger with `trace_id` + `tenant_id` on every log line |
| Alembic base | `db/base.py` | Shared `Base` model + migration config |
| Graceful shutdown | `shutdown/graceful.py` | Shared shutdown utility — SIGTERM handler |
| Base exceptions | `exceptions/base.py` | `GooclaimBaseError`, `TenantError` etc. |
| PHI hasher | `phi/hasher.py` | `hash_phone(phone, tenant_salt)` — SHA-256 + tenant-scoped salt. One implementation, used by L0/L2/L5/L6 |
| Base config | `config/base.py` | `GooclaimBaseSettings` (Pydantic) — `env`, `tenant_id`, `redis_url`, `database_url`, `otel_endpoint`. Each service extends this. |
| Retry decorator | `retry/decorator.py` | `@retry(max_attempts=3, backoff="exponential", jitter=True)` — used by L1/L2/L5 |

**What does NOT go in gooclaim-shared:**
- `ICMSConnector`, `IHMSConnector`, `ICRMConnector` ABCs → `gooclaim-truth` (only L2 uses them)
- Business logic of any layer → that layer's repo
- Service-specific config → that service's `config.py`

---

## Planned — Load Testing (Post L0+L1 integration)

> **Not in Phase 1 pilot.** Add when L0 + L1 both deployed and connected.

**Tool:** [Locust](https://locust.io/) — Python-based, fits our stack

**Plan:**
- Dedicated `gooclaim-load-tests` repo — sab layers ek jagah
- `_reusable-load-test.yml` gooclaim-infra mein — jaise `_reusable-ci.yml`

**Per-layer scenarios:**
| Layer | What to test | SLA target |
|-------|-------------|-----------|
| L0 | WhatsApp webhook burst, rate limiter | < 200ms P95 |
| L1 | Workflow decisions, LLM classifier latency | < 500ms P95 |
| L2 | CMS connector, circuit breaker failover | Failover < 100ms |
| L3 | KB/RAG query under concurrent load | < 1s P95 |
| L5 | Outbound send throughput, Meta API rate limits | < 1s P95 |
| L6 | Policy gate T1→T4 pipeline throughput | < 200ms P95 |
| Full | L0→L1→L2→L5 end-to-end | < 3s |

**Trigger:** Pre-production deploy se pehle — nprd pe baseline set karo

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
