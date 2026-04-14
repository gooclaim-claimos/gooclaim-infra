# Gooclaim — Repo Registry
> service-name = GitHub repo name = Docker image name = K8s deployment name
> Naya repo banao → yahan add karo
> Last updated: April 2026 | Total: 21 repos

---

## Platform Architecture — All 21 Repos

```
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                         GOOCLAIM — AGENTIC CLAIMS OS                                ║
║                              21 Repos · Phase 1                                     ║
╚══════════════════════════════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────────────────────────────┐
│                          GROUP 5 — PRODUCTS / UIs                                   │
│                                                                                     │
│   ┌─────────────────────────────┐     ┌─────────────────────────────┐               │
│   │     gooclaim-console        │     │      gooclaim-copilot        │               │
│   │   Internal Team (Gooclaim)  │     │    TPAs / Insurers           │               │
│   │   Ops · Audit · Templates   │     │    Claims · AI Insights      │               │
│   │        ❌ P2                 │     │         ❌ P2                │               │
│   └─────────────────────────────┘     └─────────────────────────────┘               │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                         │
                    ┌────────────────────┼────────────────────┐
                    ▼                                         ▼
┌───────────────────────────────┐       ┌──────────────────────────────────────────┐
│   GROUP 3 — CHANNEL LAYER     │       │         GROUP 2 — PLATFORM SERVICES      │
│                               │       │                                          │
│  ┌─────────────────────────┐  │       │  ┌──────────────┐  ┌──────────────────┐  │
│  │   gooclaim-gateway  ✅   │  │       │  │ gooclaim-auth│  │  gooclaim-audit  │  │
│  │   L0 · WhatsApp gate    │  │       │  │      ✅       │  │       ✅          │  │
│  │   3 gates · audit wired │  │       │  │ JWT·RBAC·MFA │  │ IRDAI · SHA-256  │  │
│  │   183 tests green       │  │       │  │ 305 tests    │  │ 144 tests        │  │
│  └─────────────────────────┘  │       │  └──────────────┘  └──────────────────┘  │
│                               │       │                                          │
│  ┌─────────────────────────┐  │       │  ┌──────────────────────────────────┐    │
│  │  gooclaim-messaging ✅   │  │       │  │   gooclaim-template-registry ✅  │    │
│  │  WhatsApp driver        │  │       │  │   Templates · Approval workflow  │    │
│  │  BullMQ · delivery      │  │       │  │   Channel×Language matrix        │    │
│  │  tracking               │  │       │  │   103 tests green                │    │
│  └─────────────────────────┘  │       │  └──────────────────────────────────┘    │
│                               │       │                                          │
│  ┌─────────────────────────┐  │       │  ┌──────────────┐  ┌──────────────────┐  │
│  │   gooclaim-voice  ❌    │  │       │  │  gooclaim-   │  │   gooclaim-      │  │
│  │   Voice · ASR · TTS     │  │       │  │  model-      │  │   connector-hub  │  │
│  │   smallest.ai · P2      │  │       │  │  gateway ⚙️  │  │      ⚙️          │  │
│  └─────────────────────────┘  │       │  │  AI proxy    │  │  CMS connectors  │  │
└───────────────────────────────┘       │  │  Spec ready  │  │  Spec ready      │  │
                                        │  └──────────────┘  └──────────────────┘  │
                                        │                                          │
                                        │  ┌──────────────────────────────────┐    │
                                        │  │       gooclaim-policy  ❌         │    │
                                        │  │   L6 · T1+T2+T3+T4               │    │
                                        │  │   Guardrails AI · PHI            │    │
                                        │  └──────────────────────────────────┘    │
                                        └──────────────────────────────────────────┘
                                                          │
                    ┌─────────────────────────────────────┼──────────────────────────┐
                    ▼                    ▼                 ▼               ▼          ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                          GROUP 4 — SERVICE LAYERS (L1–L7)                           │
│                                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │  gooclaim-   │  │  gooclaim-   │  │  gooclaim-   │  │  gooclaim-   │            │
│  │  engine  ❌  │  │  truth   ❌  │  │  knowledge ❌│  │  outbound ❌ │            │
│  │     L1       │  │     L2       │  │     L3       │  │     L5       │            │
│  │  Workflow    │  │  CMS fetch   │  │  KB + RAG    │  │  Template    │            │
│  │  RW1/RW2/RW3 │  │  Fallback   │  │  pgvector    │  │  dispatch    │            │
│  │  Temporal    │  │  chain      │  │  Haystack    │  │  Delivery    │            │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘            │
│                                                                                     │
│  ┌──────────────┐  ┌──────────────┐                                                 │
│  │  gooclaim-   │  │  gooclaim-   │                                                 │
│  │  learning ❌ │  │  observe  ❌ │                                                 │
│  │     L4       │  │     L7       │                                                 │
│  │  Passive     │  │  Prometheus  │                                                 │
│  │  signals     │  │  Grafana     │                                                 │
│  └──────────────┘  └──────────────┘                                                 │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────┐
│                          GROUP 1 — FOUNDATION (always imported)                     │
│                                                                                     │
│  ┌──────────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐    │
│  │ gooclaim-shared  │  │ gooclaim-    │  │ gooclaim-    │  │ gooclaim-        │    │
│  │      ✅           │  │ infra   ✅   │  │ docs    ✅   │  │ load-tests  ✅   │    │
│  │ Enums·Contracts  │  │ CI/CD · K8s  │  │ Architecture │  │ k6 scenarios    │    │
│  │ GooclaimBase-    │  │ Reusable     │  │ source of    │  │ SLA targets     │    │
│  │ Settings         │  │ workflows    │  │ truth        │  │                  │    │
│  └──────────────────┘  └──────────────┘  └──────────────┘  └──────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────────────┘

Legend:  ✅ Done   ⚙️ Designed (build next)   ❌ Not started
```

---

## Group 1 — Foundation (4 repos)

| Repo | Purpose | Status | Sprint |
|------|---------|--------|--------|
| `gooclaim-infra` | CI/CD master, K8s, reusable workflows | ✅ Done | — |
| `gooclaim-shared` | Enums, contracts, ABCs — 93% coverage | ✅ Done | — |
| `gooclaim-docs` | Architecture source of truth | ✅ Done | — |
| `gooclaim-load-tests` | k6 load test scenarios | ✅ Done | — |

## Group 2 — Platform Services (6 repos)

| Repo | service-name | Purpose | Status | Sprint |
|------|-------------|---------|--------|--------|
| `gooclaim-audit` | gooclaim-audit | Immutable ledger, SHA-256 chain — 144 tests green | ✅ Done | Sprint 1 |
| `gooclaim-auth` | gooclaim-auth | JWT + RBAC + MFA + DPDP + break-glass — 305 tests green | ✅ Done | Sprint 2 |
| `gooclaim-template-registry` | gooclaim-template-registry | Templates, approval workflow, channel×language — 103 tests green | ✅ Done | Sprint 2 |
| `gooclaim-model-gateway` | gooclaim-model-gateway | Provider-agnostic AI proxy — spec v4.1 ready | ⚙️ Designed | Sprint 3 |
| `gooclaim-connector-hub` | gooclaim-connector-hub | CMS + channel connectors, fallback chain | ⚙️ Designed | Sprint 3 |
| `gooclaim-policy` | gooclaim-policy | L6 — T1+T2+T3+T4, Guardrails AI, PHI redaction | ❌ Not started | Sprint 4 |

## Group 3 — Channel Layer (3 repos)

| Repo | service-name | Purpose | Status | Sprint |
|------|-------------|---------|--------|--------|
| `gooclaim-gateway` | gooclaim-gateway | L0 — 3-gate inbound, audit wired — 183 tests green | ✅ Done | Sprint 1 |
| `gooclaim-messaging` | gooclaim-messaging | WhatsApp driver — BullMQ, delivery tracking, templates | ✅ Done | Sprint 1 |
| `gooclaim-voice` | gooclaim-voice | Voice — Telephony + ASR + TTS, smallest.ai | ❌ Not started | P2 |

## Group 4 — Service Layers (6 repos)

| Repo | Layer | Purpose | Status | Sprint |
|------|-------|---------|--------|--------|
| `gooclaim-engine` | L1 | Workflow Engine — Claim Status, Pending Docs, Query Reason, Temporal | ❌ Not started | Sprint 5 |
| `gooclaim-truth` | L2 | Truth Layer — CMS fetch, fallback chain (API→Feed→RPA) | ❌ Not started | Sprint 5 |
| `gooclaim-knowledge` | L3 | Knowledge Layer — Haystack + pgvector, 8-stage ingestion | ❌ Not started | Sprint 5 |
| `gooclaim-outbound` | L5 | Outbound Engine — template dispatch, delivery tracking | ❌ Not started | Sprint 6 |
| `gooclaim-learning` | L4 | Learning Loop — passive signal capture (Phase 1) | ❌ Not started | Sprint 7 |
| `gooclaim-observe` | L7 | Observability — Prometheus + Grafana, SLO tracking | ❌ Not started | Sprint 7 |

## Group 5 — Products / UIs (2 repos)

| Repo | service-name | Purpose | Status | Sprint |
|------|-------------|---------|--------|--------|
| `gooclaim-console` | gooclaim-console | Internal Console — Gooclaim team ops, audit, templates, model gateway | ❌ Not started | P2 |
| `gooclaim-copilot` | gooclaim-copilot | TPA/Insurer Copilot — claims, AI insights, templates | ❌ Not started | P2 |

---

## Build Order

```
Sprint 1 (Done)  →  gooclaim-shared · gooclaim-infra · gooclaim-gateway
                    gooclaim-audit · gooclaim-messaging

Sprint 2 (Done)  →  gooclaim-auth · gooclaim-template-registry

Sprint 3 (Next)  →  gooclaim-shared (add model-gateway contracts)
                    → gooclaim-model-gateway
                    → gooclaim-connector-hub

Sprint 4         →  gooclaim-policy (L6)

Sprint 5         →  gooclaim-engine (L1)
                    → gooclaim-truth (L2)
                    → gooclaim-knowledge (L3)

Sprint 6         →  gooclaim-outbound (L5)

Sprint 7         →  gooclaim-learning (L4) · gooclaim-observe (L7)

Phase 2          →  gooclaim-voice
                    → gooclaim-console · gooclaim-copilot
```

---

## Progress

```
Done       ████████████░░░░░░░░░░   9 / 21  (43%)
Designed   ██░░░░░░░░░░░░░░░░░░░░   2 / 21  (10%)
Pending    ░░░░░░░░░░░░░░░░░░░░░░  10 / 21  (47%)
```

---

## New Repo Checklist

```
[ ] GitHub: gooclaim-claimos org → New repo → Private → blank
[ ] docs/repos.md mein add karo (this file)
[ ] gooclaim-shared mein register karo pehle (Register First Rule):
    - New service → ServiceLayer enum
    - New channel → ChannelType enum
    - New workflow → WorkflowID enum
[ ] gooclaim-infra se scaffold karo:
    cd gooclaim-infra && bash scripts/setup-service.sh gooclaim-<service>
[ ] CLAUDE.md mein layer-specific context fill karo
[ ] .env.example se .env banao
[ ] git push to main + develop
[ ] Branch protection: main + develop
[ ] 4 environments: dev, sdx, nprd, prod
[ ] KUBE_CONFIG + GHCR_TOKEN secrets add karo
```

---

## Service Repo Standard Structure

```
gooclaim-{service}/
├── src/gooclaim_{service}/
│   ├── main.py          ← FastAPI app + /health + /ready
│   ├── config.py        ← extends GooclaimBaseSettings
│   ├── routes/
│   ├── services/
│   ├── models/
│   └── connectors/
├── tests/
│   ├── conftest.py      ← env vars set BEFORE imports
│   ├── unit/
│   └── integration/
├── .github/workflows/
│   ├── ci.yml
│   └── deploy.yml
├── Dockerfile           ← GH_PAT ARG for gooclaim-shared
├── docker-compose.yml
├── tox.ini              ← lint · typecheck · test · badges
├── pyproject.toml       ← gooclaim-shared git dep
├── CLAUDE.md
└── CLAUDE_SESSION.md
```
