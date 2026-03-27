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

```
L0  — Channel Gateway     (apps/l0-channel-gateway)
L1  — Workflow Engine     (apps/l1-workflow-engine)
L2  — Truth Layer         (apps/l2-truth-layer)
L3  — Knowledge Layer     (apps/l3-knowledge-layer)
L4  — Learning Loop       (apps/l4-learning-loop)
L5  — Outbound Engine     (apps/l5-outbound-engine)
L6  — Policy Gate         (apps/l6-policy-gate)
L7  — Observability       (apps/l7-observability)
```

## Phase 1 Scope (Pilot)

- Channels: WhatsApp WABA only (no voice, no SMS)
- Workflows: RW1 (claim status) + RW2 (pending docs) + RW3 (query reason)
- Languages: HI, EN, HI_EN — config/languages.yml is source of truth
- Output: Templates only — never free-text LLM generation to users
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
