# Gooclaim — Project Memory
> Committed to git. Shared by all engineers. Keep under 200 lines.
> Last updated: March 2026 | Version: 1.1

---

## Layer Map — Internal to GitHub

```
L0  →  gooclaim-gateway     Channel Gateway (WhatsApp in)
L1  →  gooclaim-engine      Workflow Engine (RW1/RW2/RW3)
L2  →  gooclaim-truth       Truth Layer (CMS connector)
L3  →  gooclaim-knowledge   Knowledge Layer (RAG/KB)
L4  →  gooclaim-learning    Learning Loop (passive P1)
L5  →  gooclaim-outbound    Outbound Engine (WhatsApp out)
L6  →  gooclaim-policy      Policy Gate (Guardrails/PHI)
L7  →  gooclaim-observe     Observability
—   →  gooclaim-audit       Audit Ledger (cross-cutting)
—   →  gooclaim-shared      Shared types + contracts
—   →  gooclaim-infra       CI/CD master + architecture docs
```

Full architecture: gooclaim-infra/ARCHITECTURE.md

---

## Architecture

- Stack: Python 3.12 (FastAPI) — all services
- Queue: BullMQ (Redis-backed) — 8 queues, security = highest priority
- DB: PostgreSQL 16 (primary) + Redis 7 (cache/queue)
- Orchestration: Temporal — RW2 stateful workflow only
- AI: Azure OpenAI via Model Gateway only — never call Azure OAI directly
- Container: Docker + Kubernetes
- Secrets: AWS Secrets Manager via ESO — never hardcode

---

## Phase 1 Scope (Pilot)

- Channel: WhatsApp WABA only
- Workflows: RW1 (claim status) + RW2 (pending docs) + RW3 (query reason)
- Languages: HI, EN, HI_EN — config/languages.yml is source of truth
- Output: Templates only — never free-text LLM to users
- L2: Read-only — no write-back to CMS
- L4: Passive signal capture — no active learning
- TPA: One pilot TPA

---

## Data Flow (one-liner per layer)

```
User → L0 gateway → L6 policy check → L1 engine → L2 truth + L3 knowledge
     → L1 engine → L5 outbound → User
     → L7 observe + Audit (parallel, every request)
```

---

## Commands

```bash
pip install -e ".[dev]"          # install
uvicorn src.<service>.main:app   # run
tox                              # all checks
tox -e lint                      # ruff only
tox -e typecheck                 # pyright only
tox -e security                  # bandit + safety + trufflehog
tox -e test                      # pytest + coverage (must be ≥80%)
```

---

## Contracts (in gooclaim-shared)

```
InteractionEvent    L0 → L1    WhatsApp message normalized
OutboundIntent      L1 → L5    Template to send
AuditEvent          All → Audit Every automated decision
ClaimRequest        L1 → L2    CMS query input
KBQuery             L1 → L3    Knowledge base query
```

---

## Code Rules

- No `any` type — pyright strict mode
- No `print()` — use `logger` always
- No PHI in logs — phone/name/claim_id only hashed versions
- No direct Azure OAI — always ModelGatewayClient
- No bypass of L6 Policy Gate — every LLM output goes through it
- Audit event mandatory for every automated decision
- Consent gate (DPDP) Step 0 — no workflow without CONSENT_GIVEN
- Operational Mode check Step 0a — before consent
- registry.yml version bump mandatory on workflow change

---

## Testing Rules

- Unit tests: all business logic
- Integration tests: every external connector
- Coverage minimum: 80% (CI gate — below this = PR blocked)
- Edge cases mandatory: NOT_FOUND, timeout, circuit breaker OPEN
- Test files: `test_*.py` co-located in `tests/`

---

## Do Not Touch Without Team Review

- `config/languages.yml` — language source of truth
- `workflow_config/registry.yml` — IRDAI audit trail
- `packages/audit-ledger/` — schema changes need migration
- `.github/CODEOWNERS` — protection rules
- `/generated/` — auto-generated, never edit

---

## Branch Naming

```
feat/<service>-<description>    e.g. feat/engine-rw1-claim-status
fix/<service>-<description>     e.g. fix/gateway-lang-detect-edge-case
chore/<description>             e.g. chore/upgrade-fastapi
hotfix/<description>            e.g. hotfix/policy-phi-in-logs
```

Service names: gateway, engine, truth, knowledge, policy, outbound, audit, observe

---

## PR Checklist (quick version)

```
[ ] tox passes locally
[ ] No any types, no print(), no hardcoded secrets
[ ] No PHI in logs
[ ] Audit event emitted for new automated decisions
[ ] CLAUDE_SESSION.md updated if architectural decision made
[ ] registry.yml bumped if workflow changed
```
