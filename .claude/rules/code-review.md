# Gooclaim — Code Review Rules for Claude

When reviewing code in this repo, apply these checks in order.

---

## 1. Security & Compliance (Block PR if any fail)

- [ ] No hardcoded secrets, API keys, passwords, or credentials
- [ ] No PHI in plaintext — phone, name, claim_id must be hashed in logs
- [ ] No direct Azure OpenAI SDK calls — must use `ModelGatewayClient`
- [ ] No AWS Secrets Manager bypass — all secrets via ESO wrapper
- [ ] DPDP consent gate not skipped — `CONSENT_GIVEN` check must be Step 0
- [ ] L6 Policy Gate not bypassed — every LLM output must pass through it

## 2. Audit & Observability (Block PR if any fail)

- [ ] Every automated decision emits an `AuditEvent` to BullMQ
- [ ] No silent failures — every exception logged with structured logger
- [ ] No `print()` statements — only `logger.*` allowed
- [ ] Operational Mode (`OPERATIONAL / RESTRICTED / SUSPENDED`) checked before workflow execution
- [ ] `fraud_suspect` flag logic intact — 5+ NOT_FOUND events must set flag

## 3. Code Quality

- [ ] No `any` types (TypeScript) or missing type hints (Python)
- [ ] No `as unknown` casts
- [ ] Test coverage ≥ 80% for new code
- [ ] Unit tests for all business logic
- [ ] Integration tests for every new connector (L2, L3, L5)
- [ ] No mocking of ModelGateway in integration tests — use test doubles

## 4. Architecture Rules

- [ ] L1 decides. L5 executes. Never mix.
- [ ] L2 fetches. L1 uses. L1 never calls external systems directly.
- [ ] L6 gates ALL output — no message reaches user without L6 check
- [ ] `circuit_breaker` state is Redis-backed per tenant — not in-memory
- [ ] Workflow version bumped in `registry.yml` if workflow changed
- [ ] `config/languages.yml` not touched without team PR review
- [ ] RW2 stateful logic only in Temporal workflow — never FastAPI (see ADR-001)
- [ ] L6 uses Guardrails AI for semantic checks — no bypass or inline regex substitution (see ADR-002)
- [ ] All embedding + LLM calls go through `ModelGatewayClient` — Haystack pipeline included (see ADR-003)
- [ ] L3 C4 Content Safety Gate and L6 share the same Guardrails AI container — changes to one affect both

## 5. Phase 1 Constraints

- [ ] No free-text LLM generation to end users — templates only
- [ ] L2 is read-only — no write-back to CMS
- [ ] L4 is passive — no active learning or model updates
- [ ] Channels: WhatsApp only — no SMS, voice, email paths added

## 6. Review Comment Format

When leaving feedback:
- **BLOCK:** — must fix before merge
- **SUGGEST:** — recommended improvement, not blocking
- **NOTE:** — informational, no action needed
