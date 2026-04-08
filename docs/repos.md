# Gooclaim — Repo Registry
> service-name = GitHub repo name = Docker image name = K8s deployment name
> Naya repo banao → yahan add karo
> Last updated: April 2026 | Total: 20 repos

---

## Group 1 — Foundation (4 repos)

| Repo | Purpose | Status | Sprint |
|------|---------|--------|--------|
| `gooclaim-infra` | CI/CD master, K8s, reusable workflows | ✅ Done | — |
| `gooclaim-shared` | Enums, contracts, ABCs — 93% coverage | ✅ Done | — |
| `gooclaim-docs` | Architecture source of truth | ✅ Done | — |
| `gooclaim-load-tests` | k6 load test scenarios | ✅ Done | — |

## Group 2 — Platform Services (6 repos)

| Repo | service-name in ci.yml | Purpose | Status | Sprint |
|------|----------------------|---------|--------|--------|
| `gooclaim-audit` | gooclaim-audit | Immutable ledger, SHA-256 chain, 82% coverage | ✅ Done | Sprint 1 |
| `gooclaim-auth` | gooclaim-auth | JWT + RBAC + tenant scoping — **MOST URGENT** | ❌ Not started | Sprint 2 |
| `gooclaim-config` | gooclaim-config | Template Registry (channel × language matrix) | ❌ Not started | Sprint 2 |
| `gooclaim-model-gateway` | gooclaim-model-gateway | Azure OAI proxy — architecture designed | ⚙️ Designed | Sprint 3 |
| `gooclaim-connector-hub` | gooclaim-connector-hub | External connectors (CMS + channel) — architecture designed | ⚙️ Designed | Sprint 3 |
| `gooclaim-policy` | gooclaim-policy | L6 Policy Gate — T1+T2+T3+T4, Guardrails AI, PHI | ❌ Not started | Sprint 4 |

## Group 3 — Channel Layer (2 repos)

| Repo | service-name in ci.yml | Purpose | Status | Sprint |
|------|----------------------|---------|--------|--------|
| `gooclaim-gateway` | gooclaim-gateway | L0 — WhatsApp webhook, ~92% coverage | ✅ Done | Sprint 1 |
| `gooclaim-voice` | gooclaim-voice | Voice — Telephony + ASR + TTS (Phase 2) | ❌ Not started | P2 |

## Group 4 — Service Layers (6 repos)

| Repo | Layer | service-name in ci.yml | Purpose | Status | Sprint |
|------|-------|----------------------|---------|--------|--------|
| `gooclaim-engine` | L1 | gooclaim-engine | Workflow Engine — RW1/RW2/RW3 | ❌ Not started | Sprint 5 |
| `gooclaim-truth` | L2 | gooclaim-truth | Truth Layer — CMS connector, fallback chain | ❌ Not started | Sprint 5 |
| `gooclaim-knowledge` | L3 | gooclaim-knowledge | Knowledge Layer — Haystack + pgvector | ❌ Not started | Sprint 5 |
| `gooclaim-learning` | L4 | gooclaim-learning | Learning Loop — passive signals (Phase 1) | ❌ Not started | Sprint 7 |
| `gooclaim-outbound` | L5 | gooclaim-outbound | Outbound Engine — templates + delivery | ❌ Not started | Sprint 6 |
| `gooclaim-observe` | L7 | gooclaim-observe | Observability — Prometheus + Grafana | ❌ Not started | Sprint 7 |

## Group 5 — Products / UIs (2 repos)

| Repo | service-name in ci.yml | Purpose | Status | Sprint |
|------|----------------------|---------|--------|--------|
| `gooclaim-console` | gooclaim-console | Internal Console — audit viewer, KB mgmt, tickets | ❌ Not started | P2 |
| `gooclaim-copilot` | gooclaim-copilot | TPA Agent Copilot — AI assist for escalated cases | ❌ Not started | P2 |

---

## Build Order (Phase 1)

```
Sprint 1 (Done):  gooclaim-shared → gooclaim-infra → gooclaim-gateway → gooclaim-audit
Sprint 2:         gooclaim-auth → gooclaim-config
Sprint 3:         gooclaim-model-gateway → gooclaim-connector-hub
Sprint 4:         gooclaim-policy (L6)
Sprint 5:         gooclaim-engine (L1) → gooclaim-truth (L2) → gooclaim-knowledge (L3)
Sprint 6:         gooclaim-outbound (L5)
Sprint 7:         gooclaim-learning (L4) → gooclaim-observe (L7)

Phase 2:          gooclaim-voice → gooclaim-console → gooclaim-copilot
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
[ ] gooclaim-infra mein se scaffold karo:
    cd gooclaim-infra
    bash scripts/setup-service.sh gooclaim-<service>
[ ] cd ../gooclaim-<service>
[ ] CLAUDE.md mein layer-specific context fill karo
[ ] .env.example se .env banao, values fill karo
[ ] git init && git remote add origin https://github.com/gooclaim-claimos/gooclaim-<service>.git
[ ] git checkout -b main && git add . && git commit -m "chore: initial project setup"
[ ] git push -u origin main
[ ] git checkout -b develop && git push -u origin develop
[ ] Branch protection rules set karo (main + develop)
[ ] 4 environments banao: dev, sdx, nprd, prod
[ ] KUBE_CONFIG + GHCR_TOKEN secrets add karo har environment mein
```

---

## Service Repo Structure

```
gooclaim-{service}/
├── src/
│   └── {service}/
│       ├── __init__.py
│       ├── main.py          ← FastAPI app + /health
│       ├── config.py        ← Pydantic settings (reads .env)
│       ├── routes/          ← API route handlers
│       ├── services/        ← Business logic
│       ├── models/          ← Pydantic request/response models
│       └── connectors/      ← External system connectors
├── migrations/              ← DB migrations (alembic)
├── tests/
│   ├── conftest.py          ← Shared pytest fixtures
│   ├── unit/
│   └── integration/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml
│   │   └── deploy.yml
│   ├── PULL_REQUEST_TEMPLATE/
│   │   └── default.md
│   └── CODEOWNERS
├── .claude/
│   ├── hooks/
│   │   └── check-no-secrets.sh
│   ├── rules/
│   │   └── l{n}-{layer}.md
│   ├── skills/              ← /docs /test /new-adr /session-end
│   └── settings.json
├── badges/
│   └── coverage.svg
├── docs/                    ← Generated via /docs skill
├── Dockerfile
├── docker-compose.yml       ← Local dev (postgres + redis)
├── .dockerignore
├── tox.ini
├── pyproject.toml
├── .gitignore
├── .env.example
├── CLAUDE.md
├── CLAUDE_SESSION.md
└── README.md
```
