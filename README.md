# gooclaim-infra

> Central infrastructure repository for [Gooclaim](https://github.com/gooclaim-claimos) — AI-Powered Insurance Claims OS for India.
>
> CI/CD pipelines, service scaffolding, architecture docs, runbooks, and shared tooling for all **22 Gooclaim repos** — pre-pilot v0.x at various polish levels. See [`VERSIONS.md`](VERSIONS.md) for per-repo status.

[![License](https://img.shields.io/badge/license-private-red)](.)
[![Python](https://img.shields.io/badge/python-3.12-blue)](https://www.python.org/)
[![Node](https://img.shields.io/badge/node-20-green)](https://nodejs.org/)

---

## Table of Contents

1. [What This Repo Provides](#what-this-repo-provides)
2. [Platform Architecture](#platform-architecture)
3. [Repository Structure](#repository-structure)
4. [Cloud Infrastructure (Terraform)](#cloud-infrastructure-terraform)
5. [Reusable CI/CD Workflows](#reusable-cicd-workflows)
6. [Service Scaffolding](#service-scaffolding)
7. [Environment Ladder](#environment-ladder)
8. [Repo Registry (22 Repos)](#repo-registry-22-repos)
9. [3-UI Architecture](#3-ui-architecture)
10. [Architecture Decisions](#architecture-decisions)
11. [Key Invariants](#key-invariants)
12. [Runbooks](#runbooks)
13. [Postman Collections](#postman-collections)
14. [Local Development](#local-development)
15. [Required Secrets](#required-secrets)
16. [Contributing](#contributing)
17. [Getting Help](#getting-help)

---

## What This Repo Provides

Gooclaim is a **polyrepo platform** — each of the 22 microservices lives in its own repository (`gooclaim-gateway`, `gooclaim-engine`, `gooclaim-knowledge`, etc.). `gooclaim-infra` is **not** a monorepo; it's the central support repo that every service depends on.

It provides three kinds of shared infrastructure:

- **Reusable CI/CD workflows** — every service's `.github/workflows/ci.yml` is a 15-line file that `workflow_call`s into this repo's `_reusable-ci.yml` and `_reusable-deploy.yml`. Change CI behaviour once, every service picks it up.
- **Service scaffolding** — `scripts/setup-service.sh` generates a new service repo with the correct folder layout, Dockerfile, `pyproject.toml`, `tox.ini`, `.claude/` rules for the right layer, and boilerplate CI wiring. One command → ready-to-push service repo.
- **Platform documentation + policy** — architecture diagrams, repo registry, ADRs, runbooks (deploy / rollback / incident response), environment table, Claude Code rules (`.claude/rules/`), and the canonical `CLAUDE.md` that all service repos inherit from.

No service code lives here. Every commit affects downstream repos — treat it with care.

---

## Platform Architecture

```
                            USERS & CHANNELS
  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
  │  Claimants / │  │ TPA Admins   │  │ TPA Ops /    │  │ Gooclaim     │
  │  Hospitals   │  │              │  │ Analysts     │  │ Internal Ops │
  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
         │ WhatsApp        │ Tenant admin    │ AI copilot      │ Admin UI
         ▼                 ▼                 ▼                 ▼
  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
  │  Messaging   │  │  gooclaim-   │  │  gooclaim-   │  │  gooclaim-   │
  │  Channels    │  │  portal  ✅  │  │  copilot ✅  │  │  console ✅  │
  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
         │                 └─────────┬───────┴─────────────────┘
         │                           │ REST + JWT
         │                           ▼
         │               ┌──────────────────────┐
         │               │  gooclaim-auth ✅    │
         │               │  /auth/login + MFA   │
         │               │  /auth/introspect    │
         │               └──────────────────────┘
         ▼
  ┌────────────────────────────────────────────────────────────────────┐
  │  CHANNEL ADAPTER LAYER                                             │
  │  gooclaim-whatsapp ✅   [voice / sms / email / slack — v2.0]       │
  │  Pure I/O: webhook → normalise → InteractionEvent → BullMQ         │
  └──────────────────────────────┬─────────────────────────────────────┘
                                 ▼
  ┌────────────────────────────────────────────────────────────────────┐
  │  gooclaim-gateway ✅  (L0) — 3-gate filter                         │
  │  Gate 1: Content  |  Gate 2: Identity  |  Gate 3: Tenant           │
  │  Channel-agnostic — InteractionEvent regardless of source          │
  └──────────────────────────────┬─────────────────────────────────────┘
                                 │ BullMQ
                                 ▼
  ┌────────────────────────────────────────────────────────────────────┐
  │  gooclaim-engine ✅ (L1) — Workflow Engine / Agentic Orchestrator  │
  │  RW1 (claim-status) · RW2 (pending-docs, Temporal) · RW3 (query)   │
  │  Consent Gate (DPDP) Step 0 · Templates-only outbound (v1.0)       │
  └─────┬───────┬─────────┬──────────┬────────────┬─────────────────────┘
        ▼       ▼         ▼          ▼            ▼
   ┌────────┐ ┌──────────┐ ┌────────┐ ┌──────────┐ ┌──────────────┐
   │truth ✅│ │knowledge │ │learning│ │outbound  │ │observe (L7)  │
   │(L2)    │ │(L3) ✅   │ │(L4) 📋 │ │(L5) ✅   │ │✅            │
   └────────┘ └──────────┘ └────────┘ └────┬─────┘ └──────────────┘
                                           │ POST /send
   ┌────────────────────────┐               ▼
   │  gooclaim-policy ✅    │       Channel adapters (whatsapp, etc.)
   │  (L6) T1+T2+T3+T4      │
   │  Guardrails AI · PHI   │
   │  PASS→L5  BLOCK→Audit  │
   └────────────────────────┘

                          PLATFORM LAYER
  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────────┐
  │ gooclaim-audit ✅│  │ gooclaim-model-  │  │ gooclaim-connector-  │
  │ Immutable ledger │  │ gateway ✅       │  │ hub ✅               │
  │ IRDAI · 7yr      │  │ AI proxy · VK    │  │ REST → SFTP → RPA    │
  └──────────────────┘  │ Azure + Sarvam   │  │ Per-tenant CB        │
                        └──────────────────┘  └──────────────────────┘

  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────────┐
  │ gooclaim-auth ✅ │  │ gooclaim-        │  │ gooclaim-tenant-     │
  │ JWT · MFA · RBAC │  │ template-        │  │ config ✅            │
  │ Connector creds  │  │ registry ✅      │  │ tenant_id + op_mode  │
  │ (encrypted)      │  │ channel × lang   │  │ workflow config      │
  └──────────────────┘  │ DRAFT→PEND→APPR  │  │ (REST + gRPC :50051) │
                        └──────────────────┘  └──────────────────────┘

  ┌────────────────────────────────────────────────────────────────────┐
  │  gooclaim-shared ✅ — Register First Rule                          │
  │  ServiceLayer · WorkflowID · ChannelType · InteractionEvent ·      │
  │  OutboundIntent · AuditEventType · KBQuery · ModelAlias · Language │
  └────────────────────────────────────────────────────────────────────┘
```

**v1.0 build status (pre-pilot):**
All v1.0 layers code-complete: `truth ✅` · `engine ✅` · `knowledge ✅` · `outbound ✅` · `observe ✅` · `policy ✅` · `gateway ✅` · `whatsapp ✅`. Plus all platform services (`auth`, `audit`, `model-gateway`, `template-registry`, `tenant-config`, `connector-hub`) and 5 frontends. Pending: cloud deploy + load testing + pilot tenant onboarding (see [`tasks/PILOT_LAUNCH_CHECKLIST.md`](tasks/PILOT_LAUNCH_CHECKLIST.md)).

**v2.0 (post-pilot):** `learning` active mode (per-tenant brain) · `voice` channel · `sms` / `email` / `slack` channels · workflow-studio TPA self-service.

---

## Repository Structure

```
gooclaim-infra/
├── .github/
│   ├── CODEOWNERS
│   ├── PULL_REQUEST_TEMPLATE/default.md
│   └── workflows/
│       ├── _reusable-ci.yml          # called by every service's ci.yml
│       └── _reusable-deploy.yml      # called by every service's deploy.yml
├── .claude/                          # Claude Code config inherited by service repos
│   ├── commands/                     # Global slash commands (/docs, /test, /new-adr, /session-end)
│   ├── hooks/                        # check-no-secrets.sh and other pre-push checks
│   ├── rules/                        # Code-review, refactor, release rules
│   ├── skills/                       # Claude skills
│   └── settings.json
├── templates/                        # Scaffold for new service repos
│   ├── .claude/rules/l0-*.md … l7-*.md   # Layer-specific rules
│   ├── .github/workflows/{ci,deploy}.yml # Caller workflows (thin — 15 lines each)
│   ├── CLAUDE.md                     # Per-service project memory template
│   ├── Dockerfile                    # Digest-pinned base image
│   ├── pyproject.toml                # Python project scaffold
│   └── tox.ini                       # lint / typecheck / test / security envs
├── scripts/
│   ├── setup-service.sh              # Scaffold a new service repo
│   ├── sync-rules.sh                 # Propagate .claude/rules/ updates across repos
│   └── deploy.sh                     # Manual deploy helper
├── docs/
│   ├── architecture.md               # Layer → repo mapping, data flows, module map
│   ├── repos.md                      # Repo registry (22 services, v1.0 / v2.0 split)
│   ├── email-directory.md            # Platform email addresses + purpose
│   ├── github-guide.md               # Branch protection, secret management
│   ├── decisions/                    # Platform-wide ADRs (001-005)
│   ├── runbooks/                     # deploy.md, rollback.md, incident-response.md
│   └── service-readme-template.md    # README template for new service repos
├── postman/                          # API collections + environments per service
├── terraform/                        # IaC for Azure deploys — see Cloud Infrastructure section
│   ├── modules/                      # Reusable per-resource modules (aks, keyvault, postgres, ...)
│   └── environments/                 # Per-env compositions (dev / nprd / prod)
├── CLAUDE.md                         # Root project memory (every service inherits)
├── CLAUDE_SESSION.md                 # Session log (architectural decisions + handoff notes)
├── CONTRIBUTING.md                   # Branch strategy, commit conventions, PR rules
└── README.md                         # This file
```

---

## Cloud Infrastructure (Terraform)

`terraform/` provisions the Azure infrastructure for each environment. Region is **locked to `centralindia`** (Mumbai) per DPDP §16 data residency mandate — no resource may be created in any other region.

State lives in an Azure Storage backend (AAD-auth gated, blob versioning enabled, 90-day soft-delete). Live `terraform.tfvars`, plan files (`*.tfplan`), state files (`*.tfstate`), and any exported secret snapshots are gitignored — only `*.tfvars.example` templates and `.terraform.lock.hcl` are tracked.

### Directory layout

```
terraform/
├── modules/                     # Reusable resource modules — parameterised by var.environment
│   ├── aks/                     # AKS cluster + Log Analytics (Workload Identity + OIDC issuer enabled)
│   ├── keyvault/                # Key Vault (RBAC auth model, 90d soft-delete)
│   ├── postgres/                # PG 16 Flexible Server (AAD admin + password admin)
│   ├── redis/                   # Azure Cache for Redis (TLS 1.2, non-SSL disabled)
│   ├── storage/                 # Storage Account (StorageV2, blob versioning + soft-delete)
│   └── workload-identity/       # User-Assigned MI + federated cred for K8s ServiceAccounts (ESO + per-service)
└── environments/
    ├── dev/                     # Composition for dev — cheapest SKUs, public access enabled with firewall allowlist
    │   ├── backend.tf           # State backend config
    │   ├── main.tf              # Wires modules + outputs
    │   ├── variables.tf
    │   └── terraform.tfvars.example
    ├── nprd/                    # (Day 6+) Larger SKUs, soak environment
    └── prod/                    # (Week 9+) HA + private endpoints + GRS
```

### SKU progression by environment

| Resource | dev | nprd | prod |
|---|---|---|---|
| AKS control plane | Free | Free | Standard (Uptime SLA) |
| AKS nodes | 2× `Standard_D2s_v3` (autoscale 2-4) | 2× `Standard_D2s_v3` | 3× `Standard_D4s_v3` (autoscale 3-10) |
| Postgres | `B_Standard_B1ms` (1 vCPU / 2GB / 32GB storage) | `GP_Standard_D2ds_v5` | `GP_Standard_D4ds_v5` + Zone-Redundant HA |
| Redis | Basic C0 (250 MB) | Standard C1 (1 GB) | Premium P1 (6 GB, persistence on) |
| Storage replication | LRS | LRS | GRS |
| Key Vault SKU | Standard | Standard | Premium (HSM-backed) |
| Network posture | Public access + firewall allowlist | Private endpoint + VNet integration | Private endpoint + VNet integration |

### Usage

```bash
cd terraform/environments/<env>
terraform init                  # First-time setup — wires state backend
terraform plan -out=<env>.tfplan
terraform apply <env>.tfplan
```

For `dev`, copy `terraform.tfvars.example` → `terraform.tfvars` and edit values locally (file is gitignored).

### Hard rules

- **Secrets never in code.** Postgres password, Redis access key, Storage keys → land in Key Vault, flow into pods via External Secrets Operator (ESO) using Workload Identity federation. No `*.tfvars` or shell heredocs with credentials.
- **No region drift.** Every resource is `centralindia`. The dev composition rejects any other location at variable-validation time.
- **State files never committed.** `*.tfstate`, `*.tfvars`, `*.tfplan`, kubeconfigs, and secret snapshots are all gitignored — see `.gitignore` for the full pattern list.
- **Lock files tracked.** `.terraform.lock.hcl` is checked in so every contributor gets the same provider versions.
- **Per-env Resource Groups.** dev, nprd, and prod each get their own RG (`gooclaim-rg-<env>`) — no cross-env resource sharing.

See `CONTRIBUTING.md` for branch + commit conventions when adding new Terraform modules.

---

## Reusable CI/CD Workflows

Every service repo has a **15-line** `.github/workflows/ci.yml` that calls this repo's reusable workflow:

```yaml
# In gooclaim-<service>/.github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  ci:
    uses: gooclaim-claimos/gooclaim-infra/.github/workflows/_reusable-ci.yml@main
    with:
      service-name: gooclaim-<service>
      python-version: "3.12"
      coverage-threshold: 80
    secrets:
      GH_PAT: ${{ secrets.GH_PAT }}
```

**`_reusable-ci.yml` runs:** lint (ruff) → typecheck (pyright strict) → security (bandit + safety + TruffleHog) → test (pytest + coverage) → Docker build. All jobs must pass before merge.

**`_reusable-deploy.yml` handles:** Docker image build + push to GHCR → deploy to the chosen environment → `kubectl rollout status` verification. Prod deploys require a manual `workflow_dispatch` + approval step.

### Changing CI behaviour

```bash
# Make the change in _reusable-ci.yml here
# Merge to develop → test on one service
# Merge to main → automatically applies to all repos on next push
```

No per-repo updates required. **The reusable workflow is the contract.**

---

## Service Scaffolding

Create a new Gooclaim service repo in one command:

```bash
cd gooclaim-infra
bash scripts/setup-service.sh gooclaim-<service>
```

**What the script does:**

1. Creates `../gooclaim-<service>/` directory with the full scaffold
2. Detects the layer from the service name (e.g. `gooclaim-knowledge` → `l3-knowledge.md` rules)
3. Copies `templates/` into place — Python src layout, `pyproject.toml`, `Dockerfile`, `tox.ini`, `.github/workflows/ci.yml`, `.claude/rules/` for the right layer, `CLAUDE.md`, `CLAUDE_SESSION.md`
4. Renames placeholders — `gooclaim-knowledge` → Python package `gooclaim_knowledge`
5. Prints the manual follow-up steps — create the GitHub repo, push, enable branch protection on `main` + `develop`, add environments

### Manual follow-up (one-time per service)

- `gh repo create gooclaim-claimos/gooclaim-<service> --private`
- `git push -u origin main && git push -u origin develop`
- GitHub → Settings → Branches → protect `main` + `develop` (require PR, CI green, 1 approver)
- GitHub → Settings → Environments → create `dev`, `sdx`, `nprd`, `prod` with appropriate protection rules

### Python package naming

Gooclaim convention: hyphens in repo names become underscores in Python packages.

| Repo | Python package |
|------|----------------|
| `gooclaim-gateway` | `gooclaim_gateway` |
| `gooclaim-knowledge` | `gooclaim_knowledge` |
| `gooclaim-engine` | `gooclaim_engine` |

The scaffold handles this automatically.

---

## Environment Ladder

```
local → dev → sdx → nprd → prod
```

| Environment | Trigger | Purpose |
|-------------|---------|---------|
| `local` | `docker compose up` | Developer workstation |
| `dev` | auto-deploy on merge to `develop` | Daily developer testing, shared dev cluster |
| `sdx` (sandbox) | manual `workflow_dispatch` | QA + internal demos + pilot tenant preview |
| `nprd` (non-prod) | auto-deploy on merge to `main` | Pre-prod rehearsal with realistic load |
| `prod` | manual `workflow_dispatch` + approval | Live TPA traffic |

**The env ladder is enforced by `_reusable-deploy.yml`** — environments + approval rules are defined in each service repo's GitHub Environment settings, not in code.

---

## Repo Registry (22 Repos)

Full details in [`docs/repos.md`](docs/repos.md) and per-repo state in [`VERSIONS.md`](VERSIONS.md).
Summary — **all 22 repos exist; 21 code-complete or scaffolded, 1 (`gooclaim-learning`) deferred to v2.0**. Plus auxiliary: `gooclaim-scout` (v1.0 ship-ready) + `gooclaim-mcp-server` (built, 99% cov).

### Group 1 — Foundation (4 repos, all built)

| Repo | Lang | Purpose |
|------|------|---------|
| `gooclaim-shared` ✅ | Python | Enums, contracts, shared types — *Register First Rule* |
| `gooclaim-infra` ✅ | Shell | This repo — CI/CD, templates, platform docs |
| `gooclaim-docs` ✅ | HTML | Architecture, ADRs, runbooks, layer specs |
| `gooclaim-load-tests` ✅ | Python | k6 + pytest — SLA validation |

### Group 2 — Platform Services (7 repos, all built)

| Repo | Lang | Purpose |
|------|------|---------|
| `gooclaim-auth` ✅ | Python | JWT issuance + introspection + MFA + RBAC + connector creds (encrypted) |
| `gooclaim-audit` ✅ | Python | Immutable event ledger, IRDAI 7-year retention, SHA-256 signed |
| `gooclaim-model-gateway` ✅ | Python | AI proxy — Azure OAI + Sarvam, Virtual Keys, budget, circuit breaker |
| `gooclaim-template-registry` ✅ | Python | Channel × language templates, DRAFT→PENDING→APPROVED workflow |
| `gooclaim-tenant-config` ✅ | Python | Tenant identity + operational_mode + workflow config (REST + gRPC `:50051`) |
| `gooclaim-connector-hub` ✅ | Python | CMS connectors with REST → SFTP → RPA fallback chain, per-tenant CB |
| `gooclaim-policy` ✅ | Python | L6 safety gate — T1 keyword + T2 Guardrails AI + T3 PHI + T4 source check |

### Group 3 — Channel Layer (2 built, others planned)

| Repo | Lang | Purpose | Status |
|------|------|---------|:------:|
| `gooclaim-gateway` ✅ | Python | L0 — 3-gate filter, channel-agnostic ingress | Built |
| `gooclaim-whatsapp` ✅ | Python | WhatsApp adapter (webhook ingest + outbound send) | Built |
| `gooclaim-voice` 📋 | — | Voice adapter (ASR / TTS / telephony) | v2.0 |
| `gooclaim-sms` / `email` / `slack` 📋 | — | Other channel adapters | v2.0 / v3.0 |

### Group 4 — Products / UIs (3 repos, all built)

| Repo | Lang | Users | Purpose |
|------|------|-------|---------|
| `gooclaim-console` ✅ | TypeScript | Gooclaim staff | Platform admin — op_mode, tenants, audit, model registry |
| `gooclaim-portal` ✅ | TypeScript | Tenant admins | Tenant self-service — claims, connectors, KB, templates |
| `gooclaim-copilot` ✅ | TypeScript | TPA ops | AI copilot — tickets, KB search, bulk ops (never reaches L5) |

### Group 5 — Service Layers (5 built, 1 deferred)

| Repo | Lang | Purpose | Status |
|------|------|---------|:------:|
| `gooclaim-truth` ✅ | Python | L2 — Claim data fetch (read-only, fail-closed on STALE) | Built (97% cov) |
| `gooclaim-engine` ✅ | Python | L1 — Workflow engine + agentic orchestrator (RW1/RW2/RW3) | Built |
| `gooclaim-knowledge` ✅ | Python | L3 — RAG (Haystack components + pgvector + TenantFilter) | Built (92% cov) |
| `gooclaim-outbound` ✅ | Python | L5 — Template rendering + channel dispatch | Built |
| `gooclaim-observe` ✅ | Python | L7 — Metrics + Loki + Grafana + Health Aggregator | Built (v0.3.1) |
| `gooclaim-learning` 📋 | Python | L4 — Passive signal capture (v1.0), active learning (v2.0) | Deferred to v2.0 |

### Group 6 — Auxiliary Services (2 built)

| Repo | Lang | Purpose | Status |
|------|------|---------|:------:|
| `gooclaim-scout` ✅ | Python | IRDAI regulatory ingest agent — PydanticAI + 4-tool fallback (Serper/Tavily/Firecrawl/Parallel/BrightData) + Temporal cron + token budget guard | v1.0 ship-ready (98% cov) |
| `gooclaim-mcp-server` ✅ | Python | MCP server exposing platform tools to internal agents | Built (99% cov) |

### Group 7 — Additional Frontends (2 built)

| Repo | Lang | Users | Purpose | Status |
|------|------|-------|---------|:------:|
| `gooclaim-landing-page` ✅ | TypeScript | Public visitors | Marketing site (most polished, v0.3.0) | Built |
| `gooclaim-workflow-studio` 📋 | TypeScript | Gooclaim ops (v1.1) → TPAs (v2.0) | Visual drag-drop workflow builder (React Flow) | Scaffolded (v0.1.0) — features in v1.1/v2.0 |

---

## 3-UI Architecture

Gooclaim ships **3 separate UIs**, each tailored to one audience. All three authenticate against the same `gooclaim-auth` backend — **never duplicate login logic across UIs.**

| UI | Who uses it | Roles | Auth flow | MFA policy |
|----|-------------|-------|-----------|------------|
| **`gooclaim-console`** | Gooclaim staff | `SUPER_ADMIN`, `ADMIN`, `SUPPORT` | email + password + TOTP | TOTP **mandatory** |
| **`gooclaim-portal`** | Tenant admins | `TENANT_ADMIN`, `CONNECTOR_ADMIN`, `KB_MANAGER` | email + password | Per-tenant config (optional) |
| **`gooclaim-copilot`** | TPA ops teams | `TPA_OPS`, `TPA_VIEWER` | email + password | Per-tenant config (optional) |

**Auth flow (all UIs):**

```
UI login → POST /auth/login (gooclaim-auth) → JWT issued
            ↓
User opens downstream screen → UI passes JWT in Authorization header
            ↓
Downstream service (truth / knowledge / connector-hub / ...) verifies via
POST /auth/introspect (gooclaim-auth) → role + tenant_id + claims returned
```

Role matrix + enum values live in `gooclaim-shared` and are consumed by every service that needs to gate a route.

---

## Architecture Decisions

Platform-wide ADRs in [`docs/decisions/`](docs/decisions/):

| ADR | Decision |
|-----|----------|
| [ADR-001](docs/decisions/ADR-001-temporal-rw2.md) | Temporal for `pending-docs` (RW2) stateful workflow |
| [ADR-002](docs/decisions/ADR-002-guardrails-ai-l6.md) | Guardrails AI for L6 safety gate (T2 tier) |
| [ADR-003](docs/decisions/ADR-003-haystack-l3.md) | Haystack components for L3 ingestion + retrieval |
| [ADR-004](docs/decisions/ADR-004-templates-only-phase1.md) | Templates-only output in v1.0 (no free-text LLM to users) |
| [ADR-005](docs/decisions/ADR-005-l2-readonly-phase1.md) | L2 Truth Layer is read-only in v1.0 |

**Service-specific ADRs** live in each service's own repo at `docs/10-adr/` (e.g. `gooclaim-knowledge/docs/10-adr/006-temporal-for-scheduled-workers.md`). Cross-repo decisions that affect platform-wide rules are also reflected in root [`CLAUDE.md`](CLAUDE.md).

---

## Key Invariants

Non-negotiable platform rules. Break these at your peril — most have compliance (IRDAI, DPDP) consequences.

1. **Internal agents, external templates** — L1 reasoning is agentic + free-form; L5 output to users is templates-only. Never mix.
2. **L6 policy gate is mandatory** — no LLM output reaches a user without all 4 tiers (T1 keyword, T2 Guardrails AI semantic, T3 PHI redaction, T4 source/template check).
3. **Channel independence** — each channel = separate repo. One channel outage never affects others.
4. **Channel adapters are pure I/O** — no gate logic, no business logic, no claim processing.
5. **`gooclaim-gateway` is channel-agnostic** — adding a new channel requires zero gateway changes.
6. **`connector-hub` is L2's servant** — L2 never calls external APIs (CMS, SFTP, RPA) directly.
7. **`model-gateway` is the only path to AI providers** — L3 / L6 / L1 never import Azure OpenAI / Sarvam SDKs directly.
8. **L4 flywheel** — TPA-edited responses become gold data that improves agents over time. v2.0 active learning; v1.0 passive capture only.
9. **Register First Rule** — update `gooclaim-shared` with new `ServiceLayer` / `WorkflowID` / `AuditEventType` / `ChannelType` / `Language` values BEFORE building any new service that uses them.
10. **`gooclaim-audit` ledger is immutable** — schema changes require migration + IRDAI review. Events are SHA-256 signed. 7-year retention.
11. **`gooclaim-tenant-config` is the only source of truth for tenant identity + `operational_mode` + workflow config.** Every L0 / L1 service reads it via gRPC `:50051` on the hot path.
12. **`gooclaim-auth` is the only source of truth for user identity + connector credentials.** Credentials encrypted at rest; issued via `/auth/introspect` at runtime.
13. **3 UIs share one auth backend** — never duplicate login logic across console / portal / copilot.

---

## Runbooks

Operational playbooks in [`docs/runbooks/`](docs/runbooks/):

- **[`deploy.md`](docs/runbooks/deploy.md)** — step-by-step production deploy via GitHub Actions, including approval checkpoints + smoke test checklist
- **[`rollback.md`](docs/runbooks/rollback.md)** — immediate rollback procedure (`kubectl set image` → previous SHA) + full rollback procedure + decision tree
- **[`incident-response.md`](docs/runbooks/incident-response.md)** — on-call playbook for production incidents, severity classification, stakeholder communication

Runbooks should be **updated whenever the deploy flow changes**. They're the first place on-call looks during an incident — stale runbooks cost outage time.

---

## Postman Collections

Importable Postman collections for every service in [`postman/`](postman/):

```
postman/
├── globals/workspace.globals.yaml
├── gooclaim-audit.postman_{collection,environment}.json
├── gooclaim-auth.postman_{collection,environment}.json
├── gooclaim-connector-hub.postman_{collection,environment}.json
├── gooclaim-model-gateway.postman_{collection,environment}.json
├── gooclaim-policy.postman_{collection,environment}.json
└── gooclaim-template-registry.postman_{collection,environment}.json
```

Import into Postman workspace for quick local testing + manual QA. Environments are pre-configured for `local` + `dev`; duplicate for `sdx` / `nprd` / `prod` as needed.

---

## Local Development

Gooclaim has a unified `docker-compose.local.yml` covering every service + shared infrastructure:

```bash
# Clone the infra repo + sibling service repos into one workspace
mkdir gooclaim && cd gooclaim
git clone https://github.com/gooclaim-claimos/gooclaim-infra.git
git clone https://github.com/gooclaim-claimos/gooclaim-gateway.git
# ... repeat for services you need

# Bring up the stack
cd gooclaim-infra
cp .env.local.example .env.local
docker compose -f docker-compose.local.yml up -d
```

**What comes up:**
- PostgreSQL 16 + pgvector extension
- Redis 7 (cache + raw `BRPOP/LPUSH` queues with BullMQ-compatible key naming)
- `gooclaim-auth` (custom Python IdP — RS256 JWT, MFA, RBAC; **not Keycloak**)
- Temporal (for `pending-docs` + scheduled workers — see ADR-006 in `gooclaim-knowledge`)
- All `gooclaim-*` services pointing at the above

**`docker-compose.debug.yaml`** — same stack with debuggers exposed on host ports. Use for attaching IDE debuggers.

---

## Required Secrets

These GitHub Actions secrets must be set at the **organization level** for every service repo to use the reusable workflows:

| Secret | Purpose |
|--------|---------|
| `GH_PAT` | Classic PAT with `repo` + `write:packages` + `read:packages` — required for private `gooclaim-shared` dependency install + GHCR push |
| `KUBE_CONFIG` | kubeconfig (base64-encoded) for the target environment's GKE cluster |
| `GHCR_TOKEN` | Set to `GH_PAT` — `GITHUB_TOKEN` cannot push to org-level GHCR |

Per-environment secrets (DB URLs, API keys, etc.) are managed via **AWS Secrets Manager** pulled at runtime via the ESO wrapper — never committed to repos. See each service's `config.py` for the secret key pattern (`GOOCLAIM_SECRET__*` env-var fallback for local dev).

---

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the full guide. Key rules:

**Branch naming** (layer prefix mandatory for `feat` / `fix` / `test`):
```
feat/l1-pending-docs-temporal-workflow
fix/l6-phi-plaintext-in-logs
chore/upgrade-fastapi-0-111
docs/adr-temporal-scheduled-workers
hotfix/l5-outbound-retry-storm
```

**Commit format** (conventional commits):
```
<type>(<layer>): <short description>
```

**Merge strategy:**

| From | To | Method |
|------|-----|--------|
| `feat/*` / `fix/*` / `chore/*` | `develop` | Squash merge |
| `develop` | `main` | Merge commit |
| `hotfix/*` | `main` | Squash merge |
| `hotfix/*` | `develop` | Cherry-pick |

**Every PR** must pass CI (lint + typecheck + security + test), have test coverage ≥ 80% for new code, and include an `AuditEvent` emission for any new automated decision.

---

## Getting Help

- **Slack:** `#gooclaim-eng` (internal) · `#gooclaim-oncall` (production incidents)
- **Architectural questions:** open an issue with `question` label
- **CI/CD bugs:** open an issue in this repo with `ci` label
- **New ADR:** use the `/new-adr` Claude Code command (defined in `.claude/commands/new-adr.md`)

---

## License

Private — © Gooclaim. All rights reserved. This repository and all derived artifacts are proprietary.
