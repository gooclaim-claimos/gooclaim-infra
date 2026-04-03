# Gooclaim — Project Memory
> Committed to git. Shared by all engineers. Keep under 200 lines.
> Last updated: March 2026 | Version: 1.0

---

## Architecture

- Monorepo: `apps/` (services) + `packages/` (shared libs) + `config/`
- Runtime: Python 3.12 (FastAPI) + Node 20 (where needed)
- Queue: BullMQ (Redis-backed) — 8 queues, security = highest priority
- DB: PostgreSQL 16 (primary) + Redis 7 (cache/queue)
- Orchestration: Temporal (RW2 stateful workflows only)
- AI: Azure OpenAI via Model Gateway only — never call Azure OAI directly
- Container: Docker + Kubernetes (GKE)
- Secrets: AWS Secrets Manager via ESO wrapper — never hardcode secrets

## Layer Map

L0–L7 are architecture shorthand (docs + diagrams only).
Wire format (BullMQ, audit DB, logs) uses descriptive slugs — see `ServiceLayer` enum in gooclaim-shared.

```
Shorthand   Wire format (ServiceLayer value)   Folder
─────────── ──────────────────────────────── ──────────────────────────
L0          channel-gateway                  apps/l0-channel-gateway
L1          workflow-engine                  apps/l1-workflow-engine
L2          truth-layer                      apps/l2-truth-layer
L3          knowledge-layer                  apps/l3-knowledge-layer
L4          learning-loop                    apps/l4-learning-loop
L5          outbound-engine                  apps/l5-outbound-engine
L6          policy-gate                      apps/l6-policy-gate
L7          observability                    apps/l7-observability
—           hub                              (connector hub, inside L2)
—           model-gateway                    (Azure OAI proxy)
—           audit                            (gooclaim-audit — immutable event ledger)
```

## Phase 1 Scope (Pilot)

- Channels: WhatsApp WABA only (no voice, no SMS) — P1 only
- Voice = separate service (`gooclaim-voice`) — P2; has its own ASR/TTS/telephony stack; never embed voice logic in gooclaim-gateway
- Workflows: RW1 (claim status) + RW2 (pending docs) + RW3 (query reason)
- Languages: HI, EN, HI_EN — config/languages.yml is source of truth
- Output: Templates only — never free-text LLM generation to users; templates must be channel-aware (WhatsApp HSM / Voice TTS / SMS / Web JSON)
- L2 mode: Read-only — no write-back to CMS
- L4 mode: Passive signal capture — no active learning yet

## Commands

```bash
# Install
pnpm install

# Dev (all services)
pnpm dev

# Dev (single service)
pnpm dev --filter=l1-workflow-engine

# Test
pnpm test                          # all
pnpm test --filter=l1-workflow-engine  # single service

# Lint + type check
pnpm lint
pnpm typecheck

# Build
pnpm build

# Docker local
docker compose up

# Temporal worker
pnpm temporal:worker

# DB migrations
pnpm db:migrate
pnpm db:migrate:rollback
```

## Code Conventions

- TypeScript strict mode — no `any`, no `as unknown`
- Python: type hints mandatory on all functions
- Component/class names: PascalCase
- Files + folders: kebab-case
- Env vars: SCREAMING_SNAKE_CASE
- Never import Azure OAI SDK directly — always use ModelGatewayClient
- Never log PHI fields (phone, name, claim_id in plaintext) — use hashed versions
- Every automated decision must emit an audit event — no silent failures
- Workflow versions are mandatory — every workflow has a version in registry.yml

## Testing Rules

- Unit tests mandatory for all business logic
- Integration tests for every connector (L2, L3, L5)
- Never mock the ModelGateway in integration tests — use test doubles
- Test file: `*.test.ts` or `test_*.py` co-located with source
- Coverage minimum: 80% lines

## gooclaim-shared — Register First Rule

**Before building any new service, channel, or workflow — register it in `gooclaim-shared` first.**

`gooclaim-shared` is the single source of truth for all platform identifiers.
If it is not registered here, it does not officially exist in the platform.

| Adding a new... | Register in gooclaim-shared first | Then build |
|-----------------|-----------------------------------|------------|
| Service (layer) | `ServiceLayer` enum — new value   | Service repo |
| Channel         | `ChannelType` enum — new value    | L0 adapter + L5 adapter |
| Workflow        | `WorkflowID` enum — new value     | L1 workflow + registry.yml |
| Audit event type| `AuditEventType` enum — new value | Service that emits it |
| Language        | `Language` enum — new value       | config/languages.yml |

**Why:** Every service imports `gooclaim-shared`. If each service defines its own strings,
audit DB ends up with `"outbound-engine"`, `"outbound"`, `"L5"` for the same layer —
IRDAI audit trail breaks, Grafana dashboards break, on-call queries return wrong data.

**Process:**
1. Open PR in `gooclaim-shared` — add enum value + bump version
2. Get review + merge
3. All consuming services update their `gooclaim-shared` dependency
4. Then build the new service/feature

## Do Not Touch

- `config/languages.yml` — only update via PR with team review
- `workflows/registry.yml` — only update via PR, version bump mandatory
- `packages/audit-ledger/` — schema changes require migration + IRDAI review
- `/generated/` — auto-generated, never edit manually

## Gooclaim-Specific Rules

- Operational Mode check before every workflow: OPERATIONAL / RESTRICTED / SUSPENDED
- Consent gate (DPDP) is Step 0 — no workflow runs without CONSENT_GIVEN
- L6 Policy Gate runs on every LLM output — never bypass
- Templates only in Phase 1 — if you are generating free text for end users, stop
- Templates are channel-aware — same template ID, different format per channel (WhatsApp HSM / Voice TTS script / SMS short / Web JSON); never hardcode WhatsApp-only format
- circuit_breaker state (CLOSED/OPEN/HALF_OPEN) must be Redis-backed per tenant
- fraud_suspect flag at 5+ NOT_FOUND events — do not remove this logic

## PR Checklist

Before opening a PR:
- [ ] Tests pass locally (`pnpm test`)
- [ ] No new `any` types introduced
- [ ] No secrets or PHI in code/logs
- [ ] Audit event emitted for any new automated decision
- [ ] CLAUDE_SESSION.md updated if architectural decision was made
- [ ] registry.yml version bumped if workflow changed
