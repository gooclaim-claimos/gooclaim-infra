# gooclaim-infra

> Central infrastructure repository for [Gooclaim](https://github.com/gooclaim-claimos) — India's Agentic Claims OS.
>
> CI/CD pipelines, service scaffolding, architecture docs, runbooks, and shared tooling for all 21 Gooclaim repos.

[![License](https://img.shields.io/badge/license-private-red)](.)
[![Python](https://img.shields.io/badge/python-3.12-blue)](https://www.python.org/)
[![Node](https://img.shields.io/badge/node-20-green)](https://nodejs.org/)

---

## Table of Contents

1. [What This Repo Provides](#what-this-repo-provides)
2. [Repository Structure](#repository-structure)
3. [Reusable CI/CD Workflows](#reusable-cicd-workflows)
4. [Service Scaffolding](#service-scaffolding)
5. [Environment Ladder](#environment-ladder)
6. [Architecture & Layer Map](#architecture--layer-map)
7. [Repo Registry](#repo-registry)
8. [Architecture Decisions](#architecture-decisions)
9. [Runbooks](#runbooks)
10. [Postman Collections](#postman-collections)
11. [Local Development](#local-development)
12. [Required Secrets](#required-secrets)
13. [Contributing](#contributing)
14. [Getting Help](#getting-help)

---

## What This Repo Provides

Gooclaim is a **polyrepo platform** — each of the ~21 microservices lives in its own repository (`gooclaim-gateway`, `gooclaim-engine`, `gooclaim-knowledge`, etc.). `gooclaim-infra` is **not** a monorepo; it's the central support repo that every service depends on.

It provides three kinds of shared infrastructure:

- **Reusable CI/CD workflows** — every service's `.github/workflows/ci.yml` is a 15-line file that `workflow_call`s into this repo's `_reusable-ci.yml` and `_reusable-deploy.yml`. Change CI behaviour once, every service picks it up.
- **Service scaffolding** — `scripts/setup-service.sh` generates a new service repo with the correct folder layout, Dockerfile, `pyproject.toml`, `tox.ini`, `.claude/` rules for the right layer, and boilerplate CI wiring. One command → ready-to-push service repo.
- **Platform documentation + policy** — architecture diagrams, repo registry, ADRs, runbooks (deploy / rollback / incident response), environment table, Claude Code rules (`.claude/rules/`), and the canonical `CLAUDE.md` that all service repos inherit from.

No service code lives here. Every commit affects downstream repos — treat it with care.

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
│   ├── repos.md                      # Repo registry (21 services, Phase 1/2 split)
│   ├── email-directory.md            # Platform email addresses + purpose
│   ├── github-guide.md               # Branch protection, secret management
│   ├── decisions/                    # Platform-wide ADRs (001-005)
│   ├── runbooks/                     # deploy.md, rollback.md, incident-response.md
│   └── service-readme-template.md    # README template for new service repos
├── postman/                          # API collections + environments per service
├── CLAUDE.md                         # Root project memory (every service inherits)
├── CLAUDE_SESSION.md                 # Session log (architectural decisions + handoff notes)
├── CONTRIBUTING.md                   # Branch strategy, commit conventions, PR rules
└── README.md                         # This file
```

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
# Merge to main → automatically applies to all 21 repos on next push
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

## Architecture & Layer Map

See [`docs/architecture.md`](docs/architecture.md) for the full layer → repo mapping and data flows.

**Quick reference:**

```
L0  Channel Gateway      gooclaim-gateway           WhatsApp ingress, 3-gate filter
L1  Workflow Engine      gooclaim-engine            Config-driven workflows + Temporal for pending-docs
L2  Truth Layer          gooclaim-truth             CMS read via connector-hub (read-only Phase 1)
L3  Knowledge Layer      gooclaim-knowledge         RAG — pgvector + model-gateway + C4 safety
L4  Learning Loop        gooclaim-learning          Passive signal capture Phase 1
L5  Outbound Engine      gooclaim-outbound          Template rendering + WhatsApp send
L6  Policy Gate          gooclaim-policy            Content safety (T1+T2+T3+T4)
L7  Observability        gooclaim-observe           Metrics, logs, traces, alerts
—   Model Gateway        gooclaim-model-gateway     AI proxy (Azure OAI + future providers)
—   Connector Hub        gooclaim-connector-hub     CMS + doc-portal connectors
—   Audit Ledger         gooclaim-audit             Immutable audit event store (7-year IRDAI retention)
—   Auth                 gooclaim-auth              JWT issuance + introspection
—   Template Registry    gooclaim-template-registry Channel × language template store
```

Platform-wide rules in root [`CLAUDE.md`](CLAUDE.md). Every service inherits these.

---

## Repo Registry

See [`docs/repos.md`](docs/repos.md) for the full registry with status per repo (21 services total).

**At a glance:**
- Platform services: `gooclaim-shared`, `gooclaim-auth`, `gooclaim-audit`, `gooclaim-model-gateway`, `gooclaim-policy`, `gooclaim-template-registry`, `gooclaim-connector-hub`
- Layer services (L0–L7): `gooclaim-gateway`, `gooclaim-engine`, `gooclaim-truth`, `gooclaim-knowledge`, `gooclaim-learning`, `gooclaim-outbound`, `gooclaim-observe`
- Channel: `gooclaim-whatsapp`, `gooclaim-voice` (Phase 2)
- Data: `gooclaim-load-tests`, `gooclaim-scout` (Phase 2)
- UIs: `gooclaim-console` (internal ops), `gooclaim-copilot` (TPA), `gooclaim-portal` (tenant)
- Docs: `gooclaim-docs`

---

## Architecture Decisions

Platform-wide ADRs in [`docs/decisions/`](docs/decisions/):

| ADR | Decision |
|-----|----------|
| [ADR-001](docs/decisions/ADR-001-temporal-rw2.md) | Temporal for `pending-docs` workflow (stateful 24h wait) |
| [ADR-002](docs/decisions/ADR-002-guardrails-ai-l6.md) | Guardrails AI for L6 safety gate (T2 tier) |
| [ADR-003](docs/decisions/ADR-003-haystack-l3.md) | Haystack components for L3 ingestion + retrieval |
| [ADR-004](docs/decisions/ADR-004-templates-only-phase1.md) | Templates-only output in Phase 1 (no free-text LLM to users) |
| [ADR-005](docs/decisions/ADR-005-l2-readonly-phase1.md) | L2 Truth Layer is read-only in Phase 1 |

**Service-specific ADRs** live in each service's own repo at `docs/10-adr/` (e.g. `gooclaim-knowledge/docs/10-adr/006-temporal-for-scheduled-workers.md`). Cross-repo decisions that affect platform-wide rules are also reflected in root [`CLAUDE.md`](CLAUDE.md).

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
- Redis 7 (BullMQ queues + cache)
- Keycloak (local auth provider)
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
